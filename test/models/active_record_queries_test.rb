require "test_helper"

class ActiveRecordQueriesTest < ActiveSupport::TestCase
  test "provider clients and client providers follow enrollments" do
    provider = create_provider("Rivera")
    another_provider = create_provider("Chen")
    client = create_client("Avery")
    another_client = create_client("Jordan")

    enroll(provider, client)
    enroll(provider, another_client)
    enroll(another_provider, client)

    assert_equal [ client, another_client ], provider.clients.order(:id).to_a
    assert_equal [ provider, another_provider ], client.providers.order(:id).to_a
  end

  test "client journal entries are returned in chronological order with an id tie breaker" do
    client = create_client("Avery")
    timestamp = Time.zone.parse("2026-10-14 09:00:00")
    later = create_entry(client, "later", timestamp + 1.day)
    first = create_entry(client, "first", timestamp)
    second = create_entry(client, "second", timestamp)

    assert_equal [ first, second, later ], client.journal_entries.chronological.to_a
  end

  test "provider journal entries include every enrolled client once and are chronological" do
    provider = create_provider("Rivera")
    another_provider = create_provider("Chen")
    first_client = create_client("Avery")
    second_client = create_client("Jordan")
    timestamp = Time.zone.parse("2026-10-14 09:00:00")

    enroll(provider, first_client)
    enroll(provider, second_client)
    enroll(another_provider, first_client)

    later = create_entry(second_client, "later", timestamp + 1.day)
    first = create_entry(first_client, "first", timestamp)
    second = create_entry(second_client, "second", timestamp)
    create_entry(create_client("Unenrolled"), "not included", timestamp - 1.day)

    entries = provider.journal_entries.chronological

    assert_equal [ first, second, later ], entries.to_a
    assert_equal entries.count, entries.distinct.count
    assert_match(/SELECT DISTINCT/, entries.to_sql)
  end

  test "provider journal entries can be limited to one associated client" do
    provider = create_provider("Rivera")
    client = create_client("Avery")
    other_client = create_client("Jordan")

    enroll(provider, client)
    enroll(provider, other_client)
    entry = create_entry(client, "for Avery", Time.zone.parse("2026-10-14 09:00:00"))
    create_entry(other_client, "for Jordan", Time.zone.parse("2026-10-14 10:00:00"))

    assert_equal [ entry ], provider.journal_entries.where(client:).chronological.to_a
  end

  private

  def create_provider(name)
    Provider.create!(name:, email: "#{name.downcase}-#{SecureRandom.uuid}@example.com")
  end

  def create_client(name)
    Client.create!(name:, email: "#{name.downcase}-#{SecureRandom.uuid}@example.com")
  end

  def enroll(provider, client)
    Enrollment.create!(provider:, client:, plan: :basic)
  end

  def create_entry(client, content, created_at)
    JournalEntry.create!(client:, content:, created_at:, updated_at: created_at)
  end
end
