assert('lsp_goto_command') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.ext.data['lsp']['irb'] = LSP::Client.new('ruby', { 'args' => ["#{File.dirname(__FILE__)}/../misc/dummy_lsp.rb"] })
  app.ext.data['lsp']['irb'].start_server({})
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
  assert_nil app.lsp_formatting
end

assert('lsp_range_formatting') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_nil app.lsp_range_formatting
end

assert('lsp_rename') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_nil app.lsp_rename
end

assert('lsp_copy_diagnostic reports when the current line has no diagnostic') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  win = app.frame.view_win
  copied = []
  remembered = []
  win.text = "first\nsecond\n"
  win.define_singleton_method(:sci_get_current_pos) { 7 }
  win.define_singleton_method(:sci_annotation_get_text) { |_line| '' }
  win.define_singleton_method(:sci_copytext) { |length, text| copied << [length, text] }
  app.define_singleton_method(:remember_clipboard) { |clipboard_win| remembered << clipboard_win }

  app.lsp_copy_diagnostic

  assert_equal [], copied
  assert_equal [], remembered
  assert_equal 'No diagnostic on current line', app.logger.log[:info].last
  assert_equal 'No diagnostic on current line', app.frame.echo_message
end

assert('lsp_copy_diagnostic copies the current line diagnostic') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  win = app.frame.view_win
  copied = []
  remembered = []
  annotation_lines = []
  diagnostic = "Error: unexpected token あ"
  win.text = "first\nsecond\n"
  win.define_singleton_method(:sci_get_current_pos) { 7 }
  win.define_singleton_method(:sci_annotation_get_text) do |line|
    annotation_lines << line
    line == 1 ? diagnostic : ''
  end
  win.define_singleton_method(:sci_copytext) { |length, text| copied << [length, text] }
  app.define_singleton_method(:remember_clipboard) { |clipboard_win| remembered << clipboard_win }

  app.lsp_copy_diagnostic

  assert_equal [1], annotation_lines
  assert_equal [[diagnostic.bytesize, diagnostic]], copied
  assert_equal diagnostic, app.clipboard_text
  assert_equal [win], remembered
  assert_equal 'Diagnostic copied', app.logger.log[:info].last
  assert_equal 'Diagnostic copied', app.frame.echo_message
end

assert('lsp_hover') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_nil app.lsp_hover
end

assert('lsp_hover tracks a command request at the caret position') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  request = nil
  cancelled_method = nil
  client = Object.new
  client.define_singleton_method(:status) { :running }
  client.define_singleton_method(:server_capabilities) { { 'hoverProvider' => true } }
  client.define_singleton_method(:cancel_request_with_method) do |method|
    cancelled_method = method
  end
  client.define_singleton_method(:hover) do |param|
    request = param
    51
  end
  app.ext.data['lsp']['irb'] = client
  app.frame.view_win.text = "first\nsecond"
  app.frame.view_win.test_return[Scintilla::SCI_GETCURRENTPOS] = 8

  app.lsp_hover

  assert_equal({ 'line' => 1, 'character' => 2 }, request['position'])
  assert_equal 'textDocument/hover', cancelled_method
  assert_equal 51, app.instance_variable_get(:@lsp_hover_request_id)
  assert_equal 8, app.instance_variable_get(:@lsp_hover_position)
  assert_equal :command, app.instance_variable_get(:@lsp_hover_trigger)
end

assert('lsp_completion') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_nil app.lsp_completion
end
