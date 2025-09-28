{
  description = "Flake exporting mkNodeModulesShell and mkYarnNodeModules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

        readNamePackageJson = { packageJsonPath }:
          let
            packageJsonContents = builtins.readFile packageJsonPath;
            packageData = builtins.fromJSON packageJsonContents;
          in
            packageData.name;

        mkNodeModulesShell = { src, node_modules_name ? "default", ... }@args:
          let
            name = readNamePackageJson {
              packageJsonPath = src + "/package.json";
            };
          in
            pkgs.mkShell (args // {
              shellHook = ''
                flake_path=".#node_modules.$(uname -m)-linux.${node_modules_name}"
                nix build $flake_path --no-link
                echo $flake_path
                node_path=$(nix path-info $flake_path)
                echo $node_path 
                rm -rf ./node_modules
                ln -s $node_path/libexec/${name}/node_modules ./node_modules

                ${args.shellHook or ""}
              '';
            });

        mkYarnNodeModules = { name, src }:
          let
            package = pkgs.mkYarnPackage { inherit name src; };
          in {
            node_modules_path = "${package}/libexec/${name}/node_modules";
          };

      in {
        # Ready-to-use default dev shell
        # devShells.default = mkNodeModulesShell { src = ./.; };

        # Export builder functions for reuse (system-dependent)
        lib = {
          inherit mkNodeModulesShell mkYarnNodeModules readNamePackageJson;
        };
      }
    );
}
