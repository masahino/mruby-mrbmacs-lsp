require "#{File.dirname(__FILE__)}/test_helper.rb"

assert('lsp default command') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_equal 'solargraph', app.ext.data['lsp']['ruby'].server[:command]
  assert_equal ['stdio'], app.ext.data['lsp']['ruby'].server[:args]
end

assert('lsp config') do
  app = setup_app
  app.config.ext['lsp'] = {
    'ruby' => {
      'command' => 'ruby',
      'options' => { 'args' => ['bbb', 'ccc'] }
    },
    'whitespace' => {
      'command' => 'hogehoge',
      'options' => {}
    }
  }

  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_equal 'ruby', app.ext.data['lsp']['ruby'].server[:command]
  assert_equal ['bbb', 'ccc'], app.ext.data['lsp']['ruby'].server[:args]
end

assert('def lsp_get_completion_list') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  app.current_line_col = [1, 1]
  app.current_line_text = "hoge\n"
  assert_equal [2, ''], app.lsp_get_completion_list({}, {})
  assert_equal [2, ''], app.lsp_get_completion_list({}, { 'result' => {} })
  resp = {
    'result' => {
      'items' => [
        { 'textEdit' => { 'newText' => 'hogehoge' } },
        { 'textEdit' => { 'newText' => 'hogege' } }
      ]
    }
  }
  assert_equal [2, 'hogege hogehoge'], app.lsp_get_completion_list({}, resp)
  app.current_line_col = [1, 5]
  app.current_line_text = 'hoge("'
  assert_equal [6, 'hogege hogehoge'], app.lsp_get_completion_list({}, resp)
end

assert('lsp_completion_trigger_characters') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_equal [], app.lsp_completion_trigger_characters
  app.ext.data['lsp']['irb'] = LSP::Client.new('', {})
  assert_equal [], app.lsp_completion_trigger_characters
  app.ext.data['lsp']['irb'].server_capabilities['completionProvider'] = {}
  app.ext.data['lsp']['irb'].server_capabilities['completionProvider']['triggerCharacters'] = ['x', 'y', 'z']
  assert_equal ['x', 'y', 'z'], app.lsp_completion_trigger_characters
end

assert('lsp_signature_trigger_characters') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_equal [], app.lsp_signature_trigger_characters
  app.ext.data['lsp']['irb'] = LSP::Client.new('', {})
  assert_equal [], app.lsp_signature_trigger_characters
  app.ext.data['lsp']['irb'].server_capabilities['signatureHelpProvider'] = {}
  app.ext.data['lsp']['irb'].server_capabilities['signatureHelpProvider']['triggerCharacters'] = ['a', 'b', 'c']
  assert_equal ['a', 'b', 'c'], app.lsp_signature_trigger_characters
end

assert('lsp_on_type_formatting_trigger_characters') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  # assert_equal [], app.lsp_on_type_formatting_trigger_characters
  app.ext.data['lsp']['irb'] = LSP::Client.new('', {})
  assert_equal [], app.lsp_on_type_formatting_trigger_characters
  app.ext.data['lsp']['irb'].server_capabilities['documentOnTypeFormattingProvider'] = {}
  app.ext.data['lsp']['irb'].server_capabilities['documentOnTypeFormattingProvider']['firstTriggerCharacter'] = 'a'
  assert_equal ['a'], app.lsp_on_type_formatting_trigger_characters
  app.ext.data['lsp']['irb'].server_capabilities['documentOnTypeFormattingProvider']['moreTriggerCharacter'] = ['a', 'b', 'c']
  assert_equal ['a', 'b', 'c'], app.lsp_on_type_formatting_trigger_characters
end

assert('lsp_keymap') do
  app = setup_app
  Mrbmacs::LspExtension.set_keybind(app, 'default')
end
