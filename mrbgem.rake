MRuby::Gem::Specification.new('mruby-mrbmacs-lsp') do |spec|
  spec.license = 'MIT'
  spec.authors = 'masahino'

  spec.add_dependency 'mruby-lsp-client', :github => 'masahino/mruby-lsp-client'
end
