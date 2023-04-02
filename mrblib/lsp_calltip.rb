module Mrbmacs
  # show Calltip window for signatureHelp and Hover
  class Application
    def lsp_draw_calltip(pos)
      # over 10 lines
      lines = @lsp_calltip_info[:text].lines
      end_line = [@lsp_calltip_info[:start_line] + 9, lines.length].min
      str = lines[@lsp_calltip_info[:start_line]...end_line].join
      max_width = lines.map(&:length).max
      str = "#{' ' * (max_width - 2)}\001\n#{str}" if @lsp_calltip_info[:start_line] > 0
      str += "\n#{' ' * (max_width - 2)}\002" if end_line < lines.length
      @frame.view_win.sci_calltip_show(pos, str)
    end

    def lsp_pageup_calltip
      @lsp_calltip_info[:start_line] -= 10
      @lsp_calltip_info[:start_line] = 0 if @lsp_calltip_info[:start_line] < 0
      lsp_draw_calltip(@frame.view_win.sci_calltip_pos_start)
    end

    def lsp_pagedown_calltip
      @lsp_calltip_info[:start_line] += 10
      lsp_draw_calltip(@frame.view_win.sci_calltip_pos_start)
    end

    def lsp_redraw_calltip
      pos = @frame.view_win.sci_calltip_pos_start
      @frame.view_win.sci_calltip_cancel
      lsp_draw_calltip(pos)
    end
  end
end
