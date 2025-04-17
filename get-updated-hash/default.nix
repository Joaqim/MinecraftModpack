{pkgs}:
pkgs.writeShellApplication {
  name = "get-updated-hash";
  text = ''
    set +e
    output="$(nix flake check . --quiet 2>&1)"

    hash_candidate=$(echo "$output" | tail -c 52 | xargs)

    if [[ "$hash_candidate" =~ ^sha256-[A-Za-z0-9\\/+]{43}= ]]; then
      echo "$hash_candidate"
      exit 0
    fi
    exit 1
  '';
}
