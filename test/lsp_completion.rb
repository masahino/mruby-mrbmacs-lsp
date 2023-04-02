require "#{File.dirname(__FILE__)}/test_helper.rb"

assert('lsp_completion_max_length') do
  app = setup_app
  test_data = [{ 'k1' => 'a' }, { 'k1' => 'bb' }, { 'k2' => 'ccc' }]

  assert_equal 2, app.lsp_completion_max_length(test_data, 'k1')
  assert_equal 0, app.lsp_completion_max_length(test_data, 'k3')
end
