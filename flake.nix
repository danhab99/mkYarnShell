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

        readNamePackageJson = { packageJsonPath }:
          let
            # Read the file contents
            packageJsonContents = builtins.readFile packageJsonPath;

            # Parse the JSON
            packageData = builtins.fromJSON packageJsonContents;

            # Extract the name
            packageName = packageData.name;
          in
            packageName;

        mkYarnShell = yarnShellInputs@{
          src
          ,node_modules_name ? "default"
          ,...
        }: let
          name = readNamePackageJson {
            packageJsonPath = src + "/package.json";
          };

        in pkgs.mkShell (yarnShellInputs // {
          shellHook = ''
              flake_path=".#node_modules.$(uname -m)-linux.${node_modules_name}"
              nix build $flake_path --no-link
              echo $flake_path
              node_path=$(nix path-info $flake_path)
              echo $node_path 
              rm -rf ./node_modules
              ln -s $node_path/libexec/${name}/node_modules ./node_modules

              ${yarnShellInputs.shellHook}
          '';
        });

      in {
        # packages.node_modules.default = pkgs.mkYarnPackage {
        node_modules.default = pkgs.mkYarnPackage {
          name = "yarn-project";
          src = ./.;
        };

        node_modules.project1 = pkgs.mkYarnPackage {
          name = "project1";
          src = ./project1;
        };

        devShells = {
          default = mkYarnShell {
            src = ./.;

            packages = with pkgs; [
              gnumake
              nodejs_22
              yarn 
              prettierd
            ];

            shellHook = ''
              zsh
            '';
          };


          project1 = mkYarnShell {
            src = ./project1;
            node_modules_name = "project1";

            packages = with pkgs; [
              gnumake
              nodejs_22
              yarn 
              prettierd
            ];

            shellHook = ''
              zsh
            '';
          };
        };
      });
}


