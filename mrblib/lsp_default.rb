module Mrbmacs
  # LspExtension
  class LspExtension < Extension
    LSP_DEFAULT_CONFIG = {
      'bash' => {
        'command' => 'bash-language-server',
        'options' => { 'args' => ['start'] }
      },
      'cpp' => {
        'command' => 'ccls',
        'options' => {}
      },
      'go' => {
        'command' => 'gopls',
        'options' => {}
      },
      'html' => {
        'command' => 'html-languageserver',
        'options' => { 'args' => ['--stdio'] }
      },
      'javascript' => {
        'command' => 'typescript-language-server',
        'options' => { 'args' => ['--stdio'] }
      },
      'markdown' => {
        'command' => 'remark-language-server',
        'options' => { 'args' => ['--stdio'] }
      },
      'perl' => {
        'command' => 'perl',
        'options' => { 'args' => ['-MPerl::LanguageServer', '-e', '"Perl::LanguageServer->run"'] }
      },
      'python' => {
        'command' => 'pyls',
        'options' => {}
      },
      'r' => {
        'command' => 'R',
        'options' => { 'args' => ['--slave', '-e', 'languageserver::run\(\)'] }
      },
      'ruby' => {
        'command' => 'solargraph',
        'options' => { 'args' => ['stdio'] }
      },
      'rust' => {
        'command' => 'rls',
        'options' => {}
      }
    }.freeze

    LSP_DEFAULT_KEYMAP = {
      'M-r' => 'lsp_references',
      'M-d' => 'lsp_definition'
    }.freeze
  end
end
