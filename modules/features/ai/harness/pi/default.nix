{ self, ... }: {
  flake.homeModules.aiHarnessPi =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = with self.homeModules; [
        aiMcpLocal
      ];

      programs.pi-coding-agent = {
        enable = true;
        extraPackages = with pkgs; [ nodejs ];
        settings = {
          defaultProvider = "llama.cpp";
          defaultModel = "Qwen3.8-27B-Q4-thinking";
          theme = "dark";
          packages = [
            "npm:pi-web-access"
            "npm:pi-mcp-adapter"
          ];
        };
      };

      home.file."${config.programs.pi-coding-agent.configDir}/mcp.json".text = config.aiMcpLocal.mcpJson;
    };
}
