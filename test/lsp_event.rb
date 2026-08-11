module Mrbmacs
  class TestLspEventApp < TestApp
    attr_reader :completion_selection, :calltip_action

    def lsp_completion_select(scn)
      @completion_selection = scn
    end

    def lsp_pageup_calltip
      @calltip_action = :pageup
    end

    def lsp_pagedown_calltip
      @calltip_action = :pagedown
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
