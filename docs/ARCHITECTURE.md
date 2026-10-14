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

## Scope and planned work

The foundation intentionally has no domain models, migrations, validations,
queries, or seed data. Mail, file storage, background jobs, realtime features,
frontend frameworks, and deployment tooling are omitted because they do not
support the current exercise.

Subsequent PRs may introduce Provider, Client, Enrollment, and JournalEntry models,
their relationships, validations, and queries as requirements are explicitly
provided. These are planned concepts, not implemented components. Add focused
tests alongside that behavior and update this document as architecture changes.
