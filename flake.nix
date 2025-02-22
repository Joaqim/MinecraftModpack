{
  description = "A Flake for developing and building packwiz Minecraft Modpacks";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      moduleWithSystem,
      withSystem,
      ...
    }: {
      systems = import systems;

      perSystem = {
        system,
        pkgs,
        config,
        lib,
        ...
      }: {
        packages = let
          # These packs expects to be built using *Double Invocation*
          # Without proper hash, the first build of any pack _will_ fail.
          # Run `just check` will give you the correct hash to assign below.
          # When you've set the hash, the next build will return with a `/nix/store` location
          # of the entry of the modpack, which will also be symlinked into `./result/`.
          modrinth-pack-hash = "sha256-Kl1Rt5/BLduGSqAMPDyYgO4RsYu4rWiE5ULTPaZ88eQ=";
        in {
          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = modrinth-pack-hash;
          };
        };
        checks = config.packages;
      };

      flake.nixosModules.minecraft-server = moduleWithSystem (
        perSystem @ {config}: {
          config.services.docker-minecraft-server.modrinth-modpack = perSystem.config.packages.modrinth-pack;
          imports = [./modules/docker-minecraft-server.nix];
        }
      );
      /*
      flake.nixosConfigurations.container = withSystem "x86_64-linux" (ctx@{ config, inputs', ... }:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          packages = config.packages;
          inherit inputs inputs';
        };
        modules = [
          ({config, pkgs, ...}: {
            # Only allow this to boot as a container
            boot.isContainer = true;

            # Allow minecraft through the firewall
            networking.firewall.allowedTCPPorts = [ 25565 ];
          })
        ];
      });
      */
    });
}
