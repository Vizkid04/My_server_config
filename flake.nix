{
	description = "nixos-server with LUKS + LVM + disko";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
		disko.url = "github:nix-community/disko";
		disko.inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = { self, nixpkgs, disko, ... }:
	let
		system = "x86_64-linux";
	in {
		nixosConfigurations.nixos-server = nixpkgs.lib.nixosSystem {
			inherit system;
			modules = [
				disko.nixosModules.disko
				./configuration.nix
			];
		};
	};
}
