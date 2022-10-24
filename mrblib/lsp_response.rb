module Mrbmacs
  # LSP response
  class Application
    def lsp_response_initialize(lsp_server, _id, resp)
      lsp_server.initialized(resp)
      lsp_server.didOpen(
        { 'textDocument' => LSP::Parameter::TextDocumentItem.new(@current_buffer.filename) }
      )
      @current_buffer.additional_info = lsp_additional_info(lsp_server)
    end

    def lsp_response_completion(lsp_server, id, resp)
      return if @frame.view_win.sci_autoc_active || @frame.view_win.sci_calltip_active

      @logger.debug lsp_server.request_buffer[id].to_s
      len, candidates = lsp_get_completion_list(lsp_server.request_buffer[id][:message]['params'], resp)
      @frame.view_win.sci_autoc_show(len, candidates) if candidates.length > 0
    end

    def lsp_response_hover(_lsp_server, _id, resp)
      return if @frame.view_win.sci_autoc_active
      return if resp['result'].nil? || resp['result']['contents']['value'].nil?

      # markup_kind = resp['result']['contents']['kind']
      value = resp['result']['contents']['value']
      @frame.view_win.sci_calltip_show(@frame.view_win.sci_get_current_pos, value) if value.size > 0
    end

    def lsp_response_signaturehelp(_lsp_server, _id, resp)
      @logger.debug resp['result']['signatures'].to_s
      return if resp['result'].nil? | resp['result']['signatures'].nil?

      list = resp['result']['signatures'].map { |s| s['label'] }.uniq
      @logger.debug list.to_s
      @frame.view_win.sci_calltipshow(@frame.view_win.sci_get_current_pos, list.join("\n")) if list.size > 0
    end

    def lsp_goto_response(lsp_server, id, resp)
      method = lsp_server.request_buffer[id][:message]['method']
      list = resp['result'].map do |x|
        "#{lsp_uri_to_path(x['uri'])},#{x['range']['start']['line'] + 1},#{x['range']['start']['character'] + 1}"
      end
      message "[lsp] receive \"#{method}\" response(#{list.size})"
      @logger.debug list
      @frame.view_win.sci_userlist_show(LspExtension::LSP_LIST_TYPE, list.join(' ')) if list.size > 0
    end

    def lsp_response(lsp_server, id, resp)
      @logger.info lsp_server.request_buffer[id][:message]['method'].to_s
      case lsp_server.request_buffer[id][:message]['method']
      when 'initialize'
        lsp_response_initialize(lsp_server, id, resp)
      when 'textDocument/completion'
        lsp_response_completion(lsp_server, id, resp)
      when 'textDocument/hover'
        lsp_response_hover(lsp_server, id, resp)
      when 'textDocument/signatureHelp'
        lsp_response_signaturehelp(lsp_server, id, resp)
      when 'textDocument/declaration', 'textDocument/definition', 'textDocument/typeDefinition',
        'textDocument/implementation', 'textDocument/references'
        lsp_goto_response(lsp_server, id, resp)
      else
        @logger.info 'unknown message'
        @logger.info resp.to_s
      end
      lsp_server.request_buffer.delete(id)
    end
  end
end
