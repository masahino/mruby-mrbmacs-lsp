# mruby-mrbmacs-lsp
LSP (Language Server Protocol) extension for mrbmacs.

+ [mrbmacs-curses](https://github.com/masahino/mruby-bin-mrbmacs-curses)
+ [mrbmacs-gtk](https://github.com/masahino/mruby-bin-mrbmacs-gtk)
+ [mrbmacs-termbox](https://github.com/masahino/mruby-bin-mrbmacs-termbox)
+ [mrbmacs-cocoa](https://github.com/masahino/mruby-bin-mrbmacs-cocoa)

## Configuration

Example for `~/.config/mrbmacs/init.rb` (or
`$XDG_CONFIG_HOME/mrbmacs/init.rb` when set):
```
@config.ext['lsp'] = {
  "ruby" => {
    "command" => "solargraph",
    "options" => {"args" => ["stdio"]}
  },
  "cpp" => {
    "command" => "clangd",
    "options" => {}
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
|declaration    |Yes|lsp_declaration|
|definition     |Yes|lsp_definition|
|typeDefinition |Yes|lsp_type_definition|
|implementation |Yes|lsp_implementation|
|references     |Yes|lsp_references|
|documentHighlight|No|
|documentSymbol |Yes|lsp_document_symbol|
|codeAction |Yes|lsp_code_action|
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
|foldingRange|Request only|lsp_folding_range|

Document Symbol supports `SymbolInformation[]` responses. Hierarchical
`DocumentSymbol[]` responses are not supported.

Code actions may be returned as direct `Command` values or as `CodeAction`
values containing `edit` and/or `command`. When both are present, the edit is
applied before the command is executed. Disabled actions are not executed.
Commands are sent with `workspace/executeCommand`. Server requests for
`workspace/applyEdit` are handled and answered with the original request ID.

Workspace edits using `changes` are supported. `documentChanges` is not
currently supported. A `codeAction/resolve` request can be sent when a server
advertises it, but resolved responses are not yet applied.

## screenshot

![formatting](https://user-images.githubusercontent.com/381912/60769054-694c6200-a106-11e9-8fed-f7cd0a10f105.gif)
