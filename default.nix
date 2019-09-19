let pkgs = import ./nix/pkgs.nix {}; in
pkgs.stdenv.mkDerivation {
    name = "snowflake";
    buildInputs = [pkgs.ldc];
    phases = ["unpackPhase" "buildPhase"
              "installPhase" "fixupPhase"];
    unpackPhase = ''
        cp --recursive ${./source} source
    '';
    buildPhase = ''
        flags=(-dip1000)
        sources=$(find source -type f -name '*.d')
        ldc2 $flags -unittest $sources -of=snowflake.test
        ldc2 $flags -release -O2 $sources -of=snowflake
    '';
    installPhase = ''
        mkdir --parents $out/bin
        mv snowflake{,.test} $out/bin
    '';
}
