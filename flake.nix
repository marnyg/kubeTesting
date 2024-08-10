{
  description = "NixOS configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-root.url = "github:srid/flake-root";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    just-flake.url = "github:juspay/just-flake";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      {
        systems = [ "x86_64-linux" ];
        imports = [
          inputs.treefmt-nix.flakeModule
          inputs.flake-root.flakeModule
          inputs.pre-commit-hooks-nix.flakeModule
          # inputs.process-compose-flake.flakeModule
          inputs.just-flake.flakeModule
          ./dev-shells.nix
        ];
      };
}
