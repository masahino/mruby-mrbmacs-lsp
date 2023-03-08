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
      if lsp_signature_trigger_characters.include?(scn['ch'].chr('UTF-8'))
        @ext.data['lsp'][lang].signatureHelp(
          { 'textDocument' => td, 'position' => lsp_position }
        )
      else
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
    end

    def lsp_completion_text(text)
      current_pos = @frame.view_win.sci_get_current_pos
      start_pos = @frame.view_win.sci_word_start_position(current_pos, true)
      return if start_pos > current_pos

      @frame.view_win.sci_set_sel(start_pos, current_pos)
      @frame.view_win.sci_replace_sel('', text)
    end

    def lsp_completion_select(scn)
      @lsp_completion_items.each do |item|
        next unless item['label'] == scn['text']

        # textEdit -> insertText -> label
        if !item['textEdit'].nil?
          lsp_completion_text(item['textEdit']['newText'])
          unless item['additionalTextEdits'].nil?
            lsp_edit_buffer(item['additionalTextEdits'])
          end
        elsif !item['insertText'].nil?
          lsp_completion_text(item['insertText'])
        else
          lsp_completion_text(item['label'])
        end
        break
      end
      @frame.view_win.sci_autoc_cancel
      @lsp_completion_items = []
    end

    def lsp_completion_list(req)
      candidates = []
      @lsp_completion_items.sort { |a, b| a['sortText'] <=> b['sortText'] }.each do |item|
        candidates.push item['label']
      end
      candidates.join(@frame.view_win.sci_autoc_get_separator.chr)
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
  end
end
