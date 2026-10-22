{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.rust) toolchain;
  analyzer = config.lmx.capabilities.languageSupport.tools.rust-analyzer;
  components = [
    "rustfmt"
    "clippy"
    "rust-analyzer"
    "rust-src"
  ];
  setup = pkgs.writeShellScript "rust-toolchain-setup" (builtins.readFile ./toolchain-setup.sh);
in
{
  imports = [ ./help.nix ];

  options.lmx.rust.toolchain = lib.mkOption {
    type = lib.types.strMatching "(stable|beta|nightly)(-[0-9]{4}-[0-9]{2}-[0-9]{2})?|[0-9]+[.][0-9]+([.][0-9]+)?";
    default = "stable";
    example = "1.90.0";
    description = ''
      Default rustup toolchain of the development account: a channel, a channel with an archive
      date such as `nightly-2026-10-01`, or a Rust version. Projects with a `rust-toolchain.toml`
      use their own toolchain. The toolchain is installed with rustfmt, Clippy, rust-analyzer and
      the standard library source when the declaration changes.
    '';
  };

  config = {
    environment.systemPackages = [
      pkgs.rustup
      pkgs.gcc
      pkgs.pkg-config
      pkgs.gdb
    ]
    # Another provider replaces the rustup proxy of the same name.
    ++ lib.optional (analyzer.package.outPath != pkgs.rustup.outPath) (lib.hiPrio analyzer.package);

    # Commands from cargo install come first, as rustup's own installer arranges.
    environment.extraInit = ''
      case ":$PATH:" in
        *":$HOME/.cargo/bin:"*) ;;
        *) PATH="$HOME/.cargo/bin:$PATH" ;;
      esac
    '';

    lmx.capabilities.languageSupport = {
      languages.rust.parsers = [ "rust" ];
      # The proxy runs the rust-analyzer of the toolchain that the project selects.
      tools.rust-analyzer = lib.mkDefault {
        package = pkgs.rustup;
        command = "${pkgs.rustup}/bin/rust-analyzer";
        languages = [ "rust" ];
      };
    };

    # The account lingers, so its user manager starts at boot.
    systemd.user.services.rust-toolchain = {
      description = "Default Rust toolchain of the development account";
      wantedBy = [ "default.target" ];
      unitConfig.ConditionUser = config.limanix.user.name;
      path = [
        pkgs.rustup
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setup} ${toolchain} ${lib.concatStringsSep "," components}";
        # A user manager cannot wait for the network: retry, backing off to every ten minutes.
        Restart = "on-failure";
        RestartSec = "10s";
        RestartSteps = 6;
        RestartMaxDelaySec = "10min";
      };
    };
  };
}
