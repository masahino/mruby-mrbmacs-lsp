# Mrbmacs
module Mrbmacs
  # workspaceEdit
  class Application
    def lsp_workspace_edit(workspace_edit)
      return unless workspace_edit['changes']

      original_buffer = @current_buffer
      workspace_edit['changes'].each do |uri, text_edits|
        find_file(lsp_uri_to_path(uri))
        lsp_process_text_edits(text_edits)
      end

      switch_to_buffer(original_buffer.name)
    end
  end
end
