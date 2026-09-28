let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  root = lock.nodes.${lock.root or ""} or { };
  input = root.inputs.nixpkgs or null;
  node = if builtins.isString input then lock.nodes.${input} or { } else { };
  source = node.locked or { };
  original = node.original or { };
  isNixpkgs =
    value:
    (value.type or null) == "github"
    && (value.owner or null) == "NixOS"
    && (value.repo or null) == "nixpkgs";
  matches = pattern: value: builtins.isString value && builtins.match pattern value != null;
  onlyFields = fields: value: builtins.all (key: builtins.elem key fields) (builtins.attrNames value);
in
assert (lock.version or null) == 7 || throw "Catalog base: expected flake.lock version 7";
assert
  isNixpkgs source && isNixpkgs original
  || throw "Catalog base: nixpkgs must be a direct GitHub NixOS/nixpkgs input";
assert
  onlyFields [ "locked" "original" "inputs" "flake" ] node
  && onlyFields [ "type" "owner" "repo" "rev" "narHash" "lastModified" ] source
  && onlyFields [ "type" "owner" "repo" "ref" ] original
  || throw "Catalog base: unsupported nixpkgs input attributes";
assert
  matches "[A-Za-z0-9][A-Za-z0-9._/-]*" (original.ref or null)
  || throw "Catalog base: expected a Nixpkgs reference in nixpkgs.original.ref";
assert
  (import ../flake.nix).inputs.nixpkgs.url == "github:NixOS/nixpkgs/${original.ref}"
  || throw "Catalog base: flake.nix differs from flake.lock; run nix flake update nixpkgs";
assert
  (node.inputs or { }) == { } && (node.flake or true)
  || throw "Catalog base: nixpkgs must be a flake without additional inputs";
assert
  matches "[0-9a-f]{40}" (source.rev or null)
  || throw "Catalog base: expected a full nixpkgs commit revision";
assert
  matches "sha256-[A-Za-z0-9+/]{43}=" (source.narHash or null)
  || throw "Catalog base: expected a SHA-256 SRI hash";
builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${source.rev}.tar.gz";
  sha256 = source.narHash;
}
