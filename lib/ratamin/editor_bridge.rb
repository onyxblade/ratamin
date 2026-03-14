# frozen_string_literal: true

require "tempfile"
require "shellwords"

module Ratamin
  module EditorBridge
    # Opens $EDITOR with the given text, returns edited text.
    # Temporarily restores the terminal so the editor can run normally.
    def self.edit(text)
      editor = ENV["EDITOR"] || ENV["VISUAL"] || "vi"

      tmpfile = Tempfile.new(["ratamin_edit", ".txt"])
      tmpfile.write(text)
      tmpfile.flush

      RatatuiRuby.restore_terminal

      # Use shell expansion so editors with arguments (e.g. "code --wait") work
      success = system(*Shellwords.split(editor), tmpfile.path)

      RatatuiRuby.init_terminal

      unless success
        tmpfile.close
        tmpfile.unlink
        return text
      end

      tmpfile.rewind
      result = tmpfile.read
      tmpfile.close
      tmpfile.unlink

      result
    end
  end
end
