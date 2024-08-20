# SPDX-FileCopyrightText: 2024 The Cosmo-CoDiOS Developers
#
# SPDX-License-Identifier: GPL-3.0-only

{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-24.05";
  };

  outputs = { self, fenix, flake-utils, naersk, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        toolchain = with fenix.packages.${system}; fromToolchainFile {
          dir = ./.;
          sha256 = "sha256-3jVIIf5XPnUU1CRaTyAiO0XHVbJl12MSx3eucTXCjtE=";
        };

        naersk' = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };

        naerskBuildPackage = target: args:
          naersk'.buildPackage (
            args
            // {
              CARGO_BUILD_TARGET = target;
            }
          );
      in
      {
        packages.default = self.packages.thumbv6m-none-eabi;

        packages.thumbv6m-none-eabi = naerskBuildPackage "thumbv6m-none-eabi" {
          src = ./.;
          doCheck = false;
          nativeBuildInputs = with pkgs; [ cmake ];
        };

        devShell = pkgs.mkShell (
          {
            packages = [
              pkgs.cargo-cross
              pkgs.rustup
              toolchain
            ];
            CROSS_CONTAINER_OPTS = "--platform linux/amd64";
            CARGO_BUILD_TARGET = "thumbv6m-none-eabi";
          });
      });
}
