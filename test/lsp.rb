assert('lsp default command') do
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  assert_equal 'solargraph', app.ext.config['lsp']['ruby']['command']
  assert_equal ['stdio'], app.ext.config['lsp']['ruby']['options']['args']
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
  assert_equal 'ruby', app.ext.config['lsp']['ruby']['command']
  assert_equal ['bbb', 'ccc'], app.ext.config['lsp']['ruby']['options']['args']
end

def setup_lsp_find_file_test
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  opened_files = []
  app.ext.data['lsp']['ruby'] = server
  app.define_singleton_method(:lsp_find_server) { |_lang| true }
  app.define_singleton_method(:lsp_start_server) do |_lang, _filename|
  end
  app.define_singleton_method(:lsp_did_open) do |filename|
    opened_files << filename
  end
  [app, server, opened_files]
end

assert('lsp_find_file sends didOpen for a newly opened file') do
  app, _server, opened_files = setup_lsp_find_file_test
  filename = '/workspace/new.rb'
  app.current_buffer = Mrbmacs::Buffer.new(filename)

  app.lsp_find_file(filename)

  assert_equal [filename], opened_files
end

assert('lsp_find_file does not send duplicate didOpen for version zero') do
  app, server, opened_files = setup_lsp_find_file_test
  filename = '/workspace/opened.rb'
  app.current_buffer = Mrbmacs::Buffer.new(filename)
  uri = LSP::Parameter::TextDocumentIdentifier.new(filename).uri
  server.file_version[uri] = 0

  app.lsp_find_file(filename)

  assert_equal [], opened_files
end

assert('lsp_find_file sends didOpen for a different file') do
  app, server, opened_files = setup_lsp_find_file_test
  opened_filename = '/workspace/opened.rb'
  new_filename = '/workspace/new.rb'
  app.current_buffer = Mrbmacs::Buffer.new(new_filename)
  opened_uri = LSP::Parameter::TextDocumentIdentifier.new(opened_filename).uri
  server.file_version[opened_uri] = 0

  app.lsp_find_file(new_filename)

  assert_equal [new_filename], opened_files
end

assert('lsp_find_file sends didOpen after the file is closed') do
  app, server, opened_files = setup_lsp_find_file_test
  filename = '/workspace/reopened.rb'
  app.current_buffer = Mrbmacs::Buffer.new(filename)
  uri = LSP::Parameter::TextDocumentIdentifier.new(filename).uri
  server.file_version[uri] = 0
  server.file_version.delete(uri)

  app.lsp_find_file(filename)

  assert_equal [filename], opened_files
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
  mode = Mrbmacs::ModeManager.get_mode_by_name('ruby')
  original = mode.keymap.dup
  Mrbmacs::LspExtension.set_keybind(app, 'ruby')
  assert_equal Mrbmacs::LspExtension::LSP_DEFAULT_KEYMAP['M-.'], mode.keymap['M-.']
  mode.keymap = original
end
