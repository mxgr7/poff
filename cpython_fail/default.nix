# -*- compile-command: "nix-shell --run 'cabal exec -- ghc-pkg list'"; -*-
{ pkgs ? import <nixpkgs> {}, sources ? import ./nix/sources.nix {} }:
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/haskell-modules/make-package-set.nix
let mach-nix = import (builtins.fetchGit {
      url = "https://github.com/DavHau/mach-nix";
      ref = "refs/tags/3.5.0";
    }) { inherit pkgs; python="python310"; };
    pyEnv = mach-nix.mkPython {
      _.tomli.buildInputs.add = [pkgs.python310Packages.flit-core];
      providers =  {default = "conda,wheel,sdist,nixpkgs";};
      requirements = ''
        pandas
        cbor2
      '';
      # probagatedBuildInputs = [pkgs.pkg-config];
    };
    python3 = pyEnv;
    this = pkgs.haskellPackages.developPackage {
      root = ./.;
      withHoogle = false;
      returnShellEnv = false;
      overrides = self: super: with pkgs.haskell.lib; {
        yahp = self.callCabal2nix "yahp" sources.yahp {};
        hoff = self.callCabal2nix "hoff" sources.hoff {};
        cpython = (enableCabalFlag (self.callCabal2nix "cpython" sources.haskell-cpython { inherit python3; 
                                                                         }) "usepython310");
      };
      modifier = with pkgs.haskell.lib; drv:
        disableLibraryProfiling (dontHaddock (addBuildTools
          (drv.overrideAttrs (_: _: { # inherit LD_LIBRARY_PATH;
          } ) )
          (with pkgs.haskellPackages; [ cabal-install pkgs.pkg-config ghcid ])));
    };
in this // { env = this.env.overrideAttrs(_: prev: {shellHook = prev.shellHook + ''
   export PYTHONPATH="${python3}/lib/python3.10/site-packages:${sources.hoff}/python"
   ''; });}
