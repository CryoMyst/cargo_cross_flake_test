{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv/02196df5a23e511d9fe7b9e80147cb198eceb450";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devenv.shells.default = let
          mkCargoCross = pkgs:
            pkgs.cargo-cross.overrideAttrs (drv: rec {
              src = pkgs.fetchFromGitHub {
                owner = "cross-rs";
                repo = "cross";
                rev = "6d097fb548ec121c2a0faf1c1d8ef4ca360d6750";
                hash = "sha256-DA82TU1Liyly6bLXpdqFGF6+xVI27ZkhhSGRW4UKgq4=";
              };
              cargoDeps = drv.cargoDeps.overrideAttrs (pkgs.lib.const {
                inherit src;
                outputHash = "sha256-mgSLTViu52U7LpkYpX/+xj+Dz8/9Cd1bd2fx9xEuPuM=";
              });
            });
          cargo-cross = mkCargoCross pkgs;
        in {
          packages = with pkgs; [
            rustup
            docker
            cargo-cross
          ];
          languages.rust.enable = true;
          languages.rust.channel = "nightly";
          languages.rust.targets = [ "x86_64-pc-windows-gnu" ];

          env.CROSS_CUSTOM_TOOLCHAIN = "1";
          env.CROSS_CUSTOM_TOOLCHAIN_COMPAT = "x86_64-pc-windows-gnu";

          env.RUST_BACKTRACE = "1";
        };
      };
    };
}
