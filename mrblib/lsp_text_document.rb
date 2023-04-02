module Mrbmacs
  # TextDocument ContentChangeEvent
  class Application
    def lsp_line_char_from_pos(pos)
      line = @frame.view_win.sci_line_from_position(pos)
      line_start_pos = @frame.view_win.sci_position_from_line(line)
      tmp_text = @frame.view_win.sci_get_textrange(line_start_pos, pos)
      [line, tmp_text.length]
    end

    def lsp_delete_range_from_scn(scn)
      start_line, start_char = lsp_line_char_from_pos(scn['position'])
      end_line = start_line - scn['lines_added']
      if scn['lines_added'] == 0
        end_char = start_char + scn['length']
      elsif scn['text'][-1] == "\n"
        end_char = 0
      else
        end_char = scn['text'].split("\n").last.length
      end
      LSP::Parameter::Range.new(start_line, start_char, end_line, end_char)
    end

    def lsp_insert_range_from_scn(scn)
      line, char = lsp_line_char_from_pos(scn['position'])
      LSP::Parameter::Range.new(line, char, line, char)
    end

    def lsp_content_change_event_from_scn(scn)
      case scn['modification_type'] & 0x0f
      when Scintilla::SC_MOD_INSERTTEXT
        range = lsp_insert_range_from_scn(scn)
        text = scn['text']
      when Scintilla::SC_MOD_DELETETEXT
        range = lsp_delete_range_from_scn(scn)
        text = ''
      end
      [LSP::Parameter::TextDocumentContentChangeEvent.new(text[0, scn['length']], range)]
    end

    def lsp_server_text_document_sync_kind(server)
      return 0 if server.server_capabilities['textDocumentSync'].nil?

      return server.server_capabilities['textDocumentSync'] if server.server_capabilities['textDocumentSync'].is_a?(Integer)

      if !server.server_capabilities['textDocumentSync']['change'].nil?
        return server.server_capabilities['textDocumentSync']['change']
      end
      0
    end

    # DidOpenTextDocument Notification
    # textDocument/didOpen
    def lsp_did_open(filename)
      lang = @current_buffer.mode.name
      if @ext.data['lsp'][lang].status == :running
        @ext.data['lsp'][lang].didOpen({ 'textDocument' => LSP::Parameter::TextDocumentItem.new(filename) })
      end
      @current_buffer.additional_info = lsp_additional_info(@ext.data['lsp'][lang])
    end

    # DidChangeTextDocument Notification
    # textDocument/didChange
    def lsp_did_change_for_content_change(content_change)
      lang = @current_buffer.mode.name
      td = LSP::Parameter::VersionedTextDocumentIdentifier.new(@current_buffer.filename, 0)
      text_document_sync = lsp_server_text_document_sync_kind(@ext.data['lsp'][lang])

      case text_document_sync
      when LSP::TextDocumentSyncKind[:Full]
        cc = [LSP::Parameter::TextDocumentContentChangeEvent.new(@frame.view_win.sci_get_text(@frame.view_win.sci_get_length + 1))]
      when LSP::TextDocumentSyncKind[:Incremental]
        cc = content_change
      else
        # None
        return
      end
      param = { 'textDocument' => td, 'contentChanges' => cc }
      @ext.data['lsp'][lang].didChange(param)
    end

    def lsp_did_change_for_scn(scn)
      lsp_did_change_for_content_change(lsp_content_change_event_from_scn(scn))
    end

    # WillSaveTextDocument Notification
    # textDocument/willSave

    # WillSaveWaitUntilTextDocument Request
    # textDocument/willSave

    # DidSaveTextDocument Notification
    # textDocument/didSave
    def lsp_did_save(filename)
      return unless lsp_is_running?

      lang = @current_buffer.mode.name
      @ext.data['lsp'][lang].didSave(
        {
          'textDocument' => LSP::Parameter::TextDocumentIdentifier.new(filename)
        }
      )
    end

    # DidCloseTextDocument Notification
    # textDocument/didClose
  end
end
