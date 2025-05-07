{
  description = "FabricModpack Dev";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    update-hash = {
      url = "github:Joaqim/update-hash";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
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
        self',
        system,
        pkgs,
        inputs',
        lib,
        ...
      }: let
        inherit (inputs'.update-hash.packages) update-hash;
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.poetry2nix.overlays.default];
        };

        apps.update-hash = {
          type = "app";
          program = lib.getExe update-hash;
        };

        packages.generate-readme = pkgs.callPackage ../generate-readme {};

        pre-commit = {
          settings = {
            src = ./..;
            hooks = {
              changie = {
                enable = true;
                entry = "task bump";
                fail_fast = true;
                pass_filenames = false;
                stages = ["pre-push"];
              };
              update-hash = {
                enable = true;
                entry = "${lib.getExe update-hash} run --amend";
                fail_fast = true;
                files = "(\\.toml$|\\.nix$|^flake.lock$)";
                pass_filenames = false;
                package = update-hash;
                stages = ["pre-push"];
              };
              check-flake = {
                enable = true;
                entry = "nix flake check";
                always_run = true;
                pass_filenames = false;
                after = ["update-hash"];
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
              update-hash
              changie # Automatic changelog tool for tags
              go-task
            ];
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };
      };
    };
}
