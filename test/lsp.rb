require File.dirname(__FILE__) + '/test_helper.rb'

assert('lsp default command') do
  app = setup_app
  Mrbmacs::Extension::register_lsp_client(app)
  assert_equal 5, app.ext.lsp.size
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
  assert_equal 6, app.ext.lsp.size
  assert_equal "aaaaa", app.ext.lsp['ruby'].server[:command]
  assert_equal ['bbb','ccc'], app.ext.lsp['ruby'].server[:args]
end

assert('uri_to_path') do
  assert_equal "", Mrbmacs::Extension.lsp_uri_to_path("")
  assert_equal "/foo/bar/baz.txt", Mrbmacs::Extension.lsp_uri_to_path("file:///foo/bar/baz.txt")
end

assert('def lsp_get_completion_list') do
  app = setup_app
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
