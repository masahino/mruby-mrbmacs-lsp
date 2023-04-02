module Mrbmacs
  # process 'goto XX' response
  class Application
    def lsp_goto_response(lsp_server, id, resp)
      method = lsp_server.request_buffer[id][:message]['method']
      list = resp['result'].map do |x|
        "#{lsp_uri_to_path(x['uri'])},#{x['range']['start']['line'] + 1},#{x['range']['start']['character'] + 1}"
      end
      message "[lsp] receive \"#{method}\" response(#{list.size})"
      @logger.debug list
      @frame.view_win.sci_userlist_show(LspExtension::LSP_GOTO_LIST_TYPE, list.join(@frame.view_win.sci_autoc_get_separator.chr)) unless list.empty?
    end
  end
end