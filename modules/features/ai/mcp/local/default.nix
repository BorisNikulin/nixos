{ ... }: {
  flake.homeModules.aiMcpLocal =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # Single source of truth for the mcp.json contents. mcpConfig is readOnly,
      # so its value is always this default; mcpJson renders the same value.
      mcpConfig = {
        mcpServers.nixos = {
          command = "mcp-nixos";
        };
      };
    in
    {
      options.aiMcpLocal = {
        mcpConfig = lib.mkOption {
          description = ''
            Local MCP server definitions in the mcp.json schema.
            Make sure to import this module to add required programs to PATH.
          '';
          default = mcpConfig;
          type = lib.types.attrs;
          readOnly = true;
        };
        mcpJson = lib.mkOption {
          description = "aiMcpLocal.mcpConfig rendered as a JSON string.";
          default = builtins.toJSON mcpConfig;
          type = lib.types.str;
          readOnly = true;
        };
      };

      config = {
        home.packages = [ pkgs.mcp-nixos ];
      };
    };
}
