# Initial architecture

## Rails foundation

The project uses Ruby 3.4.11 and Rails 8.1.4 with conventional `app/`, `config/`,
`db/`, and `test/` directories. ActiveRecord provides the persistence layer;
`ApplicationRecord` is its generated abstract base class. Minitest provides the
standard Rails testing harness. Puma serves HTTP requests.

API-only mode keeps the foundation small by omitting asset tooling, views, and
browser session middleware. It does not introduce application APIs. Browser UI
work would require adding the relevant Rails facilities later. The only explicit
route is Rails' generated `/up` boot health check, which does not query the database.

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

## Scope

The project intentionally does not yet include seed data, controllers, endpoints,
or the interview query methods. Mail, file storage, background jobs, realtime
features, frontend frameworks, and deployment tooling remain out of scope for this
exercise.
