module Mrbmacs
  # formatting
  class Application
    # formatting response
    def lsp_formatting_response(lsp_server, id, resp)
      method = lsp_server.request_buffer[id][:message]['method']

      @logger.info "[lsp] receive \"#{method}\""
      @logger.info resp
      if !resp.nil? && resp.key?('result') && !resp['result'].nil?
        lsp_edit_buffer(resp['result'])
      elsif resp.key?('error')
        message resp['error']['message']
      end
    end

    # OnTypeFormatting
    def lsp_on_type_formatting(input_char)
      return unless lsp_on_type_formatting_trigger_characters.include?(input_char)

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = {
        'textDocument' => td,
        'position' => lsp_position,
        'ch' => input_char,
        'options' => {
          'tabSize' => @current_buffer.mode.indent,
          'insertSpaces' => !@current_buffer.mode.use_tab
        }
      }
      @logger.info param
      @ext.data['lsp'][@current_buffer.mode.name].onTypeFormatting(param)
    end
  end
end
