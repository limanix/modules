{
  # Latest maintained minors on 2026-09-30: 3.22 and 4.3.
  # https://helm.sh/docs/topics/version_skew/#supported-versions
  "3.20" = {
    source = "base";
    package = "kubernetes-helm";
    endOfLife = true;
  };
  "4.2" = {
    source = {
      rev = "350fa6ec55642bd2234c9edb3e149eb3a1ba545f";
      sha256 = "sha256-c4LiLCCS+A8XvRXykGn52yjIDvlPgVsvfn2bCqa81RQ=";
    };
    package = "kubernetes-helm";
    version = "4.2.4";
    endOfLife = true;
  };
  "4.3" = {
    source = "unstable";
    package = "kubernetes-helm";
    endOfLife = false;
  };
}
