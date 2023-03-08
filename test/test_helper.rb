# Logger
class Logger
  attr_reader :log

  def initialize(_logfile)
    @log = { debug: [], info: [], error: [] }
  end

  def debug(message)
    @log[:debug].push message
  end

  def info(message)
    @log[:info].push message
  end

  def error(message)
    @log[:error].push message
  end
end

module Mrbmacs
  # TestApp
  class TestApp < Application
    attr_accessor :ext, :logger, :current_line_col, :current_line_text

    def initialize
      @current_buffer = Buffer.new('*scratch*')
      @frame = Mrbmacs::Frame.new(@current_buffer)
      @buffer_list = []
      @theme = Theme.new
      @command_handler = {}
      @sci_handler = {}
      @ext = Extension.new
      @logger = Logger.new(File.dirname('__FILE__') + 'test.log')
      @command_list = {}
      @config = Config.new
    end

    def find_file(file)
      @text = File.open(file).read
      @frame.view_win.text = @text
    end

    def line_col_from_pos(pos)
      line = @text[0..pos].count("\n")
      if @text[0..pos].split("\n").length == line
        if pos == @text[0..pos].length
          [line, 0]
        else
          [line - 1, @text[0..pos].split("\n")[line - 1].length]
        end
      else
        [line, @text[0..pos].split("\n")[line].length - 1]
      end
    end

    def add_buffer_to_frame(buffer)
      # dummy
    end
  end

  # Frame
  class Frame
    attr_accessor :view_win, :echo_win, :tk, :echo_message, :edit_win

    def initialize(buffer)
      @view_win = Scintilla::TestScintilla.new
      @echo_win = Scintilla::TestScintilla.new
      @edit_win = Mrbmacs::EditWindow.new(self, buffer, 0, 0, 0, 0)
    end

    def waitkey(win) end

    def strfkey(key) end

    def echo_set_prompt(prompt) end

    def echo_gets(_prompt, _text = '', &_block)
      'test'
    end

    def echo_puts(text)
      @echo_message = text
    end

    def modeline(app) end

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
  # TestScintilla
  class TestScintilla < ScintillaBase
    attr_accessor :pos, :messages, :test_return, :text

    def initialize
      @pos = 0
      @messages = []
      @test_return = {}
      @text = ''
    end

    def send_message(id, *_args)
      @messages.push id
      if @test_return[id] != nil
        return @test_return[id]
      else
        return 0
      end
    end

    def send_message_get_docpointer(message, *args) end

    def send_message_set_docpointer(id, wparam) end

    def resize_window(height, width) end

    def move_window(x, y) end

    def refresh() end

    def sci_set_lexer_language(lang) end

    def send_key(key, mod_shift, mod_ctrl, mod_alt) end

    #   def sci_get_current_pos()
    #      @pos
    #    end

    def sci_get_curline
      []
    end

    def sci_autoc_get_separator
      ' '
    end

    def sci_line_from_position(pos)
      line = @text[0..pos].count("\n")
      line -= 1 if @text[0..pos] != @text && @text[0..pos][-1] == "\n"
      line
    end

    def sci_position_from_line(line)
      return 0 if line == 0
      line -= 1
      tmp_text = @text.split("\n")[0..line].join("\n")
      tmp_text.bytesize + 1
    end

    def sci_get_textrange(start_pos, end_pos)
      return '' if start_pos == end_pos

      @text[start_pos..end_pos - 1]
    end
  end
end

# TermKey
class TermKey
  attr_accessor :key_buffer

  # Key
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
        @key_str = ''
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

  def initialize(_fd, _flag)
    @key_buffer = []
  end

  def waitkey
    if @key_buffer.size > 0
      [TermKey::RES_KEY, TermKey::Key.new(@key_buffer.shift)]
    else
      [TermKey::RES_NONE, TermKey::Key.new]
    end
  end

  def strfkey(key, _flag)
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
  # dummy
end

def setup_app
  Mrbmacs::TestApp.new
end
