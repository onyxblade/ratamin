# frozen_string_literal: true

require "active_support/lazy_load_hooks"

module Ratamin
  class Railtie < Rails::Railtie; end
end

# Defined outside the Railtie initializer so it runs whenever this file is
# required — whether during normal boot or from config/initializers (after
# railties have already initialized). on_load fires immediately if
# ActiveRecord is already loaded, otherwise defers until it is.
ActiveSupport.on_load(:active_record) do
  include Ratamin::ModelMixin
  ActiveRecord::Relation.include(Ratamin::RelationMixin)
end
