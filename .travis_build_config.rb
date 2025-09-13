MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'default'
  conf.gem github: 'mattn/mruby-iconv' do |g|
    g.linker.libraries.delete 'iconv' if RUBY_PLATFORM.include?('linux')
  end
  conf.gem File.expand_path(__dir__)
  conf.enable_test
end
