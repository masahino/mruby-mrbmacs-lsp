module Mrbmacs
  # signatureHelp response
  class Application
    def lsp_process_signature_help_response(resp)
      @frame.view_win.sci_calltip_cancel if @frame.view_win.sci_calltip_active

      @logger.debug resp['result']['signatures'].to_s
      list = resp['result']['signatures'].map { |s| s['label'] }.uniq

      @logger.debug list.to_s
      @lsp_calltip_info[:text] = list.join("\n")
      @lsp_calltip_info[:start_line] = 0
      lsp_draw_calltip(@frame.view_win.sci_get_current_pos) unless list.empty?
    end

    def lsp_send_signature_help_request
      return unless lsp_is_running?

      lang = @current_buffer.mode.name
      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = {
        'textDocument' => td,
        'position' => lsp_position
      }
      @ext.data['lsp'][lang].signatureHelp(param)
    end
  end
end
