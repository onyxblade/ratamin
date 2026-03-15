# frozen_string_literal: true

module Ratamin
  module ModelMixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Define column config for the TUI:
      #
      #   class User < ApplicationRecord
      #     has_ratamin do
      #       column :name, label: "Full Name", width: 20
      #       column :email, width: 30
      #     end
      #   end
      #
      def has_ratamin(&block)
        @ratamin_config = ModelConfig.new
        @ratamin_config.instance_eval(&block)
      end

      def ratamin_config
        @ratamin_config
      end

      # Open the TUI for this model (defaults to all records, newest first):
      #
      #   User.ratamin
      #
      def ratamin
        scope = all.order(arel_table[primary_key].desc)
        App.new(ScopeDataSource.new(scope)).run
      end
    end
  end

  module RelationMixin
    def ratamin
      source = ScopeDataSource.new(self)
      App.new(source).run
    end
  end
end
