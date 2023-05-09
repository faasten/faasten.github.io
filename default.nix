with (import <nixpkgs> {});
let
  gems = bundlerEnv {
    name = "faasten-web";
    inherit ruby;
    gemdir = ./.;
  };
in stdenv.mkDerivation {
  name = "faasten-web";
  buildInputs = [gems ruby];
}
