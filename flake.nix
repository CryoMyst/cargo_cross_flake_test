# {
#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#     devenv.url = "github:cachix/devenv";
#     fenix = {
#       url = "github:nix-community/fenix";
#       inputs.nixpkgs.follows = "nixpkgs";
#     };
#   };

#   outputs = inputs@{ nixpkgs, flake-parts, ... }:
#     flake-parts.lib.mkFlake { inherit inputs; } {
#       imports = [
#         inputs.devenv.flakeModule
#       ];
#       systems = nixpkgs.lib.systems.flakeExposed;

#       perSystem = { config, self', inputs', pkgs, system, ... }: {
#         devenv.shells.default = {
#           packages = with pkgs; [
#             rustup
#             docker
#             cargo-cross
#             inputs.fenix.packages.${system}.latest.rustc
#             inputs.fenix.packages.${system}.latest.cargo
#           ];
#           languages.rust.enable = true;
#           languages.rust.channel = "nightly";
#           languages.rust.components = [];
#           languages.rust.toolchain = pkgs.lib.mkForce (with inputs.fenix.packages.${system};
#             combine [ latest.rustc latest.cargo latest.rust-src targets.x86_64-pc-windows-gnu.latest.rust-std ]
#           );
#           env.RUST_BACKTRACE = "1";
#           env.NIX_STORE = "/nix/store";
#           env.CROSS_CUSTOM_TOOLCHAIN = "1";
#           env.CROSS_CUSTOM_TOOLCHAIN_COMPAT = "x86_64-pc-windows-gnu";
#           enterShell = ''
#             export PATH="${inputs.fenix.packages.${system}.latest.rustc.outPath}/bin:$PATH"
#             export PATH="${inputs.fenix.packages.${system}.latest.cargo.outPath}/bin:$PATH"
#           '';
#         };
#       };
#     };
# }

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };
  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          # 👇 new! note that it refers to the path ./rust-toolchain.toml
          rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./toolchain.toml;
        in
        with pkgs;
        {
          devShells.default = mkShell {
            # 👇 we can just use `rustToolchain` here:
            buildInputs = [ rustToolchain ];
            shellHook = ''
              export NIX_STORE="/nix/store"
              export CROSS_CUSTOM_TOOLCHAIN="1"
              export CROSS_CUSTOM_TOOLCHAIN_COMPAT="x86_64-pc-windows-gnu"
            ''; 
          };
        }
      );
}