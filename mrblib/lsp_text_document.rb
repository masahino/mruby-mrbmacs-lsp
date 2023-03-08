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
      [LSP::Parameter::TextDocumentContentChangeEvent.new(text, range)]
    end
  end
end
