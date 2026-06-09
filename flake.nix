{
  description = "A portable, self-contained transient Google Chrome launcher";

  inputs = {
    # Tracks the absolute lightest upstream package tree branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Only permits google-chrome's unfree license, keeps rest of env pure
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "google-chrome" ];
        };

        # Bakes an internal launcher script that executes Chrome with isolated data paths
        chromeLauncher = pkgs.writeShellScriptBin "chrome" ''
          #!/usr/bin/env bash
          echo "🌐 Launching Google Chrome inside a secure transient sandbox bubble..."

          # Runs Chrome using an isolated user data directory to prevent cookie/tracker clutter
          exec ${pkgs.google-chrome}/bin/google-chrome \
            --user-data-dir="$HOME/.cache/chrome-sandbox" \
            "$@"
        '';
      in
      {
        packages.default = chromeLauncher;
        apps.default = {
          type = "app";
          program = "${chromeLauncher}/bin/chrome";
        };
      }
    );
}
