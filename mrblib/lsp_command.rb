module Mrbmacs
  # LSP commands
  module Command
    # LSP Language Features
    # Goto Declaration Request
    def lsp_declaration
      lsp_goto_command('declaration', 'declarationProvider')
    end

    # Goto Definition Request
    def lsp_definition
      lsp_goto_command('definition', 'definitionProvider')
    end

    # Goto Type Definition Request
    def lsp_type_definition
      lsp_goto_command('typeDefinition', 'typeDefinitionProvider')
    end

    # Goto Implementation Request
    def lsp_implementation
      lsp_goto_command('implementation', 'implementationProvider')
    end

    # Find References Request
    def lsp_references
      lsp_goto_command('references', 'referencesProvider')
    end

    # Prepare Call Hierarchy Request
    # Call Hierarchy Incoming Calls
    # Call Hierarchy Outgoing Calls
    # Prepare Type Hierarchy Request
    # Type Hierarchy Supertypes
    # Type Hierarchy Subtypes

    # Document Highlights Request
    def lsp_highlight
      lsp_document_position_command(:documentHighlight, 'documentHighlightProvider')
    end

    # Document Link Request
    # Document Link Resolve Request

    # Hover Request
    def lsp_hover
      lsp_document_position_command(:hover, 'hoverProvider')
    end

    # Code Lens Request
    def lsp_code_lens
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      @ext.data['lsp'][@current_buffer.mode.name].codeLens({ 'textDocument' => td })
    end

    # Code Lens Refresh Request

    # Folding Range Request
    def lsp_folding_range
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      @ext.data['lsp'][@current_buffer.mode.name].foldingRange({ 'textDocument' => td })
    end

    # Selection Range Request
    def lsp_selection_range
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = { 'textDocument' => td, 'positions' => [lsp_position] }
      @ext.data['lsp'][@current_buffer.mode.name].selectionRange(param)
    end

    # Document Symbols Request
    def lsp_document_symbol
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      @ext.data['lsp'][@current_buffer.mode.name].documentSymbol({ 'textDocument' => td })
    end

    # Semantic Tokens
    # Inline Value Request
    # Inline Value Refresh Request
    # Inlay Hint Request
    # Inlay Hint Resolve Request
    # Inlay Hint Refresh Request

    # Monikers
    def lsp_moniker
      lsp_document_position_command(:moniker, 'monikerProvider')
    end

    # Completion Request
    def lsp_completion
      return unless lsp_is_running?

      param = lsp_document_position_param
      param['context'] = { 'triggerKind' => LSP::CompletionTriggerKind[:Invoked] }
      @ext.data['lsp'][@current_buffer.mode.name].completion(param)
    end

    # Completion Item Resolve Request
    # Document Diagnostics

    # Signature Help Request
    def lsp_signature_help
      lsp_send_signature_help_request
    end

    # Code Action Request
    # Code Action Resolve Request
    # Document Color Request
    # Color Presentation Request

    # Document Formatting Request
    def lsp_formatting
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = {
        'textDocument' => td, 'options' => {
          'tabSize' => @current_buffer.mode.indent,
          'insertSpaces' => !@current_buffer.mode.use_tab
        }
      }
      @ext.data['lsp'][@current_buffer.mode.name].formatting(param)
    end

    # Document Range Formatting Request
    def lsp_range_formatting
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = {
        'textDocument' => td,
        'range' => {
          'start' => lsp_position(@mark_pos),
          'end' => lsp_position
        },
        'options' => {
          'tabSize' => @current_buffer.mode.indent,
          'insertSpaces' => !@current_buffer.mode.use_tab
        }
      }
      @logger.debug param
      @ext.data['lsp'][@current_buffer.mode.name].rangeFormatting(param)
    end

    # Document on Type Formatting Request

    # Rename Request
    def lsp_rename
      return unless lsp_is_running?

      current_pos = @frame.view_win.sci_get_current_pos
      word_start = @frame.view_win.sci_word_start_position(current_pos, false)
      word_end = @frame.view_win.sci_word_end_position(current_pos, false)
      word = @frame.view_win.sci_get_textrange(word_start, word_end)
      @logger.debug "srtart = #{word_start}, end = #{word_end}, word = #{word}"
      newstr = @frame.echo_gets("Replace string #{word} with: ", '')
      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = { 'textDocument' => td, 'position' => lsp_position, 'newName' => newstr }
      @ext.data['lsp'][@current_buffer.mode.name].rename(param)
    end

    # Prepare Rename Request
    # Linked Editing Range

    # end of Language Features

    # show server capabilities
    def lsp_server_capabilities
      return unless lsp_is_running?

      @logger.info JSON.pretty_generate @ext.data['lsp'][@current_buffer.mode.name].server_capabilities
    end

    # install new server
    def lsp_install_server(server = nil)
      lang = lsp_select_lang_for_server
      server = lsp_select_install_server(lang) if server.nil?
      return if server.nil?

      install_cmd = lsp_install_command(server)
      unless File.exist?(install_cmd)
        message "Installation command not found for #{server}."
        return
      end

      server_dir = lsp_server_dir(server, true)
      return if server_dir.nil?

      Dir.mkdir(server_dir) unless Dir.exist?(server_dir)

      exec_shell_command('*LSPInstall*', "(cd #{server_dir} ; #{install_cmd})") do |res|
      end
    end
  end

  # for commands
  class Application
    def lsp_goto_command(method, capability)
      unless lsp_is_running?
        message '[LSP] server is not running'
        return
      end
      unless lsp_supports_capability?(capability)
        message "[LSP] '#{method}' is not supported"
        return
      end

      message "[LSP] sending \"#{method}\" message..."
      @ext.data['lsp'][@current_buffer.mode.name].send(method, lsp_document_position_param)
    end

    def lsp_document_position_command(method, capability)
      return unless lsp_is_running?

      unless lsp_supports_capability?(capability)
        message "[LSP] '#{method}' is not supported"
        return
      end

      @ext.data['lsp'][@current_buffer.mode.name].send(method, lsp_document_position_param)
    end
  end
end
