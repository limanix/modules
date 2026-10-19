# Release records for the shared resolver tests. Lines 3 to 8 are invalid, one reason each.
{
  "1.9" = {
    source = "base";
    package = "tool";
    endOfLife = true;
  };
  "1.10" = {
    source = "unstable";
    package = "tool";
    endOfLife = false;
  };
  "2" = {
    source = {
      rev = "0123456789abcdef0123456789abcdef01234567";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    buildSource = {
      rev = "89abcdef0123456789abcdef0123456789abcdef";
      sha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
    };
    package = "tool";
    version = "2.0.1";
    endOfLife = null;
  };
  "3" = {
    source = "base";
    package = "tool";
    version = "3.0.0";
    endOfLife = false;
  };
  "4" = {
    source = {
      rev = "0123456789abcdef0123456789abcdef01234567";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    package = "tool";
    endOfLife = false;
  };
  "5" = {
    source = "nixos-26.05";
    package = "tool";
    endOfLife = false;
  };
  "6" = {
    source = {
      rev = "0123456";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    package = "tool";
    version = "6.0.0";
    endOfLife = false;
  };
  "7" = {
    source = "base";
    endOfLife = false;
  };
  "8" = {
    source = "base";
    package = "tool";
    endOfLife = "yes";
  };
}
