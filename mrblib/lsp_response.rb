module Mrbmacs
  # LSP response
  class Application
    def to_underscore(str)
      str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end

    def lsp_response_initialize(lsp_server, _id, resp)
      lsp_server.initialized(resp)
      unless lsp_server.server_capabilities['documentOnTypeFormattingProvider'].nil?
        @current_buffer.mode.use_builtin_formatting = false
      end
      lsp_server.didOpen(
        { 'textDocument' => LSP::Parameter::TextDocumentItem.new(@current_buffer.filename) }
      )
      @current_buffer.additional_info = lsp_additional_info(lsp_server)
      @logger.info JSON.pretty_generate lsp_server.server_capabilities
    end

    def lsp_response_text_document_completion(lsp_server, id, resp)
      return if @frame.view_win.sci_autoc_active || @frame.view_win.sci_calltip_active

      @logger.debug lsp_server.request_buffer[id].to_s
      @logger.debug JSON.pretty_generate resp
      @lsp_completion_items = if resp['result'].is_a?(Hash) && resp['result'].key?('items')
                                resp['result']['items']
                              elsif resp['result'].is_a?(Array)
                                resp['result']
                              end

      unless @lsp_completion_items.nil?
        candidates = lsp_completion_list(lsp_server.request_buffer[id][:message]['params'])
        # @frame.view_win.sci_autoc_show(len, candidates) unless candidates.empty?
        @frame.view_win.sci_userlist_show(LspExtension::LSP_COMPLETION_LIST_TYPE, candidates) unless candidates.empty?
      end
    end

    def lsp_response_text_document_hover(_lsp_server, _id, resp)
      return if @frame.view_win.sci_autoc_active
      return if resp['result'].nil? || resp['result']['contents'].nil?

      contents = if resp['result']['contents'].is_a?(Array)
                   resp['result']['contents'][0]
                 else
                   resp['result']['contents']
                 end
      str = if contents.is_a?(Hash)
              contents['value']
            else
              contents
            end
      @frame.view_win.sci_calltip_show(@frame.view_win.sci_get_current_pos, str) unless str.empty?
    end

    def lsp_response_text_document_signature_help(_lsp_server, _id, resp)
      return if resp['result'].nil? || resp['result']['signatures'].nil?

      @logger.debug resp['result']['signatures'].to_s
      list = resp['result']['signatures'].map { |s| s['label'] }.uniq
      @logger.debug list.to_s
      @frame.view_win.sci_calltipshow(@frame.view_win.sci_get_current_pos, list.join("\n")) unless list.empty?
    end

    def lsp_goto_response(lsp_server, id, resp)
      method = lsp_server.request_buffer[id][:message]['method']
      list = resp['result'].map do |x|
        "#{lsp_uri_to_path(x['uri'])},#{x['range']['start']['line'] + 1},#{x['range']['start']['character'] + 1}"
      end
      message "[lsp] receive \"#{method}\" response(#{list.size})"
      @logger.debug list
      @frame.view_win.sci_userlist_show(LspExtension::LSP_GOTO_LIST_TYPE, list.join(@frame.view_win.sci_autoc_get_separator.chr)) unless list.empty?
    end

    def lsp_response_text_document_declaration(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    def lsp_response_text_document_definition(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    def lsp_response_text_document_type_definition(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    def lsp_response_text_document_implementation(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    def lsp_response_text_document_references(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    def lsp_response_text_document_rename(_lsp_server, _id, resp)
      @logger.debug resp
      if resp.key?('result') && resp['result']['changes'].key?("file://#{@current_buffer.filename}")
        lsp_edit_buffer(resp['result']['changes']["file://#{@current_buffer.filename}"])
      end
    end

    def lsp_response_text_document_formatting(lsp_server, id, resp)
      lsp_formatting_response(lsp_server, id, resp)
    end

    def lsp_response_text_document_range_formatting(lsp_server, id, resp)
      lsp_formatting_response(lsp_server, id, resp)
    end

    def lsp_response_text_document_on_type_formatting(lsp_server, id, resp)
      lsp_formatting_response(lsp_server, id, resp)
    end

    def lsp_response_error(_lsp_server, _id, resp)
      error_type = LSP::ErrorCodes.key(resp['error']['code'])
      message "[#{error_type}]#{resp['error']['message']}"
    end

    def lsp_response(lsp_server, id, resp)
      if resp['error'].nil?
        method = lsp_server.request_buffer[id][:message]['method']
        @logger.info "[lsp] Handling response for method: #{method}"
        handler = "lsp_response_#{to_underscore(method.tr('/', '_'))}"
        if respond_to?(handler, true)
          send(handler, lsp_server, id, resp)
        else
          @logger.info "Unknown method in response: #{method}"
          @logger.info "Response: #{resp}"
        end
      else
        lsp_response_error(lsp_server, id, resp) unless resp['error'].nil?
      end
      lsp_server.request_buffer.delete(id)
    end
  end
end
