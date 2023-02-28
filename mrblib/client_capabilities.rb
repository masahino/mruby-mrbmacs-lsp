module Mrbmacs
  # LspExtension
  class LspExtension < Extension
    def self.client_capabilities
      {
        workspace: {
          applyEdit: true,
          # workspaceEdit:
          # didChangeConfiguration:
          # didChangeWatchedFiles:
          # symbol:
          # executeCommand:
          # workspaceFolders:
          configuration: false
          # semanticTokens:
          # fileOperations:
          # inlineValue:
          # inlayHint:
          # diagnostics:
        },
        textDocument: {
          synchronization: {
            dynamicRegistration: false,
            willSave: false,
            willSaveWaitUntil: false,
            didSave: true
          },
          completion: {
            dynamicRegistration: false,
            completionItem: {
              snippetSupport: false,
              commitCharactersSupport: false,
              # documentationFormat
              deprecatedSupport: false,
              preselectSupport: false
              # tagSupport:
            },
            insertReplaceSupport: true
            # resolveSupport:
            # insertTextModeSupport:
            # labelDetailsSupport:
          },
          hover: {
            dynamicRegistration: false,
            contentFormat: ['plaintext']
          },
          signatureHelp: {
            dynamicRegistration: false,
            signatureInformation: {
              documentationFormat: ['plaintext'],
              parameterInformation: {
                labelOffsetSupport: false
              },
              activeParameterSupport: false
            },
            contextSupport: false
          },
          declaration: {
            dynamicRegistration: false,
            linkSupport: false
          },
          definition: {
            dynamicRegistration: false,
            linkSupport: false
          },
          typeDefinition: {
            dynamicRegistration: false,
            linkSupport: false
          },
          implementation: {
            dynamicRegistration: false,
            linkSupport: false
          },
          references: {
            dynamicRegistration: false
          },
          # documentHighlight:
          # documentSymbol:
          # codeAction:
          # codeLens:
          # documentLink:
          # colorProvider:
          formatting: {
            dynamicRegistration: false
          },
          rangeFormatting: {
            dynamicRegistration: false
          },
          onTypeFormatting: {
            dynamicRegistration: false
          },
          rename: {
            dynamicRegistration: false,
            prepareSupport: false,
            # prepareSupportDefaultBehavior
            honorsChangeAnnotations: false
          },
          publishDiagnostics: {
            relatedInformation: false,
            # tagSupport:
            versionSupport: false,
            codeDescriptionSupport: false,
            dataSupport: false
          }
          # foldingRange:
          # selectionRange:
          # linkedEditingRange:
          # callHierarchy:
          # semanticTokens:
          # moniker:
          # typeHierarchy:
          # inlineValue:
          # inlayHint:
          # diagnostic:
        }
      }
    end
  end
end
