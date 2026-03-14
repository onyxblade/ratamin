# frozen_string_literal: true

require "ratatui_ruby"

require_relative "ratamin/version"
require_relative "ratamin/column"
require_relative "ratamin/data_source"
require_relative "ratamin/array_data_source"
require_relative "ratamin/table_view"
require_relative "ratamin/form_view"
require_relative "ratamin/editor_bridge"
require_relative "ratamin/app"

module Ratamin
  class Error < StandardError; end
end
