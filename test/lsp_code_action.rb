def setup_code_action_request_app(supported)
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  server.status = :running
  server.server_capabilities['codeActionProvider'] = supported
  requests = []
  server.define_singleton_method(:codeAction) { |params| requests << params }
  app.ext.data['lsp'][app.current_buffer.mode.name] = server
  app.current_buffer.filename = '/tmp/code_action.rb'
  [app, requests]
end

def stub_code_action_positions(app, current_pos, mark_pos = nil)
  app.frame.view_win.text = "zero\none\ntwo\n"
  app.frame.view_win.define_singleton_method(:sci_get_current_pos) { current_pos }
  app.instance_variable_set(:@mark_pos, mark_pos)
end

assert('lsp_code_action sends an empty range without a selection') do
  app, requests = setup_code_action_request_app(true)
  stub_code_action_positions(app, 6)

  app.lsp_code_action

  assert_equal 1, requests.size
  assert_equal 'file:///tmp/code_action.rb', requests[0]['textDocument'].uri
  assert_equal({ 'line' => 1, 'character' => 1 }, requests[0]['range']['start'])
  assert_equal({ 'line' => 1, 'character' => 1 }, requests[0]['range']['end'])
  assert_equal [], requests[0]['context']['diagnostics']
  assert_equal false, requests[0]['context'].key?('only')
  assert_equal '[LSP] sending "codeAction" message...', app.logger.log[:info].last
end

assert('lsp_code_action sends the selected range') do
  app, requests = setup_code_action_request_app({})
  stub_code_action_positions(app, 9, 2)

  app.lsp_code_action

  assert_equal 1, requests.size
  assert_equal({ 'line' => 0, 'character' => 2 }, requests[0]['range']['start'])
  assert_equal({ 'line' => 2, 'character' => 0 }, requests[0]['range']['end'])
end

assert('lsp_code_action normalizes a backward selection') do
  app, requests = setup_code_action_request_app(true)
  stub_code_action_positions(app, 2, 9)

  app.lsp_code_action

  assert_equal 1, requests.size
  assert_equal({ 'line' => 0, 'character' => 2 }, requests[0]['range']['start'])
  assert_equal({ 'line' => 2, 'character' => 0 }, requests[0]['range']['end'])
end

assert('lsp_code_action does not send a request to an unsupported server') do
  app, requests = setup_code_action_request_app(false)
  stub_code_action_positions(app, 6)

  app.lsp_code_action

  assert_equal 0, requests.size
  assert_equal "[LSP] 'codeAction' is not supported", app.logger.log[:info].last
end
