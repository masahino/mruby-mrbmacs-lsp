module Mrbmacs
  class Application
    def lsp_sync_text
      lang = @current_buffer.mode.name
      if @ext.lsp[lang] != nil and @ext.lsp[lang].status == :running
        td = LSP::Parameter::VersionedTextDocumentIdentifier.new(@current_buffer.filename, 0)
        cc = [LSP::Parameter::TextDocumentContentChangeEvent.new(
            @frame.view_win.sci_get_text(@frame.view_win.sci_get_length+1))]
        param = {"textDocument" => td, "contentChanges" => cc}
        if @ext.lsp[lang].file_version[td.uri] == nil
          @ext.lsp[lang].didOpen(
            {"textDocument" => LSP::Parameter::TextDocumentItem.new(@current_buffer.filename)})
        end
        @ext.lsp[lang].didChange(param)
      end
    end
  end
end