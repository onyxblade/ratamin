# frozen_string_literal: true

require_relative "lib/ratamin/version"

Gem::Specification.new do |spec|
  spec.name = "ratamin"
  spec.version = Ratamin::VERSION
  spec.authors = ["merely"]
  spec.email = ["git@merely.ca"]

  spec.summary = "TUI admin console for ActiveRecord"
  spec.description = "A terminal UI for browsing and editing ActiveRecord scopes, built on ratatui_ruby."
  spec.homepage = "https://github.com/onyxblade/ratamin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/onyxblade/ratamin"
  spec.metadata["changelog_uri"] = "https://github.com/onyxblade/ratamin/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ references/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ratatui_ruby", "~> 1.4"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
