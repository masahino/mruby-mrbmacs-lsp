MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'default'
  conf.gem :github => 'masahino/mruby-scintilla-base' do |g|
    g.download_scintilla
  end
  conf.gem File.expand_path(File.dirname(__FILE__))
  conf.enable_test
end
