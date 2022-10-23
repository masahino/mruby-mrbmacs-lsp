module Mrbmacs
  # LSP notification
  class Application
    def lsp_notification(_lsp_server, message)
      case message['method']
      when 'textDocument/publishDiagnostics'
        @logger.info 'publishDiagnostics'
        if @current_buffer.filename == lsp_uri_to_path(message['params']['uri'])
          lsp_show_annotation(message['params']['diagnostics'])
        end
      else
        @logger.info "unknown method #{message}"
        @logger.info message.to_s
      end
    end
  end
end
