require File.dirname(__FILE__) + '/test_helper.rb'

assert('lsp default command') do
  app = setup_app
  Mrbmacs::Extension::register_lsp_client(app)
  assert_equal 9, app.ext.lsp.size
  assert_equal "solargraph", app.ext.lsp['ruby'].server[:command]
  assert_equal ['stdio'], app.ext.lsp['ruby'].server[:args]
end

assert('lsp config') do
  app = setup_app
  app.ext.config['lsp'] = {
    "ruby" => {
      "command" => "aaaaa",
      "options" => {"args" => ["bbb","ccc"]}
    },
    "whitespace" => {
      "command" => "hogehoge",
      "options" => {}
    }
  }

  Mrbmacs::Extension::register_lsp_client(app)
  assert_equal 10, app.ext.lsp.size
  assert_equal "aaaaa", app.ext.lsp['ruby'].server[:command]
  assert_equal ['bbb','ccc'], app.ext.lsp['ruby'].server[:args]
end

assert('uri_to_path') do
  app = setup_app
  assert_equal "", app.lsp_uri_to_path("")
  assert_equal "/foo/bar/baz.txt", app.lsp_uri_to_path("file:///foo/bar/baz.txt")
end

assert('def lsp_get_completion_list') do
  app = setup_app
  Mrbmacs::Extension::register_lsp_client(app)
  app.get_current_line_col = [1, 1]
  app.get_current_line_text = "hoge\n"
  assert_equal [2, ''], app.lsp_get_completion_list({}, {})
  assert_equal [2, ''], app.lsp_get_completion_list({}, {'result' => {}})
  resp = {'result' => {
      'items' => [
        {'textEdit' => {'newText' => 'hogehoge'}},
        {'textEdit' => {'newText' => 'hogege'}}
        ]}}
  assert_equal [2, 'hogege hogehoge'], app.lsp_get_completion_list({}, resp)
  app.get_current_line_col = [1, 5]
  app.get_current_line_text = 'hoge("'
  assert_equal [6, 'hogege hogehoge'], app.lsp_get_completion_list({}, resp)
end

assert('lsp_get_completion_trigger_characters') do
  app = setup_app
  Mrbmacs::Extension::register_lsp_client(app)
  assert_equal [], app.lsp_completion_trigger_characters
  app.ext.lsp['default'] = LSP::Client.new("", {})
  assert_equal [], app.lsp_completion_trigger_characters
  app.ext.lsp['default'].server_capabilities['completionProvider']['triggerCharacters'] = ['x', 'y', 'z']
  assert_equal ['x', 'y', 'z'], app.lsp_completion_trigger_characters
end

assert('lsp_get_signature_trigger_characters') do
  app = setup_app
  Mrbmacs::Extension::register_lsp_client(app)
  assert_equal [], app.lsp_signature_trigger_characters
  app.ext.lsp['default'] = LSP::Client.new("", {})
  assert_equal [], app.lsp_signature_trigger_characters
  app.ext.lsp['default'].server_capabilities['signatureHelpProvider']['triggerCharacters'] = ['a', 'b', 'c']
  assert_equal ['a', 'b', 'c'], app.lsp_signature_trigger_characters

end