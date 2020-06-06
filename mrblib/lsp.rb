module Mrbmacs
  class Extension
    attr_accessor :lsp
    LSP_LIST_TYPE = 99
    LSP_DEFAULT_CONFIG = {
      "cpp" => {
        "command" => "clangd",
        "options" => {},
      },
      "go" => {
        "command" => "gopls",
        "options" => {},
      },
      "html" => {
        "command" => "html-languageserver",
        "options" => {"args" => ["--stdio"]},
      },
      "python" => {
        "command" => "pyls",
        "options" => {},
      },
      "ruby" => {
        "command" => "solargraph",
        "options" => {"args" => ["stdio"]},
      },
      "rust" => {
        "command" => "rls",
        "options" => {},
      },
    }

    def self.register_lsp_client(app)
      app.use_builtin_completion = false
      app.ext.lsp = {}
      config = LSP_DEFAULT_CONFIG
      if app.ext.config['lsp'] != nil
        config.merge! app.ext.config['lsp']
      end
      config.each do |l, v|
        app.ext.lsp[l] = LSP::Client.new(v["command"], v["options"])
      end
      app.add_command_event(:after_find_file) do |app, filename|
        current_buffer = app.current_buffer
        lang = current_buffer.mode.name
        if app.ext.lsp[lang] != nil
          if app.ext.lsp[lang].status == :stop
            app.ext.lsp[lang].start_server({
                'rootUri' => 'file://' + current_buffer.directory,
                'capabilities' => {
                  'workspace' => {},
                  'textDocument' => {
#                    'hover' => {
#                      'contentFormat' => 'plaintext',
#                    },
                },
                'trace' => 'verbose',
                }
              })
            if app.ext.lsp[lang].io != nil
              app.add_io_read_event(app.ext.lsp[lang].io) do |app, io|
                app.lsp_read_message(io)
              end
            end
          end
#          if app.ext.lsp[lang].status == :running
            app.ext.lsp[lang].didOpen({"textDocument" => LSP::Parameter::TextDocumentItem.new(filename)})
#          end
          current_buffer.additional_info = app.ext.lsp[lang].server[:command] + ":" + app.ext.lsp[lang].status.to_s[0]
        end
      end

      app.add_command_event(:after_save_buffer) do |app, filename|
        current_buffer = app.current_buffer
        lang = current_buffer.mode.name
        if app.ext.lsp[lang] != nil and app.ext.lsp[lang].status == :running
          app.ext.lsp[lang].didSave({"textDocument" => LSP::Parameter::TextDocumentIdentifier.new(filename)})
        end
      end

      app.add_command_event(:before_save_buffers_kill_terminal) do |app|
        app.ext.lsp.each do |lang, client|
          if client.status != :stop
            client.shutdown
            client.stop_server
          end
        end
      end


      app.add_sci_event(Scintilla::SCN_CHARADDED) do |app, scn|
        lang = app.current_buffer.mode.name
        if app.ext.lsp[lang] != nil and app.ext.lsp[lang].status == :running and
          app.frame.view_win.sci_autoc_active == 0 
          app.ext.lsp[lang].cancel_request_with_method('textDocument/completion')
          app.lsp_send_completion_request(scn)
        end
      end

      app.add_sci_event(Scintilla::SCN_MODIFIED) do |app, scn|
        lang = app.current_buffer.mode.name
        if app.ext.lsp[lang] != nil and app.ext.lsp[lang].status == :running
          if scn['modification_type'] & (Scintilla::SC_MOD_INSERTTEXT | Scintilla::SC_MOD_DELETETEXT) > 0
            pos = scn['position']
            line, col = app.get_current_line_col(pos)
            length = scn['length']
            filename = app.current_buffer.filename
            td = LSP::Parameter::VersionedTextDocumentIdentifier.new(app.current_buffer.filename, 0)
            range = LSP::Parameter::Range.new(line, col, line, col+length)
#            cc = [LSP::Parameter::TextDocumentContentChangeEvent.new(scn['text'], range, length)]
            cc = [LSP::Parameter::TextDocumentContentChangeEvent.new(app.frame.view_win.sci_get_text(app.frame.view_win.sci_get_length+1))]
            param = {"textDocument" => td, "contentChanges" => cc}
            if app.ext.lsp[lang].file_version[td.uri] == nil
              app.ext.lsp[lang].didOpen({"textDocument" => LSP::Parameter::TextDocumentItem.new(filename)})
            end
            app.ext.lsp[lang].didChange(param)
          end
        end
      end

      app.add_sci_event(Scintilla::SCN_DWELLSTART) do |app, scn|
        lang = app.current_buffer.mode.name
        if app.ext.lsp[lang] != nil and app.ext.lsp[lang].status == :running
          line, col = app.get_current_line_col(scn['pos'])
          td = LSP::Parameter::TextDocumentIdentifier.new(app.current_buffer.filename)
          param = {"textDocument" => td, "position" => {"line" => line, "character" => col}}
          app.ext.lsp[lang].hover(param)
        end
      end

      app.add_sci_event(Scintilla::SCN_USERLISTSELECTION) do |app, scn|
        if scn['list_type'] == LSP_LIST_TYPE
          target_file, lines, col = scn['text'].split(",")
          if app.current_buffer.filename != target_file
            app.find_file(target_file)
          end
          app.frame.view_win.sci_gotopos(app.frame.view_win.sci_find_column(lines.to_i-1, col.to_i-1))
        end
      end

    end

    def self.lsp_uri_to_path(uri)
      uri.gsub('file://','')
    end
  end

  class Application
    def lsp_is_running?
      lang = @current_buffer.mode.name
      if @ext.lsp[lang] != nil and @ext.lsp[lang].status == :running
        true
      else
        false
      end
    end

    def lsp_read_message(io)
      @ext.lsp.each_pair do |k, v|
        if io == v.io
          resp = v.recv_message[1]
          @logger.debug resp.to_s
          if resp['id'] != nil
            # request or response
            id = resp['id'].to_i
            if v.request_buffer[id] != nil 
              @logger.debug v.request_buffer[id][:message]['method'].to_s
              case v.request_buffer[id][:message]['method']
              when 'initialize'
                v.initialized(resp)
                @current_buffer.additional_info = v.server[:command] + ":" + v.status.to_s[0]
              when 'textDocument/completion'
                if @frame.view_win.sci_autoc_active == 0 and @frame.view_win.sci_calltip_active == 0
                  @logger.debug v.request_buffer[id].to_s
                  len, candidates = lsp_get_completion_list(v.request_buffer[id][:message]['params'], resp)
                  if candidates.length > 0
                    @frame.view_win.sci_autoc_show(len, candidates)
                  end
                end
              when 'textDocument/hover'
                if frame.view_win.sci_autoc_active == 0
                  if resp['result'] != nil and resp['result']['contents']['value'] != nil
                    markup_kind = resp['result']['contents']['kind']
                    value = resp['result']['contents']['value']
                    if value.size > 0
                      @frame.view_win.sci_calltip_show(@frame.view_win.sci_get_current_pos, value)
                    end
                  end
                end
              when 'textDocument/signatureHelp'
                @logger.debug resp['result']['signatures'].to_s
                if resp['result'] != nil and resp['result']['signatures'] != nil
                  list = resp['result']['signatures'].map {|s| s['label']}.uniq
                  @logger.debug list.to_s
                  if list.size > 0
                    @frame.view_win.sci_calltipshow(@frame.view_win.sci_get_current_pos, list.join("\n"))
                  end
                end
              else
                @logger.info "unknown message"
                @logger.info resp.to_s
              end
              v.request_buffer.delete(id)
            else # request?
              @logger.info resp.to_s
            end
          else # notification
            case resp['method']
            when 'textDocument/publishDiagnostics'
              @logger.info "publishDiagnostics"
              if @current_buffer.filename == lsp_uri_to_path(resp['params']['uri'])
                lsp_show_annotation(resp['params']['diagnostics'])
              end
            else
              @logger.info "unknown method #{resp['method']}"
              @logger.info resp.to_s
            end
          end
          break
        end
      end
    end

    def lsp_send_completion_request(scn)
      view_win = @frame.view_win
      lang = @current_buffer.mode.name
      if @ext.lsp[lang] != nil and @ext.lsp[lang].status == :running
        pos = view_win.sci_get_current_pos()
        col = view_win.sci_get_column(pos)
        if col > 0
          line = view_win.sci_line_from_position(pos)
          line_text = view_win.sci_get_line(line).chomp[0..col]
          input = line_text.split(" ").pop
          td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
          if input != nil and input.length > 0
            if @ext.lsp[lang].server_capabilities['completionProvider']['triggerCharacters'].include?(scn['ch'].chr)
              trigger_kind = 2
              trigger_char = scn['ch'].chr
            else
              trigger_kind = 1
              trigger_char = ""
            end
            param = {"textDocument" => td,
                "position" => {"line" => line, "character" => col},
                "context" => {"triggerKind" => trigger_kind, "triggerCharacter" => trigger_char},
            }
            @logger.debug param.to_s
            @ext.lsp[lang].completion(param)

          end
          if @ext.lsp[lang].server_capabilities['signatureHelpProvider'] != nil and
            @ext.lsp[lang].server_capabilities['signatureHelpProvider']['triggerCharacters'] != nil
            if @ext.lsp[lang].server_capabilities['signatureHelpProvider']['triggerCharacters'].include?(scn['ch'].chr)
              @ext.lsp[lang].signatureHelp({
                "textDocument" => td, "position" => {"line" => line, "character" => col}})
            end
          end

        end
      else
        @logger.info "not yet initialized"
      end
    end

    def lsp_get_completion_list(req, res)
      line, col = get_current_line_col()
      line_text = get_current_line_text().chomp[0..col]
      input = if req.has_key?('context') and
        req['context'].has_key?('triggerKind') and
        req['context']['triggerKind'] == 2
        ""
      else
        line_text.split(" ").pop
      end
      if res.has_key?('result')
        items = []
        if res['result'].is_a?(Hash)
          if res['result'].has_key?('items')
            items = res['result']['items']
          end
        elsif res['result'].is_a?(Array)
          items = res['result']
        end
#        candidates = res['result']['items'].map { |h|
        candidates = items.map { |h|
          str = ""
          if h['textEdit'] != nil
            str = h['textEdit']['newText'].strip
          elsif h['insertText'] != nil
            str = h['insertText'].strip
          elsif h['label'] != nil
            str = h['label'].strip
          end
          str
        }
      else
        candidates = []
      end
      @logger.debug candidates.to_s
      [input.length, candidates.sort.uniq.join(" ")]
    end

    def lsp_show_annotation(diagnostics)
      @frame.view_win.sci_annotation_clearall
      diagnostics.each do |d|
        @frame.show_annotation(
          d['range']['start']['line'] + 1,
          d['range']['start']['character'] + 1,
          d['message']
          )
      end
    end
  end
end
