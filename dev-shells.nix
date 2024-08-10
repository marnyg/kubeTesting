{ ... }: {
  perSystem = { config, pkgs, ... }: {
    config = {
      just-flake.features = {
        treefmt.enable = true;
        rust.enable = true;
        convco.enable = true;
        hello = {
          enable = true;
          justfile = ''
            hello:
            echo Hello World
            a:
            ${pkgs.argocd}/bin/argocd app list
          '';
        };
      };

      devShells.default = pkgs.mkShell
        {
          shellHook = config.pre-commit.installationScript;
          inputsFrom = [ config.just-flake.outputs.devShell ];
        };

      pre-commit = {
        settings.hooks.nixpkgs-fmt.enable = true;
        settings.hooks.deadnix.enable = true;
        settings.hooks.nil.enable = true;
        settings.hooks.statix.enable = true;
        settings.hooks.typos.enable = true;
        settings.hooks.commitizen.enable = true;
        settings.hooks.yamllint.enable = true;
        settings.hooks.yamllint.settings.preset = "relaxed";
        settings.hooks.statix.settings.format = "stderr";
        settings.hooks.typos.settings.ignored-words = [ "noice" ];
        settings.hooks.typos.stages = [ "manual" ];
      };


      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        package = pkgs.treefmt;

        programs.nixpkgs-fmt.enable = true;
        programs.yamlfmt.enable = true;
      };
    };
  };
}
