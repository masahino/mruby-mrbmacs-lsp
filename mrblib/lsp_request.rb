module Mrbmacs
  # Requests from an LSP server
  class Application
    def lsp_request(lsp_server, request)
      method = request['method']
      handler = "lsp_request_#{to_underscore(method.tr('/', '_'))}"
      if respond_to?(handler, true)
        send(handler, lsp_server, request)
      else
        @logger.info "[LSP] unsupported server request: #{method}"
        @logger.debug request.to_s
      end
    end

    def lsp_request_workspace_apply_edit(lsp_server, request)
      result = {}
      begin
        params = request['params'] || {}
        result['applied'] = lsp_workspace_edit(params['edit'])
      rescue StandardError => e
        result['applied'] = false
        reason = e.message
        result['failureReason'] = reason unless reason.nil? || reason.empty?
      end

      lsp_server.send_message(
        'jsonrpc' => LSP::Client::JSON_RPC_VERSION,
        'id' => request['id'],
        'result' => result
      )
    end
  end
end
