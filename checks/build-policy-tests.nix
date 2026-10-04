{ system, ... }:
let
  policy = import ./build-plan.nix;
  root = "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-test.drv";
  permitted = "/nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-artifact.drv";
  dependency = "/nix/store/cccccccccccccccccccccccccccccccc-dependency.drv";
  local = "/nix/store/dddddddddddddddddddddddddddddddd-wrapper.drv";
  metadata = {
    ${root} = {
      inherit system;
      env = { };
    };
    ${permitted} = {
      inherit system;
      env = { };
      inputDrvs.${dependency} = [ "out" ];
    };
    ${dependency} = {
      inherit system;
      env = { };
    };
    ${local} = {
      inherit system;
      env.preferLocalBuild = "1";
    };
  };
  arguments = {
    roots = [ root ];
    builds = [ permitted ];
    derivations = metadata;
  };
  allowed = policy (
    arguments
    // {
      planned = [
        root
        permitted
        local
      ];
    }
  );
  denied = policy (arguments // { planned = [ dependency ]; });
  modern = policy (
    arguments
    // {
      planned = [ local ];
      derivations = {
        version = 4;
        derivations.${builtins.baseNameOf local} = {
          structuredAttrs.preferLocalBuild = true;
          env = { };
        };
      };
    }
  );
  falseFlag = policy (
    arguments
    // {
      planned = [ local ];
      derivations.${local} = {
        structuredAttrs.preferLocalBuild = false;
        env.preferLocalBuild = "1";
      };
    }
  );
  rejects = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
in
assert allowed.allowed && allowed.blocked == [ ];
assert !denied.allowed && denied.blocked == [ dependency ];
assert modern.allowed;
assert
  (policy (
    arguments
    // {
      planned = [ local ];
      derivations = {
        version = 3;
        derivations.${builtins.baseNameOf local} = metadata.${local};
      };
    }
  )).allowed;
assert !falseFlag.allowed;
assert (policy (arguments // { planned = [ ]; })).allowed;
assert rejects (
  policy (
    arguments
    // {
      planned = [ dependency ];
      derivations = { };
    }
  )
);
assert rejects (policy (arguments // { planned = [ "relative.drv" ]; }));
assert rejects (
  policy (
    arguments
    // {
      planned = [ ];
      derivations = {
        version = 99;
        derivations = { };
      };
    }
  )
);
true
