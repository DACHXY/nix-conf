-- Mason is not usable on NixOS
return {
  { "williamboman/mason-lspconfig.nvim", enabled = false },
  { "williamboman/mason.nvim", enabled = false },
}
