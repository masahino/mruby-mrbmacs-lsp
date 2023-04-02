module Mrbmacs
  # LspExtension
  class LspExtension < Extension
    LSP_GOTO_LIST_TYPE = 99
    LSP_COMPLETION_LIST_TYPE = 98

    def self.register_lsp_client(appl)
      appl.lsp_init

      appl.add_command_event(:after_find_file) do |app, filename|
        app.lsp_find_file(filename)
      end

      appl.add_command_event(:after_save_buffer) do |app, filename|
        app.lsp_did_save(filename)
      end

      appl.add_command_event(:before_save_buffers_kill_terminal) do |app|
        app.lsp_shutdown
      end

      appl.add_sci_event(Scintilla::SCN_CHARADDED) do |app, scn|
        next unless app.lsp_is_running?

        app.lsp_on_type_formatting(scn['ch'].chr('UTF-8'))
        app.lsp_send_completion_request(scn) unless app.frame.view_win.sci_autoc_active
      end

      appl.add_sci_event(Scintilla::SCN_MODIFIED) do |app, scn|
        next unless app.lsp_is_running?

        app.lsp_did_change_for_scn(scn)
      end

      appl.add_sci_event(Scintilla::SCN_DWELLSTART) do |app, scn|
        next unless app.lsp_is_running?

        td = LSP::Parameter::TextDocumentIdentifier.new(app.current_buffer.filename)
        param = { 'textDocument' => td, 'position' => app.lsp_position(scn['pos']) }
        app.ext.data['lsp'][lang].hover(param)
      end

      appl.add_sci_event(Scintilla::SCN_USERLISTSELECTION) do |app, scn|
        case scn['list_type']
        when LSP_COMPLETION_LIST_TYPE
          app.lsp_completion_select(scn)
        when LSP_GOTO_LIST_TYPE
          target_file, lines, col = scn['text'].split(',')
          app.find_file(target_file) if app.current_buffer.filename != target_file
          app.frame.view_win.sci_gotopos(app.frame.view_win.sci_find_column(lines.to_i - 1, col.to_i - 1))
          app.recenter
        end
      end

      appl.add_sci_event(Scintilla::SCN_CALLTIPCLICK) do |app, scn|
        case scn['position']
        when 1
          app.lsp_pageup_calltip
        when 2
          app.lsp_pagedown_calltip
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
  end

  # Application
  class Application
    def lsp_init
      @lsp_completion_items = []
      @lsp_calltip_info = { text: '', start_line: 0 }
      @config.use_builtin_completion = false
      @ext.data['lsp'] = {}
      config = Mrbmacs::LspExtension::LSP_DEFAULT_CONFIG.dup
      config.merge! @config.ext['lsp'] unless @config.ext['lsp'].nil?
      config = lsp_installed_servers.merge config
      config.each do |l, v|
        # if Which.which(v['command']) != nil
        @ext.data['lsp'][l] = LSP::Client.new(v['command'], v['options'])
        Mrbmacs::LspExtension.set_keybind(appl, l)
        # end
      end
    end

    def lsp_find_file(filename)
      lang = @current_buffer.mode.name
      return unless lsp_find_server(lang)

      lsp_start_server(lang, filename)
      lsp_did_open(filename)
    end

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

    # TODO: process equests from server
    # Diagnostics Refresh
    # workspace/diagnostic/refresh

    def lsp_read_message(io)
      @ext.data['lsp'].each_pair do |_k, v|
        next unless io == v.io

        headers, resp = v.recv_message
        if headers == {}
          @logger.error "server(#{v.server[:command]}) is not running"
          v.status = :not_found
          # del_io_read_event(v.io)
          next
        end
        if resp == nil
          @logger.error '[lsp] error'
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

    def lsp_additional_info(lsp_client)
      "#{File.basename(lsp_client.server[:command])}:#{lsp_client.status.to_s[0]}"
    end

    def lsp_start_server(lang, filename)
      if @ext.data['lsp'][lang].status == :stop
        @ext.data['lsp'][lang].start_server(
          {
            'rootUri' => "file://#{@current_buffer.directory}",
            'capabilities' => Mrbmacs::LspExtension.client_capabilities,
            'trace' => 'verbose'
          }
        )
        unless @ext.data['lsp'][lang].io.nil?
          add_io_read_event(@ext.data['lsp'][lang].io) do |iapp, io|
            iapp.lsp_read_message(io)
          end
        end
      end
    end

    def lsp_shutdown
      @ext.data['lsp'].each do |_lang, client|
        if client.status != :stop && client.status != :not_found
          client.shutdown
          client.stop_server
        end
      end
    end
  end
end
