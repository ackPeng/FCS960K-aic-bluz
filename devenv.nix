{ pkgs, lib, config, ... }:

{
  imports = lib.optional (builtins.pathExists ./.github/local/devenv.nix) ./.github/local/devenv.nix;

  packages = with pkgs; [
    bash-completion
  ];

  git-hooks = {
    hooks = {
      commitizen.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;
    };
  };

  starship.enable = true;
}
