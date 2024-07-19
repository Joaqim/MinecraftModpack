{
  description = "FabricModpack";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    packwiz2nix = {
      url = "github:getchoo/packwiz2nix/rewrite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, systems, packwiz2nix, self, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({ moduleWithSystem, ... }: {
    systems = import systems;

    perSystem = { system, pkgs, config, lib, ... }: {
      _module.args = {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (import ./nix/overlay.nix)
          ];
        };
      };

      packages =
        let
          packwiz2nixLib = inputs.packwiz2nix.lib.${system};
        in
        {
          ## These builds expects Double Invocation
          # Invalid will be invalid newer builds ( use placeholder sah with `lib.fakeSha256` ) 
          # The failed result will tell you the expected `hash` to place in their respective place.
          # When you've set the hash, the build will return with a `/nix/store` entry of the results, 
          # symlinked as `./result`.
          packwiz-server = packwiz2nixLib.fetchPackwizModpack {
            manifest = "${self}/pack.toml";
            hash = "sha256-lvU6MFCpY8D14SxREjQRdEheHkOMiXrdFWgLdaD1lPI=";
            side = "server";
          };

          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = "sha256-4D1scaGPv84ej/cwXc7WTU+8C1W0Asy6xIwvjElDA9w=";
          };

          # Not used for anything right now
          # packwiz-client = packwiz2nixLib.fetchPackwizModpack {
          #   manifest = "${self}/pack.toml";
          #   hash = "sha256-cd3NdmkO3yaLljNzO6/MR4Aj7+v1ZBVcxtL2RoJB5W8=";
          #   side = "client";
          # };
        };

      checks = config.packages;
    };
  });
}
