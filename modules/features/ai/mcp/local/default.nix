{ ... }: {
  flake.homeModules.aiMcpLocal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.aiMcpLocal = {
        mcpConfig = lib.mkOption {
          description = ''
            Local MCP server definitions in the mcp.json schema.
            Make sure to import this module to add required programs to PATH.
            '';
          default = {
            mcpServers.nixos = {
              command = "mcp-nixos";
            };
          type = lib.types.attrs;
          readOnly = true;
          };
        };

        mcpJson = lib.mkOption {
          description = "aiMcpLocal.mcpConfig rendered as a JSON string.";
          default = builtins.toJSON config.aiMcpLocal.mcpConfig;
          type = lib.types.str;
          readOnly = true;
        };
      };

      config = {
        home.packages = [ pkgs.mcp-nixos ];
      };
    };
}
