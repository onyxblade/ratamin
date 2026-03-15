# frozen_string_literal: true

require "ratatui_ruby"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Ratamin
  class Error < StandardError; end
end

require "ratamin/railtie" if defined?(Rails::Railtie)
