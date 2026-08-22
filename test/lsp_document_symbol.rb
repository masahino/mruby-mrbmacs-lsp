def setup_document_symbol_response(items)
  app = setup_app
  Mrbmacs::LspExtension.register_lsp_client(app)
  server = LSP::Client.new('', {})
  request_id = 1
  server.request_buffer[request_id] = {
    message: { 'method' => 'textDocument/documentSymbol' }
  }
  userlists = []
  view = app.frame.view_win
  view.define_singleton_method(:sci_autoc_get_separator) { '|'.ord }
  view.define_singleton_method(:sci_userlist_show) do |list_type, list|
    userlists << [list_type, list]
  end
  app.lsp_process_document_symbol_response(
    server, request_id, { 'result' => items }
  )
  [app, userlists]
end

assert('document symbol response shows SymbolInformation items') do
  items = [
    {
      'name' => 'main',
      'kind' => LSP::SymbolKind[:Function],
      'location' => {
        'uri' => 'file:///workspace/main.c',
        'range' => { 'start' => { 'line' => 2, 'character' => 0 } }
      }
    },
    {
      'name' => 'initialize',
      'kind' => LSP::SymbolKind[:Method],
      'containerName' => 'Counter',
      'location' => {
        'uri' => 'file:///workspace/counter.rb',
        'range' => { 'start' => { 'line' => 7, 'character' => 2 } }
      }
    }
  ]

  _app, userlists = setup_document_symbol_response(items)

  assert_equal [
    [
      Mrbmacs::LspExtension::LSP_DOCUMENT_SYMBOL_LIST_TYPE,
      'main [Function] :3|initialize [Method] (Counter) :8'
    ]
  ], userlists
end

assert('document symbol response ignores an empty result') do
  _app, userlists = setup_document_symbol_response([])

  assert_equal [], userlists
end

assert('document symbol response ignores DocumentSymbol items') do
  items = [
    {
      'name' => 'main',
      'kind' => LSP::SymbolKind[:Function],
      'range' => { 'start' => { 'line' => 2, 'character' => 0 } },
      'selectionRange' => { 'start' => { 'line' => 2, 'character' => 0 } }
    }
  ]

  _app, userlists = setup_document_symbol_response(items)

  assert_equal [], userlists
end

assert('document symbol selection navigates to the selected duplicate item') do
  items = [
    {
      'name' => 'target',
      'kind' => LSP::SymbolKind[:Function],
      'location' => {
        'uri' => 'file:///workspace/symbols.rb',
        'range' => { 'start' => { 'line' => 2, 'character' => 1 } }
      }
    },
    {
      'name' => 'target',
      'kind' => LSP::SymbolKind[:Function],
      'location' => {
        'uri' => 'file:///workspace/symbols.rb',
        'range' => { 'start' => { 'line' => 2, 'character' => 5 } }
      }
    }
  ]
  app, _userlists = setup_document_symbol_response(items)
  opened_files = []
  positions = []
  recenter_count = 0
  app.define_singleton_method(:find_file) { |filename| opened_files << filename }
  app.define_singleton_method(:recenter) { recenter_count += 1 }
  view = app.frame.view_win
  view.define_singleton_method(:sci_find_column) do |line, character|
    positions << [line, character]
    42
  end
  view.define_singleton_method(:sci_gotopos) { |position| positions << position }

  app.lsp_document_symbol_select('text' => 'target [Function] :3 (2)')

  assert_equal ['/workspace/symbols.rb'], opened_files
  assert_equal [[2, 5], 42], positions
  assert_equal 1, recenter_count
end
