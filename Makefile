SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=23.05

help:
	@echo type make make build-hyperv

build-hyperv: nixos-${VERSION}-amd64-hyperv.box

nixos-${VERSION}-amd64-hyperv.box: install.sh nixos.pkr.hcl Vagrantfile.template
	rm -f $@
	install -d tmp
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log \
		packer init nixos.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=hyperv-iso.nixos-amd64 -on-error=abort -timestamp-ui nixos.pkr.hcl
	@./box-metadata.sh hyperv nixos-${VERSION}-amd64 $@

.PHONY: help build-hyperv
