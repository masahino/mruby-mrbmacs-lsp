require "#{File.dirname(__FILE__)}/test_helper.rb"

module Mrbmacs
  class TestApp
    attr_accessor :lsp_calltip_info
  end
end

module Scintilla
  class TestScintilla
    def sci_calltip_show(pos, text)
      @pos = pos
      @text = text
    end
  end
end

def setup
  @app = setup_app
  @app.lsp_calltip_info = {
    start_line: 0,
    text: "This is a\ntest\ncalltip\nthat spans\nmultiple lines\nin the editor"
  }
end

assert('shows_full_calltip_when_less_than_10_lines') do
  setup
  @app.lsp_draw_calltip(0)
  assert_equal "This is a\ntest\ncalltip\nthat spans\nmultiple lines\nin the editor", @app.frame.view_win.text
end

assert('shows_bottom_of_calltip_when_at_end_of_text') do
  setup
  @app.lsp_calltip_info[:start_line] = 3
  @app.lsp_draw_calltip(0)
  assert_equal "             \001\nthat spans\nmultiple lines\nin the editor", @app.frame.view_win.text
end

assert('shows_bottom_of_calltip_when_at_end_of_text') do
  setup
  @app.lsp_calltip_info[:text] += "\nadd\nsome\nlines\nand\nmore\nand\nmore\n"
  @app.lsp_draw_calltip(0)
  assert_equal "This is a\ntest\ncalltip\nthat spans\nmultiple lines\nin the editor\nadd\nsome\nlines\n\n             \002", @app.frame.view_win.text
end

assert('shows_top_of_calltip_when_at_start_of_text') do
  setup
  @app.lsp_calltip_info[:start_line] = 2
  @app.lsp_draw_calltip(0)
  assert_equal "             \001\ncalltip\nthat spans\nmultiple lines\nin the editor", @app.frame.view_win.text
end

assert('shows_top_and_bottom_of_calltip_when_in_middle_of_text') do
  setup
  @app.lsp_calltip_info[:start_line] = 2
  @app.lsp_calltip_info[:text] += "\nadd\nsome\nlines\nand\nmore\nand\nmore\n"
  @app.lsp_draw_calltip(0)
  assert_equal "             \001\ncalltip\nthat spans\nmultiple lines\nin the editor\nadd\nsome\nlines\nand\nmore\n\n             \002", @app.frame.view_win.text
end
