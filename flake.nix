{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        lib = pkgs.lib;

        node-modules = pkgs.mkYarnPackage {
          name = "node-modules";
          src = ./.;
        };

      in {
        node_modules.default = pkgs.mkYarnPackage {
          name = "node-modules";
          src = ./.;
        };


        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              gnumake
              nodejs_22
              yarn 
              prettierd
            ];

            PRISMA_QUERY_ENGINE_LIBRARY =
              "${pkgs.prisma-engines}/lib/libquery_engine.node";
            PRISMA_QUERY_ENGINE_BINARY =
              "${pkgs.prisma-engines}/bin/query-engine";
            PRISMA_SCHEMA_ENGINE_BINARY =
              "${pkgs.prisma-engines}/bin/schema-engine";

            DATABASE_PATH="file:/home/dan/Documents/node/mcp-server/db";
            shellHook = ''
            export DATABASE_PATH="file:$(dirname $(realpath $(git rev-parse --git-dir)) )/db"
            zsh
            '';
          };
        };
      });
}


