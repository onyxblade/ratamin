# frozen_string_literal: true

require "tempfile"

module Ratamin
  module EditorBridge
    # Opens $EDITOR with the given text, returns edited text.
    # Temporarily restores the terminal so the editor can run normally.
    def self.edit(text)
      editor = ENV["EDITOR"] || ENV["VISUAL"] || "vi"

      tmpfile = Tempfile.new(["ratamin_edit", ".txt"])
      tmpfile.write(text)
      tmpfile.flush

      # Restore terminal before launching editor
      RatatuiRuby.restore_terminal

      system(editor, tmpfile.path)

      # Re-init terminal after editor closes
      RatatuiRuby.init_terminal

      tmpfile.rewind
      result = tmpfile.read
      tmpfile.close
      tmpfile.unlink

      result
    end
  end
end
