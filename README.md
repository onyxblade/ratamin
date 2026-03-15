# Ratamin

A TUI admin console for ActiveRecord, built on [ratatui_ruby](https://github.com/nicholasgasior/ratatui_ruby).

Give it a scope, get a navigable table with inline editing and `$EDITOR` support for long text.

## Installation

Add to your Gemfile:

```ruby
gem "ratamin"
```

## Usage

### Rails integration (automatic)

In a Rails app, `Model.ratamin` and `scope.ratamin` are available automatically — no configuration needed. Just add the gem and define which columns to show in your model:

```ruby
class User < ApplicationRecord
  has_ratamin do
    column :name, label: "Full Name", width: 20
    column :email, width: 30
    column :bio                        # type and editable inferred from schema
  end
end
```

Open the console and run:

```ruby
User.ratamin                           # all records, newest first
User.where(role: "admin").ratamin      # filtered scope
```

Column type (`:text` vs `:string`) and editability (`id`, `created_at`, `updated_at` are read-only by default) are inferred from the schema. Any option explicitly passed to `column` overrides the inferred default.

To opt out of the Rails integration, use `require: false` in your Gemfile and `require "ratamin"` manually — `scope.ratamin` will then be unavailable, but the core API still works.

### Manual usage (without Railtie)

```ruby
require "ratamin"

# Columns are inferred from the schema automatically
Ratamin::App.new(Ratamin::ScopeDataSource.new(User.all)).run

# Or specify columns explicitly
columns = [
  Ratamin::Column.new(key: :name, label: "Name", width: 20),
  Ratamin::Column.new(key: :email, label: "Email", width: 30),
  Ratamin::Column.new(key: :bio, label: "Bio", type: :text),
]
Ratamin::App.new(Ratamin::ScopeDataSource.new(User.all, columns: columns)).run
```

### Without ActiveRecord

```ruby
require "ratamin"

columns = [
  Ratamin::Column.new(key: :name, width: 20),
  Ratamin::Column.new(key: :email, width: 30),
]

rows = [
  { name: "Alice", email: "alice@example.com" },
  { name: "Bob",   email: "bob@example.com" },
]

ds = Ratamin::ArrayDataSource.new(columns: columns, rows: rows)
Ratamin::App.new(ds).run
```

## Keybindings

### Table view

| Key | Action |
|-----|--------|
| `j` / `Down` | Next row |
| `k` / `Up` | Previous row |
| `g` | First row |
| `G` | Last row |
| `Enter` | Edit selected record |
| `r` | Reload data |
| `q` | Quit |

### Form view

| Key | Action |
|-----|--------|
| `Tab` | Next field |
| `Shift+Tab` | Previous field |
| `Enter` | Save |
| `Esc` | Cancel |
| `e` | Open `$EDITOR` (on `:text` fields) |

## Architecture

Ratamin separates data, state, and rendering:

- **DataSource** — duck-type protocol (`#columns`, `#rows`, `#update_row`, `#reload!`)
  - `ArrayDataSource` — in-memory arrays
  - `ScopeDataSource` — wraps an ActiveRecord scope
- **State** — pure Ruby, no TUI dependency, fully unit-testable
  - `FormState` — field values, cursor, text editing, validation errors
- **Views** — thin renderers that read from state objects
  - `TableView` — record list with selection
  - `FormView` — field-by-field editor

## Column types

| Type | Behavior |
|------|----------|
| `:string` (default) | Inline text editing |
| `:text` | Truncated in table, opens `$EDITOR` for editing |

## Development

```bash
bin/setup
bundle exec rspec
```

## License

MIT
