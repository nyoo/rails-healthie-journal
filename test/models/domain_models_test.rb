require "test_helper"

class DomainModelsTest < ActiveSupport::TestCase
  test "models expose the expected associations" do
    assert_equal :has_many, Provider.reflect_on_association(:enrollments).macro
    assert_equal "Client", Provider.reflect_on_association(:clients).class_name
    assert_equal :has_many, Client.reflect_on_association(:enrollments).macro
    assert_equal "Provider", Client.reflect_on_association(:providers).class_name
    assert_equal :has_many, Client.reflect_on_association(:journal_entries).macro
    assert_equal :belongs_to, Enrollment.reflect_on_association(:provider).macro
    assert_equal :belongs_to, Enrollment.reflect_on_association(:client).macro
    assert_equal :belongs_to, JournalEntry.reflect_on_association(:client).macro
  end

  test "provider and client require names and emails" do
    provider = Provider.new
    client = Client.new

    assert_not provider.valid?
    assert_includes provider.errors[:name], "can't be blank"
    assert_includes provider.errors[:email], "can't be blank"
    assert_not client.valid?
    assert_includes client.errors[:name], "can't be blank"
    assert_includes client.errors[:email], "can't be blank"
  end

  test "enrollment validates plan and provider client uniqueness" do
    provider = create_provider
    client = create_client
    Enrollment.create!(provider:, client:, plan: :basic)

    duplicate = Enrollment.new(provider:, client:, plan: :premium)
    invalid_plan = Enrollment.new(provider:, client: create_client, plan: "other")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:client_id], "has already been taken"
    assert_not invalid_plan.valid?
    assert_includes invalid_plan.errors[:plan], "is not included in the list"
    assert_equal %w[basic premium], Enrollment.plans.keys
  end

  test "active enrollment pair is unique at the database level" do
    provider = create_provider
    client = create_client
    Enrollment.create!(provider:, client:, plan: :basic)

    assert_raises ActiveRecord::RecordNotUnique do
      Enrollment.insert_all!([ {
        provider_id: provider.id,
        client_id: client.id,
        plan: "premium",
        started_at: Time.current,
        created_at: Time.current,
        updated_at: Time.current
      } ])
    end
  end

  test "journal entries require content and belong to a client" do
    client = create_client
    entry = JournalEntry.new(client:, content: "Felt well today.")

    assert_predicate entry, :valid?
    assert_equal client, entry.client
    assert_not JournalEntry.new(client:).valid?
  end

  test "ending enrollments preserves history and allows a new active enrollment" do
    provider = create_provider
    client = create_client
    entry = JournalEntry.create!(client:, content: "Feeling well")
    started_at = 2.days.ago
    first = Enrollment.create!(provider:, client:, plan: :basic, started_at:)
    first.update!(ended_at: 1.day.ago)
    second = Enrollment.create!(provider:, client:, plan: :premium)
    historical = Enrollment.create!(provider:, client:, plan: :basic,
      started_at:, ended_at: started_at)

    assert_equal [ first, second, historical ], client.enrollments.order(:id).to_a
    assert_equal [ second ], Enrollment.active.where(provider:, client:).to_a
    assert_not first.reload.active?
    assert_equal provider, first.provider
    assert_equal client, first.client
    client.update!(deactivated_at: Time.current)
    assert_equal client, entry.reload.client
    assert_equal [ entry ], client.journal_entries.to_a
    assert_not Client.active.exists?(client.id)
    assert Provider.active.exists?(provider.id)
    provider.update!(deactivated_at: Time.current)
    assert_not Provider.active.exists?(provider.id)
    assert second.reload.active?
  end

  test "enrollment requires a plan and start and rejects an end before its start" do
    enrollment = Enrollment.new(provider: create_provider, client: create_client,
      plan: nil, started_at: nil)
    assert_not enrollment.valid?
    assert_includes enrollment.errors[:plan], "can't be blank"
    assert_includes enrollment.errors[:started_at], "can't be blank"

    enrollment.assign_attributes(plan: :basic, started_at: Time.current, ended_at: 1.day.ago)
    assert_not enrollment.valid?
    assert_includes enrollment.errors[:ended_at], "cannot precede started_at"
  end

  test "historical enrollments restrict deletion of either participant" do
    provider = create_provider
    client = create_client
    Enrollment.create!(provider:, client:, plan: :basic, started_at: 1.day.ago, ended_at: Time.current)

    assert_raises(ActiveRecord::DeleteRestrictionError) { client.destroy! }
    assert_raises(ActiveRecord::DeleteRestrictionError) { provider.destroy! }
    error = assert_raises ActiveRecord::StatementInvalid do
      Client.transaction(requires_new: true) { client.delete }
    end
    assert_instance_of PG::RestrictViolation, error.cause
    error = assert_raises ActiveRecord::StatementInvalid do
      Provider.transaction(requires_new: true) { provider.delete }
    end
    assert_instance_of PG::RestrictViolation, error.cause
  end

  test "journal entries restrict client deletion without enrollments" do
    client = create_client
    entry = JournalEntry.create!(client:, content: "Feeling well")

    assert_raises(ActiveRecord::DeleteRestrictionError) { client.destroy! }
    error = assert_raises ActiveRecord::StatementInvalid do
      Client.transaction(requires_new: true) { client.delete }
    end
    assert_instance_of PG::RestrictViolation, error.cause
    assert_equal client, entry.reload.client
  end

  private

  def create_provider
    Provider.create!(name: "Dr. Rivera", email: "rivera-#{SecureRandom.uuid}@example.com")
  end

  def create_client
    Client.create!(name: "Avery Smith", email: "avery-#{SecureRandom.uuid}@example.com")
  end
end
