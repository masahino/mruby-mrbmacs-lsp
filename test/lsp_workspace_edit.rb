def setup_workspace_edit_app
  app = setup_app
  calls = []
  app.define_singleton_method(:lsp_uri_to_path) do |uri|
    calls << [:lsp_uri_to_path, uri]
    uri.sub('file://', '')
  end
  app.define_singleton_method(:find_file) do |path|
    calls << [:find_file, path]
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

  app.lsp_workspace_edit({})

  assert_equal [], calls
end

assert('lsp_workspace_edit applies changes to one file and restores the buffer') do
  app, calls = setup_workspace_edit_app
  original_buffer_name = app.current_buffer.name
  uri = 'file:///workspace/one.rb'
  text_edits = [{ 'newText' => 'one' }]

  app.lsp_workspace_edit('changes' => { uri => text_edits })

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

  app.lsp_workspace_edit(
    'changes' => {
      first_uri => first_edits,
      second_uri => second_edits
    }
  )

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
