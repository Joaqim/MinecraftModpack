{
  description = "A Flake for developing and building packwiz Minecraft Modpacks";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    flake-parts,
    self,
    systems,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
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
          # Run `nix flake check ./?dir=dev&submodules=1` will give you the correct hash to assign below.
          # When you've set the hash, the next build will return with a `/nix/store` location
          # of the entry of the modpack, which will also be symlinked into `./result/`.
          modrinth-pack-hash = "sha256-IghKmISyA6t/j+MYxz2nLvu8siE15qzXa8IIDIpxVjQ=";
        in {
          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = modrinth-pack-hash;
          };
        };

        checks = config.packages;
      };
    };
}
