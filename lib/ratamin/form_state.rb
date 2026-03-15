# frozen_string_literal: true

module Ratamin
  class FormState
    attr_reader :columns, :values, :field_index, :cursor_positions, :errors, :mode

    def initialize(columns, row)
      @columns = columns
      @values = columns.map { |col| row[col.key].to_s }
      @original_values = @values.dup
      @field_index = first_editable_index || 0
      @cursor_positions = @values.map(&:length)
      @errors = []
      @mode = :select
    end

    def errors?
      !@errors.empty?
    end

    def set_errors(errors)
      @errors = Array(errors)
    end

    def clear_errors
      @errors = []
    end

    def handle_event(event)
      @mode == :select ? handle_select_event(event) : handle_edit_event(event)
    end

    def current_column
      columns[@field_index]
    end

    def current_value
      @values[@field_index]
    end

    def set_value(index, value)
      @values[index] = value.to_s
      @cursor_positions[index] = @values[index].length
    end

    # Returns only dirty editable fields.
    def changes
      result = {}
      columns.each_with_index do |col, i|
        next unless col.editable
        next if @values[i] == @original_values[i]
        result[col.key] = @values[i]
      end
      result
    end

    def next_field
      return unless any_editable?
      loop do
        @field_index = (@field_index + 1) % columns.length
        break if current_column.editable
      end
    end

    def prev_field
      return unless any_editable?
      loop do
        @field_index = (@field_index - 1) % columns.length
        break if current_column.editable
      end
    end

    def insert_char(c)
      pos = @cursor_positions[@field_index]
      @values[@field_index] = @values[@field_index].dup.insert(pos, c)
      @cursor_positions[@field_index] += 1
    end

    def handle_backspace
      pos = @cursor_positions[@field_index]
      return if pos == 0
      val = @values[@field_index].dup
      val.slice!(pos - 1)
      @values[@field_index] = val
      @cursor_positions[@field_index] -= 1
    end

    def handle_delete
      pos = @cursor_positions[@field_index]
      val = @values[@field_index].dup
      return if pos >= val.length
      val.slice!(pos)
      @values[@field_index] = val
    end

    def move_cursor_left
      @cursor_positions[@field_index] = [0, @cursor_positions[@field_index] - 1].max
    end

    def move_cursor_right
      @cursor_positions[@field_index] = [@values[@field_index].length, @cursor_positions[@field_index] + 1].min
    end

    private

    def handle_select_event(event)
      case event
      in {type: :key, code: "esc"} | {type: :key, code: "h", modifiers: []}
        return :cancel
      in {type: :key, code: "s", modifiers: []}
        return :save
      in {type: :key, code: "e", modifiers: ["ctrl"]}
        return :editor if current_column&.editable
      in {type: :key, code: "enter"} | {type: :key, code: "l", modifiers: []}
        enter_edit_mode
      in {type: :key, code: "j", modifiers: []} | {type: :key, code: "down"}
        next_field
      in {type: :key, code: "k", modifiers: []} | {type: :key, code: "up"}
        prev_field
      in {type: :key, code: "tab", modifiers: []}
        next_field
      in {type: :key, code: "backtab"} | {type: :key, code: "tab", modifiers: ["shift"]}
        prev_field
      else
        nil
      end
    end

    def handle_edit_event(event)
      case event
      in {type: :key, code: "esc"}
        discard_edit
      in {type: :key, code: "enter"}
        @mode = :select
      in {type: :key, code: "e", modifiers: ["ctrl"]}
        return :editor
      in {type: :key, code: "backspace"}
        handle_backspace
      in {type: :key, code: "delete"}
        handle_delete
      in {type: :key, code: "left"}
        move_cursor_left
      in {type: :key, code: "right"}
        move_cursor_right
      in {type: :key, code: "home"}
        @cursor_positions[@field_index] = 0
      in {type: :key, code: "end"}
        @cursor_positions[@field_index] = @values[@field_index].length
      in {type: :key, code: c, modifiers: []} if c.length == 1
        insert_char(c)
      else
        nil
      end
    end

    def enter_edit_mode
      return unless current_column&.editable
      @edit_snapshot = [@values[@field_index].dup, @cursor_positions[@field_index]]
      @mode = :edit
    end

    def discard_edit
      if @edit_snapshot
        @values[@field_index], @cursor_positions[@field_index] = @edit_snapshot
        @edit_snapshot = nil
      end
      @mode = :select
    end

    def any_editable?
      columns.any?(&:editable)
    end

    def first_editable_index
      columns.index(&:editable)
    end
  end
end
