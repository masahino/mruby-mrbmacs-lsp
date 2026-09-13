module Mrbmacs
  # hover
  class Application
    def lsp_simplify_hover_markdown(text)
      lines = []

      text.lines.each do |line|
        stripped = line.strip
        if stripped.start_with?('```')
          next
        end

        line = "#{stripped[1...-1]}\n" if stripped.length >= 2 &&
                                                stripped.start_with?('`') &&
                                                stripped.end_with?('`')
        next if line.strip.empty? && !lines.empty? && lines[-1].strip.empty?

        lines << line
      end

      simplified = lines.join
      highlight_line = nil
      lines.each_with_index do |line, index|
        unless line.strip.empty?
          highlight_line = index
          break
        end
      end
      highlight_start = nil
      highlight_end = nil
      unless highlight_line.nil?
        highlight_start = lines[0...highlight_line].join.bytesize
        highlight_end = highlight_start + lines[highlight_line].sub(/\n\z/, '').bytesize
      end
      [simplified, highlight_start, highlight_end]
    end

    def lsp_process_hover_response(resp, position = nil)
      contents = if resp['result']['contents'].is_a?(Array)
                   resp['result']['contents'][0]
                 else
                   resp['result']['contents']
                 end
      markdown = contents.is_a?(Hash) && contents['kind'] == 'markdown'
      str = contents.is_a?(Hash) ? contents['value'] : contents
      markdown ||= str.include?('```')
      str, highlight_start, highlight_end = lsp_simplify_hover_markdown(str) if markdown
      str = str.lines.first(15).join
      @lsp_calltip_info[:text] = str
      @lsp_calltip_info[:start_line] = 0
      @lsp_calltip_info[:highlight_start] = highlight_start
      @lsp_calltip_info[:highlight_end] = highlight_end
      position = @frame.view_win.sci_get_current_pos if position.nil?
      lsp_draw_calltip(position) unless str.empty?
    end
  end
end
