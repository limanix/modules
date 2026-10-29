# Gradle

Installs Gradle on the JDK of the [Java toolchain](../java/README.md).

## Select

```toml
[toolchains]
java = "21"
gradle = "9"
```

Gradle needs `java` in the same table. Choose both in the `[toolchains]` table
of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). Gradle
and [Maven](../maven/README.md) can be selected together.

## Versions

| Value | Gradle | Runs on | Notes |
| -- | -- | -- | -- |
| `9` | 9.x | Java 17 to 25 | Recommended |
| `8` | 8.x | Java 24 or older |  |

Lines come from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) and
receive their updates with each catalog release. Select one line per VM.

A Gradle line that does not support the selected Java line stops the build:

```text
gradle 8 runs on Java 24 or older: choose a newer gradle line or an older java line in [toolchains]
```

## Use

Inside the VM, from a directory that contains a Gradle build:

```console
gradle build
```

`gradle --version` shows the JDK under `Launcher JVM`. A project with
`./gradlew` runs the Gradle version that it pins, on the same JDK.

Gradle and `./gradlew` find the selected JDK at `/usr/lib/jvm`. Downloading
another JDK requires a configured toolchain download repository. See
[other JDKs](../java/README.md#other-tools-and-jdks) for setup.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | Gradle runs on `lmx.capabilities.jdk.package` |
| Personal state | Caches and wrapper distributions in `~/.gradle` |
| Integration | Imports the Java toolchain; rejects a Java line that the Gradle line does not support |
| Services | Gradle starts its build daemon on demand |
