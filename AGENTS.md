# Development guidance

This project is for Healthie Rails pairing interview preparation.

- Prefer idiomatic Rails and ActiveRecord. Preserve existing conventions.
- Write simple, readable code; avoid unnecessary abstractions and gems.
- Keep changes small and focused, with minimal tests for meaningful behavior.
- Explain significant architectural decisions and update the README and
  `docs/ARCHITECTURE.md` when those decisions change.
- Avoid production infrastructure; this is an interview exercise.
- Do not implement future interview requirements unless explicitly requested.
  Domain models, validations, queries, seeds, authentication, and application
  endpoints are not part of the initial bootstrap.

## Current foundation

Ruby 3.4.11, Rails 8.1.4, PostgreSQL, and Minitest. API-only mode retains
ActiveRecord while omitting browser asset and session setup. There are no domain
models or migrations yet. `ApplicationRecord` is the generated abstract base.
`/up` is Rails' generated boot health check.

## Commands

Use the existing Ruby version manager and a running local PostgreSQL server.

```sh
bundle install
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
bin/rails server
bin/rails console
bin/rails test
bin/rails runner 'puts ActiveRecord::Base.connection.adapter_name'
```

`bin/setup --skip-server` performs conventional setup without starting the server.
Development and test databases are separate. Keep lockfiles, database configuration,
and future schema/migration files tracked; never commit local secrets or dumps.
