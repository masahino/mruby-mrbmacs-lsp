module Mrbmacs
  # LSP
  class Application
    def lsp_sync_text
      lang = @current_buffer.mode.name
      if @ext.data['lsp'][lang] != nil && @ext.data['lsp'][lang].status == :running
        td = LSP::Parameter::VersionedTextDocumentIdentifier.new(@current_buffer.filename, 0)
        cc = [LSP::Parameter::TextDocumentContentChangeEvent.new(
            @frame.view_win.sci_get_text(@frame.view_win.sci_get_length + 1))]
        param = { 'textDocument' => td, 'contentChanges' => cc }
        if @ext.data['lsp'][lang].file_version[td.uri].nil?
          @ext.data['lsp'][lang].didOpen(
            { 'textDocument' => LSP::Parameter::TextDocumentItem.new(@current_buffer.filename) })
        end
        @ext.data['lsp'][lang].didChange(param)
      end
    end

    def lsp_position(pos = nil)
      if pos.nil?
        pos = @frame.view_win.sci_get_current_pos
      end
      line = @frame.view_win.sci_line_from_position(pos)
      start_of_line_pos = @frame.view_win.sci_position_from_line(line)
      count_codeunits = @frame.view_win.sci_count_codeunits(start_of_line_pos, pos)
      { 'line' => line, 'character' => count_codeunits }
    end
  end
end