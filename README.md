# Rails Healthie Journal

A minimal Rails foundation for Healthie full-stack engineering pairing interview
preparation. It provides ActiveRecord, PostgreSQL, Minitest, and the interview's
core domain schema. No seed data, application endpoints, or query methods exist yet.

## Prerequisites

- Ruby 3.4.11 (recorded in `.ruby-version`; use your existing Ruby version manager).
- Bundler 2.6.9 and Rails 8.1.4 (dependencies are pinned in `Gemfile.lock`).
- A running local PostgreSQL server on `localhost:5432`; verified with PostgreSQL
  18.6. No Node.js or Docker is required.

The database configuration uses the PostgreSQL role matching your operating-system
username. That role must be able to create databases. On the existing Homebrew
setup, PostgreSQL is managed with `brew services start postgresql@18`.
Check availability with `pg_isready -h localhost`.

If your local installation uses another role, password, or port, set the standard
PostgreSQL environment variables `PGUSER`, `PGPASSWORD`, and `PGPORT` in your shell.
Do not commit secrets. Rails also supports `DATABASE_URL`; use a separate test
database when setting a URL for tests.

## Local setup

```sh
bundle install
bin/rails db:prepare
```

This creates `rails_healthie_journal_development` and
`rails_healthie_journal_test`. To prepare only the test environment explicitly:

```sh
RAILS_ENV=test bin/rails db:prepare
```

Check ActiveRecord connectivity:

```sh
bin/rails runner 'puts ActiveRecord::Base.connection.adapter_name'
```

The expected output is `PostgreSQL`. `bin/setup --skip-server` is also available
as the conventional Rails setup helper.

## Development commands

```sh
bin/rails server
bin/rails console
bin/rails test
```

The server listens at `http://localhost:3000`. Verify boot using Rails' generated
health route:

```sh
curl --fail http://localhost:3000/up
```

There is no application root route. `/up` checks application boot, not database
connectivity. The Minitest harness is ready; there are currently no application
tests because no domain behavior has been implemented.

If port 3000 is occupied, run `bin/rails server -p 3001` and check
`http://localhost:3001/up`. The initial bootstrap was verified on port 3001.

## Architecture and next steps

The application uses Rails' API-only mode to omit browser assets and session
middleware while retaining conventional Rails and ActiveRecord structure.
Browser UI work would require adding that support later. Unused mail, storage,
jobs, realtime features, and deployment tooling were skipped.

The domain includes providers, clients, enrollments, and client-owned journal
entries. Enrollments connect providers and clients with a `basic` or `premium`
plan. Enrollments preserve relationship history using start/end timestamps, with
only one active enrollment per provider/client pair. Providers and clients can be
deactivated, and restrictive associations and foreign keys protect enrollments and
journal entries from accidental parent deletion. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the complete schema and design
rationale, and [AGENTS.md](AGENTS.md) for development guidance.
