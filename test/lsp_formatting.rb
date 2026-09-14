def setup_formatting_response_app
  app = setup_app
  app.current_buffer.filename = '/workspace/one.rb'
  edits = []
  app.define_singleton_method(:lsp_process_text_edits) do |text_edits|
    edits << text_edits
  end
  request_buffer = {
    1 => {
      message: {
        'method' => 'textDocument/formatting',
        'params' => {
          'textDocument' => LSP::Parameter::TextDocumentIdentifier.new('/workspace/one.rb')
        }
      }
    }
  }
  server = Object.new
  server.define_singleton_method(:request_buffer) { request_buffer }
  [app, server, edits]
end

assert('lsp_formatting_response applies edits when the document URI matches') do
  app, server, edits = setup_formatting_response_app
  text_edits = [{ 'newText' => 'formatted' }]

  app.lsp_formatting_response(server, 1, 'result' => text_edits)

  assert_equal [text_edits], edits
  assert_equal [], app.logger.log[:error]
end

assert('lsp_formatting_response skips edits after switching to another document') do
  app, server, edits = setup_formatting_response_app
  app.current_buffer.filename = '/workspace/two.rb'
  current_buffer = app.current_buffer
  switches = []
  app.define_singleton_method(:switch_to_buffer) do |name|
    switches << name
  end

  result = app.lsp_formatting_response(server, 1, 'result' => [{ 'newText' => 'formatted' }])

  assert_false result
  assert_equal [], edits
  assert_equal [], switches
  assert_equal current_buffer, app.current_buffer
  assert_equal '/workspace/two.rb', app.current_buffer.filename
  assert_equal [
    'LSP formatting skipped: current buffer differs from requested document file:///workspace/one.rb'
  ], app.logger.log[:error]
end

assert('lsp_formatting_response does not edit for nil or empty results') do
  app, server, edits = setup_formatting_response_app

  app.lsp_formatting_response(server, 1, 'result' => nil)
  app.lsp_formatting_response(server, 1, 'result' => [])
  app.lsp_formatting_response(server, 1, nil)

  assert_equal [], edits
  assert_equal [], app.logger.log[:error]
end
