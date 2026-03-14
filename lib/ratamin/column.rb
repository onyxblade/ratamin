# frozen_string_literal: true

module Ratamin
  Column = Data.define(:key, :label, :width, :type, :editable) do
    def initialize(key:, label: nil, width: nil, type: :string, editable: true)
      super(key: key, label: label || key.to_s.capitalize, width: width, type: type, editable: editable)
    end
  end
end
