def setup_code_action_response(result)
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  request_id = 1
  server.request_buffer[request_id] = {
    message: { 'method' => 'textDocument/codeAction' }
  }
  userlists = []
  view = app.frame.view_win
  view.define_singleton_method(:sci_autoc_get_separator) { "\t".ord }
  view.define_singleton_method(:sci_userlist_show) do |list_type, list|
    userlists << [list_type, list]
  end
  app.lsp_process_code_action_response(server, request_id, { 'result' => result })
  [app, server, request_id, app.instance_variable_get(:@lsp_code_action_items), userlists]
end

assert('code action response handles nil as no candidates') do
  app, _server, _request_id, items, userlists = setup_code_action_response(nil)

  assert_equal [], items
  assert_equal [], userlists
  assert_equal '[lsp] receive "textDocument/codeAction" response(0)', app.logger.log[:info].last
end

assert('code action response handles an empty array as no candidates') do
  _app, _server, _request_id, items, userlists = setup_code_action_response([])

  assert_equal [], items
  assert_equal [], userlists
end

assert('code action response keeps a CodeAction') do
  code_action = {
    'title' => 'Add include',
    'kind' => 'quickfix',
    'edit' => { 'changes' => {} },
    'data' => { 'id' => 1 }
  }
  app, _server, _request_id, items, userlists = setup_code_action_response([code_action])

  assert_equal [{ type: :code_action, item: code_action, label: 'Add include [edit]' }], items
  assert_equal [[Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE, 'Add include [edit]']], userlists
  assert_equal({
                 title: 'Add include',
                 type: 'CodeAction',
                 kind: 'quickfix',
                 edit: true,
                 command: false,
                 data: true
               }, app.logger.log[:debug].last)
end

assert('code action response keeps a Command') do
  command = {
    'title' => 'Run fix',
    'command' => 'example.runFix',
    'arguments' => [1]
  }
  app, _server, _request_id, items, userlists = setup_code_action_response([command])

  assert_equal [{ type: :command, item: command, label: 'Run fix [command]' }], items
  assert_equal [[Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE, 'Run fix [command]']], userlists
  assert_equal({
                 title: 'Run fix',
                 type: 'Command',
                 kind: nil,
                 edit: false,
                 command: true,
                 data: false
               }, app.logger.log[:debug].last)
end

assert('code action response keeps mixed CodeAction and Command items') do
  code_action = {
    'title' => 'Refactor',
    'command' => { 'title' => 'Refactor', 'command' => 'example.refactor' }
  }
  command = { 'title' => 'Organize imports', 'command' => 'example.organizeImports' }

  _app, _server, _request_id, items, userlists = setup_code_action_response([code_action, command])

  assert_equal [:code_action, :command], items.map { |item| item[:type] }
  assert_equal [code_action, command], items.map { |item| item[:item] }
  assert_equal [[
    Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE,
    "#{'Refactor'.ljust('Organize imports'.length)} [command]\t" \
      'Organize imports [command]'
  ]], userlists
end

assert('code action response keeps a title-only CodeAction') do
  code_action = { 'title' => 'Deferred action' }

  _app, _server, _request_id, items = setup_code_action_response([code_action])

  assert_equal [{ type: :code_action, item: code_action, label: 'Deferred action' }], items
end

assert('code action response labels CodeAction capabilities') do
  edit = { 'title' => 'Edit action', 'edit' => { 'changes' => {} } }
  command = {
    'title' => 'Command action',
    'command' => { 'title' => 'Command action', 'command' => 'example.command' }
  }
  edit_and_command = {
    'title' => 'Combined action',
    'edit' => { 'changes' => {} },
    'command' => { 'title' => 'Combined action', 'command' => 'example.combined' }
  }
  disabled = {
    'title' => 'Disabled action',
    'disabled' => { 'reason' => 'Not available' },
    'edit' => { 'changes' => {} }
  }
  data = { 'title' => 'Data action', 'data' => { 'id' => 1 } }

  _app, _server, _request_id, items, userlists = setup_code_action_response(
    [edit, command, edit_and_command, disabled, data]
  )

  assert_equal [
    "#{'Edit action'.ljust('Disabled action'.length)} [edit]",
    "#{'Command action'.ljust('Disabled action'.length)} [command]",
    'Combined action [edit][command]',
    'Disabled action [disabled]',
    "#{'Data action'.ljust('Disabled action'.length)} [data]"
  ], items.map { |item| item[:label] }
  assert_equal [[
    Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE,
    "#{'Edit action'.ljust('Disabled action'.length)} [edit]\t" \
      "#{'Command action'.ljust('Disabled action'.length)} [command]\t" \
      "Combined action [edit][command]\tDisabled action [disabled]\t" \
      "#{'Data action'.ljust('Disabled action'.length)} [data]"
  ]], userlists
end

assert('code action response ignores and logs unknown items') do
  unknown_items = [nil, { 'command' => 'missing.title' }, { 'title' => 'Invalid', 'command' => 1 }]

  app, _server, _request_id, items = setup_code_action_response(unknown_items)

  assert_equal [], items
  unknown_logs = app.logger.log[:debug].select do |log|
    log.is_a?(String) && log.start_with?('[lsp] unknown code action item:')
  end
  assert_equal 3, unknown_logs.size
end

assert('code action response preserves spaces in titles') do
  first = { 'title' => 'Extract subexpression to variable', 'command' => 'clangd.applyTweak' }
  second = { 'title' => 'Swap operands to +', 'command' => 'clangd.applyTweak' }

  _app, _server, _request_id, _items, userlists = setup_code_action_response([first, second])

  assert_equal [[
    Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE,
    "Extract subexpression to variable [command]\t" \
      "#{'Swap operands to +'.ljust('Extract subexpression to variable'.length)} [command]"
  ]], userlists
end

assert('code action selection applies edit before executing command') do
  code_action = {
    'title' => 'Refactor expression',
    'kind' => 'refactor.extract',
    'edit' => { 'changes' => {} },
    'command' => { 'title' => 'Refactor expression', 'command' => 'example.refactor' }
  }
  app, server, _request_id, items, _userlists = setup_code_action_response([code_action])
  calls = []
  app.define_singleton_method(:lsp_workspace_edit) { |edit| calls << [:edit, edit] }
  app.define_singleton_method(:lsp_execute_command) do |target_server, command|
    calls << [:command, target_server, command]
  end

  selected = app.lsp_code_action_select('text' => 'Refactor expression [edit][command]')

  assert_same items[0], selected
  assert_same code_action, selected[:item]
  assert_same selected, app.instance_variable_get(:@lsp_selected_code_action_item)
  assert_equal [
    [:edit, code_action['edit']],
    [:command, server, code_action['command']]
  ], calls
  assert_equal({
                 title: 'Refactor expression',
                 type: 'CodeAction',
                 command: 'example.refactor',
                 kind: 'refactor.extract'
               }, app.logger.log[:debug].last)
end

assert('code action selection uses displayed capabilities to identify the selected item') do
  first = {
    'title' => 'Fix issue',
    'kind' => 'quickfix',
    'edit' => { 'changes' => {} }
  }
  second = { 'title' => 'Fix issue', 'command' => 'example.fix' }
  app, server, _request_id, items, userlists = setup_code_action_response([first, second])
  commands = []
  app.define_singleton_method(:lsp_execute_command) do |target_server, command|
    commands << [target_server, command]
  end

  selected = app.lsp_code_action_select('text' => 'Fix issue [command]')

  assert_equal [[
    Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE,
    "Fix issue [edit]\tFix issue [command]"
  ]], userlists
  assert_same items[1], selected
  assert_same second, selected[:item]
  assert_same selected, app.instance_variable_get(:@lsp_selected_code_action_item)
  assert_equal [[server, second]], commands
  assert_equal({
                 title: 'Fix issue',
                 type: 'Command',
                 command: 'example.fix',
                 kind: nil
               }, app.logger.log[:debug].last)
end


assert('code action selection identifies duplicate display labels') do
  first = { 'title' => 'Fix issue', 'command' => 'example.firstFix' }
  second = { 'title' => 'Fix issue', 'command' => 'example.secondFix' }
  app, server, _request_id, items, userlists = setup_code_action_response([first, second])
  commands = []
  app.define_singleton_method(:lsp_execute_command) do |target_server, command|
    commands << [target_server, command]
  end

  selected = app.lsp_code_action_select('text' => 'Fix issue (2) [command]')

  assert_equal [[
    Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE,
    "#{'Fix issue'.ljust('Fix issue (2)'.length)} [command]\tFix issue (2) [command]"
  ]], userlists
  assert_same items[1], selected
  assert_same second, selected[:item]
  assert_equal [[server, second]], commands
end

assert('code action selection dispatches an edit-only CodeAction') do
  code_action = {
    'title' => 'Apply fix',
    'edit' => { 'changes' => { 'file:///workspace/main.rb' => [] } }
  }
  app, _server, _request_id, _items, _userlists = setup_code_action_response([code_action])
  edits = []
  commands = []
  app.define_singleton_method(:lsp_workspace_edit) { |edit| edits << edit }
  app.define_singleton_method(:lsp_execute_command) do |_server, command|
    commands << command
  end

  app.lsp_code_action_select('text' => 'Apply fix [edit]')

  assert_equal [code_action['edit']], edits
  assert_equal [], commands
end

assert('code action edit changes text through WorkspaceEdit changes') do
  code_action = {
    'title' => 'Replace value',
    'edit' => {
      'changes' => {
        'file:///workspace/main.cpp' => [{
          'range' => {
            'start' => { 'line' => 0, 'character' => 12 },
            'end' => { 'line' => 0, 'character' => 13 }
          },
          'newText' => '2'
        }]
      }
    }
  }
  app, _server, _request_id, _items, _userlists = setup_code_action_response([code_action])
  view = app.frame.view_win
  view.text = "int value = 1;\n"
  selection = [0, 0]
  opened_files = []
  restored_buffers = []
  view.define_singleton_method(:sci_findcolumn) do |line, character|
    lines = text.split("\n", -1)
    lines[0...line].inject(0) { |length, value| length + value.length + 1 } + character
  end
  view.define_singleton_method(:sci_set_sel) do |start_pos, end_pos|
    selection[0] = start_pos
    selection[1] = end_pos
  end
  view.define_singleton_method(:sci_replace_sel) do |_unused, new_text|
    self.text = text[0...selection[0]] + new_text + text[selection[1]..-1]
    selection[1] = selection[0] + new_text.length
  end
  view.define_singleton_method(:sci_begin_undo_action) {}
  view.define_singleton_method(:sci_end_undo_action) {}
  view.define_singleton_method(:sci_get_mod_event_mask) { 0 }
  view.define_singleton_method(:sci_set_mod_event_mask) { |_mask| }
  view.define_singleton_method(:sci_get_current_pos) { selection[1] }
  view.define_singleton_method(:sci_goto_pos) { |_position| }
  app.define_singleton_method(:find_file) { |path| opened_files << path }
  app.define_singleton_method(:switch_to_buffer) { |name| restored_buffers << name }
  app.define_singleton_method(:lsp_did_change_for_content_change) { |_change| }

  app.lsp_code_action_select('text' => 'Replace value [edit]')

  assert_equal "int value = 2;\n", view.text
  assert_equal ['/workspace/main.cpp'], opened_files
  assert_equal [app.current_buffer.name], restored_buffers
end

assert('code action selection dispatches a command-only CodeAction') do
  command = { 'title' => 'Run fix', 'command' => 'example.fix', 'arguments' => [1] }
  code_action = { 'title' => 'Run fix', 'command' => command }
  app, server, _request_id, _items, _userlists = setup_code_action_response([code_action])
  commands = []
  app.define_singleton_method(:lsp_execute_command) do |target_server, target_command|
    commands << [target_server, target_command]
  end

  app.lsp_code_action_select('text' => 'Run fix [command]')

  assert_equal [[server, command]], commands
end

assert('code action selection resolves an unresolved CodeAction when supported') do
  code_action = { 'title' => 'Resolve fix', 'data' => { 'id' => 1 } }
  app, server, _request_id, _items, _userlists = setup_code_action_response([code_action])
  server.server_capabilities['codeActionProvider'] = { 'resolveProvider' => true }
  resolutions = []
  app.define_singleton_method(:lsp_resolve_code_action) do |target_server, action|
    resolutions << [target_server, action]
  end

  app.lsp_code_action_select('text' => 'Resolve fix [data]')

  assert_equal [[server, code_action]], resolutions
end

assert('code action selection does not resolve when the server does not support it') do
  code_action = { 'title' => 'Unresolved fix', 'data' => { 'id' => 1 } }
  app, _server, _request_id, _items, _userlists = setup_code_action_response([code_action])
  resolutions = []
  app.define_singleton_method(:lsp_resolve_code_action) do |server, action|
    resolutions << [server, action]
  end

  app.lsp_code_action_select('text' => 'Unresolved fix [data]')

  assert_equal [], resolutions
  assert_equal '[lsp] code action has no edit or command: Unresolved fix', app.logger.log[:debug].last
end

assert('code action selection does not dispatch a disabled CodeAction') do
  code_action = {
    'title' => 'Disabled fix',
    'disabled' => { 'reason' => 'Not available' },
    'edit' => { 'changes' => {} },
    'command' => { 'title' => 'Disabled fix', 'command' => 'example.fix' }
  }
  app, _server, _request_id, _items, _userlists = setup_code_action_response([code_action])
  calls = []
  app.define_singleton_method(:lsp_workspace_edit) { |edit| calls << edit }
  app.define_singleton_method(:lsp_execute_command) { |server, command| calls << [server, command] }
  app.define_singleton_method(:lsp_resolve_code_action) { |server, action| calls << [server, action] }

  app.lsp_code_action_select('text' => 'Disabled fix [disabled]')

  assert_equal [], calls
end

assert('lsp_execute_command sends workspace executeCommand parameters') do
  app = setup_app
  server = LSP::Client.new('', {})
  requests = []
  server.define_singleton_method(:send_request) do |method, params|
    requests << [method, params]
  end
  command = { 'title' => 'Run fix', 'command' => 'example.fix', 'arguments' => [1, 'two'] }

  app.lsp_execute_command(server, command)

  assert_equal [[
    'workspace/executeCommand',
    { 'command' => 'example.fix', 'arguments' => [1, 'two'] }
  ]], requests
end

assert('lsp_execute_command omits absent arguments') do
  app = setup_app
  server = LSP::Client.new('', {})
  requests = []
  server.define_singleton_method(:send_request) do |method, params|
    requests << [method, params]
  end

  app.lsp_execute_command(server, 'title' => 'Run fix', 'command' => 'example.fix')

  assert_equal [[
    'workspace/executeCommand',
    { 'command' => 'example.fix' }
  ]], requests
end

assert('lsp_resolve_code_action sends codeAction resolve') do
  app = setup_app
  server = LSP::Client.new('', {})
  requests = []
  server.define_singleton_method(:send_request) do |method, params|
    requests << [method, params]
  end
  code_action = { 'title' => 'Resolve fix', 'data' => { 'id' => 1 } }

  app.lsp_resolve_code_action(server, code_action)

  assert_equal [['codeAction/resolve', code_action]], requests
end

assert('code action response is dispatched by the request method') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  request_id = 1
  command = { 'title' => 'Run fix', 'command' => 'example.runFix' }
  server.request_buffer[request_id] = {
    message: { 'method' => 'textDocument/codeAction' }
  }

  app.lsp_response(server, request_id, { 'result' => [command] })

  items = app.instance_variable_get(:@lsp_code_action_items)
  assert_equal [{ type: :command, item: command, label: 'Run fix [command]' }], items
  assert_nil server.request_buffer[request_id]
end
