# Maven

Installs Apache Maven on the JDK of the [Java toolchain](../java/README.md).

## Select

```toml
[toolchains]
java = "21"
maven = "3"
```

Maven needs `java` in the same table. Choose both in the `[toolchains]` table of
`limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). Maven
and [Gradle](../gradle/README.md) can be selected together.

## Versions

| Value | Maven | Notes |
| -- | -- | -- |
| `3` | 3.x | Recommended |

The line comes from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) and
receives its updates with each catalog release.

## Use

Inside the VM, from a directory that contains `pom.xml`:

```console
mvn package
```

`mvn --version` shows the JDK that Maven runs on. A project with `./mvnw` runs
the Maven version that it pins, on the same JDK.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Maven runs on `lmx.capabilities.jdk.package` |
| Personal state | Downloaded dependencies in `~/.m2/repository` |
| Integration | Imports the Java toolchain |
| Services | No daemon |
