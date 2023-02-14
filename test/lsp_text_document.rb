require "#{File.dirname(__FILE__)}/test_helper.rb"

assert('lsp_content_change_event_from_scn: insert char 1') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # insert head of text
  scn = { 'position' => 0, 'length' => 1, 'lines_added' => 0, 'modification_type' => 0x2011, 'text' => 'a' }
  cc = {
    'text' => 'a',
    'range' => {
      'start' => { 'line' => 0, 'character' => 0 },
      'end' => { 'line' => 0, 'character' => 0 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: insert char 2') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # insert line:2, char:9
  scn = { 'position' => 31, 'length' => 1, 'lines_added' => 0, 'modification_type' => 0x2011, 'text' => 'b' }
  cc = {
    'text' => 'b',
    'range' => {
      'start' => { 'line' => 1, 'character' => 8 },
      'end' => { 'line' => 1, 'character' => 8 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: add char') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # add last pos
  scn = { 'position' => 75, 'length' => 1, 'lines_added' => 0, 'modification_type' => 0x2011, 'text' => 'c' }
  cc = {
    'text' => 'c',
    'range' => {
      'start' => { 'line' => 4, 'character' => 0 },
      'end' => { 'line' => 4, 'character' => 0 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: add text') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # add last pos
  scn = { 'position' => 38, 'length' => 6, 'lines_added' => 0, 'modification_type' => 0x2011, 'text' => 'sample' }
  cc = {
    'text' => 'sample',
    'range' => {
      'start' => { 'line' => 1, 'character' => 15 },
      'end' => { 'line' => 1, 'character' => 15 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: enter key') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # enter 
  scn = { 'position' => 22, 'length' => 1, 'lines_added' => 1, 'modification_type' => 0x2011, 'text' => "\n" }
  cc = {
    'text' => "\n",
    'range' => {
      'start' => { 'line' => 0, 'character' => 22 },
      'end' => { 'line' => 0, 'character' => 22 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: enter key 2') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # enter "sev\neral"
  scn = { 'position' => 33, 'length' => 1, 'lines_added' => 1, 'modification_type' => 0x2011, 'text' => "\n" }
  cc = {
    'text' => "\n",
    'range' => {
      'start' => { 'line' => 1, 'character' => 10 },
      'end' => { 'line' => 1, 'character' => 10 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: del char') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # add last pos
  scn = { 'position' => 0, 'length' => 1, 'lines_added' => 0, 'modification_type' => 0x2012, 'text' => 'H' }
  cc = {
    'text' => '',
    'range' => {
      'start' => { 'line' => 0, 'character' => 0 },
      'end' => { 'line' => 0, 'character' => 1 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: del \n') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # add last pos
  scn = { 'position' => 22, 'length' => 1, 'lines_added' => -1, 'modification_type' => 0x2012, 'text' => "\n" }
  cc = {
    'text' => '',
    'range' => {
      'start' => { 'line' => 0, 'character' => 22 },
      'end' => { 'line' => 1, 'character' => 0 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: del text') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # add last pos
  scn = { 'position' => 30, 'length' => 8, 'lines_added' => 0, 'modification_type' => 0x2012, 'text' => 'several ' }
  cc = {
    'text' => '',
    'range' => {
      'start' => { 'line' => 1, 'character' => 7 },
      'end' => { 'line' => 1, 'character' => 15 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: del line') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # add last pos
  scn = { 'position' => 23, 'length' => 22, 'lines_added' => -1, 'modification_type' => 0x2012,
          'text' => "It has several lines.\n" }
  cc = {
    'text' => '',
    'range' => {
      'start' => { 'line' => 1, 'character' => 0 },
      'end' => { 'line' => 2, 'character' => 0 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end

assert('lsp_content_change_event_from_scn: del multi lines text') do
  app = setup_app
  app.find_file("#{File.dirname(__FILE__)}#{File::SEPARATOR}content_change_event.txt")
  # add last pos
  scn = { 'position' => 8, 'length' => 22, 'lines_added' => -1, 'modification_type' => 0x2012,
          'text' => "a sample file.\nIt has " }
  cc = {
    'text' => '',
    'range' => {
      'start' => { 'line' => 0, 'character' => 8 },
      'end' => { 'line' => 1, 'character' => 7 }
    }
  }
  assert_equal cc, app.lsp_content_change_event_from_scn(scn)[0].to_h
end
