{
  sources = {
    "1.95" = {
      rev = "70bf138dfe687985e108978de2c4c60e9f0adf32";
      sha256 = "sha256-zYRBEX/lrt69yizRwRBytPWuO4VMOkjRmv+R2pi3mBM=";
    };
    "1.96" = {
      rev = "ef2a4dc29159b41658eed178a4c1ec07920fc2e6";
      sha256 = "sha256-f87mnaiFXAa9O4V4v8r+s8djctGDr75nan/KuwFKaPw=";
    };
    "1.97" = {
      rev = "ad2d6648d4f842ca6f0c0385973424c549d3d960";
      sha256 = "sha256-5yko1NPlzNDhFtwyadqEp6tDDlM8Wvc8vf582mD+7Oo=";
    };
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    "1.95" = {
      source = "1.95";
      package = "rust_1_95";
      version = "1.95.0";
      endOfLife = true;
    };
    "1.96" = {
      source = "1.96";
      package = "rust_1_96";
      version = "1.96.1";
      endOfLife = true;
    };
    "1.97" = {
      source = "1.97";
      package = "rust_1_97";
      version = "1.97.1";
      endOfLife = true;
    };
    "1.98" = {
      source = "current";
      package = "rust_1_98";
      version = "1.98.1";
      endOfLife = false;
    };
  };
}
