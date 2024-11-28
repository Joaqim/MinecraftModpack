{
  description = "A Flake for developing and building packwiz Minecraft Modpacks";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs@{ flake-parts, systems, self, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({ moduleWithSystem, ... }: {
    systems = import systems;

    perSystem = { system, pkgs, config, lib, ... }: {
      packages =
        let
          # These packs expects to be built using *Double Invocation*
          # Without proper hash, the first build of any pack _will_ fail. 
          # The failed result will tell you the expected `hash` to assign below.
          # When you've set the hash, the next build will return with a `/nix/store` 
          # entry of the modpack, which will also be symlinked into `./result/`.

          modrinth-pack-hash = "sha256-/1M2Ii99X539f9j31LHtMGxEirUxZ3BrVisqmlKIOuk=";
        in
        {
          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = modrinth-pack-hash;
          };
        };

      checks = config.packages;
    };
  });
}
