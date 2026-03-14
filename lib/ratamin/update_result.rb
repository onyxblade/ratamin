# frozen_string_literal: true

module Ratamin
  UpdateResult = Data.define(:ok, :errors) do
    def initialize(ok:, errors: [])
      super
    end

    def ok? = ok
    def failed? = !ok

    def self.success
      new(ok: true)
    end

    def self.failure(errors)
      new(ok: false, errors: Array(errors))
    end
  end
end
