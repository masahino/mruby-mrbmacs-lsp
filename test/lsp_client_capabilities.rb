assert('client capabilities advertise basic code action support') do
  capability = Mrbmacs::LspExtension.client_capabilities[:textDocument][:codeAction]

  assert_equal false, capability[:dynamicRegistration]
  assert_equal false, capability.key?(:resolveSupport)
end
