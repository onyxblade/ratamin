# frozen_string_literal: true

module Ratamin
  class FormState
    attr_reader :columns, :values, :field_index, :cursor_positions, :errors

    def initialize(columns, row)
      @columns = columns
      @values = columns.map { |col| row[col.key].to_s }
      @field_index = 0
      @cursor_positions = @values.map(&:length)
      @errors = []
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
      case event
      in {type: :key, code: "tab", modifiers: []}
        next_field
      in {type: :key, code: "backtab"} | {type: :key, code: "tab", modifiers: ["shift"]}
        prev_field
      in {type: :key, code: "enter"}
        return :save
      in {type: :key, code: "esc"}
        return :cancel
      in {type: :key, code: "e"} if current_column.type == :text
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

    def changes
      columns.each_with_object({}) do |col, result|
        result[col.key] = @values[columns.index(col)]
      end
    end

    def next_field
      @field_index = (@field_index + 1) % columns.length
    end

    def prev_field
      @field_index = (@field_index - 1) % columns.length
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
  end
end
