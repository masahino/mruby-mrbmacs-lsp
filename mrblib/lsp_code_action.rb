module Mrbmacs
  # Code Action
  class Application
    def lsp_process_code_action_response(lsp_server, id, resp)
      @logger.debug resp
      @lsp_code_action_items = []
      @lsp_selected_code_action_item = nil
      @lsp_code_action_server = lsp_server
      result = resp['result']
      unless result.nil? || result.is_a?(Array)
        @logger.debug "[lsp] unknown code action result: #{result}"
        result = []
      end

      used_labels = {}
      candidates = []
      (result || []).each do |item|
        type = lsp_code_action_item_type(item)
        if type.nil?
          @logger.debug "[lsp] unknown code action item: #{item}"
          next
        end

        suffix = lsp_code_action_display_suffix(item, type)
        title = lsp_unique_code_action_title(item['title'], suffix, used_labels)
        candidates << { type: type, item: item, title: title, suffix: suffix }
        @logger.debug({
                        title: item['title'],
                        type: type == :code_action ? 'CodeAction' : 'Command',
                        kind: type == :code_action ? item['kind'] : nil,
                        edit: item.key?('edit'),
                        command: item.key?('command'),
                        data: item.key?('data')
                      })
      end

      max_title_length = candidates.map { |candidate| candidate[:title].length }.max || 0
      @lsp_code_action_items = candidates.map do |candidate|
        label = if candidate[:suffix].empty?
                  candidate[:title]
                else
                  "#{candidate[:title].ljust(max_title_length)} #{candidate[:suffix]}"
                end
        { type: candidate[:type], item: candidate[:item], label: label }
      end

      method = lsp_server.request_buffer[id][:message]['method']
      message "[lsp] receive \"#{method}\" response(#{@lsp_code_action_items.size})"
      return if @lsp_code_action_items.empty?

      labels = @lsp_code_action_items.map { |item| item[:label] }
      separator = @frame.view_win.sci_autoc_get_separator.chr
      @frame.view_win.sci_userlist_show(
        LspExtension::LSP_CODE_ACTION_LIST_TYPE,
        labels.join(separator)
      )
    end

    def lsp_code_action_item_type(item)
      return nil unless item.is_a?(Hash) && item['title'].is_a?(String)

      command = item['command']
      return :command if command.is_a?(String)
      return :code_action if command.nil? || command.is_a?(Hash)

      nil
    end

    def lsp_unique_code_action_title(title, suffix, used_labels)
      display_title = title
      label = "#{display_title} #{suffix}"
      count = 2
      while used_labels.key?(label)
        display_title = "#{title} (#{count})"
        count += 1
        label = "#{display_title} #{suffix}"
      end
      used_labels[label] = true
      display_title
    end

    def lsp_code_action_display_suffix(item, type)
      suffixes = if type == :command
                   ['command']
                 elsif item.key?('disabled')
                   ['disabled']
                 else
                   values = []
                   values << 'edit' if item.key?('edit')
                   values << 'command' if item.key?('command')
                   values << 'data' if values.empty? && item.key?('data')
                   values
                 end

      suffixes.map { |value| "[#{value}]" }.join
    end

    def lsp_code_action_select(scn)
      selected = @lsp_code_action_items.find do |item|
        item[:label] == scn['text']
      end
      return if selected.nil?

      @lsp_selected_code_action_item = selected
      item = selected[:item]
      command = item['command']
      command_name = command.is_a?(Hash) ? command['command'] : command
      @logger.debug({
                      title: item['title'],
                      type: selected[:type] == :code_action ? 'CodeAction' : 'Command',
                      command: command_name,
                      kind: selected[:type] == :code_action ? item['kind'] : nil
                    })
      if selected[:type] == :command
        lsp_execute_command(@lsp_code_action_server, item)
      else
        lsp_dispatch_code_action(@lsp_code_action_server, item)
      end
      selected
    end

    def lsp_dispatch_code_action(lsp_server, code_action)
      if code_action['disabled']
        @logger.debug "[lsp] disabled code action: #{code_action['disabled']}"
        return
      end

      edit = code_action['edit']
      command = code_action['command']
      lsp_workspace_edit(edit) if edit
      lsp_execute_command(lsp_server, command) if command

      return if edit || command

      if lsp_code_action_resolve_supported?(lsp_server)
        lsp_resolve_code_action(lsp_server, code_action)
      else
        @logger.debug "[lsp] code action has no edit or command: #{code_action['title']}"
      end
    end

    def lsp_code_action_resolve_supported?(lsp_server)
      provider = lsp_server.server_capabilities['codeActionProvider']
      provider.is_a?(Hash) && provider['resolveProvider'] == true
    end

    def lsp_execute_command(lsp_server, command)
      params = { 'command' => command['command'] }
      params['arguments'] = command['arguments'] if command.key?('arguments')
      lsp_server.send_request('workspace/executeCommand', params)
    end

    def lsp_resolve_code_action(lsp_server, code_action)
      lsp_server.send_request('codeAction/resolve', code_action)
    end
  end
end
