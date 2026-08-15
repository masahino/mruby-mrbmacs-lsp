def setup_completion_request_app(trigger_characters)
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  server.status = :running
  server.server_capabilities['completionProvider'] = {
    'triggerCharacters' => trigger_characters
  }
  requests = []
  server.define_singleton_method(:completion) { |params| requests << params }
  app.ext.data['lsp'][app.current_buffer.mode.name] = server
  [app, requests]
end

def stub_completion_input(app, text, word_start_position)
  view = app.frame.view_win
  current_position = text.bytesize
  view.text = text
  view.define_singleton_method(:sci_get_current_pos) { current_position }
  view.define_singleton_method(:sci_word_start_position) do |_position, _only_word_characters|
    word_start_position
  end
  view.define_singleton_method(:sci_get_text_range) do |start_position, end_position|
    text[start_position...end_position]
  end
end

assert('lsp completion request for a trigger character with empty partial input') do
  app, requests = setup_completion_request_app(['.'])
  stub_completion_input(app, 'foo.', 4)
  assert_equal '', app.lsp_partial_input

  app.lsp_send_completion_request({ 'ch' => '.'.ord })

  assert_equal 1, requests.size
  assert_equal LSP::CompletionTriggerKind[:TriggerCharacter], requests[0]['context']['triggerKind']
  assert_equal '.', requests[0]['context']['triggerCharacter']
end

assert('lsp completion request for invoked completion with partial input') do
  app, requests = setup_completion_request_app(['.'])
  stub_completion_input(app, 'foo', 0)
  assert_equal 'foo', app.lsp_partial_input

  app.lsp_send_completion_request({ 'ch' => 'o'.ord })

  assert_equal 1, requests.size
  assert_equal LSP::CompletionTriggerKind[:Invoked], requests[0]['context']['triggerKind']
  assert_equal false, requests[0]['context'].key?('triggerCharacter')
end

assert('no lsp completion request for invoked completion with empty partial input') do
  app, requests = setup_completion_request_app(['.'])
  stub_completion_input(app, 'foo ', 4)
  assert_equal '', app.lsp_partial_input

  app.lsp_send_completion_request({ 'ch' => ' '.ord })

  assert_equal 0, requests.size
end

assert('lsp_completion_max_length') do
  app = setup_app
  test_data = [{ 'k1' => 'a' }, { 'k1' => 'bb' }, { 'k2' => 'ccc' }]

  assert_equal 2, app.lsp_completion_max_length(test_data, 'k1')
  assert_equal 0, app.lsp_completion_max_length(test_data, 'k3')
end
