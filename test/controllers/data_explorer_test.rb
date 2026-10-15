require "test_helper"

class DataExplorerTest < ActionDispatch::IntegrationTest
  setup do
    @provider = Provider.create!(name: "Kaiser Permanente", email: "kaiser@example.test")
    @client = Client.create!(name: "Alice Nguyen", email: "alice.nguyen@example.test")
    @enrollment = Enrollment.create!(provider: @provider, client: @client, plan: :premium,
      started_at: Time.zone.parse("2026-01-15 09:00:00"))
    @journal_entry = JournalEntry.create!(client: @client, content: "Started a new nutrition plan.")
  end

  test "root and index pages provide the explorer navigation" do
    get root_path

    assert_response :success
    assert_select "h1", "Providers"
    assert_select "a[href='#{clients_path}']", "Clients"
    assert_select "a[href='#{enrollments_path}']", "Enrollments"
    assert_select "a[href='#{journal_entries_path}']", "Journal Entries"

    get clients_path
    assert_response :success
    assert_select "a[href='#{client_path(@client)}']", @client.name

    get enrollments_path
    assert_response :success
    assert_select "a[href='#{enrollment_path(@enrollment)}']", @enrollment.id.to_s

    get journal_entries_path
    assert_response :success
    assert_select "a[href='#{journal_entry_path(@journal_entry)}']", @journal_entry.id.to_s
  end

  test "detail pages link related records and show lifecycle information" do
    get provider_path(@provider)
    assert_response :success
    assert_select "h2", "Current Clients"
    assert_select "a[href='#{client_path(@client)}']", @client.name
    assert_select "a[href='#{enrollment_path(@enrollment)}']", @enrollment.plan

    get client_path(@client)
    assert_response :success
    assert_select "h2", "Current Providers"
    assert_select "a[href='#{provider_path(@provider)}']", @provider.name
    assert_select "a[href='#{journal_entry_path(@journal_entry)}']", @journal_entry.content

    get enrollment_path(@enrollment)
    assert_response :success
    assert_select "dd", "premium"

    get journal_entry_path(@journal_entry)
    assert_response :success
    assert_select ".content", @journal_entry.content
  end

  test "ended enrollments and their client journal entries remain visible" do
    @enrollment.update!(ended_at: Time.zone.parse("2026-02-01 09:00:00"))

    get provider_path(@provider)
    assert_response :success
    assert_select ".status.ended", "Ended"
    assert_select "a[href='#{client_path(@client)}']", @client.name

    get client_path(@client)
    assert_response :success
    assert_select ".empty", "No current providers."
    assert_select "a[href='#{journal_entry_path(@journal_entry)}']", @journal_entry.content
  end

  test "account status remains separate from an open enrollment" do
    @client.update!(deactivated_at: Time.zone.parse("2026-02-01 09:00:00"))

    get client_path(@client)

    assert_response :success
    assert_select "strong", "Account Status:"
    assert_select ".status.inactive", "Inactive"
    assert_select "h2", "Current Providers"
    assert_select "a[href='#{provider_path(@provider)}']", @provider.name
    assert_select "th", "Enrollment Status"
    assert_select ".status.active", "Active"
  end
end
