# frozen_string_literal: true

module Ratamin
  class FormView
    attr_reader :state

    def initialize(state)
      @state = state
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

      columns = state.columns
      constraints = columns.map { RatatuiRuby::Layout::Constraint.length(1) }
      constraints << RatatuiRuby::Layout::Constraint.length(1) # help line
      constraints << RatatuiRuby::Layout::Constraint.fill(1)   # spacer

      field_areas = RatatuiRuby::Layout::Layout.split(
        inner_area,
        direction: :vertical,
        constraints: constraints
      )

      label_width = columns.map { |c| c.label.length }.max + 2

      columns.each_with_index do |col, i|
        label_area, value_area = RatatuiRuby::Layout::Layout.split(
          field_areas[i],
          direction: :horizontal,
          constraints: [
            RatatuiRuby::Layout::Constraint.length(label_width),
            RatatuiRuby::Layout::Constraint.fill(1)
          ]
        )

        active = i == state.field_index

        label_style = active ? {fg: :yellow, modifiers: [:bold]} : {fg: :dark_gray}
        frame.render_widget(tui.paragraph(text: "#{col.label}: ", style: label_style), label_area)

        display_value = if col.type == :text && state.values[i].length > 40
          "[press 'e' to edit in $EDITOR]"
        else
          state.values[i]
        end

        value_style = active ? {fg: :white, modifiers: [:underlined]} : {fg: :gray}
        frame.render_widget(tui.paragraph(text: display_value, style: value_style), value_area)

        if active && col.type != :text
          cursor_x = value_area.x + [state.cursor_positions[i], value_area.width - 1].min
          frame.set_cursor_position(cursor_x, value_area.y)
        end
      end

      help = tui.paragraph(
        text: " Tab:next  Shift+Tab:prev  Enter:save  Esc:cancel  e:editor(text) ",
        style: {fg: :dark_gray}
      )
      frame.render_widget(help, field_areas[columns.length])
    end
  end
end
