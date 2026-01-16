{
	disko.devices = {
		disk = {
			main = {
				type = "disk";
				device = "/dev/sda";
				content = {
					type = "gpt";
					partitions = {
						esp = {
							size = "1G";
							type = "EF00";
							content = {
								type = "filesystem";
								format = "vfat";
								mountpoint = "/boot";
							};
						};
						crypt = {
							size = "100%";
							content = {
								type = "luks";
								name = "cryptroot";
								settings = {
									allowDiscards = true;
								};
								content = {
									type = "lvm_pv";
									vg = "vg0";
								};
							};
						};
					};
				};
			};
		};
		lvm_vg = {
			vg0 = {
				type = "lvm_vg";
				lvs = {
					root = {
						size = "114G";
						content = {
							type = "filesystem";
							format = "ext4";
							mountpoint = "/";
						};
					};	
					vizkid = {
						size = "91G";
						content = {
							type = "filesystem";
							format = "ext4";
							mountpoint = "/home/vizkid";
						};
					};
					vishnu = {
						size = "100%FREE";
						content = {
							type = "filesystem";
							format = "ext4";
							mountpoint = "/home/vishnu";
						};
					};
				};
			};
		};
	};
}
