{
  sources = {
    legacy = {
      rev = "d8e0934a9d1930216faff15fc833705a1e534c9c";
      sha256 = "sha256-AQntWugziZX1B8MSdNWiBjW4deyAGQeEpHs8ph3Ziig=";
    };
    previous = {
      rev = "a3116115851d68b8952a2a4221cc25a84e56b532";
      sha256 = "sha256-Z+vUNbfd2FIKkWOTkcT7RYlh3oFCnig/d2eXD1SWf2E=";
    };
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    # Upstream maintenance status for these lines has not been confirmed.
    "0.40" = {
      source = "legacy";
      package = "k9s";
      version = "0.40.10";
      endOfLife = null;
    };
    "0.50" = {
      source = "previous";
      package = "k9s";
      version = "0.50.18";
      endOfLife = null;
    };
    "0.51" = {
      source = "current";
      package = "k9s";
      version = "0.51.0";
      endOfLife = null;
    };
  };
}
