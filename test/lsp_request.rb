def setup_lsp_request_server
  server = LSP::Client.new('', {})
  messages = []
  server.define_singleton_method(:send_message) do |message|
    messages << message
    true
  end
  [server, messages]
end

assert('lsp_read_message recognizes a server request by its method') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  io = Object.new
  server.io = io
  request = {
    'jsonrpc' => '2.0',
    'id' => 23,
    'method' => 'workspace/applyEdit',
    'params' => { 'edit' => { 'changes' => {} } }
  }
  server.define_singleton_method(:recv_message) { [{ 'Content-Length' => 1 }, request] }
  app.ext.data['lsp']['test'] = server
  received = []
  app.define_singleton_method(:lsp_request) do |request_server, message|
    received << [request_server, message]
  end

  app.lsp_read_message(io)

  assert_equal [[server, request]], received
end

assert('lsp_read_message keeps client request responses on the response path') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  io = Object.new
  server.io = io
  server.request_buffer[24] = {
    message: { 'method' => 'workspace/executeCommand' },
    block: nil
  }
  response = { 'jsonrpc' => '2.0', 'id' => 24, 'result' => nil }
  server.define_singleton_method(:recv_message) { [{ 'Content-Length' => 1 }, response] }
  app.ext.data['lsp']['test'] = server
  received = []
  app.define_singleton_method(:lsp_response) do |response_server, id, message|
    received << [response_server, id, message]
  end

  app.lsp_read_message(io)

  assert_equal [[server, 24, response]], received
end

assert('lsp_read_message logs an unexpected response id') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  io = Object.new
  server.io = io
  response = { 'jsonrpc' => '2.0', 'id' => 25, 'result' => nil }
  server.define_singleton_method(:recv_message) { [{ 'Content-Length' => 1 }, response] }
  app.ext.data['lsp']['test'] = server

  app.lsp_read_message(io)

  assert_equal '[LSP] unexpected response id=25', app.logger.log[:info].last
  assert_equal response.to_s, app.logger.log[:debug].last
end

assert('dispatches workspace/applyEdit and returns an applied response') do
  app = setup_app
  server, messages = setup_lsp_request_server
  edit = { 'changes' => { 'file:///workspace/main.rb' => [] } }
  applied_edits = []
  app.define_singleton_method(:lsp_workspace_edit) do |workspace_edit|
    applied_edits << workspace_edit
    true
  end
  request = {
    'jsonrpc' => '2.0',
    'id' => 37,
    'method' => 'workspace/applyEdit',
    'params' => { 'edit' => edit }
  }

  app.lsp_request(server, request)

  assert_equal [edit], applied_edits
  assert_equal [{
    'jsonrpc' => '2.0',
    'id' => 37,
    'result' => { 'applied' => true }
  }], messages
end

assert('returns applied false when workspace/applyEdit is unsupported') do
  app = setup_app
  server, messages = setup_lsp_request_server
  app.define_singleton_method(:lsp_workspace_edit) { |_workspace_edit| false }
  request = {
    'jsonrpc' => '2.0',
    'id' => 'server-request-1',
    'method' => 'workspace/applyEdit',
    'params' => { 'edit' => { 'documentChanges' => [] } }
  }

  app.lsp_request(server, request)

  assert_equal [{
    'jsonrpc' => '2.0',
    'id' => 'server-request-1',
    'result' => { 'applied' => false }
  }], messages
end

assert('returns failureReason when workspace/applyEdit raises an error') do
  app = setup_app
  server, messages = setup_lsp_request_server
  app.define_singleton_method(:lsp_workspace_edit) do |_workspace_edit|
    raise 'edit failed'
  end
  request = {
    'jsonrpc' => '2.0',
    'id' => 41,
    'method' => 'workspace/applyEdit',
    'params' => { 'edit' => { 'changes' => {} } }
  }

  app.lsp_request(server, request)

  assert_equal [{
    'jsonrpc' => '2.0',
    'id' => 41,
    'result' => { 'applied' => false, 'failureReason' => 'edit failed' }
  }], messages
end

assert('keeps the existing behavior for an unsupported server request') do
  app = setup_app
  server, messages = setup_lsp_request_server
  request = {
    'jsonrpc' => '2.0',
    'id' => 52,
    'method' => 'workspace/unknown',
    'params' => {}
  }

  app.lsp_request(server, request)

  assert_equal [], messages
  assert_equal '[LSP] unsupported server request: workspace/unknown', app.logger.log[:info].last
  assert_equal request.to_s, app.logger.log[:debug].last
end
