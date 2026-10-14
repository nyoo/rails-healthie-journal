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

  test "enrollment pair is unique at the database level" do
    provider = create_provider
    client = create_client
    Enrollment.create!(provider:, client:, plan: :basic)

    assert_raises ActiveRecord::RecordNotUnique do
      Enrollment.insert_all!([ {
        provider_id: provider.id,
        client_id: client.id,
        plan: "premium",
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

  private

  def create_provider
    Provider.create!(name: "Dr. Rivera", email: "rivera-#{SecureRandom.uuid}@example.com")
  end

  def create_client
    Client.create!(name: "Avery Smith", email: "avery-#{SecureRandom.uuid}@example.com")
  end
end
