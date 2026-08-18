{ self, inputs, ... }: {
  flake.nixosModules.llamaCpp =
    { pkgs, lib, ... }:
    let
      models = {
        "Qwen3.8-27B-q4-thinking" = {
          hf = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
          chat-template-kwargs = builtins.toJSON {
            reasoning_effort = "low";
          };
          temperature = "1.0";
          top-p = "0.95";
          top-k = "20";
          min-p = "0.0";
          spec-type = "draft-mtp";
          spec-default = true;
          reasoning-preserve = true;
          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
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
          parallel = 1;
        };
      };
    };
}
