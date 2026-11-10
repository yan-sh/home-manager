{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Track Git main so `nix flake update` picks up the latest commit.
    workmux = {
      url = "github:raine/workmux/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ketch = {
      url = "github:1broseidon/ketch/v0.8.0";
      flake = false;
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, nixgl, ketch, workmux, ... }:
    let
      lib = nixpkgs.lib;
      # Current nixpkgs-unstable no longer supports Intel macOS.
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

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

      packages = lib.genAttrs systems (system:
        let
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
          workmuxPkg = workmux.packages.${system}.default.overrideAttrs (_: {
            # Skip upstream tests to keep builds from Git fast.
            doCheck = false;
          });
        in {
          inherit workmuxPkg;
          ketchPkg = mkKetch pkgs-unstable;
          default = workmuxPkg;
        });

      # Existing Linux Home Manager profile; plain switch uses the host platform.
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgs-unstable = import nixpkgs-unstable { inherit system; };
    in
    {
      inherit packages;

      homeConfigurations.freak = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit pkgs-unstable;
          inherit (packages.${system}) ketchPkg workmuxPkg;
          ghosttyPkg = pkgs-unstable.ghostty;
          nixGLIntel = nixgl.packages.${system}.nixGLIntel;
        };
        modules = [ ./home.nix ];
      };
    };
}
