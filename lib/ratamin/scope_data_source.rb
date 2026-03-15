# frozen_string_literal: true

module Ratamin
  class ScopeDataSource
    include DataSource

    attr_reader :columns, :page, :per_page, :total_count

    # @param scope [ActiveRecord::Relation] the AR scope to display
    # @param columns [Array<Column>, nil] explicit columns, or nil to infer from model
    # @param per_page [Integer] records per page
    def initialize(scope, columns: nil, per_page: 20)
      @scope = scope
      @columns = columns || infer_columns
      @per_page = per_page
      @page = 1
      @total_count = 0
      @records = []
      reload!
    end

    def paginated?
      true
    end

    def total_pages
      [(@total_count.to_f / @per_page).ceil, 1].max
    end

    def next_page
      go_to_page(@page + 1)
    end

    def prev_page
      go_to_page(@page - 1)
    end

    def go_to_page(n)
      n = [[1, n].max, total_pages].min
      return if n == @page
      @page = n
      load_page
    end

    def rows
      @records.map { |record| row_hash(record) }
    end

    def row_count
      @records.length
    end

    def create_row(attributes)
      record = @scope.klass.new
      cast_attrs = attributes.transform_keys(&:to_s)
      record.assign_attributes(cast_attrs)

      if record.save
        UpdateResult.success
      else
        UpdateResult.failure(record.errors.full_messages)
      end
    rescue => e
      UpdateResult.failure("#{e.class}: #{e.message}")
    end

    def update_row(index, changes)
      record = @records[index]
      cast_changes = changes.transform_keys(&:to_s)
      record.assign_attributes(cast_changes)

      if record.save
        UpdateResult.success
      else
        errors = record.errors.full_messages
        record.reload
        UpdateResult.failure(errors)
      end
    rescue => e
      record&.reload rescue nil
      UpdateResult.failure("#{e.class}: #{e.message}")
    end

    def with_silenced_output
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      yield
    ensure
      ActiveRecord::Base.logger = old_logger
    end

    def reload!
      @total_count = @scope.reset.count
      @page = [[1, @page].max, total_pages].min
      load_page
    end

    private

    def load_page
      @records = ordered_scope.limit(@per_page).offset((@page - 1) * @per_page).to_a
    end

    def ordered_scope
      s = @scope.reset
      if s.order_values.empty?
        s.order(s.klass.arel_table[s.klass.primary_key].desc)
      else
        s
      end
    end

    def row_hash(record)
      columns.each_with_object({}) do |col, hash|
        hash[col.key] = record.public_send(col.key)
      end
    end

    READONLY_COLUMNS = %w[id created_at updated_at].freeze

    def infer_columns
      model = @scope.klass
      schema_defaults = build_schema_defaults(model)

      if model.respond_to?(:ratamin_config) && (config = model.ratamin_config)
        return config.column_specs.map do |spec|
          Column.new(**schema_defaults.fetch(spec[:key], {}).merge(spec))
        end
      end

      schema_defaults.values.map { |attrs| Column.new(**attrs) }
    end

    def build_schema_defaults(model)
      model.column_names.each_with_object({}) do |name, hash|
        col = model.columns_hash[name]
        hash[name.to_sym] = {
          key: name.to_sym,
          type: map_ar_type(col.type),
          width: guess_width(name, col.type),
          editable: !READONLY_COLUMNS.include?(name)
        }
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
