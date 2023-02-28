module Mrbmacs
  # Annotation
  class LspExtension < Extension
    LSP_DIAGNOSTIC_SEVERITY = {
      1 => 'Error',
      2 => 'Warning',
      3 => 'Information',
      4 => 'Hint'
    }.freeze

    def self.get_diagnostic_severity_to_s(severity)
      LSP_DIAGNOSTIC_SEVERITY[severity] || 'Unknown'
    end
  end

  # Annotation
  class Application
    def lsp_get_style_from_severity(severity)
      case severity
      when 1
        @theme.annotation_style(:error)
      when 2
        @theme.annotation_style(:warn)
      when 3
        @theme.annotation_style(:info)
      when 4
        @theme.annotation_style(:info)
      else
        @theme.annotation_style(:other)
      end
    end

    def lsp_show_annotation(diagnostics)
      return if @frame.view_win.sci_autoc_active || @frame.view_win.sci_calltip_active

      @frame.view_win.sci_annotation_clearall
      diagnostics.each do |d|
        line = d['range']['start']['line']
        col = d['range']['start']['character'] + 1
        severity_str = Mrbmacs::LspExtension.get_diagnostic_severity_to_s(d['severity'])
        message = "#{severity_str}:#{d['message'].gsub(/\n\n/, "\n")}"
        # margin(6+2) + scrollbar
        max_len = @frame.edit_win.width - 11 - @frame.view_win.sci_get_line_indentation(line)
        message.insert(max_len, "\n#{' ' * (severity_str.length + 1)}") if message.length > max_len
        style = lsp_get_style_from_severity(d['severity'])
        if @frame.view_win.sci_annotation_get_lines(line) > 0
          message = "#{@frame.view_win.sci_annotation_get_text(line)}\n#{message}"
          style = @frame.view_win.sci_annotation_get_style(line)
        end
        @frame.show_annotation(line + 1, col, message, style)
      end
      @frame.view_win.sci_scrollcaret
    end
  end
end
