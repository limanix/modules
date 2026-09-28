{
  sources = {
    legacy = {
      rev = "d581d019cf215cd74c9d55824b72e72481df72d2";
      sha256 = "sha256-mDrldNaaaWy8OhIBHBHNgq8fypNBjTSe3hvjrxexohc=";
    };
    previous = {
      rev = "c212e10c0c9b1079417e6de171ed685fc6012a33";
      sha256 = "sha256-DGjQx8RO/kYMXnLA7q8/BuvbhVuAu839pSd7YTP3fco=";
    };
    current = {
      rev = "79b35bf0bda5cd110f856aa5b5b2c5ba4460dbf5";
      sha256 = "sha256-COQmpo4lFIzMgUjr3ntDpjH0NwrCnf7N0uhR+6WPGP8=";
    };
  };

  versions = {
    "1.36" = {
      source = "legacy";
      package = "minikube";
      version = "1.36.0";
    };
    "1.37" = {
      source = "previous";
      package = "minikube";
      version = "1.37.0";
    };
    "1.38" = {
      source = "current";
      package = "minikube";
      version = "1.38.1";
    };
  };
}
