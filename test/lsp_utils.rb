require "#{File.dirname(__FILE__)}/test_helper.rb"

assert('uri_to_path') do
  app = setup_app
  assert_equal '', app.lsp_uri_to_path('')
  assert_equal '/foo/bar/baz.txt', app.lsp_uri_to_path('file:///foo/bar/baz.txt')
end
