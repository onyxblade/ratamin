# frozen_string_literal: true

module Ratamin
  Column = Data.define(:key, :label, :width, :type) do
    def initialize(key:, label: nil, width: nil, type: :string)
      super(key: key, label: label || key.to_s.capitalize, width: width, type: type)
    end
  end
end
