set dotenv-load

build-mrpack *args:
    nix build .#modrinth-pack --print-out-paths {{args}}

generate-readme:
    nix run ./dev#generate-readme -- --manifest pack.toml --output README.md ${CF_API_KEY:+--cf-key "$CF_API_KEY"}

develop:
    nix develop ./dev

check:
    nix flake check ./?dir=dev&submodules=1

addMr *args:
    packwiz modrinth install {{args}}

