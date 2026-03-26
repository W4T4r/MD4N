{
  pkgs,
  lib,
  user,
  ...
}: {
  programs = {
    home-manager.enable = true;
    gitui.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    starship = {
      enable = true;
    };

    git = {
      enable = true;
      settings =
        {
          user.name = user.gitName or user.fullname;
          core.editor = "nvim";
          color.ui = "auto";
        }
        // lib.optionalAttrs ((user ? gitEmail) && user.gitEmail != "") {
          user.email = user.gitEmail;
        };
    };

    kitty.enable = true;

    nvchad = {
      enable = true;
      hm-activation = true;
      backup = false;
      extraPackages = with pkgs; [
        nodePackages.bash-language-server
        docker-compose-language-service
        dockerfile-language-server
        emmet-language-server
        nixd
        (python3.withPackages (ps:
          with ps; [
            python-lsp-server
            flake8
          ]))
      ];
      chadrcConfig = ''
        local M = {}
        M.base46 = {
            theme = "catppuccin",
        }
        return M
      '';
    };
  };
}
