module Mrbmacs
  class Application
    def lsp_goto_command(method, capability)
      lang = @current_buffer.mode.name
      if @ext.data['lsp'][lang].server_capabilities[capability] == false
        message "#{capability} is not supported"
        return nil
      end
      if lsp_is_running?
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
#        line, col = get_current_line_col()
        param = {"textDocument" => td, "position" => lsp_position}
        message "[lsp] sending \"#{method}\" message..."
        ret = @ext.data['lsp'][lang].send(method, param) do |resp|
          list = resp['result'].map {|x|
            sprintf("%s,%d,%d",
              lsp_uri_to_path(x['uri']),
              x['range']['start']['line'] + 1,
              x['range']['start']['character'] + 1)
          }
          message "[lsp] receive \"#{method}\" response(#{list.size})"
          @logger.debug list
          if list.size > 0
            @frame.view_win.sci_userlist_show(LspExtension::LSP_LIST_TYPE, list.join(" "))
          end
        end
      else
        message '[lsp] server is not running'
      end
    end

    def lsp_declaration()
        lsp_goto_command("declaration", "declarationProvider")
    end

    def lsp_definition()
      lsp_goto_command("definition", "definitionProvider")
    end

    def lsp_type_definition()
      lsp_goto_command("typeDefinition", "typeDefinitionProvider")
    end

    def lsp_implementation()
      lsp_goto_command("implementation", "implementationProvider")
    end

    def lsp_references()
      lsp_goto_command("references", "referencesProvider")
    end

    def lsp_edit_buffer(text_edit)
$stderr.puts "lsp edit buffer"
$stderr.puts text_edit
      sci_begin_undo_action()
      text_edit.reverse_each do |e|
        @logger.debug e
        @frame.view_win.sci_set_sel(
          @frame.view_win.sci_findcolumn(e['range']['start']['line'], e['range']['start']['character']),
          @frame.view_win.sci_findcolumn(e['range']['end']['line'], e['range']['end']['character']))
        sci_replace_sel("", e['newText'])
      end
      sci_end_undo_action()
    end

    def lsp_formatting()
      @logger.debug "lsp_formatting"
      if lsp_is_running?
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
        param = {"textDocument" => td, "options" => {
            "tabSize" => @current_buffer.mode.indent,
            "insertSpaces" => !@current_buffer.mode.use_tab
          }
        }
        @ext.data['lsp'][@current_buffer.mode.name].formatting(param) do |resp|
          @logger.debug "resp"
          @logger.debug resp
          if resp != nil
            lsp_edit_buffer(resp['result'])
          end
        end
      end
    end

    def lsp_range_formatting()
      @logger.debug "lsp_range_formatting"
      if lsp_is_running?
        @logger.debug "lsp_range_formatting go"
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
 #       anchor_line, anchor_col = get_current_line_col(@mark_pos)
#        current_line, current_col = get_current_line_col(sci_get_current_pos())
        param = {"textDocument" => td, "options" => {
            "range" => {
              "start" => lsp_position(@mark_pos),
              "end" => lsp_position
            },
            "tabSize" => @current_buffer.mode.indent,
            "insertSpaces" => !@current_buffer.mode.use_tab
          }
        }
        @logger.debug param
        @ext.data['lsp'][@current_buffer.mode.name].rangeFormatting(param) do |resp|
          @logger.debug "resp"
          @logger.debug resp
          if resp != nil and resp.has_key?('result')
            lsp_edit_buffer(resp['result'])
          else
            if resp.has_key?('error')
              message resp['error']['message']
            end
          end
        end
      end
    end

    def lsp_rename()
      @logger.debug "lsp_rename"
      if lsp_is_running?
        current_pos = @frame.view_win.sci_get_current_pos
        word_start = @frame.view_win.sci_word_start_position(current_pos, false)
        word_end = @frame.view_win.sci_word_end_position(current_pos, false)
        word = @frame.view_win.sci_get_textrange(word_start, word_end)
        @logger.debug "srtart = #{word_start}, end = #{word_end}, word = #{word}"
        newstr = @frame.echo_gets("Replace string #{word} with: ", "")
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
#        line, col = get_current_line_col
        param = {"textDocument" => td, "position" => lsp_position, "newName" => newstr}
        @ext.data['lsp'][@current_buffer.mode.name].rename(param) do |resp|
          @logger.debug resp
          if resp.has_key?('result')
            if resp['result']['changes'].has_key?('file://' + @current_buffer.filename)
              lsp_edit_buffer(resp['result']['changes']['file://' + @current_buffer.filename])
            end
          end          
        end
      end
    end

    def lsp_hover()
      if lsp_is_running?
#        line, col = get_current_line_col()
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
        param = {"textDocument" => td, "position" => lsp_position}
        @ext.data['lsp'][@current_buffer.mode.name].hover(param)
      end
    end

    def lsp_completion()
      if lsp_is_running?
 #       line, col = get_current_line_col()
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
        param = { 'textDocument' => td,
          'position' => lsp_position,
          'context' => { 'triggerKind' => 1, 'triggerCharacter' => ''},
        }
        @ext.data['lsp'][@current_buffer.mode.name].completion(param)
      end
    end
  end
end
