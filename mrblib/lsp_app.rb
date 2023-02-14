module Mrbmacs
  # LSP
  class Application
    def lsp_server_text_document_sync_kind(server)
      return 0 if server.server_capabilities['textDocumentSync'].nil?

      return server.server_capabilities['textDocumentSync'] if server.server_capabilities['textDocumentSync'].is_a?(Integer)

      if !server.server_capabilities['textDocumentSync']['change'].nil?
        return server.server_capabilities['textDocumentSync']['change']
      end
      0
    end

    def lsp_did_change(scn)
      lang = @current_buffer.mode.name
      td = LSP::Parameter::VersionedTextDocumentIdentifier.new(@current_buffer.filename, 0)
      if @ext.data['lsp'][lang].file_version[td.uri].nil?
        @ext.data['lsp'][lang].didOpen({ 'textDocument' => LSP::Parameter::TextDocumentItem.new(@current_buffer.filename) })
      end
      text_document_sync = lsp_server_text_document_sync_kind(@ext.data['lsp'][lang])

      case text_document_sync
      when LSP::TextDocumentSyncKind::FULL
        cc = [LSP::Parameter::TextDocumentContentChangeEvent.new(@frame.view_win.sci_get_text(@frame.view_win.sci_get_length + 1))]
      when LSP::TextDocumentSyncKind::INCREMENTAL
        cc = lsp_content_change_event_from_scn(scn)
      else
        # None
        return
      end

      param = { 'textDocument' => td, 'contentChanges' => cc }
      @ext.data['lsp'][lang].didChange(param)
    end

    def lsp_sync_text
      lang = @current_buffer.mode.name
      return if @ext.data['lsp'][lang].nil? || @ext.data['lsp'][lang].status != :running

      td = LSP::Parameter::VersionedTextDocumentIdentifier.new(@current_buffer.filename, 0)
      cc = [LSP::Parameter::TextDocumentContentChangeEvent.new(@frame.view_win.sci_get_text(@frame.view_win.sci_get_length + 1))]
      param = { 'textDocument' => td, 'contentChanges' => cc }
      if @ext.data['lsp'][lang].file_version[td.uri].nil?
        @ext.data['lsp'][lang].didOpen({ 'textDocument' => LSP::Parameter::TextDocumentItem.new(@current_buffer.filename) })
      end
      @ext.data['lsp'][lang].didChange(param)
    end

    def lsp_position(pos = nil)
      pos = @frame.view_win.sci_get_current_pos if pos.nil?
      line = @frame.view_win.sci_line_from_position(pos)
      start_of_line_pos = @frame.view_win.sci_position_from_line(line)
      count_codeunits = @frame.view_win.sci_count_codeunits(start_of_line_pos, pos)
      { 'line' => line, 'character' => count_codeunits }
    end
  end
end
