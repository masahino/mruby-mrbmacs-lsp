require "#{File.dirname(__FILE__)}/test_helper.rb"

assert('lsp_position') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}position-test.txt")
  pos_hash = { 'line' => 0, 'character' => 0 }
  assert_equal pos_hash, app.lsp_position(0)
end

assert('uri_to_path') do
  app = setup_app
  assert_equal '', app.lsp_uri_to_path('')
  assert_equal '/foo/bar/baz.txt', app.lsp_uri_to_path('file:///foo/bar/baz.txt')
end

assert('lsp_supports_capability') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.ext.data['lsp']['irb'] = LSP::Client.new('', {})
  assert_equal false, app.lsp_supports_capability?('monikerProvider')
  app.ext.data['lsp']['irb'].server_capabilities['monikerProvider'] = {}
end
