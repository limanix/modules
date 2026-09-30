{
  sources = {
    legacy = {
      rev = "a3116115851d68b8952a2a4221cc25a84e56b532";
      sha256 = "sha256-Z+vUNbfd2FIKkWOTkcT7RYlh3oFCnig/d2eXD1SWf2E=";
    };
    previous = {
      rev = "350fa6ec55642bd2234c9edb3e149eb3a1ba545f";
      sha256 = "sha256-c4LiLCCS+A8XvRXykGn52yjIDvlPgVsvfn2bCqa81RQ=";
    };
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    # Latest maintained minors on 2026-09-30: 3.22 and 4.3.
    # https://helm.sh/docs/topics/version_skew/#supported-versions
    "3.20" = {
      source = "legacy";
      package = "kubernetes-helm";
      version = "3.20.2";
      endOfLife = true;
    };
    "4.2" = {
      source = "previous";
      package = "kubernetes-helm";
      version = "4.2.4";
      endOfLife = true;
    };
    "4.3" = {
      source = "current";
      package = "kubernetes-helm";
      version = "4.3.0";
      endOfLife = false;
    };
  };
}
