{
  services.nginx = {
    enable = true;
    virtualHosts."localhost".locations."/".extraConfig = ''
      default_type text/plain;
      return 200 "Hello from Limanix\n";
    '';
  };
}
