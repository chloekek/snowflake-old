let
    tarball = fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/f6a6cf3d7386ac1a62faf273957ee827d97fa678.tar.gz";
        sha256 = "1bsai1rwx9ma5b185rdwb3vsp4akn69fbyjhx78n95gb1kr5rw1f";
    };
    config = {};
in
    {}: import tarball {inherit config;}
