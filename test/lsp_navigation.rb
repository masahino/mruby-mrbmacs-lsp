assert('location selection navigates to the selected position') do
  app = setup_app
  navigation = []
  app.define_singleton_method(:lsp_navigate_to) do |filename, line, character|
    navigation << [filename, line, character]
  end

  app.lsp_location_select('text' => '/workspace/main.rb,3,5')

  assert_equal [['/workspace/main.rb', 2, 4]], navigation
end
