# yarn-shell

A Nix flake that makes development shells with `node_modules` always ready to use.  
It builds `node_modules` once with `mkYarnPackage` and symlinks them into your shell, so you don’t need to `yarn install` manually.

---

## Installation

Add this flake to your project’s `flake.nix` inputs:

```nix
{
  inputs = {
    # ...
    yarnShell.url = "github:danhab99/yarn-shell";
  };
}
````

Pass `yarnShell` into your outputs:

```nix
outputs = { self, nixpkgs, flake-utils, yarnShell }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      ys = yarnShell.lib."${system}";
    in {
      # your outputs here
    });
```

## Defining node_modules

Declare your `node_modules` as a build output using `mkYarnNodeModules`.
This takes the package name and the path to the directory containing your `package.json` and `yarn.lock`:

```nix
{
  node_modules.default = ys.mkYarnNodeModules {
    name = "insert-project-name-here";
    src = ./.; # path to project root
  };
}
```

## DevShell with node_modules

Create a development shell with `mkNodeModulesShell`.
It works like `pkgs.mkShell` (or `mkDevShell`), but automatically wires up the built `node_modules`:

```nix
{
  devShells.default = ys.mkNodeModulesShell {
    src = ./.;

    packages = with pkgs; [
      nodejs_22
      # ...
    ];
  };
}
```

When you run:

```bash
nix develop
```

The flake will:

* Build `node_modules` via Nix
* Symlink them into your working directory
* Drop you into a shell with everything ready

---

## Example Workflow

```bash
# enter your dev shell
nix develop

# run your scripts normally
yarn dev
```

No more `yarn install` before each run — `node_modules` are managed by Nix.

---

## API

* `ys.mkYarnNodeModules { name, src; }`
  Build `node_modules` from a `package.json` + `yarn.lock`.

* `ys.mkNodeModulesShell { src, packages ? [], shellHook ? "" }`
  Create a dev shell with those `node_modules` linked in.

---

## Notes

* Only `yarn`-based projects are supported (uses `mkYarnPackage` under the hood).
* The flake uses `uname -m` to pick the correct `node_modules` derivation for your system.
