module Mrbmacs
  # Commands of Workspace Features
  module Command
    # Workspace Symbols Request
    def lsp_workspace_symbols
      return unless lsp_is_running?

      @ext.data['lsp'][@current_buffer.mode.name].workspaceSymbol({ 'query' => '' })
    end

    # Workspace Symbol Resolve Request

    # DidChangeConfiguration Notification

    # DidChangeWorkspaceFolders Notification
    # WillCreateFiles Request
    # DidCreateFiles Notification
    # WillRenameFiles Request
    # DidRenameFiles Notification
    # WillDeleteFiles Request
    # DidDeleteFiles Notification
    # DidChangeWatchedFiles Notification
    # Execute a command
    # Applies a WorkspaceEdit
  end
end
