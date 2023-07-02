# About

This builds a [NixOS](https://nixos.org) Vagrant Base Box.

# Usage

Depending on your host, choose one of the next sections.

## Ubuntu Host

On a Ubuntu host, install the dependencies by running the file at:

    https://github.com/rgl/xfce-desktop-vagrant/blob/master/provision-virtualization-tools.sh

And you should also install and configure the NFS server. E.g.:

```bash
# install the nfs server.
sudo apt-get install -y nfs-kernel-server

# enable password-less configuration of the nfs server exports.
sudo bash -c 'cat >/etc/sudoers.d/vagrant-synced-folders' <<'EOF'
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
EOF
```

For more information see the [Vagrant NFS documentation](https://www.vagrantup.com/docs/synced-folders/nfs.html).

### qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Type `make build-libvirt` and follow the instructions.

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt
vagrant up --provider=libvirt --no-destroy-on-error --no-tty
vagrant ssh
exit
vagrant destroy -f
```

## Windows Host

On a Windows host, install [Chocolatey](https://chocolatey.org/install), then execute the following PowerShell commands in a Administrator PowerShell window:

```powershell
# NB if you want to use Hyper-V see the Hyper-V section in this document
#    and do not install virtualbox at all.
choco install -y virtualbox --params "/NoDesktopShortcut /ExtensionPack"
choco install -y packer vagrant jq msys2
```

Then open a bash shell by starting `C:\tools\msys64\mingw64.exe` and install the remaining dependencies:

```bash
pacman --noconfirm -Sy make zip unzip tar dos2unix netcat procps xorriso mingw-w64-x86_64-libcdio openssh
for n in /*.ini; do
    sed -i -E 's,^#?(MSYS2_PATH_TYPE)=.+,\1=inherit,g' $n
done
exit
```

**NB** The commands described in this README should be executed in a mingw64 bash shell.

### Hyper-V usage

Install [Hyper-V](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v)
and also install the `Windows Sandbox` feature (for some reason,
installing this makes DHCP work properly in the vEthernet Default Switch).

Make sure your user is in the `Hyper-V Administrators` group
or you run with Administrative privileges.

Make sure your Virtual Switch (its vEthernet network adapter) is excluded
from the Windows Firewall protected network connections by executing the
following commands in a bash shell with Administrative privileges:

```bash
PowerShell -Command 'Get-NetFirewallProfile | Select-Object -Property Name,DisabledInterfaceAliases'
PowerShell -Command 'Set-NetFirewallProfile -DisabledInterfaceAliases (Get-NetAdapter -name "vEthernet*" | Where-Object {$_.ifIndex}).InterfaceAlias'
```

Create the base image in a bash shell with Administrative privileges:

```bash
cat >secrets-hyperv.sh <<EOF
# set this value when you need to set the VM Switch Name.
export HYPERV_SWITCH_NAME='Default Switch'
# set this value when you need to set the VM VLAN ID.
export HYPERV_VLAN_ID=''
# set the credentials that the guest will use
# to connect to this host smb share.
# NB you should create a new local user named _vagrant_share
#    and use that one here instead of your user credentials.
# NB it would be nice for this user to have its credentials
#    automatically rotated, if you implement that feature,
#    let me known!
export VAGRANT_SMB_USERNAME='_vagrant_share'
export VAGRANT_SMB_PASSWORD=''
# remove the virtual switch from the windows firewall.
# NB execute if the VM fails to obtain an IP address from DHCP.
PowerShell -Command 'Set-NetFirewallProfile -DisabledInterfaceAliases (Get-NetAdapter -name "vEthernet*" | Where-Object {$_.ifIndex}).InterfaceAlias'
EOF
source secrets-hyperv.sh
make build-hyperv
```

Try the example guest:

**NB** You will need Administrative privileges to create the SMB share.

```bash
cd example
# grant $VAGRANT_SMB_USERNAME full permissions to the
# current directory.
# NB you must first install the Carbon PowerShell module
#    with choco install -y carbon.
# TODO set VM screen resolution.
PowerShell -Command '&"$env:ChocolateyInstall/lib/Carbon/Carbon/Import-Carbon.ps1"; Grant-CPermission . $env:VAGRANT_SMB_USERNAME FullControl'
vagrant up --provider=hyperv --no-destroy-on-error --no-tty
vagrant ssh
exit
vagrant destroy -f
```

# References

* [NixOS Manual](https://nixos.org/manual/nixos/stable/).
* [NixOS Options](https://search.nixos.org/options).
* [Vagrant NixOS Guest Plugin](https://github.com/hashicorp/vagrant/tree/master/plugins/guests/nixos).
* [Vagrant NixOS Guest Plugin Template](https://github.com/hashicorp/vagrant/tree/master/templates/guests/nixos)
