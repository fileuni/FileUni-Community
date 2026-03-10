{ pkgs ? import <nixpkgs> { } }:
{
  fileuni = pkgs.callPackage ./pkgs/fileuni-bin.nix { };
}
