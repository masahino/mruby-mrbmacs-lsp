module Mrbmacs
  # LSP commands
  module Command
    def lsp_declaration
      lsp_goto_command('declaration', 'declarationProvider')
    end

    def lsp_definition
      lsp_goto_command('definition', 'definitionProvider')
    end

    def lsp_type_definition
      lsp_goto_command('typeDefinition', 'typeDefinitionProvider')
    end

    def lsp_implementation
      lsp_goto_command('implementation', 'implementationProvider')
    end

    def lsp_references
      lsp_goto_command('references', 'referencesProvider')
    end

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

    def lsp_server_capabilities
      return unless lsp_is_running?

      @logger.info JSON.pretty_generate @ext.data['lsp'][@current_buffer.mode.name].server_capabilities
    end

    def lsp_hover
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = { 'textDocument' => td, 'position' => lsp_position }
      @ext.data['lsp'][@current_buffer.mode.name].hover(param)
    end

    def lsp_completion
      return unless lsp_is_running?

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = {
        'textDocument' => td,
        'position' => lsp_position,
        'context' => { 'triggerKind' => LSP::CompletionTriggerKind::INVOKED,
                       'triggerCharacter' => '' }
      }
      @ext.data['lsp'][@current_buffer.mode.name].completion(param)
    end

    def lsp_install_server(server = nil)
      lang = lsp_select_lang_for_server
      server = lsp_select_install_server(lang) if server.nil?
      return if server.nil?

      install_cmd = lsp_install_command(server)
      return unless File.exist?(install_cmd)

      server_dir = lsp_server_dir(server, true)
      return if server_dir.nil?

      Dir.mkdir(server_dir) unless Dir.exist?(server_dir)

      exec_shell_command('*LSPInstall*', "(cd #{server_dir} ; #{install_cmd})") do |res|
      end
    end
  end

  # for commands
  class Application
    include Command

    def lsp_goto_command(method, capability)
      lang = @current_buffer.mode.name
      if @ext.data['lsp'][lang].server_capabilities[capability] == false
        message "#{capability} is not supported"
        return nil
      end
      if lsp_is_running?
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
        param = { 'textDocument' => td, 'position' => lsp_position }
        message "[lsp] sending \"#{method}\" message..."
        @ext.data['lsp'][lang].send(method, param)
      else
        message '[lsp] server is not running'
      end
    end

  end
end
