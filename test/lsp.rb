module Mrbmacs
  class TestApp < Application
    attr_accessor :ext
    def initialize
      @command_handler = {}
      @sci_handler = {}
      @ext = Extension.new
    end
  end
end

def setup_app
  Mrbmacs::TestApp.new
end

assert('lsp default command') do
  app = setup_app
  Mrbmacs::Extension::register_lsp_client(app)
  assert_equal 4, app.ext.lsp.size
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
  assert_equal 5, app.ext.lsp.size
  assert_equal "aaaaa", app.ext.lsp['ruby'].server[:command]
  assert_equal ['bbb','ccc'], app.ext.lsp['ruby'].server[:args]
end

assert('uri_to_path') do
  assert_equal "", Mrbmacs::Extension.lsp_uri_to_path("")
  assert_equal "/foo/bar/baz.txt", Mrbmacs::Extension.lsp_uri_to_path("file:///foo/bar/baz.txt")
end