# mruby-mrbmacs-lsp
LSP(Language Server Protocl) extension for mrbmacs

+ [mrbmacs-curses](https://github.com/masahino/mruby-bin-mrbmacs-curses)
+ [mrbmacs-gtk](https://github.com/masahino/mruby-bin-mrbmacs-gtk)

## Configuration

example of ~/.mrbmacsrc
```
@ext.config['lsp'] = {
  "ruby" => {
    "command" => "solargraph",
    "options" => {"args" => ["stdio"]}
  },
  "cpp" => {
    "command" => "cquery",
    "options" => {
      "initializationOptions" => {"cacheDirectory" => "/tmp/cquery/cache"}
    }
  },
}
```
