# frozen_string_literal: true

module Ratamin
  class ArrayDataSource
    include DataSource

    attr_reader :columns, :rows

    # @param columns [Array<Column>] column definitions
    # @param rows [Array<Hash>] row data, each hash maps column key -> value
    def initialize(columns:, rows:)
      @columns = columns
      @rows = rows.map(&:dup)
    end

    def row_count
      @rows.length
    end

    def update_row(index, changes)
      changes.each { |k, v| @rows[index][k] = v }
    end

    def reload!
      # no-op for array source
    end
  end
end
