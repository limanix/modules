{ pkgs, hasPackage, ... }:
builtins.all hasPackage [
  pkgs.awscli2
  pkgs.google-cloud-sdk
]
