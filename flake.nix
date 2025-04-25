{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    solc = {
      url = "github:hellwolf/solc.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    foundry.url = "github:shazow/foundry.nix/main";
  };
  outputs =
    {
      self,
      nixpkgs,
      solc,
      foundry,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          system = system;
          overlays = [
            foundry.overlay
            solc.overlay
          ];
        };
        deployAndVerify = pkgs.writeShellScriptBin "deploy-and-verify" (
          builtins.readFile ./scripts/deploy-and-verify.sh
        );
      in
      {
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            foundry-bin
            solc_0_8_29
            (solc.mkDefault pkgs solc_0_8_29)
            deployAndVerify
          ];

          FOUNDRY_SOLC = "${pkgs.solc_0_8_29}/bin/solc-0.8.29";
          SOLC_PATH = "${pkgs.solc_0_8_29}/bin/solc-0.8.29";
        };
      }
    );
}
