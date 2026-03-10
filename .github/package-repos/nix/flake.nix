{
  description = "Standalone Nix package source for FileUni CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          fileuni = pkgs.callPackage ./pkgs/fileuni-bin.nix { };
        in {
          inherit fileuni;
          default = fileuni;
        });

      overlays.default = final: prev: {
        fileuni = final.callPackage ./pkgs/fileuni-bin.nix { };
      };
    };
}
