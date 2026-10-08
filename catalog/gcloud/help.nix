let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.gcloud = {
    title = "Google Cloud CLI";
    summary = metadata.description;
    commands = [
      "gcloud"
      "gsutil"
      "bq"
      "gke-gcloud-auth-plugin"
    ];
    tips = [
      {
        label = "Sign in";
        text = "gcloud auth login";
      }
      {
        label = "Project";
        text = "gcloud config set project PROJECT_ID";
      }
      {
        label = "Check";
        text = "gcloud config list";
      }
      {
        label = "App login";
        text = "gcloud auth application-default login";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/gcloud/README.html";
  };
}
