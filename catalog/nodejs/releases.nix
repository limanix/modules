{
  sources = {
    legacy = {
      rev = "d8e0934a9d1930216faff15fc833705a1e534c9c";
      sha256 = "sha256-AQntWugziZX1B8MSdNWiBjW4deyAGQeEpHs8ph3Ziig=";
    };
    previous = {
      rev = "79dd4ac915e3acaf434b2974af214a7e90df2e50";
      sha256 = "sha256-X0pBoIkVuoOCkUv0m/wmVbJAXBj43FTE/m1+YqEpeF0=";
    };
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    "23" = {
      source = "legacy";
      package = "nodejs_23";
      version = "23.11.0";
      endOfLife = true;
    };
    "24" = {
      source = "current";
      package = "nodejs_24";
      version = "24.20.0";
      endOfLife = false;
    };
    "25" = {
      source = "previous";
      package = "nodejs_25";
      version = "25.9.0";
      endOfLife = true;
    };
    "26" = {
      source = "current";
      package = "nodejs_26";
      version = "26.9.0";
      endOfLife = false;
      npm = {
        version = "12.1.0";
        hash = "sha512-Fyhu62pNx70YCs/5+dEmJQTFVmSKwvo5CA0qvBkGDRpob42MJ6G2RQ2tdxeKM4nYnIZDqkYAxEgqtoejn9QGtQ==";
      };
    };
  };
}
