def setup_workspace_edit_app
  app = setup_app
  calls = []
  app.define_singleton_method(:lsp_uri_to_path) do |uri|
    calls << [:lsp_uri_to_path, uri]
    uri.sub('file://', '')
  end
  app.define_singleton_method(:find_file) do |path|
    calls << [:find_file, path]
    true
  end
  app.define_singleton_method(:lsp_process_text_edits) do |text_edits|
    calls << [:lsp_process_text_edits, text_edits]
  end
  app.define_singleton_method(:switch_to_buffer) do |buffer_name|
    calls << [:switch_to_buffer, buffer_name]
  end
  [app, calls]
end

assert('lsp_workspace_edit does nothing without changes') do
  app, calls = setup_workspace_edit_app

  result = app.lsp_workspace_edit({})

  assert_false result
  assert_equal [], calls
end

assert('lsp_workspace_edit applies changes to one file and restores the buffer') do
  app, calls = setup_workspace_edit_app
  original_buffer_name = app.current_buffer.name
  uri = 'file:///workspace/one.rb'
  text_edits = [{ 'newText' => 'one' }]

  result = app.lsp_workspace_edit('changes' => { uri => text_edits })

  assert_true result
  assert_equal [
    [:lsp_uri_to_path, uri],
    [:find_file, '/workspace/one.rb'],
    [:lsp_process_text_edits, text_edits],
    [:switch_to_buffer, original_buffer_name]
  ], calls
end

assert('lsp_workspace_edit applies changes to multiple files in order') do
  app, calls = setup_workspace_edit_app
  original_buffer_name = app.current_buffer.name
  first_uri = 'file:///workspace/one.rb'
  second_uri = 'file:///workspace/two.rb'
  first_edits = [{ 'newText' => 'one' }]
  second_edits = [{ 'newText' => 'two' }]

  result = app.lsp_workspace_edit(
    'changes' => {
      first_uri => first_edits,
      second_uri => second_edits
    }
  )

  assert_true result
  assert_equal [
    [:lsp_uri_to_path, first_uri],
    [:find_file, '/workspace/one.rb'],
    [:lsp_process_text_edits, first_edits],
    [:lsp_uri_to_path, second_uri],
    [:find_file, '/workspace/two.rb'],
    [:lsp_process_text_edits, second_edits],
    [:switch_to_buffer, original_buffer_name]
  ], calls
end

assert('lsp_workspace_edit stops when the first file cannot be opened') do
  app, calls = setup_workspace_edit_app
  original_buffer_name = app.current_buffer.name
  uri = 'file:///workspace/one.rb'
  app.define_singleton_method(:find_file) do |path|
    calls << [:find_file, path]
    false
  end

  result = app.lsp_workspace_edit(
    'changes' => {
      uri => [{ 'newText' => 'one' }],
      'file:///workspace/two.rb' => [{ 'newText' => 'two' }]
    }
  )

  assert_false result
  assert_equal ["LSP workspace edit aborted: unable to open #{uri}"], app.logger.log[:error]
  assert_equal [
    [:lsp_uri_to_path, uri],
    [:find_file, '/workspace/one.rb'],
    [:switch_to_buffer, original_buffer_name]
  ], calls
end

assert('lsp_workspace_edit keeps earlier edits and stops after an open failure') do
  app, calls = setup_workspace_edit_app
  original_buffer_name = app.current_buffer.name
  first_uri = 'file:///workspace/one.rb'
  second_uri = 'file:///workspace/two.rb'
  first_edits = [{ 'newText' => 'one' }]
  app.define_singleton_method(:find_file) do |path|
    calls << [:find_file, path]
    path != '/workspace/two.rb'
  end

  result = app.lsp_workspace_edit(
    'changes' => {
      first_uri => first_edits,
      second_uri => [{ 'newText' => 'two' }],
      'file:///workspace/three.rb' => [{ 'newText' => 'three' }]
    }
  )

  assert_false result
  assert_equal ["LSP workspace edit aborted: unable to open #{second_uri}"], app.logger.log[:error]
  assert_equal [
    [:lsp_uri_to_path, first_uri],
    [:find_file, '/workspace/one.rb'],
    [:lsp_process_text_edits, first_edits],
    [:lsp_uri_to_path, second_uri],
    [:find_file, '/workspace/two.rb'],
    [:switch_to_buffer, original_buffer_name]
  ], calls
end

assert('lsp_workspace_edit restores the original buffer after an error') do
  app, calls = setup_workspace_edit_app
  original_buffer_name = app.current_buffer.name
  app.define_singleton_method(:lsp_process_text_edits) do |_text_edits|
    raise 'edit failed'
  end

  error = nil
  begin
    app.lsp_workspace_edit(
      'changes' => { 'file:///workspace/one.rb' => [{ 'newText' => 'one' }] }
    )
  rescue StandardError => e
    error = e
  end

  assert_equal 'edit failed', error.message
  assert_equal [:switch_to_buffer, original_buffer_name], calls.last
end
