{
  sources = {
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    "3.12" = {
      source = "current";
      package = "python312";
      version = "3.12.14";
      endOfLife = false;
    };
    "3.13" = {
      source = "current";
      package = "python313";
      version = "3.13.15";
      endOfLife = false;
    };
    "3.14" = {
      source = "current";
      package = "python314";
      version = "3.14.7";
      endOfLife = false;
    };
  };
}
