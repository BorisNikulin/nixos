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
          defaultModel = "Qwen3.8-27B-Q4";
          theme = "dark";
          packages = [
            "npm:pi-web-access"
            "npm:pi-mcp-adapter"
          ];
        };

        models = {
          providers."llama.cpp".modelOverrides = {
            "Qwen3.8-27B-Q4" = {
              reasoning = true;
              thinkingLevelMap = {
                off = "off";
                minimal = null;
                low = "low";
                medium = "medium";
                high = null;
                xhigh = "xhigh";
                max = null;
              };
              compat = {
                thinkingFormat = "chat-template";
                chatTemplateKwargs = {
                  enable_thinking = {
                    "$var" = "thinking.enabled";
                  };
                  preserve_thinking = true;
                  reasoning_effort = {
                    "$var" = "thinking.effort";
                    omitWhenOff = true;
                  };
                };
              };
            };
          };
        };
      };

      home.file."${config.programs.pi-coding-agent.configDir}/mcp.json".text = config.aiMcpLocal.mcpJson;
    };
}
