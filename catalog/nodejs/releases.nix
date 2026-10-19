{
  # Cached upstream snapshots preserve the advertised versions and source hashes.
  "23" = {
    source = {
      rev = "2589c813e138db4ecab0912798c0b65512dba1e8";
      sha256 = "sha256-bKD2zezDqJBwrPgP5a05areWFTE3wHpEmo+9feEWCAY=";
    };
    package = "nodejs_23";
    version = "23.11.0";
    endOfLife = true;
  };
  "24" = {
    source = "base";
    package = "nodejs_24";
    endOfLife = false;
  };
  "25" = {
    source = {
      rev = "e5dba655b6ca52684b242820f633be8186778154";
      sha256 = "sha256-JdYSPSbipK0Ytwanv0cyB17SppMA7KSZgq/7WJnhYYM=";
    };
    package = "nodejs_25";
    version = "25.9.0";
    endOfLife = true;
  };
  "26" = {
    source = "base";
    package = "nodejs_26";
    endOfLife = false;
    npm = {
      version = "12.1.0";
      hash = "sha512-Fyhu62pNx70YCs/5+dEmJQTFVmSKwvo5CA0qvBkGDRpob42MJ6G2RQ2tdxeKM4nYnIZDqkYAxEgqtoejn9QGtQ==";
    };
  };
}
