{ config, pkgs, lib, ... }:

{
	imports = [
		./hardware-configuration.nix
		./disko.nix
	];

	# Bootloader
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "nixos-server";

	# Networking
	networking.networkmanager.enable = true;

	networking.firewall = {
		enable = true;
		allowedTCPPorts = [ 22 80 443 ];
		interfaces.tailscale0.allowedTCPPorts = [ 8096 2283 8080 8081 8222 ];
	};

	# Time & locale
	time.timeZone = "Asia/Calcutta";
	i18n.defaultLocale = "en_US.UTF-8";
	console.keyMap = "us";

	# No GUI
	services.xserver.enable = false;

	# SSH
	services.openssh = {
		enable = true;
		settings = {
			PasswordAuthentication = true;
			PermitRootLogin = "no";
		};
	};

	# Users
	users.groups.services = {};
	users.groups.filebrowser = {};

	users.users.jellyfin = {
		extraGroups = ["services"];
	};

	users.users.immich = {
		extraGroups = [ "services" ];
	};

	users.users.filebrowser = {
		isSystemUser = true;
		group = "filebrowser";
		extraGroups = [ "services" ];
		home = "/services/Filebrowser";
		createHome = true;
	};

	users.users.vizkid = {
		isNormalUser = true;
		description = "vizkid";
		home = "/home/vizkid";
		shell = pkgs.bash;
		extraGroups = [ "wheel" "networkmanager" ];
	};

	users.users.vishnu = {
		isNormalUser = true;
		description = "vishnu";
		home = "/home/vishnu";
		shell = pkgs.bash;
		extraGroups = [ "wheel" "networkmanager" ];
	};

	security.sudo = {
		enable = true;
		wheelNeedsPassword = true;
	};
	
	# Permissions
	system.activationScripts.permissions = {
		text = ''
			mkdir -p /services
			chown root:services /services
			chmod 0710 /services

			mkdir -p /services/Filebrowser
			chown filebrowser:filebrowser /services/Filebrowser
			chmod 0700 /services/Filebrowser

			mkdir -p /services/Jellyfin
			chown jellyfin:jellyfin /services/Jellyfin
			chmod 0700 /services/Jellyfin

			mkdir -p /services/Immich
			chown immich:immich /services/Immich
			chmod 0700 /services/Immich

			${pkgs.acl}/bin/setfacl -m u:jellyfin:x /home/vizkid
			${pkgs.acl}/bin/setfacl -m u:jellyfin:rx /home/vizkid/Jellyfin
			find /home/vizkid/Jellyfin -type d -exec ${pkgs.acl}/bin/setfacl -m u:jellyfin:rx {} +
			find /home/vizkid/Jellyfin -type f -exec ${pkgs.acl}/bin/setfacl -m u:jellyfin:r {} +
			find /home/vizkid/Jellyfin -type d -exec ${pkgs.acl}/bin/setfacl -d -m u:jellyfin:rx {} +	
			${pkgs.acl}/bin/setfacl -m u:jellyfin:x /home/vishnu
			${pkgs.acl}/bin/setfacl -m u:jellyfin:rx /home/vishnu/Jellyfin
			find /home/vishnu/Jellyfin -type d -exec ${pkgs.acl}/bin/setfacl -m u:jellyfin:rx {} +
			find /home/vishnu/Jellyfin -type f -exec ${pkgs.acl}/bin/setfacl -m u:jellyfin:r {} +
			find /home/vishnu/Jellyfin -type d -exec ${pkgs.acl}/bin/setfacl -d -m u:jellyfin:rx {} +
			${pkgs.acl}/bin/setfacl -R -m g:filebrowser:rwx /home
			${pkgs.acl}/bin/setfacl -R -d -m g:filebrowser:rwx /home
			mkdir -p /services/Filebrowser/db
			mkdir -p /services/Filebrowser/cache
			chown -R filebrowser:filebrowser /services/Filebrowser
			find /services/Filebrowser -type d -exec chmod 2770 {} +
			find /services/Filebrowser -type f -exec chmod 0660 {} +
			${pkgs.acl}/bin/setfacl -R -d -m g:filebrowser:rwx /services/Filebrowser
			mkdir -p /var/lib/tailscale/certs
			chmod o+x /var/lib/tailscale
			chown nginx:nginx /var/lib/tailscale/certs
			chmod 750 /var/lib/tailscale/certs
			if [ -f /var/lib/tailscale/certs/nixos-server.tail2d9243.ts.net.crt ]; then
				chown nginx:nginx /var/lib/tailscale/certs/nixos-server.tail2d9243.ts.net.*
				chmod 640 /var/lib/tailscale/certs/nixos-server.tail2d9243.ts.net.*
			fi
		'';
	};

	# Swap file
	swapDevices = [
		{
			device = "/swapfile";
			size = 4096;
		}
	];

	# Jellyfin
	services.jellyfin = {
		enable = true;
		openFirewall = false;
		dataDir = "/services/Jellyfin";
		cacheDir = "/services/Jellyfin/cache";
	};

	# Tailscale
	services.tailscale = {
		enable = true;
	};

	# Immich
	services.immich = {
		enable = true;
		host = "0.0.0.0";
		port = 2283;
		mediaLocation = "/services/Immich";
		openFirewall = false;
	};

	systemd.services.immich-server.serviceConfig = {
		ProtectHome   = lib.mkForce false;
		ReadWritePaths = [
			"/services/Immich"
		];
	};

	virtualisation.podman = {
			enable = true;
			dockerCompat = true;
		};

	# Onlyoffice
	systemd.services.onlyoffice = {
		description = "OnlyOffice Document Server";
		after = [ "network.target" ];
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			ExecStart = ''
				${pkgs.podman}/bin/podman run --rm \
				--name onlyoffice \
				--network office-net \
				--user 0:0 \
				-p 8081:80 \
				-e JWT_ENABLED=true \
				-e JWT_SECRET="bruh123" \
				-e ALLOW_PRIVATE_IP_ADDRESS=true \
				-e JWT_HEADER="Authorization" \
				-v /services/onlyoffice/data:/var/www/onlyoffice/Data \
				onlyoffice/documentserver:latest
	    		'';
		Restart = "always";
		RestartSec = 20;
		TimeoutStartSec = 600;
		};
	};

	# Filebrowser Quantum
	systemd.services.filebrowser-quantum = {
		description = "FileBrowser Quantum Service";
		after = [ "network.target" ];
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			ExecStart = ''
				${pkgs.podman}/bin/podman run \
				--replace \
				--name filebrowser-quantum \
				--network office-net \
				--user 0:0 \
				-p 8080:80 \
				-v /home:/srv \
				-v /services/Filebrowser/db:/db \
				-v /services/Filebrowser/database:/database:Z \
				-v /services/Filebrowser/cache:/cache:Z \
				-e FILEBROWSER_CONFIG=/db/config.yaml \
				gtstef/filebrowser:beta
	    		'';
		Restart = "always";
		RestartSec = 5;
		};
	};

	# Vaultwarden
	services.vaultwarden = {
		enable = true;
		config = {
			ROCKET_ADDRESS = "127.0.0.1";
			ROCKET_PORT = 8222;
			DOMAIN = "https://nixos-server.tail2d9243.ts.net";
			SIGNUPS_ALLOWED = false;
			INVITATIONS_ALLOWED = false;
		};
	};
	
	# Nginx for Vaultwarden
	services.tailscale.permitCertUid = "nginx";	
	services.nginx = {
		enable = true;
		recommendedProxySettings = true;
		recommendedTlsSettings = true;
		virtualHosts."nixos-server.tail2d9243.ts.net" = {
			addSSL = true;
			sslCertificate = "/var/lib/tailscale/certs/nixos-server.tail2d9243.ts.net.crt";
			sslCertificateKey = "/var/lib/tailscale/certs/nixos-server.tail2d9243.ts.net.key";
			locations."/" = {
				proxyPass = "http://127.0.0.1:8222";
				proxyWebsockets = true;
			};
		};
		serviceConfig = {
			ProtectHome = "read-only";
			ReadOnlyPaths = [ "/var/lib/tailscale/certs" ];
		};
	};
	
	# Https certificate renewal
	systemd.services.tailscale-cert-renewal = {
		description = "Renew Tailscale certificates for Nginx";
		after = [ "network-online.target" "tailscaled.service" ];
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			Type = "oneshot";
			ExecStart = "${pkgs.tailscale}/bin/tailscale cert --cert-file /var/lib/tailscale/certs/nixos-server.tail2d9243.ts.net.crt --key-file /var/lib/tailscale/certs/nixos-server.tail2d9243.ts.net.key nixos-server.tail2d9243.ts.net";
			ExecPost = "${pkgs.systemd}/bin/systemctl reload nginx";
			User = "root"; 
		};
		startAt = "weekly";
	};
	
	environment.systemPackages = with pkgs; [
		vim
		wget
		git
		curl
		acl
	];

	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	system.stateVersion = "25.11";
}
