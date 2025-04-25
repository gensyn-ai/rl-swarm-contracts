{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    solc = {
      url = "github:hellwolf/solc.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      solc,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          system = system;
          overlays = [
            solc.overlay
          ];
        };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            foundry
            solc_0_8_29
          ];

          FOUNDRY_SOLC = "${pkgs.solc_0_8_29}/bin/solc-0.8.29";
        };
      }
    );
}
