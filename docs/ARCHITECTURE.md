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
CASCADE`. The parent ActiveRecord associations also use `dependent: :destroy` so
ordinary application deletion runs through Rails while direct database deletion
cannot leave orphaned rows. Client journal entries are deleted with their client;
enrollments are deleted with either participant.

`enrollments` has a unique composite index on `[provider_id, client_id]`, backed
by a matching ActiveRecord uniqueness validation, so the same relationship cannot
be recorded twice. Its string-backed enum keeps plan values readable in the
database, while a PostgreSQL check constraint allows only `basic` and `premium`,
including when writes bypass ActiveRecord.

## Scope

The project intentionally does not yet include seed data, controllers, endpoints,
or the interview query methods. Mail, file storage, background jobs, realtime
features, frontend frameworks, and deployment tooling remain out of scope for this
exercise.
