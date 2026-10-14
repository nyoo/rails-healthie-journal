require "test_helper"

class ActiveRecordQueriesTest < ActiveSupport::TestCase
  test "provider current clients include multiple active clients" do
    provider = create_provider("Rivera")
    client = create_client("Avery")
    another_client = create_client("Jordan")

    enroll(provider, client)
    enroll(provider, another_client)

    assert_equal [ client, another_client ], provider.current_clients.order(:id).to_a
    assert_respond_to provider.current_clients, :where
  end

  test "ended enrollments are historical and excluded from provider current clients" do
    provider = create_provider("Rivera")
    current_client = create_client("Avery")
    former_client = create_client("Jordan")

    enroll(provider, current_client)
    enroll(provider, former_client, ended_at: Time.current)

    assert_equal [ current_client ], provider.current_clients.to_a
    assert_equal [ current_client, former_client ], provider.clients.order(:id).to_a
    assert_equal [ former_client ], provider.enrollments.where.not(ended_at: nil).map(&:client)
  end

  test "client current providers include multiple active providers and exclude historical ones" do
    client = create_client("Avery")
    first_provider = create_provider("Rivera")
    second_provider = create_provider("Chen")
    former_provider = create_provider("Patel")

    enroll(first_provider, client)
    enroll(second_provider, client)
    enroll(former_provider, client, ended_at: Time.current)

    assert_equal [ first_provider, second_provider ], client.current_providers.order(:id).to_a
    assert_equal [ first_provider, second_provider, former_provider ], client.providers.order(:id).to_a
  end

  test "client journal entries remain available without active enrollments and order recent first" do
    client = create_client("Avery")
    provider = create_provider("Rivera")
    timestamp = Time.zone.parse("2026-10-14 09:00:00")
    later = create_entry(client, "later", timestamp + 1.day)
    first = create_entry(client, "first", timestamp)
    second = create_entry(client, "second", timestamp)
    enroll(provider, client, ended_at: Time.current)

    assert_equal [ later, second, first ], client.journal_entries.recent_first.to_a
    assert_empty client.current_providers
  end

  test "provider current-client journal entries exclude former clients and are distinct" do
    provider = create_provider("Rivera")
    first_client = create_client("Avery")
    second_client = create_client("Jordan")
    former_client = create_client("Taylor")
    timestamp = Time.zone.parse("2026-10-14 09:00:00")

    enroll(provider, first_client)
    enroll(provider, second_client)
    enroll(provider, former_client, ended_at: Time.current)

    later = create_entry(second_client, "later", timestamp + 1.day)
    first = create_entry(first_client, "first", timestamp)
    second = create_entry(second_client, "second", timestamp)
    create_entry(former_client, "former", timestamp + 2.days)

    entries = provider.current_client_journal_entries.recent_first

    assert_equal [ later, second, first ], entries.to_a
    assert_equal entries.count, entries.distinct.count
    assert_match(/SELECT DISTINCT/, entries.to_sql)
    assert_respond_to entries, :where
  end

  test "a new active enrollment after history does not duplicate provider journal entries" do
    provider = create_provider("Rivera")
    client = create_client("Avery")

    enroll(provider, client, ended_at: 1.day.ago)
    enroll(provider, client)
    entry = create_entry(client, "for Avery", Time.zone.parse("2026-10-14 09:00:00"))

    assert_equal [ entry ], provider.current_client_journal_entries.to_a
    assert_equal 1, provider.current_client_journal_entries.count
  end

  private

  def create_provider(name)
    Provider.create!(name:, email: "#{name.downcase}-#{SecureRandom.uuid}@example.com")
  end

  def create_client(name)
    Client.create!(name:, email: "#{name.downcase}-#{SecureRandom.uuid}@example.com")
  end

  def enroll(provider, client, ended_at: nil)
    Enrollment.create!(provider:, client:, plan: :basic, started_at: ended_at ? ended_at - 1.day : Time.current, ended_at:)
  end

  def create_entry(client, content, created_at)
    JournalEntry.create!(client:, content:, created_at:, updated_at: created_at)
  end
end
