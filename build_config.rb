MRuby::Build.new do |conf|
  toolchain :gcc
  class << conf
    def libraries
      [libmruby_static, libmruby_core_static]
    end
  end
  conf.gembox 'default'
  conf.gem github: 'mattn/mruby-iconv' do |g|
    g.skip_test = true
    g.linker.libraries.delete 'iconv' if RUBY_PLATFORM.include?('linux')
  end
  conf.gem github: 'iij/mruby-regexp-pcre' do |g|
    g.skip_test = true
  end
  conf.gem github: 'masahino/mruby-lsp-client' do |g|
    g.skip_test = true
  end
  conf.gem File.expand_path(__dir__)
  conf.enable_test
end
