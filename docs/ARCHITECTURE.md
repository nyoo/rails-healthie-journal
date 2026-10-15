# Initial architecture

## Rails foundation

The project uses Ruby 3.4.11 and Rails 8.1.4 with conventional `app/`, `config/`,
`db/`, and `test/` directories. ActiveRecord provides the persistence layer;
`ApplicationRecord` is its generated abstract base class. Minitest provides the
standard Rails testing harness. Puma serves HTTP requests.

The application enables conventional Rails controller and view support for a small,
read-only data explorer. `ApplicationController` inherits from
`ActionController::Base`, and the explorer exposes only index and show routes for
providers, clients, enrollments, and journal entries; the root route lists
providers. It does not introduce application APIs or mutation endpoints. The
layout contains the explorer's small amount of CSS, avoiding asset-pipeline and
frontend-package dependencies. Rails' generated `/up` boot health check remains
available and does not query the database.

## PostgreSQL

PostgreSQL supports the relational modeling and ActiveRecord queries that will be
the focus of the interview. The existing local PostgreSQL 18.6 installation is
used without Docker. Development and test connect to localhost with the default
local PostgreSQL role and separate databases:

- `rails_healthie_journal_development`
- `rails_healthie_journal_test`

`bin/rails db:prepare` creates and prepares these databases. Local credentials can
be supplied through standard PostgreSQL environment variables. Production database
configuration remains the generated Rails default.

## Domain schema

The domain uses four conventional ActiveRecord models:

- `Provider` has a required name and email, many enrollments, and many clients
  through enrollments.
- `Client` has a required name and email, many enrollments, many providers through
  enrollments, and many journal entries.
- `Enrollment` belongs to a provider and client and has a required `plan` of
  `basic` or `premium`.
- `JournalEntry` belongs to a client and has required freeform text content.

All tables use Rails timestamps. Foreign keys are non-null and use `ON DELETE
RESTRICT`. Providers and clients restrict deletion when enrollments exist, and
clients also restrict deletion when journal entries exist, using
`dependent: :restrict_with_exception`. Database foreign keys enforce the same
protection for direct deletes. This preserves relationship history and client-owned
journal entries after a relationship ends or a participant becomes inactive.

Enrollments have a required `started_at` (defaulting to the current time for new
ActiveRecord objects) and nullable `ended_at`. Existing start times are backfilled
from `created_at`. End a relationship with `enrollment.update!(ended_at: Time.current)`;
the enrollment and both participants remain stored. An end cannot precede its start.
`Enrollment.active` and `active?` identify records with no end timestamp.

A provider/client pair may have multiple historical enrollments. A PostgreSQL
partial unique index on `[provider_id, client_id] WHERE ended_at IS NULL` permits
that history while enforcing at most one active enrollment, including concurrent
writes and writes bypassing validation. The matching conditional ActiveRecord
validation provides ordinary validation errors. A separate provider index supports
lookups across all history. The string-backed plan enum and database check
constraint retain the allowed `basic` and `premium` values.

Providers and clients have nullable `deactivated_at` timestamps and an `active`
scope. Participant status is separate from enrollment status: a client may end one
provider relationship while retaining another, and deactivation does not implicitly
end enrollments. Through-associations include historical relationships.

Historical record retention does not grant authorization to access those records.
Neither an enrollment association nor its active status implements an access policy;
authorization is outside this exercise. Actual healthcare retention requirements
and deletion policies are also outside scope. There is no soft-deletion framework
or retention service. The history migration deliberately refuses rollback because
the original pair uniqueness cannot represent multiple historical enrollments.

## Production considerations

Healthcare retention periods, legal holds, and a client's deletion request need a
policy-driven workflow rather than ad hoc record deletion; that workflow may retain
some records while deleting or de-identifying others. Access to current and
historical health data needs authorization based on the actor and relationship, and
auditable access/change logs and privacy controls would be required. At larger
volumes, paginate journal-entry result sets and measure query plans before adding
indexes beyond the current foreign-key and active-pair indexes. Plan changes are
currently represented by ending one enrollment and beginning another. If future
rules allow overlapping enrollment periods, add explicit date-range constraints and
decide which relationship controls access.

## ActiveRecord queries

The required queries use explicit current-relationship associations alongside the
existing historical associations:

- `provider.current_clients` joins through `active_enrollments`, which applies
  `ended_at IS NULL`. `provider.clients` returns each historically related client
  once; `provider.enrollments` retains the individual enrollment records.
- `client.current_providers` applies the same filter in the inverse direction;
  `client.providers` returns each historically related provider once, while
  `client.enrollments` retains individual relationship periods.
- `client.journal_entries.recent_first` filters by the `journal_entries.client_id`
  foreign key and therefore includes entries even when the client has no active
  enrollments.
- `provider.current_client_journal_entries.recent_first` joins through current
  clients only and returns entries for clients currently enrolled with that
  provider. The partial unique index guarantees at most one active join row for
  each provider/client pair, so entries are not duplicated without adding
  `DISTINCT`; that also keeps later `pluck` or `select` calls composable with the
  ordering scope. It does not restrict entries to the dates of an enrollment: an
  entry created before, during, or after an active enrollment is included as long
  as the client is currently enrolled.

`JournalEntry.recent_first` orders by `created_at DESC, id DESC`. The schema has no
separate entry-date field, so `created_at` is the journal-entry date for this
exercise. Ordering by the primary key makes results deterministic when timestamps
are equal. These associations and scope return relations, so callers can compose
additional conditions.

The current-relationship queries deliberately do not apply the provider or client
`active` scopes. Enrollment lifecycle and participant deactivation are separate
concepts, and this exercise defines "current" as an enrollment with no `ended_at`.
Historical relationships remain straightforward to inspect with
`provider.enrollments`, `client.enrollments`, `Enrollment.where(provider:, client:)`,
and `Enrollment.where.not(ended_at: nil)`.

The existing foreign-key indexes support the direct client-entry lookup and the
enrollment joins. For a much larger dataset, the query shape remains useful but a
composite index tailored to the final access pattern (for example,
`journal_entries(client_id, created_at, id)`) could reduce sorting work; the active
enrollment partial index already serves the current relationship lookup. Pagination
would also become relevant for application responses. Those production optimizations
are intentionally outside this exercise.

## Development seed data and scope

`db/seeds.rb` provides a small deterministic development dataset for explaining
the associations and lifecycle-aware queries in a pairing interview. It finds
participants by stable sample email addresses, historical enrollments by their
provider, client, and start time, and journal entries by client, content, and
timestamp. Re-running it preserves historical rows and does not delete existing
application data.

The data explorer loads its relationships through the existing ActiveRecord
associations and scopes: current participants use `current_clients` and
`current_providers`, enrollment history uses `enrollments`, and journal entries use
`recent_first`. It intentionally has no editing actions, custom query console,
authentication, or authorization policy. Mail, file storage, background jobs,
realtime features, frontend frameworks, and deployment tooling also remain out of
scope for this exercise.
