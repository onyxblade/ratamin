# frozen_string_literal: true

module Ratamin
  class TableView
    attr_reader :data_source, :table_state

    def initialize(data_source)
      @data_source = data_source
      @table_state = RatatuiRuby::TableState.new(0)
    end

    def render(tui, frame, area)
      columns = data_source.columns
      rows = data_source.rows

      header = columns.map(&:label)

      table_rows = rows.map do |row|
        columns.map { |col| format_cell(row[col.key], col) }
      end

      widths = compute_widths(columns, area.width)

      table = tui.table(
        header: header,
        rows: table_rows,
        widths: widths,
        row_highlight_style: {bg: :dark_gray, modifiers: [:bold]},
        highlight_symbol: "> ",
        block: tui.block(
          title: " #{title_text} ",
          borders: [:all],
          border_type: :rounded,
          border_style: {fg: :cyan}
        ),
        style: {fg: :white}
      )

      frame.render_stateful_widget(table, area, @table_state)
    end

    def selected_index
      @table_state.selected
    end

    def selected_row
      idx = selected_index
      return nil if idx.nil? || idx >= data_source.row_count
      data_source.rows[idx]
    end

    def select_next
      max = data_source.row_count - 1
      return if max < 0
      return if (selected_index || 0) >= max
      @table_state.select_next
    end

    def select_previous
      return if (selected_index || 0) <= 0
      @table_state.select_previous
    end

    def select_first
      @table_state.select_first
    end

    def select_last
      max = data_source.row_count - 1
      @table_state.select(max) if max >= 0
    end

    def reset_selection
      @table_state.select(0)
    end

    private

    def title_text
      ds = data_source
      if ds.paginated?
        "Records (page #{ds.page}/#{ds.total_pages}, #{ds.total_count} total)"
      else
        "Records (#{ds.row_count})"
      end
    end

    def format_cell(value, column)
      text = value.to_s
      case column.type
      when :text
        # Truncate long text for table display
        text.length > 40 ? "#{text[0, 37]}..." : text
      else
        text
      end
    end

    def compute_widths(columns, available_width)
      columns.map do |col|
        if col.width
          RatatuiRuby::Layout::Constraint.length(col.width)
        else
          RatatuiRuby::Layout::Constraint.fill(1)
        end
      end
    end
  end
end
