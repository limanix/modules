{ pkgs, lib }:
let
  packagePriority =
    package:
    if builtins.isAttrs package then
      package.meta.priority or lib.meta.defaultPriority
    else
      lib.meta.defaultPriority;
  selected =
    packages: package:
    import ./selected-package.nix { inherit packagePriority; } {
      config.environment.systemPackages = packages;
    } package;
  script = pkgs.writeShellScriptBin "contract-selected-tool" "printf chosen";
  unrelated = pkgs.writeShellScriptBin "contract-unrelated-tool" "printf unrelated";
  conflicting = pkgs.writeShellScriptBin "contract-selected-tool" "printf conflicting";
  provider =
    version:
    pkgs.runCommand "contract-provider-${version}" {
      pname = "contract-provider";
      inherit version;
    } "touch $out";
  old = provider "1";
  new = lib.setPrio (lib.meta.defaultPriority - 1) (provider "2");
  wrapped = {
    __toString = _: toString script;
  };
in
assert !(script ? pname) && !(unrelated ? pname);
assert selected [ script unrelated ] script;
assert selected [ unrelated script ] script;
assert !(selected [ script conflicting ] script);
assert
  !(selected [
    (script // { pname = null; })
    (conflicting // { pname = null; })
  ] (script // { pname = null; }));
assert
  !(selected [
    (script // { pname = ""; })
    (conflicting // { pname = ""; })
  ] (script // { pname = ""; }));
assert selected [
  (script // { pname = ""; })
  (unrelated // { pname = ""; })
] (script // { pname = ""; });
assert selected [
  (script // { pname = null; })
  (unrelated // { pname = null; })
] (script // { pname = null; });
assert selected [
  script
  (lib.setPrio (lib.meta.defaultPriority + 1) conflicting)
] script;
assert
  !(selected [
    script
    (lib.setPrio (lib.meta.defaultPriority - 1) conflicting)
  ] script);
assert selected [ old new ] new;
assert selected [ new old ] new;
assert !(selected [ old new ] old);
assert !(selected [ old (lib.setPrio lib.meta.defaultPriority new) ] old);
assert !(selected [ unrelated ] script);
assert selected [ "${script}" unrelated ] "${script}";
assert selected [ wrapped unrelated ] wrapped;
assert selected [
  script
  (lib.setPrio (lib.meta.defaultPriority - 1) script)
  unrelated
] script;
true
