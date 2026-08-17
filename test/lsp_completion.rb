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

def process_completion_items_for_test(items)
  app = setup_app
  server = LSP::Client.new('', {})
  request_id = 1
  server.request_buffer[request_id] = {
    message: { 'params' => {} }
  }
  sorted_items = []
  app.define_singleton_method(:lsp_filter_completion_items) { |completion_items| completion_items }
  app.define_singleton_method(:lsp_completion_list) do |_request|
    sorted_items.concat(@lsp_completion_items)
    ''
  end

  app.lsp_process_completion_response(server, request_id, { 'result' => items })
  sorted_items
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

assert('completion items are sorted by sortText') do
  items = [
    { 'label' => 'alpha', 'sortText' => '2' },
    { 'label' => 'beta', 'sortText' => '1' }
  ]

  sorted_items = process_completion_items_for_test(items)

  assert_equal ['beta', 'alpha'], sorted_items.map { |item| item['label'] }
end

assert('completion items without sortText are sorted by label') do
  items = [
    { 'label' => 'beta' },
    { 'label' => 'alpha' }
  ]

  sorted_items = process_completion_items_for_test(items)

  assert_equal ['alpha', 'beta'], sorted_items.map { |item| item['label'] }
end

assert('completion items with and without sortText are sorted together') do
  items = [
    { 'label' => 'alpha' },
    { 'label' => 'beta', 'sortText' => '02' },
    { 'label' => 'gamma', 'sortText' => '01' }
  ]

  sorted_items = process_completion_items_for_test(items)

  assert_equal ['gamma', 'beta', 'alpha'], sorted_items.map { |item| item['label'] }
end

assert('completion items are filtered by filterText') do
  app = setup_app
  stub_completion_input(app, 'foo', 0)
  items = [
    { 'label' => 'display name', 'filterText' => 'foo' }
  ]

  filtered_items = app.lsp_filter_completion_items(items)

  assert_equal ['display name'], filtered_items.map { |item| item['label'] }
end

assert('completion item filterText takes precedence over label') do
  app = setup_app
  stub_completion_input(app, 'foo', 0)
  items = [
    { 'label' => 'foo', 'filterText' => 'bar' }
  ]

  filtered_items = app.lsp_filter_completion_items(items)

  assert_equal [], filtered_items
end

assert('completion items without filterText are filtered by label') do
  app = setup_app
  stub_completion_input(app, 'foo', 0)
  items = [
    { 'label' => 'foo item' },
    { 'label' => 'bar item' }
  ]

  filtered_items = app.lsp_filter_completion_items(items)

  assert_equal ['foo item'], filtered_items.map { |item| item['label'] }
end

assert('lsp_completion_max_length') do
  app = setup_app
  test_data = [{ 'k1' => 'a' }, { 'k1' => 'bb' }, { 'k2' => 'ccc' }]

  assert_equal 2, app.lsp_completion_max_length(test_data, 'k1')
  assert_equal 0, app.lsp_completion_max_length(test_data, 'k3')
end
