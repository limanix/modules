# Java

Installs a headless OpenJDK and the jdtls language server.

## Select

```toml
[toolchains]
java = "21"
```

Choose the line in the `[toolchains]` table of `limanix.toml` and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change). Add
[Maven](../maven/README.md) or [Gradle](../gradle/README.md) in the same table
to build projects.

## Versions

| Value | JDK | Notes |
| -- | -- | -- |
| `25` | OpenJDK 25.x |  |
| `21` | OpenJDK 21.x | Recommended |
| `17` | OpenJDK 17.x |  |

Lines come from the
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions) and
receive its updates with each catalog release. The JDK is headless: it leaves
out the graphical libraries, which a VM without a display does not use.

## Use

Inside the VM, compile and run a class:

```console
javac Main.java
java Main
```

Run `jshell` to try code interactively. `JAVA_HOME` points to the selected JDK
in every session.

## Other tools and JDKs

The selected JDK is also at `/usr/lib/jvm/openjdk-<line>`. Gradle, IntelliJ IDEA
and VS Code look there for installed JDKs.

Gradle needs a toolchain download repository to fetch a missing JDK. Configure
one in the project; see
[Gradle toolchains](https://docs.gradle.org/current/userguide/toolchains.html#sub:download_repositories).

[nix-ld](https://github.com/nix-community/nix-ld) is enabled by default to
support downloaded Linux JDKs.

## Editor support

The module installs jdtls for editors that support the Language Server Protocol;
AstroNvim starts it for Java files. jdtls runs on its own JDK from Nixpkgs,
independent of the selected line, and loads Lombok: the editor understands code
that uses Lombok annotations.

The `jdtls` launcher keeps the state of each project in its own directory under
`${XDG_CACHE_HOME:-~/.cache}/limanix/jdtls`, named after the full canonical
project path. AstroNvim supplies the project root; other editors use the
launcher's working directory. An explicit `-data PATH` or `-data=PATH` keeps the
editor's own choice. Nothing removes the state of old projects: with no Java
editor open, `rm -rf ~/.cache/limanix/jdtls` clears it, and jdtls indexes each
project again.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Public capability | `lmx.capabilities.jdk.package`, the newest selected JDK; `lmx.capabilities.languageSupport.tools.jdtls`; Java parser |
| Settings | `JAVA_HOME`; `/usr/lib/jvm/openjdk-<line>` for every selected line |
| Integration | Maven, Gradle and Quarkus run on the JDK of the capability |
| Services | No daemon |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| A downloaded JDK does not start | Check that `programs.nix-ld.enable` is on, or select that Java line |
| A desktop Java program needs a display | The headless JDK cannot open windows; run the program on the Mac |
