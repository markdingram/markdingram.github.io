let  
  pkgs = import <nixpkgs> {};
  stdenv = pkgs.stdenv;

  ruby = pkgs.ruby_2_5;
  rubygems = (pkgs.rubygems.override { ruby = ruby; });

in stdenv.mkDerivation rec {  
  name = "markdingram.github.io";
  buildInputs = [
    ruby
    pkgs.libxml2
    pkgs.libxslt
  ];

  shellHook = ''
    export PKG_CONFIG_PATH=${pkgs.libxml2}/lib/pkgconfig:${pkgs.libxslt}/lib/pkgconfig

    mkdir -p .nix-gems
    export GEM_HOME=$PWD/.nix-gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
  '';
}
