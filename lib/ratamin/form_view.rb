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
      constraints << RatatuiRuby::Layout::Constraint.length(state.errors.length + 1) if state.errors?
      columns.each { constraints << RatatuiRuby::Layout::Constraint.length(1) }
      constraints << RatatuiRuby::Layout::Constraint.length(1)
      constraints << RatatuiRuby::Layout::Constraint.fill(1)

      regions = RatatuiRuby::Layout::Layout.split(
        inner_area,
        direction: :vertical,
        constraints: constraints
      )

      region_idx = 0

      if state.errors?
        error_text = state.errors.map { |e| " ! #{e}" }.join("\n")
        frame.render_widget(tui.paragraph(text: error_text, style: {fg: :red, modifiers: [:bold]}), regions[region_idx])
        region_idx += 1
      end

      label_width = columns.map { |c| c.label.length }.max + 2

      columns.each_with_index do |col, i|
        field_area = regions[region_idx + i]
        marker_area, label_area, value_area = RatatuiRuby::Layout::Layout.split(
          field_area,
          direction: :horizontal,
          constraints: [
            RatatuiRuby::Layout::Constraint.length(2),
            RatatuiRuby::Layout::Constraint.length(label_width),
            RatatuiRuby::Layout::Constraint.fill(1)
          ]
        )

        active = i == state.field_index

        if col.editable
          in_edit = active && state.mode == :edit
          marker = active ? (in_edit ? "» " : "> ") : "  "
          marker_style = active ? {fg: :yellow} : {fg: :dark_gray}
          label_style = active ? {fg: :yellow, modifiers: [:bold]} : {fg: :dark_gray}

          frame.render_widget(tui.paragraph(text: marker, style: marker_style), marker_area)
          frame.render_widget(tui.paragraph(text: "#{col.label}: ", style: label_style), label_area)

          display_value = if col.type == :text && state.values[i].length > 40
            "[Ctrl+E to edit in $EDITOR]"
          else
            state.values[i]
          end

          value_style = in_edit ? {fg: :white, modifiers: [:underlined]} : (active ? {fg: :yellow} : {fg: :gray})
          frame.render_widget(tui.paragraph(text: display_value, style: value_style), value_area)

          if in_edit && !(col.type == :text && state.values[i].length > 40)
            cursor_x = value_area.x + [state.cursor_positions[i], value_area.width - 1].min
            frame.set_cursor_position(cursor_x, value_area.y)
          end
        else
          frame.render_widget(tui.paragraph(text: "  ", style: {fg: :dark_gray}), marker_area)
          frame.render_widget(tui.paragraph(text: "#{col.label}: ", style: {fg: :dark_gray}), label_area)
          frame.render_widget(tui.paragraph(text: state.values[i], style: {fg: :dark_gray, modifiers: [:dim]}), value_area)
        end
      end

      help_area = regions[region_idx + columns.length]
      help_text = if state.mode == :edit
        " Esc:discard  Enter:confirm  Ctrl+E:editor "
      else
        " s:save  h/Esc:back  j/k:navigate  l/Enter:edit  Ctrl+E:editor "
      end
      frame.render_widget(tui.paragraph(text: help_text, style: {fg: :dark_gray}), help_area)
    end
  end
end
