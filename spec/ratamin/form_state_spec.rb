# frozen_string_literal: true

RSpec.describe Ratamin::FormState do
  let(:columns) do
    [
      Ratamin::Column.new(key: :name, label: "Name"),
      Ratamin::Column.new(key: :email, label: "Email"),
      Ratamin::Column.new(key: :bio, label: "Bio", type: :text)
    ]
  end

  let(:row) { {name: "Alice", email: "alice@example.com", bio: "Engineer"} }

  subject(:state) { described_class.new(columns, row) }

  def key_event(code, modifiers: [])
    {type: :key, code: code, modifiers: modifiers}
  end

  def enter_edit_mode
    state.handle_event(key_event("enter"))
  end

  describe "initialization" do
    it "loads values from row" do
      expect(state.values).to eq(["Alice", "alice@example.com", "Engineer"])
    end

    it "starts on field 0" do
      expect(state.field_index).to eq(0)
    end

    it "starts in select mode" do
      expect(state.mode).to eq(:select)
    end

    it "positions cursors at end of each value" do
      expect(state.cursor_positions).to eq([5, 17, 8])
    end
  end

  describe "mode transitions" do
    it "enters edit mode on Enter" do
      enter_edit_mode
      expect(state.mode).to eq(:edit)
    end

    it "enters edit mode on l" do
      state.handle_event(key_event("l"))
      expect(state.mode).to eq(:edit)
    end

    it "returns to select mode on Esc from edit and discards changes" do
      enter_edit_mode
      state.handle_event(key_event("x"))
      state.handle_event(key_event("y"))
      expect(state.current_value).to eq("Alicexy")
      state.handle_event(key_event("esc"))
      expect(state.mode).to eq(:select)
      expect(state.current_value).to eq("Alice")
    end

    it "returns to select mode and advances field on Enter from edit, keeping changes" do
      enter_edit_mode
      state.handle_event(key_event("!"))
      expect(state.current_value).to eq("Alice!")
      state.handle_event(key_event("enter"))
      expect(state.mode).to eq(:select)
      expect(state.values[0]).to eq("Alice!")
      expect(state.field_index).to eq(1)
    end

    it "does not enter edit mode on non-editable field" do
      cols = [Ratamin::Column.new(key: :id, editable: false), Ratamin::Column.new(key: :name)]
      s = described_class.new(cols, {id: "1", name: "Alice"})
      s.handle_event(key_event("enter")) # on non-editable id... wait, starts on name
      # starts on first editable (name), so this enters edit mode — navigate to id first
      s2 = described_class.new(cols, {id: "1", name: "Alice"})
      # field_index starts at 1 (name), manually set to 0 to test
      s2.instance_variable_set(:@field_index, 0)
      s2.handle_event(key_event("enter"))
      expect(s2.mode).to eq(:select)
    end
  end

  describe "field navigation (select mode)" do
    it "moves to next field with tab" do
      state.handle_event(key_event("tab"))
      expect(state.field_index).to eq(1)
    end

    it "wraps around on tab past last field" do
      3.times { state.handle_event(key_event("tab")) }
      expect(state.field_index).to eq(0)
    end

    it "moves to previous field with shift+tab" do
      state.handle_event(key_event("tab"))
      state.handle_event(key_event("backtab"))
      expect(state.field_index).to eq(0)
    end

    it "wraps around on shift+tab past first field" do
      state.handle_event(key_event("backtab"))
      expect(state.field_index).to eq(2)
    end

    it "moves to next field with down arrow" do
      state.handle_event(key_event("down"))
      expect(state.field_index).to eq(1)
    end

    it "moves to previous field with up arrow" do
      state.handle_event(key_event("down"))
      state.handle_event(key_event("up"))
      expect(state.field_index).to eq(0)
    end

    it "moves to next field with j" do
      state.handle_event(key_event("j"))
      expect(state.field_index).to eq(1)
    end

    it "moves to previous field with k" do
      state.handle_event(key_event("j"))
      state.handle_event(key_event("k"))
      expect(state.field_index).to eq(0)
    end

    it "does not navigate in edit mode (j inserts character)" do
      enter_edit_mode
      state.handle_event(key_event("j"))
      expect(state.values[0]).to eq("Alicej")
      expect(state.field_index).to eq(0)
    end
  end

  describe "text editing (edit mode)" do
    before { enter_edit_mode }

    it "inserts a character at cursor position" do
      state.insert_char("!")
      expect(state.values[0]).to eq("Alice!")
      expect(state.cursor_positions[0]).to eq(6)
    end

    it "inserts in the middle when cursor is moved" do
      state.move_cursor_left
      state.insert_char("X")
      expect(state.values[0]).to eq("AlicXe")
    end

    it "handles backspace" do
      state.handle_backspace
      expect(state.values[0]).to eq("Alic")
      expect(state.cursor_positions[0]).to eq(4)
    end

    it "handles backspace at position 0 (no-op)" do
      5.times { state.handle_backspace }
      state.handle_backspace
      expect(state.values[0]).to eq("")
      expect(state.cursor_positions[0]).to eq(0)
    end

    it "handles delete" do
      state.move_cursor_left
      state.handle_delete
      expect(state.values[0]).to eq("Alic")
    end

    it "handles delete at end (no-op)" do
      state.handle_delete
      expect(state.values[0]).to eq("Alice")
    end

    it "inserts characters via handle_event" do
      state.handle_event(key_event("e"))
      expect(state.values[0]).to eq("Alicee")
    end
  end

  describe "cursor movement (edit mode)" do
    before { enter_edit_mode }

    it "moves left" do
      state.move_cursor_left
      expect(state.cursor_positions[0]).to eq(4)
    end

    it "does not move left past 0" do
      10.times { state.move_cursor_left }
      expect(state.cursor_positions[0]).to eq(0)
    end

    it "moves right up to value length" do
      state.move_cursor_left
      state.move_cursor_right
      expect(state.cursor_positions[0]).to eq(5)
    end

    it "does not move right past value length" do
      state.move_cursor_right
      expect(state.cursor_positions[0]).to eq(5)
    end

    it "handles home key" do
      state.handle_event(key_event("home"))
      expect(state.cursor_positions[0]).to eq(0)
    end

    it "handles end key" do
      state.handle_event(key_event("home"))
      state.handle_event(key_event("end"))
      expect(state.cursor_positions[0]).to eq(5)
    end
  end

  describe "event handling results" do
    it "returns :save on s (select mode)" do
      expect(state.handle_event(key_event("s"))).to eq(:save)
    end

    it "returns :cancel on esc (select mode)" do
      expect(state.handle_event(key_event("esc"))).to eq(:cancel)
    end

    it "returns :editor on Ctrl+E in select mode" do
      expect(state.handle_event(key_event("e", modifiers: ["ctrl"]))).to eq(:editor)
    end

    it "returns :editor on Ctrl+E in edit mode" do
      enter_edit_mode
      expect(state.handle_event(key_event("e", modifiers: ["ctrl"]))).to eq(:editor)
    end

    it "returns nil for unhandled events" do
      expect(state.handle_event(key_event("f1"))).to be_nil
    end
  end

  describe "#changes" do
    it "returns only dirty fields" do
      state.insert_char("!")
      expect(state.changes).to eq({name: "Alice!"})
    end

    it "returns empty hash when nothing changed" do
      expect(state.changes).to eq({})
    end

    it "excludes non-editable fields" do
      cols = [
        Ratamin::Column.new(key: :id, editable: false),
        Ratamin::Column.new(key: :name)
      ]
      s = described_class.new(cols, {id: "1", name: "Alice"})
      s.insert_char("!")
      expect(s.changes).to eq({name: "Alice!"})
      expect(s.changes).not_to have_key(:id)
    end
  end

  describe "#set_value" do
    it "replaces value and moves cursor to end" do
      state.set_value(0, "Bob")
      expect(state.values[0]).to eq("Bob")
      expect(state.cursor_positions[0]).to eq(3)
    end
  end

  describe "#current_column" do
    it "returns the column at field_index" do
      expect(state.current_column.key).to eq(:name)
      state.next_field
      expect(state.current_column.key).to eq(:email)
    end
  end

  describe "non-editable fields" do
    let(:columns) do
      [
        Ratamin::Column.new(key: :id, editable: false),
        Ratamin::Column.new(key: :name),
        Ratamin::Column.new(key: :created_at, editable: false),
        Ratamin::Column.new(key: :email)
      ]
    end

    let(:row) { {id: "1", name: "Alice", created_at: "2026-01-01", email: "alice@example.com"} }

    subject(:state) { described_class.new(columns, row) }

    it "starts on first editable field" do
      expect(state.field_index).to eq(1)
    end

    it "skips non-editable fields on tab" do
      state.next_field
      expect(state.field_index).to eq(3)
    end

    it "skips non-editable fields on shift+tab" do
      state.prev_field
      expect(state.field_index).to eq(3)
    end
  end

  describe "all-readonly fields" do
    let(:columns) do
      [
        Ratamin::Column.new(key: :id, editable: false),
        Ratamin::Column.new(key: :created_at, editable: false)
      ]
    end

    let(:row) { {id: "1", created_at: "2026-01-01"} }

    subject(:state) { described_class.new(columns, row) }

    it "returns :cancel on esc" do
      expect(state.handle_event(key_event("esc"))).to eq(:cancel)
    end

    it "returns :save on s" do
      expect(state.handle_event(key_event("s"))).to eq(:save)
    end

    it "ignores character input" do
      expect(state.handle_event(key_event("a"))).to be_nil
      expect(state.values).to eq(["1", "2026-01-01"])
    end
  end

  describe "errors" do
    it "starts with no errors" do
      expect(state.errors).to eq([])
      expect(state).not_to be_errors
    end

    it "can set errors" do
      state.set_errors(["Name is too short"])
      expect(state).to be_errors
      expect(state.errors).to eq(["Name is too short"])
    end

    it "can clear errors" do
      state.set_errors(["Something wrong"])
      state.clear_errors
      expect(state).not_to be_errors
    end
  end
end
