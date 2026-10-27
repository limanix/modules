{
  name = "python";
  title = "Python";
  directory = ./.;
  main = "runtime";
  tool = "pyright";
  parsers.python = [ "python" ];
  packages = import ./packages.nix;
  provider =
    { pkgs, ... }:
    {
      package = pkgs.pyright;
      command = "${pkgs.pyright}/bin/pyright-langserver";
      args = [ "--stdio" ];
      languages = [ "python" ];
    };
  systemPackages =
    {
      version,
      tools,
      pkgs,
      lib,
      priority,
    }:
    [
      (lib.setPrio priority tools.runtime)
      (lib.setPrio priority tools.virtualenv)
      (pkgs.runCommandLocal "python-${version}-command" { } ''
        mkdir -p "$out/bin"
        ln -s "${tools.runtime}/bin/python${tools.python.pythonVersion}" "$out/bin/python-${version}"
      '')
    ];
  commands = [
    "python"
    "virtualenv"
    "pyright"
  ];
  versioned = line: [ "python-${line}" ];
  tips = [
    {
      label = "New venv";
      text = "python -m venv .venv && source .venv/bin/activate";
    }
    {
      label = "Install";
      text = "python -m pip install -r requirements.txt";
    }
    {
      label = "Leave";
      text = "deactivate";
    }
  ];
  page = "modules/python";
}
