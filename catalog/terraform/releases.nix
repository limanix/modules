{
  sources = {
    legacy = {
      rev = "d30430e7eca9645a26e0e40000bcc31261aadc3c";
      sha256 = "sha256-bkBN5ZrMyYMNI4nqvN7bvrIx3FHB7n7iTZmeZ3BQTDM=";
    };
    previous = {
      rev = "ad2d6648d4f842ca6f0c0385973424c549d3d960";
      sha256 = "sha256-5yko1NPlzNDhFtwyadqEp6tDDlM8Wvc8vf582mD+7Oo=";
    };
    current = {
      rev = "af5659602cad8953ebfe6d741e33f161fa8eecb6";
      sha256 = "sha256-YktOVADbGUSxMG1GH7Wq2zW4/B+1RYvCcTflfAJ9uEU=";
    };
  };

  versions = {
    # Upstream maintenance status for these CLI lines has not been confirmed.
    "1.14" = {
      source = "legacy";
      package = "terraform";
      version = "1.14.9";
      endOfLife = null;
    };
    "1.15" = {
      source = "previous";
      package = "terraform";
      version = "1.15.9";
      endOfLife = null;
    };
    "1.16" = {
      source = "current";
      package = "terraform";
      version = "1.16.4";
      endOfLife = null;
    };
  };
}
