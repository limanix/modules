{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  releases = import ./releases.nix;
  selected = builtins.sort lib.versionOlder config.lmx.internal.astronvim.versions;
  versions = map (line: releases.${line}.version) selected;
in
{
  limanix.help.astronvim = {
    title = "AstroNvim ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [
      "nvim"
      "rg"
      "fd"
      "tree-sitter"
    ];
    tips = [
      {
        label = "Open";
        text = "nvim .";
      }
      {
        label = "Shortcuts";
        text = "Press Space and pause for the shortcut hints.";
      }
      {
        label = "Resume";
        text = '':lua require("resession").load("Last Session", { reset = true })'';
      }
      {
        label = "Add parser";
        text = ":TSInstall LANGUAGE";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/astronvim/README.html";
  };
}
