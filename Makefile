SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=23.05

help:
	@echo type make build-libvirt, make build-hyperv

build-libvirt: nixos-${VERSION}-amd64-libvirt.box

build-hyperv: nixos-${VERSION}-amd64-hyperv.box

nixos-${VERSION}-amd64-libvirt.box: install.sh tmp/qemu/configuration.nix nixos.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log \
		packer init nixos.pkr.hcl
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.nixos-amd64 -on-error=abort -timestamp-ui nixos.pkr.hcl
	@./box-metadata.sh libvirt nixos-${VERSION}-amd64 $@

nixos-${VERSION}-amd64-hyperv.box: install.sh nixos.pkr.hcl Vagrantfile.template
	rm -f $@
	install -d tmp
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log \
		packer init nixos.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=hyperv-iso.nixos-amd64 -on-error=abort -timestamp-ui nixos.pkr.hcl
	@./box-metadata.sh hyperv nixos-${VERSION}-amd64 $@

tmp/qemu/configuration.nix: configuration.nix
	install -d $(shell dirname $@)
	sed -E 's,^((.+)./hardware-configuration.nix),\1\n\2./qemu-hardware-configuration.nix,g' configuration.nix >$@

.PHONY: help build-libvirt build-hyperv
