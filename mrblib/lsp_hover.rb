module Mrbmacs
  # hover
  class Application
    def lsp_process_hover_response(resp)
      contents = if resp['result']['contents'].is_a?(Array)
                   resp['result']['contents'][0]
                 else
                   resp['result']['contents']
                 end
      str = if contents.is_a?(Hash)
              contents['value']
            else
              contents
            end
      @lsp_calltip_info[:text] = str
      @lsp_calltip_info[:start_line] = 0
      lsp_draw_calltip(@frame.view_win.sci_get_current_pos) unless str.empty?
    end
  end
end
