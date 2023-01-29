module Mrbmacs
  # formatting
  class Application
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
      @ext.data['lsp'][@current_buffer.mode.name].onTypeFormatting(param) do |resp|
        @logger.info resp
        if !resp.nil? && resp.key?('result') && !resp['result'].nil?
          lsp_edit_buffer(resp['result'])
        elsif resp.key?('error')
          message resp['error']['message']
        end
      end
    end
  end
end
