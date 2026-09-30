{
  sources = {
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    # https://www.postgresql.org/support/versioning/ (checked 2026-09-30).
    "16" = {
      source = "current";
      package = "postgresql_16";
      version = "16.15";
      endOfLife = false;
    };
    "17" = {
      source = "current";
      package = "postgresql_17";
      version = "17.11";
      endOfLife = false;
    };
    "18" = {
      source = "current";
      package = "postgresql_18";
      version = "18.6";
      endOfLife = false;
    };
  };
}
