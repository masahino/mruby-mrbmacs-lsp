module Mrbmacs
  # Completion
  class Application
    def lsp_send_completion_request(scn)
      return unless lsp_is_running?

      lang = @current_buffer.mode.name
      _line, col = current_line_col
      return if col == 0

      line_text = current_line_text.chomp[0..col]
      input = line_text.split(' ').last
      return if input.nil? || input.empty?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = {
        'textDocument' => td,
        'position' => lsp_position
      }
      if lsp_completion_trigger_characters.include?(scn['ch'].chr('UTF-8'))
        trigger_kind = LSP::CompletionTriggerKind[:TriggerCharacter] # 2
        trigger_char = scn['ch'].chr('UTF-8')
        param['context'] = { 'triggerKind' => trigger_kind, 'triggerCharacter' => trigger_char }
      else
        trigger_kind = LSP::CompletionTriggerKind[:Invoked] # 1
        param['context'] = { 'triggerKind' => trigger_kind }
      end
      @ext.data['lsp'][lang].completion(param)
    end

    def lsp_completion_text(text)
      current_pos = @frame.view_win.sci_get_current_pos
      start_pos = @frame.view_win.sci_word_start_position(current_pos, true)
      return if start_pos > current_pos

      @frame.view_win.sci_set_sel(start_pos, current_pos)
      @frame.view_win.sci_replace_sel('', text)
      range = { 'start' => lsp_position(start_pos), 'end' => lsp_position(current_pos) }
      lsp_did_change_for_content_change([{ 'range' => range, 'text' => text }])
    end

    def lsp_completion_select(scn)
      selected_item = @lsp_completion_items.find { |item| item['mylabel'] == scn['text'] }

      if selected_item
        sci_begin_undo_action
        mod_mask = @frame.view_win.sci_get_mod_event_mask
        @frame.view_win.sci_set_mod_event_mask(0)
        # textEdit -> insertText -> label
        if selected_item['textEdit']
          lsp_completion_text(selected_item['textEdit']['newText'])
        elsif selected_item['insertText']
          lsp_completion_text(selected_item['insertText'])
        else
          lsp_completion_text(selected_item['label'])
        end
        if selected_item['additionalTextEdits']
          selected_item['additionalTextEdits'].reverse_each do |e|
            @logger.debug e
            lsp_edit_buffer(e)
            lsp_did_change_for_content_change([{ 'range' => e['range'], 'text' => e['newText'] }])
          end
        end
        @frame.view_win.sci_set_mod_event_mask(mod_mask)
        sci_end_undo_action
      end
      @frame.view_win.sci_autoc_cancel
      @lsp_completion_items = []
    end

    def lsp_get_completion_list(req, res)
      @logger.info res
      _line, col = current_line_col
      line_text = current_line_text.chomp[0..col]
      input = if req.key?('context') &&
                 req['context'].key?('triggerKind') &&
                 req['context']['triggerKind'] == LSP::CompletionTriggerKind::TRIGGER_CHARACTER
                ''
              else
                line_text.split(/[ #{lsp_completion_trigger_characters.join}]/).pop
              end
      if res.key?('result')
        items = []
        if res['result'].is_a?(Hash)
          if res['result'].key?('items')
            items = res['result']['items']
          end
        elsif res['result'].is_a?(Array)
          items = res['result']
        end
        # candidates = res['result']['items'].map { |h|
        candidates = items.map do |h|
          str = ''
          if !h['textEdit'].nil?
            str = h['textEdit']['newText'].strip
          elsif !h['insertText'].nil?
            str = h['insertText'].strip
          elsif !h['label'].nil?
            str = h['label'].strip
          end
          str
        end
      else
        candidates = []
      end
      @logger.debug candidates.to_s
      [input.length, candidates.sort.uniq.join(@frame.view_win.sci_autoc_get_separator.chr)]
    end

    def lsp_completion_max_length(completion_items, key)
      value_arr = completion_items.map { |h| h[key] }
      value_arr.compact!
      return 0 if value_arr.empty?

      value_arr.max_by(&:length).length
    end

    def lsp_completion_list(_req)
      candidates = []
      max_label_length = lsp_completion_max_length(@lsp_completion_items, 'label')
      max_detail_length = lsp_completion_max_length(@lsp_completion_items, 'detail')
      @lsp_completion_items.sort { |a, b| a['sortText'] <=> b['sortText'] }.each do |item|
        label = item['label'].ljust(max_label_length)
        detail = if item['detail'].nil?
                   ''.ljust(max_detail_length)
                 else
                   item['detail'].ljust(max_detail_length)
                 end
        label = "#{label} #{detail} [#{LSP::CompletionItemKind.key(item['kind'])}]"
        candidates.push label
        item['mylabel'] = label
      end
      candidates.join(@frame.view_win.sci_autoc_get_separator.chr)
    end

    def lsp_redraw_completion
      @frame.view_win.sci_autoc_cancel
      candidates = @lsp_completion_items.map { |h| h['mylabel'] }.join(@frame.view_win.sci_autoc_get_separator.chr)
      @frame.view_win.sci_userlist_show(LspExtension::LSP_COMPLETION_LIST_TYPE, candidates)
    end

    def lsp_process_completion_response(lsp_server, id, resp)
      @logger.debug lsp_server.request_buffer[id].to_s
      @logger.debug JSON.pretty_generate resp
      @lsp_completion_items = if resp['result'].is_a?(Hash) && resp['result'].key?('items')
                                resp['result']['items']
                              elsif resp['result'].is_a?(Array)
                                resp['result']
                              end

      return if @lsp_completion_items.nil?

      candidates = lsp_completion_list(lsp_server.request_buffer[id][:message]['params'])
      @frame.view_win.sci_userlist_show(LspExtension::LSP_COMPLETION_LIST_TYPE, candidates) unless candidates.empty?
    end
  end
end
