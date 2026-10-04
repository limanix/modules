{ pkgs }:
let
  metadata = builtins.fromTOML (builtins.readFile ../module.toml);
  inherit ((import ../releases.nix).versions.${metadata.default}) version;
  image = pkgs.dockerTools.buildLayeredImage {
    name = "limanix-module-smoke";
    tag = "test";
    contents = [ pkgs.busybox ];
    config.Cmd = [
      "${pkgs.busybox}/bin/sh"
      "-c"
      "printf 'container-ok\n'"
    ];
  };
  compose = pkgs.writeText "module-compose.yaml" ''
    services:
      probe:
        image: limanix-module-smoke:test
        pull_policy: never
        network_mode: none
  '';
in
pkgs.testers.runNixOSTest {
  name = "docker-service-and-development-account";
  nodes.machine = {
    imports = [
      (import ../../_shared/test/vm.nix { })
      ../default.nix
    ];
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 4096;
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("docker.service")
    machine.wait_for_file("/run/docker.sock")
    machine.succeed("su - dev -c 'id -nG' | grep -w docker")
    machine.succeed("su - dev -c 'docker info --format {{.ServerVersion}}' | grep -Fx ${version}")
    machine.succeed("docker load -i ${image}")
    output = machine.succeed("su - dev -c 'docker run --rm --network none limanix-module-smoke:test'")
    assert output.strip() == "container-ok", output
    machine.succeed("su - dev -c 'docker compose -p module-test -f ${compose} config --quiet'")
    output = machine.succeed("su - dev -c 'docker compose -p module-test -f ${compose} up --abort-on-container-exit --exit-code-from probe'")
    assert "container-ok" in output, output
    machine.succeed("su - dev -c 'docker compose -p module-test -f ${compose} down'")
  '';
}
