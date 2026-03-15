# frozen_string_literal: true

module Ratamin
  class App
    attr_reader :data_source, :mode, :table_view, :form_state, :form_view

    def initialize(data_source)
      @data_source = data_source
      @table_view = TableView.new(data_source)
      @form_state = nil
      @form_view = nil
      @mode = :table
    end

    def run
      @data_source.with_silenced_output do
        RatatuiRuby.run do |tui|
          loop do
            tui.draw { |frame| render(tui, frame) }

            event = tui.poll_event
            result = handle_event(event)
            break if result == :quit
          end
        end
      end
    end

    private

    def render(tui, frame)
      body_area, status_area = RatatuiRuby::Layout::Layout.split(
        frame.area,
        direction: :vertical,
        constraints: [
          RatatuiRuby::Layout::Constraint.fill(1),
          RatatuiRuby::Layout::Constraint.length(1)
        ]
      )

      case @mode
      when :table
        @table_view.render(tui, frame, body_area)
        render_status_bar(tui, frame, status_area, table_help)
      when :form
        @form_view.render(tui, frame, body_area)
        render_status_bar(tui, frame, status_area, form_help)
      end
    end

    def render_status_bar(tui, frame, area, text)
      bar = tui.paragraph(
        text: text,
        style: {fg: :black, bg: :cyan}
      )
      frame.render_widget(bar, area)
    end

    def table_help
      help = " q:quit  j/↓:down  k/↑:up  g:first  G:last  enter:edit  r:reload"
      help += "  n:next page  p:prev page" if @data_source.paginated?
      help + " "
    end

    def form_help
      if @form_state&.mode == :edit
        " Esc:exit edit  Enter:confirm+next "
      else
        " s:save  Esc:cancel  j/k:navigate  Enter/i:edit  Ctrl+E:editor "
      end
    end

    def handle_event(event)
      case @mode
      when :table then handle_table_event(event)
      when :form then handle_form_event(event)
      end
    end

    def handle_table_event(event)
      case event
      in {type: :key, code: "q"} | {type: :key, code: "c", modifiers: ["ctrl"]}
        :quit
      in {type: :key, code: "j"} | {type: :key, code: "down"}
        @table_view.select_next
        nil
      in {type: :key, code: "k"} | {type: :key, code: "up"}
        @table_view.select_previous
        nil
      in {type: :key, code: "g"}
        @table_view.select_first
        nil
      in {type: :key, code: "G"} | {type: :key, code: "g", modifiers: ["shift"]}
        @table_view.select_last
        nil
      in {type: :key, code: "enter"}
        enter_form
        nil
      in {type: :key, code: "n"} if @data_source.paginated?
        @data_source.next_page
        @table_view.reset_selection
        nil
      in {type: :key, code: "p"} if @data_source.paginated?
        @data_source.prev_page
        @table_view.reset_selection
        nil
      in {type: :key, code: "r"}
        @data_source.reload!
        @table_view.reset_selection
        nil
      else
        nil
      end
    end

    def handle_form_event(event)
      result = @form_state.handle_event(event)
      case result
      when :save
        save_form
      when :cancel
        exit_form
      when :editor
        open_editor
      end
      nil
    end

    def enter_form
      row = @table_view.selected_row
      return unless row

      @form_state = FormState.new(@data_source.columns, row)
      @form_view = FormView.new(@form_state)
      @mode = :form
    end

    def exit_form
      @mode = :table
      @form_state = nil
      @form_view = nil
    end

    def save_form
      idx = @table_view.selected_index
      return unless idx

      result = @data_source.update_row(idx, @form_state.changes)
      if result.ok?
        exit_form
      else
        @form_state.set_errors(result.errors)
      end
    end

    def open_editor
      field_idx = @form_state.field_index
      current_value = @form_state.values[field_idx]

      edited = EditorBridge.edit(current_value)
      @form_state.set_value(field_idx, edited.chomp)
    end
  end
end
