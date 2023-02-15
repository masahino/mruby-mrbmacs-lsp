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
        if lsp_completion_trigger_characters.include?(scn['ch'].chr('UTF-8'))
          trigger_kind = LSP::CompletionTriggerKind::TRIGGER_CHARACTER # 2
          trigger_char = scn['ch'].chr('UTF-8')
        else
          trigger_kind = LSP::CompletionTriggerKind::INVOKED # 1
          trigger_char = ''
        end
        param = {
          'textDocument' => td,
          'position' => lsp_position,
          'context' => { 'triggerKind' => trigger_kind, 'triggerCharacter' => trigger_char }
        }
        @logger.debug param.to_s
        @ext.data['lsp'][lang].completion(param)
      end
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
      [input.length, candidates.sort.uniq.join(' ')]
    end
  end
end
