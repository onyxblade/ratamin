# frozen_string_literal: true

module Ratamin
  class ModelConfig
    attr_reader :columns

    def initialize
      @columns = []
    end

    def column(key, **options)
      @columns << Column.new(key: key, **options)
    end
  end
end
