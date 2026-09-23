{
  sources = {
    previous = {
      rev = "3570433a7194b94b2fee88f7fa8656998d7fda15";
      sha256 = "sha256-Fw58NLuyhhkf59W+BWTNWeljRodUvhYcbzdAprPm4Rc=";
    };
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    "28" = {
      source = "previous";
      package = "docker_28";
      version = "28.5.2";
      endOfLife = true;
    };
    "29" = {
      source = "current";
      package = "docker_29";
      version = "29.8.0";
      endOfLife = false;
    };
  };
}
