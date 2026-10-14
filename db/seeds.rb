# Deterministic development data for the ActiveRecord query walkthrough in README.md.

providers = {
  kaiser: Provider.find_or_create_by!(email: "kaiser@example.test") { |provider| provider.name = "Kaiser Permanente" },
  mayo: Provider.find_or_create_by!(email: "mayo@example.test") { |provider| provider.name = "Mayo Clinic" },
  cleveland: Provider.find_or_create_by!(email: "cleveland@example.test") { |provider| provider.name = "Cleveland Clinic" }
}

clients = {
  alice: Client.find_or_create_by!(email: "alice.nguyen@example.test") { |client| client.name = "Alice Nguyen" },
  bob: Client.find_or_create_by!(email: "bob.martinez@example.test") { |client| client.name = "Bob Martinez" },
  carol: Client.find_or_create_by!(email: "carol.johnson@example.test") { |client| client.name = "Carol Johnson" },
  devon: Client.find_or_create_by!(email: "devon.lee@example.test") { |client| client.name = "Devon Lee" },
  erin: Client.find_or_create_by!(email: "erin.patel@example.test") do |client|
    client.name = "Erin Patel"
    client.deactivated_at = Time.utc(2026, 7, 1, 12)
  end
}

[
  [ :kaiser, :alice, :premium, Time.utc(2026, 1, 15, 9), nil ],
  [ :mayo, :alice, :basic, Time.utc(2026, 2, 1, 9), nil ],
  [ :kaiser, :bob, :basic, Time.utc(2026, 2, 1, 9), Time.utc(2026, 4, 30, 17) ],
  [ :kaiser, :bob, :premium, Time.utc(2026, 6, 1, 9), nil ],
  [ :cleveland, :carol, :basic, Time.utc(2026, 1, 10, 9), Time.utc(2026, 3, 31, 17) ],
  [ :kaiser, :devon, :basic, Time.utc(2026, 3, 1, 9), nil ],
  [ :cleveland, :erin, :premium, Time.utc(2026, 4, 1, 9), nil ]
].each do |provider_key, client_key, plan, started_at, ended_at|
  Enrollment.find_or_create_by!(provider: providers.fetch(provider_key), client: clients.fetch(client_key), started_at:) do |enrollment|
    enrollment.plan = plan
    enrollment.ended_at = ended_at
  end
end

[
  [ :alice, "Started a new nutrition plan.", Time.utc(2026, 1, 16, 8) ],
  [ :alice, "Energy has improved this week.", Time.utc(2026, 6, 15, 8) ],
  [ :bob, "Returning to care with a new plan.", Time.utc(2026, 6, 2, 8) ],
  [ :carol, "Entry written while enrolled.", Time.utc(2026, 3, 15, 8) ],
  [ :carol, "Entry written after enrollment ended.", Time.utc(2026, 4, 15, 8) ],
  [ :devon, "Completed my first week of tracking.", Time.utc(2026, 3, 8, 8) ],
  [ :erin, "Continuing to record progress.", Time.utc(2026, 7, 15, 8) ]
].each do |client_key, content, created_at|
  JournalEntry.find_or_create_by!(client: clients.fetch(client_key), content:, created_at:) do |entry|
    entry.updated_at = created_at
  end
end
