{
  compiler,
  prefix ? "/run/current-system/sw",
}:
compiler.override (previous: {
  bintools = previous.bintools.override (bintools: {
    extraBuildCommands = bintools.extraBuildCommands or "" + ''
      echo 'if [[ $linkType == dynamic ]] && ! (( relocatable )); then extraAfter+=(-rpath ${prefix}/lib); fi' >> "$out/nix-support/ld-wrapper-hook"
    '';
  });
  nixSupport = previous.nixSupport or { } // {
    libc-cflags = previous.nixSupport.libc-cflags or [ ] ++ [ "-idirafter ${prefix}/include" ];
    cc-ldflags = previous.nixSupport.cc-ldflags or [ ] ++ [ "-L${prefix}/lib" ];
  };
})
