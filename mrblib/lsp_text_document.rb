module Mrbmacs
  # TextDocument ContentChangeEvent
  class Application
    def lsp_deleted_pos_from_scn(scn)
      start_line, start_char = line_col_from_pos(scn['position'])
      end_line = start_line - scn['lines_added']
      if scn['lines_added'] == 0
        end_char = start_char + scn['length']
      else
        if scn['text'][-1] == "\n"
          end_char = 0
        else
          end_char = scn['text'].split("\n").last.length
        end
      end
    # end_char += 1 if scn['text'][-1] == "\n"
      [end_line, end_char]
    end

    def lsp_content_change_event_from_scn(scn)
      start_line, start_char = line_col_from_pos(scn['position'])
      case scn['modification_type'] & 0x0f
      when 0x01
        end_line = start_line
        end_char = start_char
        text = scn['text']
      when 0x02
        end_line, end_char = lsp_deleted_pos_from_scn(scn)
        text = ''
      end
      range = LSP::Parameter::Range.new(start_line, start_char, end_line, end_char)
      [LSP::Parameter::TextDocumentContentChangeEvent.new(text, range)]
    end
  end
end
