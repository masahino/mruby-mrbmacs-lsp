MRuby::Gem::Specification.new('mruby-mrbmacs-lsp') do |spec|
  spec.license = 'MIT'
  spec.authors = 'masahino'

  spec.add_dependency 'mruby-enum-ext'
  spec.add_dependency 'mruby-lsp-client', :github => 'masahino/mruby-lsp-client'
  spec.add_dependency 'mruby-mrbmacs-base', :github => 'masahino/mruby-mrbmacs-base'
  spec.add_dependency 'mruby-which', :github => 'masahino/mruby-which'
end
