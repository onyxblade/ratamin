# frozen_string_literal: true

module Ratamin
  # Duck-type protocol for data sources.
  # Implementations must respond to:
  #   #columns -> [Column]
  #   #rows    -> [Hash]  (each hash maps column key -> value)
  #   #row_count -> Integer
  #   #update_row(index, changes) -> void
  #   #reload! -> void
  module DataSource
  end
end
