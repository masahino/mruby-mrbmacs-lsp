module Mrbmacs
  # Document Symbol
  class Application
    def lsp_process_document_symbol_response(lsp_server, id, resp)
      result = resp['result']
      @lsp_document_symbol_items = []
      return if result.empty?
      return unless result[0].is_a?(Hash) && result[0].key?('location')

      method = lsp_server.request_buffer[id][:message]['method']
      label_counts = {}
      @lsp_document_symbol_items = result.map do |item|
        location = item['location']
        line = location['range']['start']['line'] + 1
        kind = LSP::SymbolKind.key(item['kind']) || :Unknown
        label = "#{item['name']} [#{kind}]"
        label = "#{label} (#{item['containerName']})" if item['containerName']
        label = "#{label} :#{line}"
        label_counts[label] = (label_counts[label] || 0) + 1
        label = "#{label} (#{label_counts[label]})" if label_counts[label] > 1
        { label: label, location: location }
      end
      list = @lsp_document_symbol_items.map { |item| item[:label] }
      message "[lsp] receive \"#{method}\" response(#{list.size})"
      @logger.debug list
      @frame.view_win.sci_userlist_show(
        LspExtension::LSP_DOCUMENT_SYMBOL_LIST_TYPE,
        list.join(@frame.view_win.sci_autoc_get_separator.chr)
      )
    end

    def lsp_document_symbol_select(scn)
      item = @lsp_document_symbol_items.find do |symbol|
        symbol[:label] == scn['text']
      end
      return if item.nil?

      location = item[:location]
      start = location['range']['start']
      lsp_navigate_to(lsp_uri_to_path(location['uri']), start['line'], start['character'])
    end
  end
end
