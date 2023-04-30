module Mrbmacs
  # Completion
  class Application
    def lsp_partial_input
      current_pos = @frame.view_win.sci_get_current_pos
      start_pos = @frame.view_win.sci_word_start_position(current_pos, true)
      @frame.view_win.sci_get_text_range(start_pos, current_pos)
    end

    def lsp_send_completion_request(scn)
      return unless lsp_is_running?

      lang = @current_buffer.mode.name
      input = lsp_partial_input
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

    def lsp_completion_with_text_edit(text_edit)
      lsp_process_text_edits([text_edit])
    end

    def lsp_completion_select(scn)
      selected_item = @lsp_completion_items.find { |item| item['mylabel'] == scn['text'] }

      if selected_item
        sci_begin_undo_action
        mod_mask = @frame.view_win.sci_get_mod_event_mask
        @frame.view_win.sci_set_mod_event_mask(0)
        # textEdit -> insertText -> label
        if selected_item['textEdit']
          lsp_completion_with_text_edit(selected_item['textEdit'])
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
      @lsp_completion_items.each do |item|
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

    def lsp_filter_completion_items(items)
      partial_text = lsp_partial_input.downcase
      results = []
      items.each do |h|
        results << h if h['label'].downcase.include?(partial_text)
      end
      results
    end

    def lsp_process_completion_response(lsp_server, id, resp)
      @logger.debug lsp_server.request_buffer[id].to_s
      @logger.debug JSON.pretty_generate resp
      @lsp_completion_items = if resp['result'].is_a?(Hash) && resp['result'].key?('items')
                                resp['result']['items']
                              elsif resp['result'].is_a?(Array)
                                resp['result']
                              end
      @lsp_completion_items = lsp_filter_completion_items(@lsp_completion_items)
      return if @lsp_completion_items.nil?
      @lsp_completion_items.sort! { |a, b| a['sortText'] <=> b['sortText'] }

      candidates = lsp_completion_list(lsp_server.request_buffer[id][:message]['params'])
      @frame.view_win.sci_userlist_show(LspExtension::LSP_COMPLETION_LIST_TYPE, candidates) unless candidates.empty?
    end
  end
end
