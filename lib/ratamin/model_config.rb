# frozen_string_literal: true

module Ratamin
  class ModelConfig
    attr_reader :column_specs

    def initialize
      @column_specs = []
    end

    # Stores only the explicitly provided overrides; schema defaults are applied
    # later by ScopeDataSource when it merges with AR column metadata.
    def column(key, **overrides)
      @column_specs << {key: key.to_sym, **overrides}
    end
  end
end
