module Mrbmacs
  # textEdit
  class Application
    def lsp_edit_buffer(text_edit)
      @frame.view_win.sci_set_sel(@frame.view_win.sci_findcolumn(text_edit['range']['start']['line'],
                                                                 text_edit['range']['start']['character']),
                                  @frame.view_win.sci_findcolumn(text_edit['range']['end']['line'],
                                                                 text_edit['range']['end']['character']))
      sci_replace_sel('', text_edit['newText'])
    end

    def lsp_process_text_edits(text_edits)
      sci_begin_undo_action
      mod_mask = @frame.view_win.sci_get_mod_event_mask
      @frame.view_win.sci_set_mod_event_mask(0)
      last_pos = nil
      text_edits.reverse_each do |e|
        # text_edit.each do |e|
        @logger.debug e
        lsp_edit_buffer(e)
        end_pos = @frame.view_win.sci_findcolumn(e['range']['end']['line'],
                                                 e['range']['end']['character'])
        start_pos = @frame.view_win.sci_findcolumn(e['range']['start']['line'],
                                                   e['range']['start']['character'])
        if last_pos.nil?
          last_pos = @frame.view_win.sci_get_current_pos
        else
          last_pos += e['newText'].length - (end_pos - start_pos)
        end
        lsp_did_change_for_content_change([{ 'range' => e['range'], 'text' => e['newText'] }])
      end
      @frame.view_win.sci_goto_pos(last_pos)
      @frame.view_win.sci_set_mod_event_mask(mod_mask)
      sci_end_undo_action
    end
  end
end
