{
  sources = {
    legacy = {
      rev = "0965e23c8bc793031f0bdd5a5d4ca83a348ca109";
      sha256 = "sha256-QpnezwA2rOJUKTnw2y1NSWC0FTWqMmCAfQbFLHwQ1jc=";
    };
    previous = {
      rev = "f9a1708872c749e28014296f912f0aa793421933";
      sha256 = "sha256-YmQKQX70RflNeY8jmhAvmibm9BdTwfb3qAa+jDLq6yQ=";
    };
    current = {
      rev = "6e7ff6899cc23b466a73e3f898bd4b624732fd99";
      sha256 = "sha256-4NKQGpjUu+sBYjqbMxvetWhWaUnmXGSyLwZ3o1tqTyo=";
    };
  };

  versions = {
    "3.48" = {
      source = "legacy";
      package = "go-task";
      version = "3.48.0";
      endOfLife = null;
    };
    "3.52" = {
      source = "previous";
      package = "go-task";
      version = "3.52.0";
      endOfLife = null;
    };
    "3.53" = {
      source = "current";
      package = "go-task";
      version = "3.53.1";
      endOfLife = null;
    };
  };
}
