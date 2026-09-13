module Mrbmacs
  # show Calltip window for signatureHelp and Hover
  class Application
    def lsp_draw_calltip(pos)
      lines = @lsp_calltip_info[:text].lines
      start_line = @lsp_calltip_info[:start_line]
      end_line = [start_line + 15, lines.length].min
      visible_lines = lines[start_line...end_line]
      str = visible_lines.join
      max_width = visible_lines.map { |line| line.chomp.length }.max || 0
      prefix_size = 0
      arrow_padding = [max_width - 2, 0].max
      if start_line > 0
        prefix = "#{' ' * arrow_padding}\001\n"
        str = "#{prefix}#{str}"
        prefix_size = prefix.bytesize
      end
      if end_line < lines.length
        str += "\n" unless str.end_with?("\n")
        str += "#{' ' * arrow_padding}\002"
      end
      @frame.view_win.sci_calltip_show(pos, str)

      highlight_start = @lsp_calltip_info[:highlight_start]
      highlight_end = @lsp_calltip_info[:highlight_end]
      unless highlight_start.nil? || highlight_end.nil?
        page_start = lines[0...start_line].join.bytesize
        page_end = page_start + visible_lines.join.bytesize
        if highlight_start >= page_start && highlight_end <= page_end
          @frame.view_win.sci_calltip_set_hlt(
            highlight_start - page_start + prefix_size,
            highlight_end - page_start + prefix_size
          )
        end
      end
    end

    def lsp_pageup_calltip
      @lsp_calltip_info[:start_line] -= 15
      @lsp_calltip_info[:start_line] = 0 if @lsp_calltip_info[:start_line] < 0
      lsp_draw_calltip(@frame.view_win.sci_calltip_pos_start)
    end

    def lsp_pagedown_calltip
      @lsp_calltip_info[:start_line] += 15
      lsp_draw_calltip(@frame.view_win.sci_calltip_pos_start)
    end

    def lsp_redraw_calltip
      pos = @frame.view_win.sci_calltip_pos_start
      @frame.view_win.sci_calltip_cancel
      lsp_draw_calltip(pos)
    end
  end
end
