module Mrbmacs
  class TestApp < Application
    attr_accessor :ext
    attr_accessor :get_current_line_col, :get_current_line_text
    def initialize
      @current_buffer = Buffer.new("*scratch*")
      @frame = Mrbmacs::Frame.new(@current_buffer)
      @buffer_list = []
      @theme = Theme.new
      @command_handler = {}
      @sci_handler = {}
      @ext = Extension.new
    end
  end

  class Frame
    attr_accessor :view_win, :echo_win, :tk
    attr_accessor :echo_message
    attr_accessor :edit_win
    def initialize(buffer)
      @view_win = Scintilla::TestScintilla.new
      @echo_win = Scintilla::TestScintilla.new
      @edit_win = Mrbmacs::EditWindow.new(self, buffer, 0, 0, 0, 0)
    end

    def waitkey(win)
    end

    def strfkey(key)
    end

    def echo_set_prompt(prompt)
    end

    def echo_gets(prompt, text = "", &block)
      "test"
    end

    def echo_puts(text)
      @echo_message = text
    end

    def modeline(app)
    end

    def exit
    end
  end

  class EditWindow
    def initialize(frame, buffer, x1, y1, width, height)
    end
  end
end

module Scintilla
  Scintilla::PLATFORM = :TEST
  class TestScintilla < ScintillaBase
    attr_accessor :pos
    attr_accessor :messages
    attr_accessor :test_return
    def initialize
      @pos = 0
      @messages = []
      @test_return = {}
    end

    def send_message(id, *args)
      @messages.push id
      if @test_return[id] != nil
        return @test_return[id]
      else
        return 0
      end
    end

    def resize_window(height, width)
    end

    def move_window(x, y)
    end

    def refresh
    end

#    def sci_set_docpointer(doc)
#    end

#    def sci_set_lexer_language(lang)
#    end

    def send_key(key, mod_shift, mod_ctrl, mod_alt)
    end

#   def sci_get_current_pos()
#      @pos
#    end

    def sci_get_curline()
      []
    end

  end
end

class TermKey
  attr_accessor :key_buffer
  class Key
    attr_accessor :key_str
    def initialize(key = nil)
      if key != nil
        @code = key.chr
        @type = TermKey::TYPE_UNICODE
        @modifiers = 0
        @key_str = key
      else
        @code = 0
        @type = TermKey::TYPE_UNKNOWN_CSI
        @modifiers = 0
        @key_str = ""
      end
    end

    def modifiers
      @modifiers
    end

    def type
      @type
    end

    def code
      @code
    end

  end

  def initialize(fd, flag)
    @key_buffer = []
  end

  def waitkey
    if @key_buffer.size > 0
      [TermKey::RES_KEY, TermKey::Key.new(@key_buffer.shift)]
    else
      [TermKey::RES_NONE, TermKey::Key.new]
    end
  end

  def strfkey(key, flag)
    key.key_str
  end

  def buffer_remaining
    0
  end

  def buffer_size
    0
  end
end

def exit
end
def setup_app
  Mrbmacs::TestApp.new
end