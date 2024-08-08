module Mrbmacs
  class Application
    def lsp_uri_to_path(uri)
      uri.gsub('file://', '')
    end

    def lsp_supports_capability?(capability)
      lang = @current_buffer.mode.name
      if @ext.data['lsp'][lang].server_capabilities[capability].nil? ||
         @ext.data['lsp'][lang].server_capabilities[capability] == false
        false
      else
        true
      end
    end

    def lsp_position(pos = nil)
      pos = @frame.view_win.sci_get_current_pos if pos.nil?
      line = @frame.view_win.sci_line_from_position(pos)
      start_of_line_pos = @frame.view_win.sci_position_from_line(line)
      count_codeunits = @frame.view_win.sci_count_codeunits(start_of_line_pos, pos)
      { 'line' => line, 'character' => count_codeunits }
    end

    def lsp_document_position_param
      td = LSP::Parameter::TextDocumentIdentifier.new(@current_buffer.filename)
      { 'textDocument' => td, 'position' => lsp_position }
    end
  end
end
