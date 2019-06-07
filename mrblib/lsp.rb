module Mrbmacs
  class Extension
    attr_accessor :lsp
    def self.register_lsp_client(app)
      app.ext.lsp = {}
      app.ext.lsp["ruby"] = LSP::Client.new("solargraph", {"args" => ["stdio"]})
      app.ext.lsp["cpp"] = LSP::Client.new("cquery", {"initializationOptions" => 
          {"cacheDirectory" => "/tmp/cquery/cache"}})
      app.ext.lsp["go"] = LSP::Client.new("gopls")
      app.ext.lsp["python"] = LSP::Client.new("pyls")

      app.add_command_event(:after_find_file) do |app, filename|
        current_buffer = app.current_buffer
        lang = current_buffer.mode.name
        if app.ext.lsp[lang] != nil
          if app.ext.lsp[lang].status == :stop
            app.ext.lsp[lang].start_server({'rootUri' => 'file://' + current_buffer.directory})
            if app.ext.lsp[lang].io != nil
              app.add_io_read_event(app.ext.lsp[lang].io) do |app, io|
                app.lsp_read_message(io)
              end
            end
          end
          if app.ext.lsp[lang].status == :running
            app.ext.lsp[lang].didOpen({"textDocument" => LSP::Parameter::TextDocumentItem.new(filename)})
          end
        end
      end

      app.add_sci_event(Scintilla::SCN_CHARADDED) do |app, scn|
        lang = app.current_buffer.mode.name
        if app.ext.lsp[lang] != nil and app.ext.lsp[lang].status == :running and
          app.ext.lsp[lang].cancel_request_with_method('textDocument/completion')
          app.frame.view_win.sci_autoc_active == 0 
          app.lsp_send_completion_request()
        end
      end

      app.add_sci_event(Scintilla::SCN_MODIFIED) do |app, scn|
        lang = app.current_buffer.mode.name
        if app.ext.lsp[lang] != nil and app.ext.lsp[lang].status == :running
          if scn['modification_type'] & Scintilla::SC_MOD_INSERTTEXT > 0
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
    end
  end

  class Application
    def lsp_read_message(io)
      @ext.lsp.each_pair do |k, v|
        if io == v.io
          resp = v.recv_message[1]
          if resp['id'] != nil
            # request or response
            id = resp['id'].to_i
            if v.request_buffer[id] != nil 
              case v.request_buffer[id][:message]['method']
              when 'initialize'
                v.initialized
              when 'textDocument/completion'
                if @frame.view_win.sci_autoc_active == 0 
                  len, candidates = lsp_get_completion_list(resp)
                  if len > 0 and candidates.length > 0
                    @frame.view_win.sci_autoc_show(len, candidates)
                  end
                end
              else
                $stderr.puts "unknown message"
              end
              v.request_buffer.delete(id)
            end
          else # notification
            case resp['method']
            when 'textDocument/publishDiagnostics'
              resp['params']['diagnostics'].each do |d|
                $stderr.puts d['message']
              end
            else
              $stderr.puts "unknown method #{resp['method']}"
            end
          end
          break
        end
      end
    end

    def lsp_completion()
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
            id = @ext.lsp[lang].completion({"textDocument" => td,
#                "position" => {"line" => line, "character" => col-1},
                "position" => {"line" => line, "character" => col},
                "context" => {"triggerKind" => 1}})
            res = @ext.lsp[lang].wait_response(id)
#            candidates = res['result']['items'].map { |h| h['label'] }
            candidates = res['result']['items'].map { |h| 
              if h['kind'] == 15
                input + h['textEdit']['newText']
              else
                h['textEdit']['newText']
              end
            }
            [input.length, candidates.sort.join(" ")]
#            [0, ""]
          end
        else
          $stderr.puts "not yet initialized"
          [0, ""]
        end
      end
    end

    def lsp_send_completion_request()
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
            id = @ext.lsp[lang].completion({"textDocument" => td,
#                "position" => {"line" => line, "character" => col-1},
                "position" => {"line" => line, "character" => col},
                "context" => {"triggerKind" => 1}})
          end
        end
      else
          $stderr.puts "not yet initialized"
      end
    end

    def lsp_get_completion_list(res)
      line, col = get_current_line_col()
      line_text = get_current_line_text().chomp[0..col]
      input = line_text.split(" ").pop
      candidates = res['result']['items'].map { |h|
        str = ""
        if h['textEdit'] != nil
          str = h['textEdit']['newText'].chop
        elsif h['insertText'] != nil
          str = h['insertText'].chop
        elsif h['label'] != nil
          str = h['label'].chop
        end

        if h['kind'] == 15
          input + str
        else
          str
        end
      }
      [input.length, candidates.sort.join(" ")]
    end
  end
end
