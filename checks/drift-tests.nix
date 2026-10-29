{ lib }:
let
  analyze = sets: import ../tools/drift-analysis.nix { inherit lib sets; };
  baseRecord = package: {
    source = "base";
    inherit package;
  };
  java = {
    name = "java";
    records = lib.genAttrs [ "17" "21" "25" ] (line: baseRecord "jdk${line}_headless");
  };
  javaPackages = {
    jdk17_headless.version = "17.0.20.1+1";
    jdk21_headless.version = "21.0.12.1+1";
    jdk25_headless.version = "25.0.4.1+1";
    jdk26.version = "26.0.1";
    jdk27_headless.version = "27-ea+1";
    jdk28_headless.version = "28.0.0-rc1";
    jdk29_headless.version = "29.0b1";
    jdk30_headless.version = "30.0.0+ea";
  };
  javaSets = {
    base = javaPackages;
    unstable = javaPackages;
  };
  finding = name: line: text: { inherit name line text; };
  newJava = analyze {
    base = javaPackages;
    unstable = javaPackages // {
      jdk26_headless.version = "26+1";
    };
  } java;
  missingJava = analyze (javaSets // { base = removeAttrs javaPackages [ "jdk21_headless" ]; }) java;
  currentJava = analyze javaSets {
    inherit (java) name;
    records = java.records // {
      "21" = {
        source = "unstable";
        package = "jdk21_headless";
      };
    };
  };
  family =
    name: line: package: version: nextLine: nextPackage: nextVersion:
    let
      packages = {
        ${package}.version = version;
        ${nextPackage}.version = nextVersion;
      };
    in
    analyze
      {
        base = packages;
        unstable = packages;
      }
      {
        inherit name;
        records.${line} = baseRecord package;
      } == [ (finding name nextLine "New line in the base (${nextVersion})") ];
in
assert analyze javaSets java == [ ];
assert newJava == [ (finding "java" "26" "New line in nixos-unstable (26+1)") ];
assert missingJava == [ (finding "java" "21" "No longer in the base: freeze it on a snapshot") ];
assert
  currentJava == [ (finding "java" "21" "The base has 21.0.12.1+1: take the line from the base") ];
assert family "go" "1.26" "go_1_26" "1.26.4" "1.27" "go_1_27" "1.27.0";
assert family "python" "3.14" "python314" "3.14.5" "3.15" "python315" "3.15.0";
assert family "gcc" "15" "gcc15" "15.2.0" "16" "gcc16" "16.1.0";
assert family "clang" "21" "clang_21" "21.1.8" "22" "clang_22" "22.1.0";
assert family "java" "21" "jdk21_jre" "21.0.12+1" "25" "jdk25_jre" "25.0.4+1";
assert family "compiler" "21" "compiler21-bin" "21.1.8" "22" "compiler22-bin" "22.1.0";
assert family "compiler" "21" "sdk2_compiler21-bin64" "21.1.8" "22" "sdk2_compiler22-bin64"
  "22.1.0";
assert
  analyze
    {
      base = {
        sdk2_compiler21-bin64.version = "21.1.8";
        sdk3_compiler22-bin64.version = "22.1.0";
        sdk2_compiler23-bin32.version = "23.1.0";
        sdk2_compiler24_jre64.version = "24.1.0";
      };
      unstable = { };
    }
    {
      name = "compiler";
      records."21" = baseRecord "sdk2_compiler21-bin64";
    } == [ ];
assert
  analyze
    {
      base = {
        compiler121-bin.version = "21.1.8";
        compiler122-bin.version = "22.1.0";
      };
      unstable.compiler121-bin.version = "21.1.8";
    }
    {
      name = "compiler";
      records."21" = baseRecord "compiler121-bin";
    } == [ ];
assert
  analyze
    {
      base = {
        compiler21-bin21.version = "21.1.8";
        compiler22-bin21.version = "22.1.0";
        compiler21-bin22.version = "22.1.0";
      };
      unstable.compiler21-bin21.version = "21.1.8";
    }
    {
      name = "compiler";
      records."21" = baseRecord "compiler21-bin21";
    } == [ ];
assert
  analyze
    {
      base.maven.version = "3.9.11";
      unstable = {
        maven.version = "3.9.12";
        maven4.version = "4.0.0";
      };
    }
    {
      name = "maven";
      records."3" = baseRecord "maven";
    } == [ ];
true
