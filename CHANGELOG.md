# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-03-15

### Added
- Create new records with `n` key in table view
- `create_row(attributes)` method on the `DataSource` protocol
- Two-mode form UX: select mode (vim-style navigation) and inline edit mode
- Unsaved changes confirmation dialog when leaving a dirty form
- Ctrl+E opens `$EDITOR` for any field type (not just `:text`)
- Vim-style `j`/`k` field navigation in form select mode
- PageUp/PageDown pagination (replaces `n`/`p`)

### Changed
- Form title is now dynamic ("New Record" vs "Edit Record")
- Removed duplicate help text from form body (shown only in status bar)
- Removed dead code from `TableView#compute_widths`

### Fixed
- SQL logging no longer interferes with TUI in dev mode (suppressed for entire session)
- Esc in edit mode now discards field changes (Enter confirms)
- Save errors display inline instead of crashing
- Stale in-memory data no longer shown after failed save (record reloaded)
- Column labels use raw names instead of capitalized

## [0.2.0] - 2026-03-14

### Added
- `has_ratamin` DSL on models to declare which columns to display and override labels/widths
- `Ratamin::Railtie` (opt-in via `require "ratamin/railtie"`) — injects `has_ratamin`/`Model.ratamin` into all AR models and `scope.ratamin` into `AR::Relation`
- Default sort order is now newest-first (descending primary key) when no explicit order is given

### Fixed
- `has_ratamin` columns now inherit type and editability from the AR schema; explicitly passed options override the schema defaults
- `Model.ratamin` no longer causes `SystemStackError` when the Railtie is not loaded
- Forms where all columns are read-only no longer trap the user — `Esc` and `Enter` always work
- Pagination fallback order now uses a table-qualified `ORDER BY "table"."id"` to avoid ambiguous column errors on joined scopes

## [0.1.0] - 2026-03-14

### Added
- TUI admin console built on `ratatui_ruby` with table view and inline form editing
- `ArrayDataSource` for in-memory data with a duck-type `DataSource` protocol
- `ScopeDataSource` for ActiveRecord scopes with automatic column inference
- Pagination support for AR scopes (limit/offset with configurable `per_page`)
- `$EDITOR` integration for `:text` type fields (respects arguments in `$EDITOR`)
- Non-editable fields (`id`, `created_at`, `updated_at`) protected from editing
- Save failure handling — validation errors displayed inline in the form
- Dirty tracking — only changed fields are sent to `update_row`
- Zeitwerk autoloading
- RSpec test suite with in-memory SQLite for ActiveRecord integration tests
- GitHub Actions CI on Ruby 3.3, 3.4, and 4.0

[Unreleased]: https://github.com/onyxblade/ratamin/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/onyxblade/ratamin/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/onyxblade/ratamin/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/onyxblade/ratamin/releases/tag/v0.1.0
