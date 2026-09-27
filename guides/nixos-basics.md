---
myst:
  heading_anchors: 2
---

# NixOS basics

Every Limanix VM runs [NixOS](https://nixos.org/), a Linux distribution configured entirely in code.
You can select catalog modules without knowing Nix.
This page covers what you need to read and write your own modules.

## Why NixOS

On most Linux systems, you install packages and edit configuration files one command at a time.
NixOS starts from a description instead: its configuration lists the packages, services, and settings the system should have, and NixOS builds a system that matches it.

For a Limanix VM, this means:

| Property | What it gives you |
| --- | --- |
| Declarative | `limanix.toml` and the selected modules describe the whole VM, with no manual setup steps to repeat or forget |
| Reproducible | The same configuration and the same package revision produce the same tools and services |
| Composable | Independent modules, such as Go, Docker, and your own, combine into one system |
| Reversible | Removing a module takes its packages and services out of the next build |

## Key terms

| Term | Meaning |
| --- | --- |
| **Nix** | The package manager that builds packages and whole systems, and the language of `.nix` files |
| **Nixpkgs** | The collection of package definitions and NixOS modules that Nix builds from |
| **NixOS** | The Linux distribution built from Nixpkgs and configured by modules |
| **Package** | Software built by Nix, such as `pkgs.jq` |
| **Option** | A named, typed setting with a default value, such as `programs.git.enable` |
| **Module** | A Nix file that sets options, and can declare new ones |

## Read a module

This module installs `jq` and enables Git:

```{code-block} nix
:linenos:
:name: nixos-basics-module
:class: code-example

{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jq ];
  programs.git.enable = true;
}
```

| Code | Meaning |
| --- | --- |
| [1](#nixos-basics-module.1){.external .code-lines} | A function that receives `pkgs` from NixOS; `...` accepts the other arguments it does not use |
| [2–5](#nixos-basics-module.2-5){.external .code-lines} | The braces enclose the settings that the module contributes |
| [3](#nixos-basics-module.3){.external .code-lines} | Adds `jq` for every user; square brackets form a list whose entries are separated with spaces, not commas |
| [4](#nixos-basics-module.4){.external .code-lines} | Enables Git through a NixOS option |
| [3–4](#nixos-basics-module.3-4){.external .code-lines} | Each setting ends with a semicolon |

Besides `pkgs`, modules often use `lib`, a library of helper functions, and `config`, the final configuration after all modules are merged.
A module that needs no arguments can be a plain set of settings: `{ programs.git.enable = true; }`.

## Packages and options

A package only adds programs and files.
An option can do more: create users and groups, write configuration files, and define services that start with the system.

| Goal | Use | Example |
| --- | --- | --- |
| Run a command-line tool | A package in `environment.systemPackages` | `pkgs.ripgrep` |
| Configure a program for the whole system | Its `programs.*` options | `programs.git.enable` |
| Run a service | Its `services.*` or other service options | `services.postgresql.enable` |

For example, the package `pkgs.docker` only installs Docker's programs, while the option `virtualisation.docker.enable` also runs Docker Engine as a service.
When NixOS has an option for the software you need, prefer it over the bare package.

## Find packages and options

| Search | Use it for |
| --- | --- |
| [NixOS packages](https://search.nixos.org/packages) | Package attribute names |
| [NixOS options](https://search.nixos.org/options) | Option names, types, defaults, and examples |

In both searches, select the NixOS release that the catalog pins; [NixOS version and package pins](concepts.md#nixos-version-and-package-pins) names it.
A package's attribute name can differ from its command: `pkgs.ripgrep` provides `rg`.

## The Nix store

Nix keeps every package and every built system under `/nix/store`.
Store paths never change after they are built; a new configuration creates new paths instead of editing files in place.
Everything in the store is readable by every user in the VM.
Keep secrets outside the store; see [Trust and secrets](concepts.md#trust-and-secrets).

## Learn more

- [Nix language basics](https://nix.dev/tutorials/nix-language.html) on nix.dev
- [Writing NixOS modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules) in the NixOS manual
- The complete [NixOS manual](https://nixos.org/manual/nixos/stable/) and [Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/)
