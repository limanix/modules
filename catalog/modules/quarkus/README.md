# Quarkus

Installs the Quarkus CLI on the JDK of the
[Java toolchain](../../toolchains/java/README.md).

## Select

```toml
[toolchains]
java = "21"

[nixos]
modules = ["lmx:quarkus", "lmx:docker"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). Without
a `java` line, the CLI runs on the Java default. [Docker](../docker/README.md)
is optional: Dev Services and native builds in a container need it.

## Use

Inside the VM, create an application and start dev mode:

```console
quarkus create app org.acme:demo
cd demo
quarkus dev
```

Dev mode listens on `localhost:8080` inside the VM. To open the application from
your Mac, start it with `quarkus dev -Dquarkus.http.host=0.0.0.0`, add `8080` to
`network.ports` and use the VM's address;
[Networking](https://docs.limanix.dev/vms/network) shows how to find it.

With Docker, Dev Services start the databases and brokers that the application
uses, and a native executable builds in a container:

```console
quarkus build --native -Dquarkus.native.container-build=true
```

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | The CLI runs on `lmx.capabilities.jdk.package` |
| Personal state | Project files; Maven or Gradle caches in your home directory |
| Integration | Imports the Java toolchain; Dev Services use Docker when `lmx:docker` is selected |
| Services | No daemon |
