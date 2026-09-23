{
  sources = {
    legacy = {
      rev = "b6018f87da91d19d0ab4cf979885689b469cdd41";
      sha256 = "sha256-twXPFqFsrrY5r28Zh7Homgcp2gUMBgQ6WDS98Q/3xFI=";
    };
    previous = {
      rev = "6d663c0533ff269008fb84e45930151e37c99db9";
      sha256 = "sha256-mDNo95riUw8k0MA2Btzj/OuiMcfLKofqIliLYsLbrSY=";
    };
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    "1.24" = {
      source = "legacy";
      package = "go_1_24";
      version = "1.24.13";
      endOfLife = true;
    };
    "1.25" = {
      source = "previous";
      package = "go_1_25";
      version = "1.25.13";
      endOfLife = true;
    };
    "1.26" = {
      source = "current";
      package = "go_1_26";
      version = "1.26.7";
      endOfLife = false;
    };
    "1.27" = {
      source = "current";
      package = "go_1_27";
      version = "1.27.1";
      endOfLife = false;
    };
  };
}
