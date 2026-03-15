# frozen_string_literal: true

module Ratamin
  # Duck-type protocol for data sources.
  # Implementations must respond to:
  #   #columns    -> [Column]
  #   #rows       -> [Hash]  (current page of data)
  #   #row_count  -> Integer
  #   #update_row(index, changes) -> UpdateResult
  #   #reload!    -> void
  #
  # Pagination (optional, when #paginated? returns true):
  #   #page        -> Integer (1-indexed)
  #   #total_count -> Integer
  #   #total_pages -> Integer
  #   #next_page   -> void
  #   #prev_page   -> void
  #   #go_to_page(n) -> void
  module DataSource
    def paginated?
      false
    end

    def with_silenced_output
      yield
    end
  end
end
