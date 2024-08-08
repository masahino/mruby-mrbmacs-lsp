module Mrbmacs
  LSP_SERVERS = {
    'bash' => [
      {
        'command' => 'bash-language-server',
        'options' => { 'args' => ['start'] },
        'requires' => []
      }
    ],
    'cpp' => [
      {
        'command' => 'clangd',
        'options' => {},
        'requires' => []
      }
    ],
    'css' => [
      {
        'command' => 'vscode-css-language-server',
        'options' => {},
        'requires' => [
          'npm'
        ]
      },
      {
        'command' => 'css-languageserver',
        'options' => {},
        'requires' => [
          'npm'
        ]
      },
      {
        'command' => 'tailwindcss-intellisense',
        'options' => {},
        'requires' => [
          'npm'
        ]
      }
    ],
    'go' => [
      {
        'command' => 'gopls',
        'options' => {},
        'requires' => ['go']
      }
    ],
    'html' => [
      {
        'command' => 'html-languageserver',
        'options' => { 'args' => ['--stdio'] },
        'requires' => ['npm']
      }
    ],
    'java' => [
      {
        'command' => 'eclipse-jdt-ls',
        'options' => {},
        'requires' => [
          'java'
        ]
      },
      {
        'command' => 'java-language-server',
        'options' => {},
        'requires' => [
          'java',
          'mvn'
        ]
      }
    ],
    'javascript' => [
      {
        'command' => 'typescript-language-server',
        'options' => { 'args' => ['--stdio'] },
        'requires' => ['npm']
      }
    ],
    'lisp' => [
      {
        'command' => 'cl-lsp',
        'options' => {},
        'requires' => [
          'ros'
        ]
      }
    ],
    'lua' => [
      {
        'command' => 'emmylua-ls',
        'options' => {},
        'requires' => [
          'java'
        ]
      },
      {
        'command' => 'sumneko-lua-language-server',
        'options' => {},
        'requires' => []
      }
    ],
    'markdown' => [
      {
        'command' => 'vscode-markdown-languageserver',
        'requires' => ['npm']
      },
      {
        'command' => 'marksman',
        'requires' => []
      },
      {
        'command' => 'remark-language-server',
        'options' => { 'args' => ['--stdio'] },
        'requires' => ['npm']
      }
    ],
    'python' => [
      {
        'command' => 'pyls',
        'options' => {},
        'requires' => ['python3']
      }
    ],
    'ruby' => [
      {
        'command' => 'solargraph',
        'options' => { 'args' => ['stdio'] },
        'requires' => ['gem']
      },
      {
        'command' => 'ruby-lsp',
        'options' => { 'args' => ['stdio'] },
        'requires' => ['gem']
      },
      {
        'command' => 'ruby_language_server',
        'options' => {},
        'requires' => ['gem']
      }
    ],
    'rust' => [
      {
        'command' => 'rls',
        'options' => {},
        'requires' => []
      },
      {
        'command' => 'rust-analyzer',
        'options' => {},
        'requires' => []
      }
    ],
    'latex' => [
      {
        'command' => 'texlab',
        'options' => {},
        'requires' => []
      },
      {
        'command' => 'digestif',
        'options' => {},
        'requires' => [
          'luarocks'
        ]
      }
    ],
    'xml' => [
      {
        'command' => 'lemminx',
        'options' => {},
        'requires' => [
          'java'
        ]
      }
    ],
    'yaml' => [
      {
        'command' => 'yaml-language-server',
        'options' => {},
        'requires' => [
          'npm'
        ]
      }
    ]
  }
end
