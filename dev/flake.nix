{
  description = "FabricModpack Dev";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    selfup = {
      url = "github:kachick/selfup/v1.1.9";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        nix-github-actions.follows = "";
        treefmt-nix.follows = "";
      };
    };

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;

      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      perSystem = {
        config,
        system,
        pkgs,
        inputs',
        lib,
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.poetry2nix.overlays.default];
        };

        packages = {
          generate-readme = pkgs.callPackage ../generate-readme {};
          get-updated-hash = pkgs.callPackage ../get-updated-hash {};
        };
        pre-commit = {
          settings = {
            src = ./..;
            hooks = {
              update-hash = let
                selfup = inputs'.selfup.packages.default;
              in {
                enable = true;
                entry = "${lib.getExe selfup} run flake.nix >/dev/null";
                files = "(^\\.nix$|^flake\\.lock$|^\\.toml$)";
                pass_filenames = false;
                name = "update-hash";
                package = selfup;
                extraPackages = with pkgs; [coreutils];
                stages = ["pre-push"];
              };
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nvfetcher
              packwiz
              poetry
              inputs'.selfup.packages.default
            ];
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };
      };
    };
}
