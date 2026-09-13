module Mrbmacs
  class TestLspEventApp < TestApp
    attr_reader :completion_selection, :document_symbol_selection, :code_action_selection
    attr_reader :calltip_action, :killed_buffer, :navigation, :hover_position, :hover_response,
                :hover_response_position

    def lsp_is_running?(_lang = nil)
      true
    end

    def lsp_position(position)
      @hover_position = position
      { 'line' => 1, 'character' => 2 }
    end

    def lsp_process_hover_response(response, position = nil)
      @hover_response = response
      @hover_response_position = position
    end

    def lsp_completion_select(scn)
      @completion_selection = scn
    end

    def lsp_document_symbol_select(scn)
      @document_symbol_selection = scn
    end

    def lsp_code_action_select(scn)
      @code_action_selection = scn
    end

    def lsp_navigate_to(filename, line, character)
      @navigation = [filename, line, character]
    end

    def lsp_pageup_calltip
      @calltip_action = :pageup
    end

    def lsp_pagedown_calltip
      @calltip_action = :pagedown
    end

    def lsp_kill_buffer(buffer)
      @killed_buffer = buffer
    end
  end
end

def setup_lsp_event_app
  app = Mrbmacs::TestLspEventApp.new
  Mrbmacs::LspExtension.register_lsp_client(app)
  app
end

assert('dispatches user list selection to LSP completion') do
  app = setup_lsp_event_app
  event = {
    'code' => Scintilla::SCN_USERLISTSELECTION,
    'list_type' => Mrbmacs::LspExtension::LSP_COMPLETION_LIST_TYPE,
    'text' => 'completion'
  }

  app.call_sci_event(event)

  assert_same event, app.completion_selection
end

assert('dispatches user list selection to LSP document symbols') do
  app = setup_lsp_event_app
  event = {
    'code' => Scintilla::SCN_USERLISTSELECTION,
    'list_type' => Mrbmacs::LspExtension::LSP_DOCUMENT_SYMBOL_LIST_TYPE,
    'text' => 'main [Function] :3'
  }

  app.call_sci_event(event)

  assert_same event, app.document_symbol_selection
end

assert('dispatches user list selection to LSP code actions') do
  app = setup_lsp_event_app
  event = {
    'code' => Scintilla::SCN_USERLISTSELECTION,
    'list_type' => Mrbmacs::LspExtension::LSP_CODE_ACTION_LIST_TYPE,
    'text' => 'Extract subexpression to variable'
  }

  app.call_sci_event(event)

  assert_same event, app.code_action_selection
end

assert('navigates to an LSP location user list selection') do
  app = setup_lsp_event_app

  app.call_sci_event(
    'code' => Scintilla::SCN_USERLISTSELECTION,
    'list_type' => Mrbmacs::LspExtension::LSP_GOTO_LIST_TYPE,
    'text' => '/workspace/main.rb,3,5'
  )

  assert_equal ['/workspace/main.rb', 2, 4], app.navigation
end

assert('dispatches calltip click to page up') do
  app = setup_lsp_event_app

  app.call_sci_event('code' => Scintilla::SCN_CALLTIPCLICK, 'position' => 1)

  assert_equal :pageup, app.calltip_action
end

assert('dispatches calltip click to page down') do
  app = setup_lsp_event_app

  app.call_sci_event('code' => Scintilla::SCN_CALLTIPCLICK, 'position' => 2)

  assert_equal :pagedown, app.calltip_action
end

assert('sends hover for the dwell notification position') do
  app = setup_lsp_event_app
  request = nil
  client = Object.new
  client.define_singleton_method(:hover) do |param|
    request = param
    41
  end
  app.ext.data['lsp'][app.current_buffer.mode.name] = client

  app.call_sci_event('code' => Scintilla::SCN_DWELLSTART, 'position' => 123)

  assert_equal 123, app.hover_position
  assert_equal({ 'line' => 1, 'character' => 2 }, request['position'])
  assert_equal 41, app.instance_variable_get(:@lsp_hover_request_id)
  assert_equal 123, app.instance_variable_get(:@lsp_hover_position)
end

assert('dwell end invalidates hover and cancels the calltip') do
  app = setup_lsp_event_app
  app.instance_variable_set(:@lsp_hover_request_id, 41)

  app.call_sci_event('code' => Scintilla::SCN_DWELLEND, 'position' => 123)

  assert_nil app.instance_variable_get(:@lsp_hover_request_id)
  assert_nil app.instance_variable_get(:@lsp_hover_position)
  assert_true app.frame.view_win.messages.include?(Scintilla::SCI_CALLTIPCANCEL)
end

assert('ignores a hover response that is no longer current') do
  app = setup_lsp_event_app
  response = { 'result' => { 'contents' => 'old hover' } }
  app.instance_variable_set(:@lsp_hover_request_id, 42)

  app.lsp_response_text_document_hover(nil, 41, response)

  assert_nil app.hover_response
  assert_equal 42, app.instance_variable_get(:@lsp_hover_request_id)
end

assert('handles only the current hover response') do
  app = setup_lsp_event_app
  response = { 'result' => { 'contents' => 'current hover' } }
  app.instance_variable_set(:@lsp_hover_request_id, 41)
  app.instance_variable_set(:@lsp_hover_position, 123)

  app.lsp_response_text_document_hover(nil, 41, response)

  assert_same response, app.hover_response
  assert_equal 123, app.hover_response_position
  assert_nil app.instance_variable_get(:@lsp_hover_request_id)
  assert_nil app.instance_variable_get(:@lsp_hover_position)
end

assert('dispatches killed buffer to LSP') do
  app = setup_lsp_event_app
  buffer = Mrbmacs::Buffer.new('closed.rb')

  app.after_kill_buffer(app, buffer)

  assert_same buffer, app.killed_buffer
end
