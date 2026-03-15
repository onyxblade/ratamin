# frozen_string_literal: true

require "ratamin"
require "rails"

module Ratamin
  class Railtie < Rails::Railtie
    initializer "ratamin.extend_active_record" do
      ActiveSupport.on_load(:active_record) do
        include Ratamin::ModelMixin
        ActiveRecord::Relation.include(Ratamin::RelationMixin)
      end
    end
  end
end
