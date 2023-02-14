module Mrbmacs
  # LspExtension
  class LspExtension < Extension
    LSP_LIST_TYPE = 99
    LSP_DEFAULT_CONFIG = {
      'bash' => {
        'command' => 'bash-language-server',
        'options' => { 'args' => ['start'] }
      },
      'cpp' => {
        'command' => 'ccls',
        'options' => {}
      },
      'go' => {
        'command' => 'gopls',
        'options' => {}
      },
      'html' => {
        'command' => 'html-languageserver',
        'options' => { 'args' => ['--stdio'] }
      },
      'javascript' => {
        'command' => 'typescript-language-server',
        'options' => { 'args' => ['--stdio'] }
      },
      'markdown' => {
        'command' => 'remark-language-server',
        'options' => { 'args' => ['--stdio'] }
      },
      'perl' => {
        'command' => 'perl',
        'options' => { 'args' => ['-MPerl::LanguageServer', '-e', '"Perl::LanguageServer->run"'] }
      },
      'python' => {
        'command' => 'pyls',
        'options' => {}
      },
      'r' => {
        'command' => 'R',
        'options' => { 'args' => ['--slave', '-e', 'languageserver::run\(\)'] }
      },
      'ruby' => {
        'command' => 'solargraph',
        'options' => { 'args' => ['stdio'] }
      },
      'rust' => {
        'command' => 'rls',
        'options' => {}
      }
    }

    LSP_DEFAULT_KEYMAP = {
      'M-r' => 'lsp_references',
      'M-d' => 'lsp_definition'
    }
    def self.register_lsp_client(appl)
      appl.config.use_builtin_completion = false
      appl.ext.data['lsp'] = {}
      config = LSP_DEFAULT_CONFIG
      unless appl.config.ext['lsp'].nil?
        config.merge! appl.config.ext['lsp']
      end
      config = appl.lsp_installed_servers.merge config
      config.each do |l, v|
        # if Which.which(v['command']) != nil
        appl.ext.data['lsp'][l] = LSP::Client.new(v['command'], v['options'])
        Mrbmacs::LspExtension.set_keybind(appl, l)
        # end
      end
      appl.add_command_event(:after_find_file) do |app, filename|
        lang = app.current_buffer.mode.name
        if app.lsp_find_server(lang)
          if app.ext.data['lsp'][lang].status == :stop
            app.ext.data['lsp'][lang].start_server(
              {
                'rootUri' => "file://#{app.current_buffer.directory}",
                'capabilities' => {
                  'workspace' => {},
                  'textDocument' => {
                    #                    'hover' => {
                    #                      'contentFormat' => 'plaintext',
                    #                    },
                  },
                  'trace' => 'verbose'
                }
              }
            )
            unless app.ext.data['lsp'][lang].io.nil?
              app.add_io_read_event(app.ext.data['lsp'][lang].io) do |iapp, io|
                iapp.lsp_read_message(io)
              end
            end
          end
          if app.ext.data['lsp'][lang].status == :running
            app.ext.data['lsp'][lang].didOpen({ 'textDocument' => LSP::Parameter::TextDocumentItem.new(filename) })
          end
          app.current_buffer.additional_info = app.lsp_additional_info(app.ext.data['lsp'][lang])
        end
      end

      appl.add_command_event(:after_save_buffer) do |app, filename|
        lang = app.current_buffer.mode.name
        if app.lsp_is_running?
          app.ext.data['lsp'][lang].didSave(
            {
              'textDocument' => LSP::Parameter::TextDocumentIdentifier.new(filename)
            }
          )
        end
      end

      appl.add_command_event(:before_save_buffers_kill_terminal) do |app|
        app.ext.data['lsp'].each do |_lang, client|
          if client.status != :stop && client.status != :not_found
            client.shutdown
            client.stop_server
          end
        end
      end

      appl.add_sci_event(Scintilla::SCN_CHARADDED) do |app, scn|
        next unless app.lsp_is_running?

        lang = app.current_buffer.mode.name
         app.lsp_on_type_formatting(scn['ch'].chr('UTF-8'))
        unless app.frame.view_win.sci_autoc_active
          app.ext.data['lsp'][lang].cancel_request_with_method('textDocument/completion')
          app.lsp_send_completion_request(scn)
        end
      end

      appl.add_sci_event(Scintilla::SCN_MODIFIED) do |app, scn|
        next unless app.lsp_is_running?

        app.lsp_did_change(scn)
      end

      appl.add_sci_event(Scintilla::SCN_DWELLSTART) do |app, scn|
        lang = app.current_buffer.mode.name
        if app.lsp_is_running?
          _line, _col = app.line_col_from_pos(scn['pos'])
          td = LSP::Parameter::TextDocumentIdentifier.new(app.current_buffer.filename)
          param = { 'textDocument' => td, 'position' => app.lsp_position(scn['pos']) }
          app.ext.data['lsp'][lang].hover(param)
        end
      end

      appl.add_sci_event(Scintilla::SCN_USERLISTSELECTION) do |app, scn|
        if scn['list_type'] == LSP_LIST_TYPE
          target_file, lines, col = scn['text'].split(',')
          if app.current_buffer.filename != target_file
            app.find_file(target_file)
          end
          app.frame.view_win.sci_gotopos(app.frame.view_win.sci_find_column(lines.to_i - 1, col.to_i - 1))
          app.recenter
        end
      end
    end

    def self.set_keybind(_app, lang)
      mode = Mrbmacs::Mode.get_mode_by_name(lang)
      return if mode.nil?

      LSP_DEFAULT_KEYMAP.each do |k, v|
        mode.keymap[k] = v
      end
    end

    def self.get_diagnostic_severity_to_s(severity)
      case severity
      when 1
        'Error'
      when 2
        'Warning'
      when 3
        'Information'
      when 4
        'Hint'
      else
        'Unknwon'
      end
    end
  end

  # Application
  class Application
    def lsp_is_running?
      lang = @current_buffer.mode.name
      if !@ext.data['lsp'][lang].nil? && @ext.data['lsp'][lang].status == :running
        # @ext[:lsp].server[lang]
        true
      else
        false
      end
    end

    def lsp_uri_to_path(uri)
      uri.gsub('file://', '')
    end

    def lsp_trigger_characters(provider, parameter = 'triggerCharacters')
      lang = @current_buffer.mode.name
      if !@ext.data['lsp'][lang].nil? &&
         !@ext.data['lsp'][lang].server_capabilities[provider].nil? &&
         !@ext.data['lsp'][lang].server_capabilities[provider][parameter].nil?
        @ext.data['lsp'][lang].server_capabilities[provider][parameter]
      else
        []
      end
    end

    def lsp_on_type_formatting_trigger_characters
      triggers = []
      lang = @current_buffer.mode.name
      if !@ext.data['lsp'][lang].nil? &&
         !@ext.data['lsp'][lang].server_capabilities['documentOnTypeFormattingProvider'].nil? &&
         !@ext.data['lsp'][lang].server_capabilities['documentOnTypeFormattingProvider']['firstTriggerCharacter'].nil?
        triggers.push @ext.data['lsp'][lang].server_capabilities['documentOnTypeFormattingProvider']['firstTriggerCharacter']
      end
      triggers.union(lsp_trigger_characters('documentOnTypeFormattingProvider', 'moreTriggerCharacter'))
    end

    def lsp_completion_trigger_characters
      lsp_trigger_characters('completionProvider')
    end

    def lsp_signature_trigger_characters
      lsp_trigger_characters('signatureHelpProvider')
    end

    def lsp_read_message(io)
      @ext.data['lsp'].each_pair do |_k, v|
        next unless io == v.io

        headers, resp = v.recv_message
        if headers == {}
          @logger.error "server(#{v.server[:command]}) is not running"
          v.status = :not_found
          del_io_read_event(v.io)
          next
        end
        @logger.debug resp.to_s
        if !resp['id'].nil?
          # request or response
          id = resp['id'].to_i
          if !v.request_buffer[id].nil?
            lsp_response(v, id, resp)
          else # request?
            @logger.info resp.to_s
          end
        else # notification
          lsp_notification(v, resp)
        end
        break
      end
      # end
    end

    def lsp_send_completion_request(scn)
      unless lsp_is_running?
        @logger.info 'not yet initialized'
        return
      end

      lang = @current_buffer.mode.name
      _line, col = current_line_col
      return if col == 0

      line_text = current_line_text.chomp[0..col]
      input = line_text.split(' ').pop
      return if input.nil? || input.length == 0

      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      if lsp_signature_trigger_characters.include?(scn['ch'].chr('UTF-8'))
        @ext.data['lsp'][lang].signatureHelp(
          { 'textDocument' => td, 'position' => lsp_position }
        )
      else
        if lsp_completion_trigger_characters.include?(scn['ch'].chr('UTF-8'))
          trigger_kind = LSP::CompletionTriggerKind::TRIGGER_CHARACTER # 2
          trigger_char = scn['ch'].chr('UTF-8')
        else
          trigger_kind = LSP::CompletionTriggerKind::INVOKED # 1
          trigger_char = ''
        end
        param = {
          'textDocument' => td,
          'position' => lsp_position,
          'context' => { 'triggerKind' => trigger_kind, 'triggerCharacter' => trigger_char }
        }
        @logger.debug param.to_s
        @ext.data['lsp'][lang].completion(param)
      end
    end

    def lsp_get_completion_list(req, res)
@logger.info res
      _line, col = current_line_col
      line_text = current_line_text.chomp[0..col]
      input = if req.key?('context') &&
                 req['context'].key?('triggerKind') &&
                 req['context']['triggerKind'] == LSP::CompletionTriggerKind::TRIGGER_CHARACTER
                ''
              else
                line_text.split(/[ #{lsp_completion_trigger_characters.join}]/).pop
              end
      if res.key?('result')
        items = []
        if res['result'].is_a?(Hash)
          if res['result'].key?('items')
            items = res['result']['items']
          end
        elsif res['result'].is_a?(Array)
          items = res['result']
        end
        # candidates = res['result']['items'].map { |h|
        candidates = items.map do |h|
          str = ''
          if !h['textEdit'].nil?
            str = h['textEdit']['newText'].strip
          elsif !h['insertText'].nil?
            str = h['insertText'].strip
          elsif !h['label'].nil?
            str = h['label'].strip
          end
          str
        end
      else
        candidates = []
      end
      @logger.debug candidates.to_s
      [input.length, candidates.sort.uniq.join(' ')]
    end

    def lsp_get_style_from_severity(severity)
      case severity
      when 1
        @theme.annotation_style(:error)
      when 2
        @theme.annotation_style(:warn)
      when 3
        @theme.annotation_style(:info)
      when 4
        @theme.annotation_style(:info)
      else
        @theme.annotation_style(:other)
      end
    end

    def lsp_show_annotation(diagnostics)
      @frame.view_win.sci_annotation_clearall
      diagnostics.each do |d|
        line = d['range']['start']['line']
        col = d['range']['start']['character'] + 1
        severity_str = Mrbmacs::LspExtension.get_diagnostic_severity_to_s(d['severity'])
        message = "#{severity_str}:#{d['message'].gsub(/\n\n/, "\n")}"
        # margin(6+2) + scrollbar
        max_len = @frame.edit_win.width - 11 - @frame.view_win.sci_get_line_indentation(line)
        message.insert(max_len, "\n#{' ' * (severity_str.length + 1)}") if message.length > max_len
        style = lsp_get_style_from_severity(d['severity'])
        if @frame.view_win.sci_annotation_get_lines(line) > 0
          message = "#{@frame.view_win.sci_annotation_get_text(line)}\n#{message}"
          style = @frame.view_win.sci_annotation_get_style(line)
        end
        @frame.show_annotation(line + 1, col, message, style)
      end
      @frame.view_win.sci_scrollcaret
    end

    def lsp_additional_info(lsp_client)
      "#{File.basename(lsp_client.server[:command])}:#{lsp_client.status.to_s[0]}"
    end

    def lsp_start_server(lang, filename)
      if @ext.data['lsp'][lang].status == :stop
        @ext.data['lsp'][lang].start_server(
          {
            'rootUri' => "file://#{@current_buffer.directory}",
            'capabilities' => {
              'workspace' => {},
              'textDocument' => {
                'onTypeFormatting' => {
                  'dynamicRegistration' => true
                }
              },
              'trace' => 'verbose'
            }
          }
        )
        unless @ext.data['lsp'][lang].io.nil?
          add_io_read_event(@ext.data['lsp'][lang].io) do |iapp, io|
            iapp.lsp_read_message(io)
          end
        end
      end
      if @ext.data['lsp'][lang].status == :running
        @ext.data['lsp'][lang].didOpen({ 'textDocument' => LSP::Parameter::TextDocumentItem.new(filename) })
      end
      @current_buffer.additional_info = lsp_additional_info(@ext.data['lsp'][lang])
    end
  end
end
