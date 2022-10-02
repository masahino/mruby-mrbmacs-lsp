require File.dirname(__FILE__) + '/test_helper.rb'

assert('lsp_position') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}position-test.txt")
  pos_hash = { 'line' => 0, 'character' => 0 }
  assert_equal pos_hash, app.lsp_position(0)
end
