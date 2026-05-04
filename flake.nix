{
  description = "Home Manager config with custom beads package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ketch = {
      url = "github:1broseidon/ketch/v0.8.0";
      flake = false;
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ghostty, nixgl, ketch, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      mkKetch = pkgs: pkgs.buildGoModule {
        pname = "ketch";
        version = "0.8.0";

        src = ketch;

        vendorHash = "sha256-m3IwAYsczsxcVk9fay+f2AsNjmXoPk7NS0abES6b594=";

        ldflags = [
          "-s"
          "-w"
          "-X github.com/1broseidon/ketch/cmd.version=0.8.0"
        ];

        meta = with lib; {
          description = "Fast, stateless CLI for web search and scrape. Built for AI agents.";
          homepage = "https://github.com/1broseidon/ketch";
          license = licenses.mit;
          mainProgram = "ketch";
          platforms = platforms.linux ++ platforms.darwin;
        };
      };

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

      ghosttyPkg = ghostty.packages.${system}.default;
      nixGLIntel = nixgl.packages.${system}.nixGLIntel;
      ketchPkg = mkKetch pkgs-unstable;
    in
    {
      packages.${system} = {
        inherit beads ketchPkg;
        default = beads;
      };

      homeConfigurations.freak = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit pkgs-unstable beads ghosttyPkg nixGLIntel ketchPkg;
        };
        modules = [ ./home.nix ];
      };
    };
}
