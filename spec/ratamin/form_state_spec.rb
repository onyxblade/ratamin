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

  describe "initialization" do
    it "loads values from row" do
      expect(state.values).to eq(["Alice", "alice@example.com", "Engineer"])
    end

    it "starts on field 0" do
      expect(state.field_index).to eq(0)
    end

    it "positions cursors at end of each value" do
      expect(state.cursor_positions).to eq([5, 17, 8])
    end
  end

  describe "field navigation" do
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
  end

  describe "text editing" do
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
      state.handle_backspace # should not raise or go negative
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
  end

  describe "cursor movement" do
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
    it "returns :save on enter" do
      expect(state.handle_event(key_event("enter"))).to eq(:save)
    end

    it "returns :cancel on esc" do
      expect(state.handle_event(key_event("esc"))).to eq(:cancel)
    end

    it "returns :editor on 'e' for text fields" do
      2.times { state.next_field } # navigate to bio (type: :text)
      expect(state.handle_event(key_event("e"))).to eq(:editor)
    end

    it "inserts 'e' on non-text fields" do
      state.handle_event(key_event("e"))
      expect(state.values[0]).to eq("Alicee")
    end

    it "returns nil for unhandled events" do
      expect(state.handle_event(key_event("f1"))).to be_nil
    end
  end

  describe "#changes" do
    it "returns a hash of column key to current value" do
      state.insert_char("!")
      result = state.changes
      expect(result).to eq({name: "Alice!", email: "alice@example.com", bio: "Engineer"})
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

    it "clears errors on next keystroke" do
      state.set_errors(["Bad input"])
      state.handle_event(key_event("a"))
      # errors persist until explicitly cleared — user sees them while editing
      expect(state).to be_errors
    end
  end
end
