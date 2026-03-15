# frozen_string_literal: true

module Ratamin
  class FormView
    attr_reader :state, :title

    def initialize(state, title: " Edit Record ")
      @state = state
      @title = title
    end

    def render(tui, frame, area)
      border_style = state.errors? ? {fg: :red} : {fg: :yellow}
      inner_block = tui.block(
        title: title,
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

      render_confirm_dialog(tui, frame, area) if state.mode == :confirm_exit
    end

    private

    def render_confirm_dialog(tui, frame, area)
      # Clear overlay area
      dialog_w = [36, area.width - 4].min
      dialog_h = 5
      dialog_x = area.x + (area.width - dialog_w) / 2
      dialog_y = area.y + (area.height - dialog_h) / 2

      dialog_area = RatatuiRuby::Layout::Rect.new(x: dialog_x, y: dialog_y, width: dialog_w, height: dialog_h)
      frame.render_widget(tui.clear, dialog_area)

      dialog_block = tui.block(
        title: " Unsaved changes ",
        borders: [:all],
        border_type: :rounded,
        border_style: {fg: :yellow}
      )
      inner = dialog_block.inner(dialog_area)
      frame.render_widget(dialog_block, dialog_area)

      # Prompt line
      prompt_area, buttons_area = RatatuiRuby::Layout::Layout.split(
        inner,
        direction: :vertical,
        constraints: [
          RatatuiRuby::Layout::Constraint.length(1),
          RatatuiRuby::Layout::Constraint.fill(1)
        ]
      )

      frame.render_widget(
        tui.paragraph(text: "Save changes before leaving?", style: {fg: :white}),
        prompt_area
      )

      # Buttons
      sel = state.confirm_selection
      save_style = sel == 0 ? {fg: :black, bg: :yellow, modifiers: [:bold]} : {fg: :dark_gray}
      discard_style = sel == 1 ? {fg: :black, bg: :yellow, modifiers: [:bold]} : {fg: :dark_gray}

      save_label = sel == 0 ? " [Save] " : "  Save  "
      discard_label = sel == 1 ? " [Discard] " : "  Discard  "

      btn_save, btn_discard, _ = RatatuiRuby::Layout::Layout.split(
        buttons_area,
        direction: :horizontal,
        constraints: [
          RatatuiRuby::Layout::Constraint.length(save_label.length),
          RatatuiRuby::Layout::Constraint.length(discard_label.length),
          RatatuiRuby::Layout::Constraint.fill(1)
        ]
      )

      frame.render_widget(tui.paragraph(text: save_label, style: save_style), btn_save)
      frame.render_widget(tui.paragraph(text: discard_label, style: discard_style), btn_discard)
    end
  end
end
