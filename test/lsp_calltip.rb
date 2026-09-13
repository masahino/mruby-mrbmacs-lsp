module Mrbmacs
  class TestApp
    attr_accessor :lsp_calltip_info
  end
end

module Scintilla
  class TestScintilla
    attr_reader :calltip_highlight

    def sci_calltip_show(pos, text)
      @pos = pos
      @text = text
    end

    def sci_calltip_set_hlt(start_pos, end_pos)
      @calltip_highlight = [start_pos, end_pos]
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

assert('shows_full_calltip_when_less_than_15_lines') do
  setup
  @app.lsp_draw_calltip(0)
  assert_equal "This is a\ntest\ncalltip\nthat spans\nmultiple lines\nin the editor", @app.frame.view_win.text
end

assert('shows_bottom_of_calltip_when_at_end_of_text') do
  setup
  @app.lsp_calltip_info[:start_line] = 3
  @app.lsp_draw_calltip(0)
  assert_equal "            \001\nthat spans\nmultiple lines\nin the editor", @app.frame.view_win.text
end

assert('shows_next-page_control_for_more_than_15_lines') do
  setup
  @app.lsp_calltip_info[:text] = (1..16).map { |line| "line #{line}" }.join("\n")
  @app.lsp_draw_calltip(0)
  expected = (1..15).map { |line| "line #{line}" }.join("\n")
  assert_equal "#{expected}\n     \002", @app.frame.view_win.text
end

assert('shows_top_of_calltip_when_at_start_of_text') do
  setup
  @app.lsp_calltip_info[:start_line] = 2
  @app.lsp_draw_calltip(0)
  assert_equal "            \001\ncalltip\nthat spans\nmultiple lines\nin the editor", @app.frame.view_win.text
end

assert('shows_top_and_bottom_of_calltip_when_in_middle_of_text') do
  setup
  @app.lsp_calltip_info[:start_line] = 2
  @app.lsp_calltip_info[:text] = (1..20).map { |line| "line #{line}" }.join("\n")
  @app.lsp_draw_calltip(0)
  expected = (3..17).map { |line| "line #{line}" }.join("\n")
  assert_equal "     \001\n#{expected}\n     \002", @app.frame.view_win.text
end

assert('simplifies markdown hover and highlights the first non-empty line') do
  setup
  @app.lsp_process_hover_response(
    'result' => {
      'contents' => {
        'kind' => 'markdown',
        'value' => "`Kernel#puts`\n\n```ruby\n$stdout.puts(objects)\n```\n\n\nVisibility: private"
      }
    }
  )

  assert_equal "Kernel#puts\n\n$stdout.puts(objects)\n\nVisibility: private", @app.frame.view_win.text
  assert_equal [0, 'Kernel#puts'.bytesize], @app.frame.view_win.calltip_highlight
end

assert('leaves plaintext hover unchanged without highlighting') do
  setup
  @app.lsp_process_hover_response(
    'result' => {
      'contents' => {
        'kind' => 'plaintext',
        'value' => "Kernel#puts\nplain text"
      }
    }
  )

  assert_equal "Kernel#puts\nplain text", @app.frame.view_win.text
  assert_nil @app.frame.view_win.calltip_highlight
end

assert('shows hover calltip at the dwell position') do
  setup
  @app.frame.view_win.pos = 7

  @app.lsp_process_hover_response(
    {
      'result' => {
        'contents' => {
          'kind' => 'plaintext',
          'value' => 'hover text'
        }
      }
    },
    123
  )

  assert_equal 123, @app.frame.view_win.pos
end

assert('shows only one page for hover without page controls') do
  setup
  lines = (1..16).map { |line| "line #{line}" }

  @app.lsp_process_hover_response(
    'result' => {
      'contents' => {
        'kind' => 'plaintext',
        'value' => lines.join("\n")
      }
    }
  )

  assert_equal lines.first(15).join("\n"), @app.frame.view_win.text
end
