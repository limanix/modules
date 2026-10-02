{
  sources = {
    # Cached upstream snapshots preserve the advertised versions and source hashes.
    legacy = {
      rev = "2589c813e138db4ecab0912798c0b65512dba1e8";
      sha256 = "sha256-bKD2zezDqJBwrPgP5a05areWFTE3wHpEmo+9feEWCAY=";
    };
    previous = {
      rev = "e5dba655b6ca52684b242820f633be8186778154";
      sha256 = "sha256-JdYSPSbipK0Ytwanv0cyB17SppMA7KSZgq/7WJnhYYM=";
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
