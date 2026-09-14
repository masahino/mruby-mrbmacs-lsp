# Mrbmacs
module Mrbmacs
  # workspaceEdit
  class Application
    def lsp_workspace_edit(workspace_edit)
      return false unless workspace_edit.is_a?(Hash)
      return false unless workspace_edit['changes'].is_a?(Hash)

      original_buffer = @current_buffer

      begin
        workspace_edit['changes'].each do |uri, text_edits|
          unless find_file(lsp_uri_to_path(uri))
            @logger.error "LSP workspace edit aborted: unable to open #{uri}"
            return false
          end
          lsp_process_text_edits(text_edits)
        end
        true
      ensure
        switch_to_buffer(original_buffer.name)
      end
    end
  end
end
