{ self, inputs, ... }: {
  flake.nixosModules.recyclarr =
    { config, lib, ... }:
    let
      radarrApiKey = config.sops.secrets."arr/radarr/api_key".path;
      sonarrApiKey = config.sops.secrets."arr/sonarr/api_key".path;
      radarrUrl = "http://127.0.0.1:${toString config.services.radarr.settings.server.port}";
      sonarrUrl = "http://127.0.0.1:${toString config.services.sonarr.settings.server.port}";
    in
    {
      config = {
        services.recyclarr = {
          enable = true;

          configuration = {
            radarr.radarr = {
              base_url = radarrUrl;
              api_key = {
                _secret = radarrApiKey;
              };
              delete_old_custom_formats = true;
              quality_definition.type = "movie";
              media_naming = {
                folder = "default";
                movie = {
                  rename = true;
                  standard = "jellyfin-imdb";
                };
              };
              # CFs for propers/repacks handles this
              # so other CFs and it's own CFs scores can contribute to propers/repacks upgrade.
              media_management = {
                propers_and_repacks = "do_not_prefer";
              };
              quality_profiles = [
                {
                  trash_id = "722b624f9af1e492284c4bc842153a38"; # [Anime] Remux-1080p
                  reset_unmatched_scores.enabled = true;
                }
                {
                  trash_id = "fd161a61e3ab826d3a22d53f935696dd"; # Remux + WEB 2160p
                  reset_unmatched_scores.enabled = true;
                }
                {
                  trash_id = "64fb5f9858489bdac2af690e27c8f42f"; # UHD Bluray + WEB
                  reset_unmatched_scores.enabled = true;
                }
              ];
              custom_format_groups.add = [
                # prefer dolby vision (nvidia shield)
                { trash_id = "1616617ab3a14397a2b2321bcbda44d1"; } # [HDR Formats] DV Boost
                {
                  trash_id = "f4f1474b963b24cf983455743aa9906c"; # [Optional] Movie Versions
                  select = [
                    "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                  ];
                }
                # opt-in unwanted CFs (default score is negative)
                {
                  trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; # [Unwanted] Unwanted Formats
                  select = [
                    "ae9b7c9ebde1f3bd336a8cbd1ec4c5e5" # No-RlsGroup
                    "7357cf5161efbf8c4d5d0c30b4815ee2" # Obfuscated
                  ];
                }
              ];
              custom_formats = [
                {
                  trash_ids = [ "e7718d7a3ce595f289bfee26adc178f5" ]; # Repack/Proper
                  score = 5;
                  assign_scores_to = [
                    { name = "Remux + WEB 2160p"; }
                    { name = "UHD Bluray + WEB"; }
                  ];
                }
                {
                  trash_ids = [ "ae43b294509409a6a13919dedd4764c4" ]; # Repack2
                  score = 6;
                  assign_scores_to = [
                    { name = "Remux + WEB 2160p"; }
                    { name = "UHD Bluray + WEB"; }
                  ];
                }
                {
                  trash_ids = [ "5caaaa1c08c1742aa4342d8c4cc463f2" ]; # Repack3
                  score = 7;
                  assign_scores_to = [
                    { name = "Remux + WEB 2160p"; }
                    { name = "UHD Bluray + WEB"; }
                  ];
                }
              ];
            };

            sonarr.sonarr = {
              base_url = sonarrUrl;
              api_key = {
                _secret = sonarrApiKey;
              };
              delete_old_custom_formats = true;
              quality_definition.type = "series";
              media_naming = {
                series = "jellyfin-tvdb";
                season = "default";
                episodes = {
                  rename = true;
                  standard = "default";
                  daily = "default";
                  anime = "default";
                };
              };
              media_management = {
                propers_and_repacks = "do_not_prefer";
              };
              quality_profiles = [
                {
                  trash_id = "d1498e7d189fbe6c7110ceaabb7473e6"; # WEB-2160p
                  reset_unmatched_scores.enabled = true;
                }
                {
                  trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
                  reset_unmatched_scores.enabled = true;
                }
                {
                  trash_id = "20e0fc959f1f1704bed501f23bdae76f"; # [Anime] Remux-1080p
                  reset_unmatched_scores.enabled = true;
                }
              ];
              custom_format_groups.add = [
                {
                  trash_id = "e9a1944a254e6f8a9da63083f7ae15cb"; # [Audio] Audio Formats
                  select_all = true;
                  assign_scores_to = [
                    { name = "WEB-2160p"; }
                    { name = "WEB-1080p"; }
                  ];
                }
                # prefer dv though this only matters for some high budget shows
                { trash_id = "e0b2774083df4265f25c9e5bc6c80940"; } # [HDR Formats] DV Boost
                # same opt-in unwanted CFs as radarr
                {
                  trash_id = "59c3af66780d08332fdc64e68297098f"; # [Unwanted] Unwanted Formats
                  select = [
                    "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                    "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                  ];
                }
              ];
              custom_formats = [
                {
                  trash_ids = [ "ec8fa7296b64e8cd390a1600981f3923" ]; # Repack/Proper
                  score = 5;
                  assign_scores_to = [
                    { name = "WEB-2160p"; }
                    { name = "WEB-1080p"; }
                  ];
                }
                {
                  trash_ids = [ "eb3d5cc0a2be0db205fb823640db6a3c" ]; # Repack2
                  score = 6;
                  assign_scores_to = [
                    { name = "WEB-2160p"; }
                    { name = "WEB-1080p"; }
                  ];
                }
                {
                  trash_ids = [ "44e7c4de10ae50265753082e5dc76047" ]; # Repack3
                  score = 7;
                  assign_scores_to = [
                    { name = "WEB-2160p"; }
                    { name = "WEB-1080p"; }
                  ];
                }
              ];
            };
          };
        };

      };
    };
}
