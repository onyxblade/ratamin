# frozen_string_literal: true

module Ratamin
  class FormView
    attr_reader :columns, :values, :field_index, :cursor_positions, :editing

    def initialize(columns, row)
      @columns = columns
      @values = columns.map { |col| row[col.key].to_s }
      @field_index = 0
      @cursor_positions = @values.map(&:length)
      @editing = true
    end

    def render(tui, frame, area)
      inner_block = tui.block(
        title: " Edit Record ",
        borders: [:all],
        border_type: :rounded,
        border_style: {fg: :yellow}
      )
      inner_area = inner_block.inner(area)
      frame.render_widget(inner_block, area)

      # Layout: one row per field, plus a help line at bottom
      field_count = columns.length
      constraints = columns.map { RatatuiRuby::Layout::Constraint.length(1) }
      constraints << RatatuiRuby::Layout::Constraint.length(1) # help line
      constraints << RatatuiRuby::Layout::Constraint.fill(1)   # spacer

      field_areas = RatatuiRuby::Layout::Layout.split(
        inner_area,
        direction: :vertical,
        constraints: constraints
      )

      columns.each_with_index do |col, i|
        # Split each row into label and value
        label_width = columns.map { |c| c.label.length }.max + 2
        label_area, value_area = RatatuiRuby::Layout::Layout.split(
          field_areas[i],
          direction: :horizontal,
          constraints: [
            RatatuiRuby::Layout::Constraint.length(label_width),
            RatatuiRuby::Layout::Constraint.fill(1)
          ]
        )

        # Label
        label_style = i == @field_index ? {fg: :yellow, modifiers: [:bold]} : {fg: :dark_gray}
        label = tui.paragraph(text: "#{col.label}: ", style: label_style)
        frame.render_widget(label, label_area)

        # Value
        display_value = if col.type == :text
          @values[i].length > 40 ? "[press 'e' to edit in $EDITOR]" : @values[i]
        else
          @values[i]
        end

        value_style = if i == @field_index
          {fg: :white, modifiers: [:underlined]}
        else
          {fg: :gray}
        end
        value_widget = tui.paragraph(text: display_value, style: value_style)
        frame.render_widget(value_widget, value_area)

        # Show cursor on active field
        if i == @field_index && col.type != :text
          cursor_x = value_area.x + [@cursor_positions[i], value_area.width - 1].min
          frame.set_cursor_position(cursor_x, value_area.y)
        end
      end

      # Help line
      help_area = field_areas[field_count]
      help = tui.paragraph(
        text: " Tab:next  Shift+Tab:prev  Enter:save  Esc:cancel  e:editor(text) ",
        style: {fg: :dark_gray}
      )
      frame.render_widget(help, help_area)
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

    def changes
      result = {}
      columns.each_with_index do |col, i|
        result[col.key] = @values[i]
      end
      result
    end

    def current_column
      columns[@field_index]
    end

    def set_value(index, value)
      @values[index] = value.to_s
      @cursor_positions[index] = @values[index].length
    end

    private

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
