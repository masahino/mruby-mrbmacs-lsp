require "#{File.dirname(__FILE__)}/test_helper.rb"

assert('lsp_goto_command') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.ext.data['lsp']['irb'] = LSP::Client.new('ruby', { 'args' => ["#{File.dirname(__FILE__)}/../misc/dummy_lsp.rb"] })
  app.ext.data['lsp']['irb'].server_capabilities['hogehogeProvider'] = false
  assert_equal nil, app.lsp_goto_command('hogehoge', 'hogehogeProvider')
  assert_equal '[LSP] server is not running', app.logger.log[:info].last
  app.ext.data['lsp']['irb'].status = :running
  assert_equal nil, app.lsp_goto_command('hogehoge', 'hogehogeProvider')
  assert_equal "[LSP] 'hogehoge' is not supported", app.logger.log[:info].last

  app.ext.data['lsp']['irb'].server_capabilities['definitionProvider'] = true
  app.lsp_goto_command('definition', 'definitionProvider')
  assert_equal '[LSP] sending "definition" message...', app.logger.log[:info].last
end

assert('lsp_formatting') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.lsp_formatting
end

assert('lsp_range_formatting') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.lsp_range_formatting
end

assert('lsp_rename') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.lsp_rename
end

assert('lsp_hover') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.lsp_hover
end

assert('lsp_completion') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.lsp_completion
end
