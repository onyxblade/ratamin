# frozen_string_literal: true

module Ratamin
  class FormView
    attr_reader :state

    def initialize(state)
      @state = state
    end

    def render(tui, frame, area)
      border_style = state.errors? ? {fg: :red} : {fg: :yellow}
      inner_block = tui.block(
        title: " Edit Record ",
        borders: [:all],
        border_type: :rounded,
        border_style: border_style
      )
      inner_area = inner_block.inner(area)
      frame.render_widget(inner_block, area)

      columns = state.columns

      constraints = []
      # Error lines
      if state.errors?
        constraints << RatatuiRuby::Layout::Constraint.length(state.errors.length + 1)
      end
      # Field rows
      columns.each { constraints << RatatuiRuby::Layout::Constraint.length(1) }
      # Help line + spacer
      constraints << RatatuiRuby::Layout::Constraint.length(1)
      constraints << RatatuiRuby::Layout::Constraint.fill(1)

      regions = RatatuiRuby::Layout::Layout.split(
        inner_area,
        direction: :vertical,
        constraints: constraints
      )

      region_idx = 0

      # Render errors if present
      if state.errors?
        error_text = state.errors.map { |e| " ! #{e}" }.join("\n")
        error_widget = tui.paragraph(text: error_text, style: {fg: :red, modifiers: [:bold]})
        frame.render_widget(error_widget, regions[region_idx])
        region_idx += 1
      end

      label_width = columns.map { |c| c.label.length }.max + 2

      columns.each_with_index do |col, i|
        field_area = regions[region_idx + i]
        label_area, value_area = RatatuiRuby::Layout::Layout.split(
          field_area,
          direction: :horizontal,
          constraints: [
            RatatuiRuby::Layout::Constraint.length(label_width),
            RatatuiRuby::Layout::Constraint.fill(1)
          ]
        )

        active = i == state.field_index

        if col.editable
          label_style = active ? {fg: :yellow, modifiers: [:bold]} : {fg: :dark_gray}
          frame.render_widget(tui.paragraph(text: "#{col.label}: ", style: label_style), label_area)

          display_value = if col.type == :text && state.values[i].length > 40
            "[Ctrl+E to edit in $EDITOR]"
          else
            state.values[i]
          end

          value_style = active ? {fg: :white, modifiers: [:underlined]} : {fg: :gray}
          frame.render_widget(tui.paragraph(text: display_value, style: value_style), value_area)

          if active && !(col.type == :text && state.values[i].length > 40)
            cursor_x = value_area.x + [state.cursor_positions[i], value_area.width - 1].min
            frame.set_cursor_position(cursor_x, value_area.y)
          end
        else
          frame.render_widget(tui.paragraph(text: "#{col.label}: ", style: {fg: :dark_gray}), label_area)
          frame.render_widget(tui.paragraph(text: state.values[i], style: {fg: :dark_gray, modifiers: [:dim]}), value_area)
        end
      end

      help_area = regions[region_idx + columns.length]
      help = tui.paragraph(
        text: " ↑↓/Tab:navigate  Enter:save  Esc:cancel  Ctrl+E:editor ",
        style: {fg: :dark_gray}
      )
      frame.render_widget(help, help_area)
    end
  end
end
