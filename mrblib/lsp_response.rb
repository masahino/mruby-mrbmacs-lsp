module Mrbmacs
  # LSP response
  class Application
    def to_underscore(str)
      str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end

    # Lifecycle Messages
    # initialize
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

    # Language Features
    # Goto Declaration
    # textDocument/declaration
    def lsp_response_text_document_declaration(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    # Goto Definition
    # textDocument/definition
    def lsp_response_text_document_definition(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    # Goto Type Definition
    # textDocument/typeDefinition
    def lsp_response_text_document_type_definition(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    # Goto Implementation
    # textDocument/implementation
    def lsp_response_text_document_implementation(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    # Find References
    # textDocument/references
    def lsp_response_text_document_references(lsp_server, id, resp)
      lsp_goto_response(lsp_server, id, resp)
    end

    # Prepare Call Hierarchy
    # textDocument/prepareCallHierarchy

    # Call Hierarchy Incoming Calls
    # callHierarchy/incomingCalls

    # Call Hierarchy Outgoing Calls
    # callHierarchy/outgoingCalls

    # Prepare Type Hierarchy
    # textDocument/prepareTypeHierarchy

    # Type Hierarchy Supertypes
    # ypeHierarchy/supertypes

    # Type Hierarchy Subtypes
    # typeHierarchy/subtypes

    # Document Highlights
    # textDocument/documentHighlight

    # Document Link
    # textDocument/documentLink

    # Document Link Resolve
    # documentLink/resolve

    # Hover
    # textDocument/hover
    def lsp_response_text_document_hover(_lsp_server, _id, resp)
      return if @frame.view_win.sci_autoc_active
      return if resp['result'].nil? || resp['result']['contents'].nil?

      lsp_process_hover_response(resp)
    end

    # Code Lens
    # textDocument/codeLens

    # Code Lens Refresh
    # workspace/codeLens/refresh

    # Folding Range
    # textDocument/foldingRange

    # Selection Range
    # textDocument/selectionRange

    # Document Symbols
    # textDocument/documentSymbol

    # Semantic Tokens
    # textDocument/semanticTokens/full
    # textDocument/semanticTokens/full/delta
    # textDocument/semanticTokens/range
    # workspace/semanticTokens/refresh

    # Inline Value
    # textDocument/inlineValue

    # Inline Value Refresh
    # workspace/inlineValue/refresh

    # Inlay Hint
    # textDocument/inlayHint

    # Inlay Hint Resolve
    # inlayHint/resolve

    # Inlay Hint Refresh
    # workspace/inlayHint/refresh

    # Monikers
    # textDocument/moniker

    # Completion
    # textDocument/completion
    def lsp_response_text_document_completion(lsp_server, id, resp)
      lsp_process_completion_response(lsp_server, id, resp)
    end

    # Completion Item Resolve
    # completionItem/resolve

    # Document Diagnostics
    # textDocument/diagnostic

    # Workspace Diagnostics
    # workspace/diagnostic

    # Signature Help
    # textDocument/signatureHelp
    def lsp_response_text_document_signature_help(_lsp_server, _id, resp)
      return if resp['result'].nil? || resp['result']['signatures'].nil?

      lsp_process_signature_help_response(resp)
    end

    # Code Action
    # textDocument/codeAction

    # Code Action Resolve
    # codeAction/resolve

    # Document Color
    # textDocument/documentColor

    # Color Presentation
    # textDocument/colorPresentation

    # Document Formatting
    # textDocument/formatting
    def lsp_response_text_document_formatting(lsp_server, id, resp)
      lsp_formatting_response(lsp_server, id, resp)
    end

    # Document Range Formatting
    # textDocument/rangeFormatting
    def lsp_response_text_document_range_formatting(lsp_server, id, resp)
      lsp_formatting_response(lsp_server, id, resp)
    end

    # Document on Type Formatting
    # textDocument/onTypeFormatting
    def lsp_response_text_document_on_type_formatting(lsp_server, id, resp)
      lsp_formatting_response(lsp_server, id, resp)
    end

    # Rename
    # textDocument/rename
    def lsp_response_text_document_rename(_lsp_server, _id, resp)
      @logger.debug resp
      if resp.key?('result') && resp['result']['changes'].key?("file://#{@current_buffer.filename}")
        lsp_process_text_edits(resp['result']['changes']["file://#{@current_buffer.filename}"])
      end
    end

    # Prepare Rename
    # textDocument/prepareRename

    # Linked Editing
    # textDocument/linkedEditingRange

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
