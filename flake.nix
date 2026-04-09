{
  description = "Home Manager config with custom beads package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      mkBeads = pkgs:
        let
          version = "1.0.0";
          platform =
            if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then {
              suffix = "linux_amd64";
              hash = "sha256-cFfbHpJCj89cCNXcawfq1X5YiyYsuni5omiT1VvSn9s=";
            } else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then {
              suffix = "linux_arm64";
              hash = "sha256-m7MEEwQeUNrJRaD4qmQBHks0Xr/Qo/m1/M1kbG3KYac=";
            } else if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then {
              suffix = "darwin_amd64";
              hash = "sha256-mj1bygfJzoCcIF75og9z3mUDqzcUZVI5zjBthizusNA=";
            } else if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then {
              suffix = "darwin_arm64";
              hash = "sha256-uHY7Qo5raFUOsrJQVIN5d5S0muSXouJl7Txg8PCgvNI=";
            } else
              throw "Unsupported system for beads: ${pkgs.stdenv.hostPlatform.system}";
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "beads";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/gastownhall/beads/releases/download/v${version}/beads_${version}_${platform.suffix}.tar.gz";
            hash = platform.hash;
          };

          dontUnpack = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            tar -xzf "$src"
            mkdir -p "$out/bin"
            install -m755 bd "$out/bin/bd"
            runHook postInstall
          '';

          meta = with lib; {
            description = "AI-supervised issue tracker for coding workflows";
            homepage = "https://github.com/steveyegge/beads";
            license = licenses.mit;
            mainProgram = "bd";
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
              "x86_64-darwin"
              "aarch64-darwin"
            ];
          };
        };

      pkgs = import nixpkgs {
        inherit system;
      };

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
      };

      beads = mkBeads pkgs;
    in
    {
      packages.${system} = {
        inherit beads;
        default = beads;
      };

      homeConfigurations.freak = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit pkgs-unstable beads;
        };
        modules = [ ./home.nix ];
      };
    };
}
