module Mrbmacs
  # LspExtension
  class LspExtension < Extension
    LSP_GOTO_LIST_TYPE = 99
    LSP_COMPLETION_LIST_TYPE = 98
    LSP_DOCUMENT_SYMBOL_LIST_TYPE = 97
    LSP_CODE_ACTION_LIST_TYPE = 96

    def self.register_lsp_client(appl)
      appl.lsp_init
      setup_command_event_handlers(appl)
      setup_scn_event_handlers(appl)
    end

    def self.setup_command_event_handlers(appl)
      appl.add_command_event(:after_find_file) { |app, filename| app.lsp_find_file(filename) }

      appl.add_command_event(:after_save_buffer) { |app, filename| app.lsp_did_save(filename) }

      appl.add_command_event(:before_save_buffers_kill_terminal) { |app| app.lsp_shutdown }

      appl.add_command_event(:after_kill_buffer) { |app, buffer| app.lsp_kill_buffer(buffer) }
    end

    def self.setup_scn_event_handlers(appl)
      appl.add_sci_event(Scintilla::SCN_CHARADDED) do |app, scn|
        next unless app.lsp_is_running?

        app.lsp_scn_char_added(scn)
      end

      appl.add_sci_event(Scintilla::SCN_MODIFIED) do |app, scn|
        next unless app.lsp_is_running?

        app.lsp_did_change_for_scn(scn)
      end

      appl.add_sci_event(Scintilla::SCN_DWELLSTART) do |app, scn|
        next unless app.lsp_is_running?

        app.lsp_scn_dwell_start(scn)
      end

      appl.add_sci_event(Scintilla::SCN_DWELLEND) do |app, scn|
        app.lsp_scn_dwell_end(scn)
      end

      appl.add_sci_event(Scintilla::SCN_USERLISTSELECTION) do |app, scn|
        app.lsp_scn_user_list_selection(scn)
      end

      appl.add_sci_event(Scintilla::SCN_CALLTIPCLICK) do |app, scn|
        app.lsp_scn_calltip_click(scn)
      end
    end

    def self.set_keybind(_app, lang)
      mode = Mrbmacs::ModeManager.get_mode_by_name(lang)
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
      @lsp_document_symbol_items = []
      @lsp_code_action_items = []
      @lsp_selected_code_action_item = nil
      @lsp_code_action_server = nil
      @lsp_calltip_info = { text: '', start_line: 0 }
      @lsp_hover_request_id = nil
      @lsp_hover_position = nil
      @lsp_hover_trigger = nil
      @lsp_data_dir = lsp_data_dir(true)
      @config.use_builtin_completion = false
      @ext.data['lsp'] = {}
      @ext.config['lsp'] = Mrbmacs::LspExtension::LSP_DEFAULT_CONFIG.dup
      @ext.config['lsp'].merge! @config.ext['lsp'] unless @config.ext['lsp'].nil?
      @ext.config['lsp'] = lsp_installed_servers.merge @ext.config['lsp']
      # config.each do |l, v|
      #   @ext.data['lsp'][l] = LSP::Client.new(v['command'], v['options'])
      #   Mrbmacs::LspExtension.set_keybind(appl, l)
      # end
    end

    def lsp_find_file(filename)
      lang = @current_buffer.mode.name
      return unless lsp_find_server(lang)

      lsp_start_server(lang, filename)

      uri = LSP::Parameter::TextDocumentIdentifier.new(filename).uri
      return if @ext.data['lsp'][lang].file_version.key?(uri)
      lsp_did_open(filename)
    end

    def lsp_is_running?(lang = @current_buffer.mode.name)
      if !@ext.data['lsp'][lang].nil? && @ext.data['lsp'][lang].status == :running
        # @ext[:lsp].server[lang]
        true
      else
        false
      end
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

    def lsp_scn_char_added(scn)
      input_char = scn['ch'].chr('UTF-8')
      if lsp_on_type_formatting_trigger_characters.include?(input_char)
        lsp_on_type_formatting(input_char)
      elsif lsp_signature_trigger_characters.include?(input_char)
        lsp_send_signature_help_request
      else
        lsp_send_completion_request(scn) # unless app.frame.view_win.sci_autoc_active
      end
    end

    def lsp_scn_user_list_selection(scn)
      case scn['list_type']
      when LspExtension::LSP_COMPLETION_LIST_TYPE
        lsp_completion_select(scn)
      when LspExtension::LSP_GOTO_LIST_TYPE
        lsp_location_select(scn)
      when LspExtension::LSP_DOCUMENT_SYMBOL_LIST_TYPE
        lsp_document_symbol_select(scn)
      when LspExtension::LSP_CODE_ACTION_LIST_TYPE
        lsp_code_action_select(scn)
      end
    end

    def lsp_scn_dwell_start(scn)
      lsp_request_hover(scn['position'], :dwell)
    end

    def lsp_request_hover(position, trigger)
      lang = @current_buffer.mode.name
      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      param = { 'textDocument' => td, 'position' => lsp_position(position) }
      @ext.data['lsp'][lang].cancel_request_with_method('textDocument/hover')
      @lsp_hover_request_id = @ext.data['lsp'][lang].hover(param)
      if @lsp_hover_request_id.nil?
        @lsp_hover_position = nil
        @lsp_hover_trigger = nil
      else
        @lsp_hover_position = position
        @lsp_hover_trigger = trigger
      end
      @lsp_hover_request_id
    end

    def lsp_scn_dwell_end(_scn)
      return unless @lsp_hover_trigger == :dwell

      lang = @current_buffer.mode.name
      @ext.data['lsp'][lang].cancel_request_with_method('textDocument/hover')
      @lsp_hover_request_id = nil
      @lsp_hover_position = nil
      @lsp_hover_trigger = nil
      @frame.view_win.sci_calltip_cancel
    end

    def lsp_scn_calltip_click(scn)
      case scn['position']
      when 1
        lsp_pageup_calltip
      when 2
        lsp_pagedown_calltip
      end
    end

    # TODO: process equests from server
    # Diagnostics Refresh
    # workspace/diagnostic/refresh
    # Register Capability
    # client/registerCapability
    # Unregister Capability
    # client/unregisterCapability

    def lsp_read_message(io)
      @ext.data['lsp'].each_pair do |_k, v|
        next unless io == v.io

        begin
          headers, message = v.recv_message
        rescue EOFError
          # del_io_read_event(v.io)
          @logger.info "LSP server closed: #{File.basename(v.server[:command])}"
          # v.stop_server
          break
        end
        if headers == {}
          @logger.error "server(#{v.server[:command]}) is not running"
          v.status = :not_found
          break
        end
        if message.nil?
          @logger.error '[lsp] error'
          next
        end
        @logger.debug message.to_s
        if !message['id'].nil?
          if !message['method'].nil?
            lsp_request(v, message)
          else
            id = message['id'].to_i
            if !v.request_buffer[id].nil?
              lsp_response(v, id, message)
            else
              @logger.info "[LSP] unexpected response id=#{message['id']}"
              @logger.debug message.to_s
            end
          end
        else # notification
          lsp_notification(v, message)
        end
        break
      end
      # end
    end

    def lsp_additional_info(lsp_client)
      "#{File.basename(lsp_client.server[:command])}:#{lsp_client.status.to_s[0]}"
    end

    def lsp_start_server(lang, _filename)
      if @ext.data['lsp'][lang].nil?
        @ext.data['lsp'][lang] = LSP::Client.new(@ext.config['lsp'][lang]['command'],
                                                 @ext.config['lsp'][lang]['options'])
        Mrbmacs::LspExtension.set_keybind(self, lang)
      end

      return if @ext.data['lsp'][lang].status != :stop

      @ext.data['lsp'][lang].start_server(
        {
          'rootUri' => "file://#{@current_buffer.directory}",
          'capabilities' => Mrbmacs::LspExtension.client_capabilities,
          'trace' => 'verbose'
        }
      )
      return if @ext.data['lsp'][lang].io.nil?

      add_io_read_event(@ext.data['lsp'][lang].io) do |iapp, io|
        iapp.lsp_read_message(io)
      end
    end

    def lsp_shutdown
      @ext.data['lsp'].each_value do |client|
        if client.status != :stop && client.status != :not_found
          client.shutdown
          # client.stop_server
        end
      end
    end

    def lsp_kill_buffer(buffer)
      lang = buffer.mode.name
      return unless lsp_find_server(lang)

      lsp_did_close(lang, buffer.filename)
    end
  end
end
