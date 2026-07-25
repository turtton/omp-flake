{
  description = "Nix flake for oh-my-pi (omp) — a coding agent CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          omp = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.omp;
        }
      );

      checks = forAllSystems (system: {
        default = self.packages.${system}.default;
      });

      overlays.default = final: _prev: {
        omp = final.callPackage ./package.nix { };
      };
    };
}
