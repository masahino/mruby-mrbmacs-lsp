module Mrbmacs
  class Application
    def lsp_goto_command(method)
      lang = @current_buffer.mode.name
      if @ext.lsp[lang] != nil and @ext.lsp[lang].status == :running
        td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
        line, col = get_current_line_col()
        param = {"textDocument" => td, "position" => {"line" => line, "character" => col}}
        ret = @ext.lsp[lang].send(method, param) do |resp|
          list = resp['result'].map {|x|
            sprintf("%s,%d,%d",
              Extension::lsp_uri_to_path(x['uri']),
              x['range']['start']['line'] + 1,
              x['range']['start']['character'] + 1)
          }
          if list.size > 0
            @frame.view_win.sci_userlist_show(Extension::LSP_LIST_TYPE, list.join(" "))
          end
        end
      end
    end

    def lsp_goto_declaration()
      lsp_goto_command("declaration")
    end

    def lsp_goto_definition()
      lsp_goto_command("definition")
    end
  end
end
