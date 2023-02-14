require File.dirname(__FILE__) + '/test_helper.rb'

assert('lsp_position') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}position-test.txt")
  pos_hash = { 'line' => 0, 'character' => 0 }
  assert_equal pos_hash, app.lsp_position(0)
end

assert('lsp_server_text_document_sync_kind') do
  app = setup_app
  server = LSP::Client.new('', {})
  assert_equal 0, app.lsp_server_text_document_sync_kind(server)
  server.server_capabilities['textDocumentSync'] = 1
  assert_equal 1, app.lsp_server_text_document_sync_kind(server)
  server.server_capabilities['textDocumentSync'] = { 'change' => 2 }
  assert_equal 2, app.lsp_server_text_document_sync_kind(server)
end
