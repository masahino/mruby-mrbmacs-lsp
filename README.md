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

## Supported Protocol features

### Language Features
| Message | Status | Command
----------|:------:|--------
|completion     |Yes|-
|completion resolve|No|
|hover          |Yes|
|signatureHelp  |Yes|
|declaration    |Yes|lsp_goto_declaration|
|definition     |Yes|lsp_goto_definition|
|typeDefinition |No||
|implementation |No||
|references     |No||
|documentHighlight|No|
|documentSymbol |No|
|codeAction |No|
|codeLens |No|
|codeLens resolve |No|
|documentLink |No|
|documentLink resolve |No|
|documentColor |No|
|colorPresentation |No|
|formatting |No|
|rangeFormatting |No|
|onTypeFormatting |No|
|rename |No|
|prepareRename |No|
|foldingRange|No|-
