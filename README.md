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
|typeDefinition |No|lsp_type_definition|
|implementation |No|lsp_implementation|
|references     |No|lsp_references|
|documentHighlight|No|
|documentSymbol |No|
|codeAction |No|
|codeLens |No|
|codeLens resolve |No|
|documentLink |No|
|documentLink resolve |No|
|documentColor |No|
|colorPresentation |No|
|formatting |Yes|lsp_formatting|
|rangeFormatting |Yes|lsp_range_formatting|
|onTypeFormatting |No|
|rename |Yes|lsp_rename|
|prepareRename |No|
|foldingRange|No|-

## screenshot

![formatting](https://user-images.githubusercontent.com/381912/60769054-694c6200-a106-11e9-8fed-f7cd0a10f105.gif)
