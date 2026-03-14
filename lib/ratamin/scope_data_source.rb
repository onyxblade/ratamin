# frozen_string_literal: true

module Ratamin
  class ScopeDataSource
    include DataSource

    attr_reader :columns

    # @param scope [ActiveRecord::Relation] the AR scope to display
    # @param columns [Array<Column>, nil] explicit columns, or nil to infer from model
    def initialize(scope, columns: nil)
      @scope = scope
      @columns = columns || infer_columns
      @records = []
      reload!
    end

    def rows
      @records.map { |record| row_hash(record) }
    end

    def row_count
      @records.length
    end

    def update_row(index, changes)
      record = @records[index]
      # Convert string keys/values from form back to appropriate types
      cast_changes = changes.transform_keys(&:to_s)
      record.assign_attributes(cast_changes)

      if record.save
        UpdateResult.success
      else
        UpdateResult.failure(record.errors.full_messages)
      end
    end

    def reload!
      @records = @scope.reset.to_a
    end

    private

    def row_hash(record)
      columns.each_with_object({}) do |col, hash|
        hash[col.key] = record.public_send(col.key)
      end
    end

    def infer_columns
      model = @scope.klass
      model.column_names.map do |name|
        col = model.columns_hash[name]
        Column.new(
          key: name.to_sym,
          type: map_ar_type(col.type),
          width: guess_width(name, col.type)
        )
      end
    end

    def map_ar_type(ar_type)
      case ar_type
      when :text then :text
      else :string
      end
    end

    def guess_width(name, ar_type)
      case ar_type
      when :text then nil
      when :integer then 12
      when :boolean then 8
      when :datetime, :timestamp then 22
      when :date then 12
      else
        name == "id" ? 8 : nil
      end
    end
  end
end
