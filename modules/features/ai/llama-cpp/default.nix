{ self, inputs, ... }: {
  flake.nixosModules.llamaCpp =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      models = {
        "*" = {
          # Only allow 1 model context to run at a time to maximize KV cache for that session.
          parallel = "1";
          sleep-idle-seconds = "600";
        };

        # Thinking effort is instruction/prompt based.
        # See pi harness on sending the correct chat template kwargs.
        "Qwen3.8-27B-Q4" = {
          hf = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
          # https://unsloth.ai/docs/models/qwen3.8#qwen3.8-27b-settings
          temperature = "1.0";
          top-p = "0.95";
          top-k = "20";
          min-p = "0.0";

          # tps speed up at slight vram cost
          spec-type = "draft-mtp";
          spec-default = true;
          reasoning-preserve = true;

          # Further ram reductions to allow other apps to run
          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
          # Specify context size instead of taking as much as it can
          ctx-size = "81920";
          # Disable image to latent space/token model.
          # If you need to input images, consider duping this model preset and enabling.
          mmproj-auto = false;
          # Halve prompt cache for lower cache hit rate
          cache-ram = "4096";
        };
      };
      modelsFormat = pkgs.formats.ini { };
      modelsIni = modelsFormat.generate "llama-cpp-models.ini" models;
    in
    {
      environment.systemPackages = with pkgs; [
        llama-cpp-rocm
      ];

      services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp-rocm;
        settings = {
          models-preset = modelsIni;
        };
      };

      # Expose for pi harness.
      # TODO: Consider moving to pi harness nix module.
      environment.sessionVariables.LLAMA_BASE_URL = "http://${config.services.llama-cpp.settings.host}:${lib.toString config.services.llama-cpp.settings.port}";
    };
}
