{ ... }: {
  flake.homeModules.aiHarnessPi = { pkgs, ... }: {
    programs.pi-coding-agent = {
      enable = true;
      extraPackages = with pkgs; [ nodejs ];
      # No static "models" provider: pi's built-in "llama.cpp" provider is
      # configured via the LLAMA_BASE_URL session variable (set by the
      # nixos llama-cpp module) and live-detects the model list + real
      # context window from the router's /v1/models endpoint.
      settings = {
        defaultProvider = "llama.cpp";
        defaultModel = "Qwen3.8-27B-Q4-thinking";
        theme = "dark";
        # The llama-cpp model runs without its vision projector (mmproj-auto
        # = false in the llama-cpp module) to save VRAM, so images can't be sent.
        images.blockImages = true;
        packages = [ "npm:pi-web-access" ];
      };
    };
  };
}
