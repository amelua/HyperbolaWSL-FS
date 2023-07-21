OUT_TGZ=rootfs.tar.gz

DLR=curl
DLR_FLAGS=-L
BASE_URL=https://archive.fridu.us/hyperbola/iso/2023.07.16/hyperbola-bootstrap.tar.gz
FRTCP_URL=https://github.com/amelua/hyper-prebuild/raw/main/packages/fakeroot-1.24-5-x86_64.pkg.tar.lz
GLIBC_URL=https://github.com/amelua/hyper-prebuild/raw/main/packages/glibc-2.30-3-x86_64.pkg.tar.lz
AL_KEYRING_URL=https://github.com/amelua/hyper-prebuild/raw/main/packages/hyperbola-keyring-20201208-1-any.pkg.tar.lz
PAC_PKGS=hyperbola-keyring base less nano doas vim curl

all: $(OUT_TGZ)

tgz: $(OUT_TGZ)
$(OUT_TGZ): rootfinal.tmp
	@echo -e '\e[1;31mBuilding $(OUT_TGZ)\e[m'
	cd root.x86_64; sudo bsdtar -zcpf ../$(OUT_TGZ) *
	sudo chown `id -un` $(OUT_TGZ)

rootfinal.tmp: glibc.tmp fakeroot.tmp locale.tmp hyperbola-keyring-20201208-1-any.pkg.tar.lzt
	@echo -e '\e[1;31mCleaning files from rootfs...\e[m'
	yes | sudo chroot root.x86_64 /usr/bin/pacman -Scc
	sudo umount root.x86_64/sys
	sudo umount root.x86_64/proc
	-sudo umount root.x86_64/sys
	-sudo umount root.x86_64/proc
	sudo mv -f root.x86_64/etc/mtab.bak root.x86_64/etc/mtab
	sudo cp -f pacman.conf root.x86_64/etc/pacman.conf
	echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee root.x86_64/etc/resolv.conf
	sudo rm -rf `sudo find root.x86_64/root/ -type f`
	sudo rm -rf `sudo find root.x86_64/tmp/ -type f`
	@echo -e '\e[1;31mCopy Extra files to rootfs...\e[m'
	sudo cp bash_profile root.x86_64/root/.bash_profile
	sudo cp hyperbola-keyring-20201208-1-any.pkg.tar.lzt root.x86_64/root/hyperbola-keyring-20201208-1-any.pkg.tar.lzt
	sudo cp wsl.conf root.x86_64/etc/wsl.conf
	echo > rootfinal.tmp

fakeroot.tmp: proc-tmp.tmp glibc.tmp fakeroot-1.24-5-x86_64.pkg.tar.lz
	@echo -e '\e[1;31mInstalling fakeroot...\e[m'
	sudo cp -f fakeroot-1.24-5-x86_64.pkg.tar.lz root.x86_64/root/fakeroot-1.24-5-x86_64.pkg.tar.lz
	yes | sudo chroot root.x86_64 /usr/bin/pacman -U /root/fakeroot-1.24-5-x86_64.pkg.tar.lz
	sudo rm -rf root.x86_64/root/fakeroot-1.24-5-x86_64.pkg.tar.lz
	touch fakeroot.tmp

glibc.tmp: proc-tmp.tmp pacpkgs.tmp glibc-2.30-3-x86_64.pkg.tar.lz
	@echo -e '\e[1;31mInstalling glibc...\e[m'
	sudo cp -f glibc-2.30-3-x86_64.pkg.tar.lz root.x86_64/root/glibc.tar.zst
	yes | sudo chroot root.x86_64 /usr/bin/pacman -U /root/glibc.tar.zst
	sudo rm -rf root.x86_64/root/glibc-2.30-3-x86_64.pkg.tar.lz
	touch  glibc.tmp

pacpkgs.tmp: proc-tmp.tmp resolv-tmp.tmp mirrorlist-tmp.tmp paccnf-tmp.tmp
	@echo -e '\e[1;31mInstalling basic packages...\e[m'
	sudo chroot root.x86_64 /usr/bin/pacman -Syu --noconfirm $(PAC_PKGS)
	sudo mkdir -p root.x86_64/etc/pacman.d/hooks
	sudo setcap cap_net_raw+p root.x86_64/bin/ping
	touch pacpkgs.tmp

locale.tmp: proc-tmp.tmp pacpkgs.tmp
	sudo sed -i -e "s/#en_US.UTF-8/en_US.UTF-8/" root.x86_64/etc/locale.gen
	echo "LANG=en_US.UTF-8" | sudo tee root.x86_64/etc/locale.conf
	sudo ln -sf /etc/locale.conf root.x86_64/etc/default/locale
	sudo chroot root.x86_64 /usr/sbin/locale-gen
	touch locale.tmp

resolv-tmp.tmp: proc-tmp.tmp
	sudo cp -f /etc/resolv.conf root.x86_64/etc/resolv.conf
	touch resolv-tmp.tmp

mirrorlist-tmp.tmp: root.x86_64.tmp
	sudo cp -bf mirrorlist root.x86_64/etc/pacman.d/mirrorlist
	touch mirrorlist-tmp.tmp

paccnf-tmp.tmp: root.x86_64.tmp
	sudo cp -bf pacman.conf.nosig root.x86_64/etc/pacman.conf
	touch paccnf.tmp

proc-tmp.tmp: root.x86_64.tmp
	@echo -e '\e[1;31mMounting proc to rootfs...\e[m'
	sudo mv root.x86_64/etc/mtab root.x86_64/etc/mtab.bak
	echo "rootfs / rootfs rw 0 0" | sudo tee root.x86_64/etc/mtab
	sudo mount -t proc proc root.x86_64/proc/
	sudo mount --bind /sys root.x86_64/sys
	touch proc-tmp.tmp

root.x86_64.tmp: base.tar.gz
	@echo -e '\e[1;31mExtracting rootfs...\e[m'
	sudo bsdtar -zxpf base.tar.gz
	sudo mv -Tv x86_64 root.x86_64
	sudo chmod +x root.x86_64
	touch root.x86_64.tmp

hyperbola-keyring-20201208-1-any.pkg.tar.lzt:
	@echo -e '\e[1;31mDownloading hyperbola-keyring-20201208-1-any.pkg.tar.lzt...\e[m'
	$(DLR) $(DLR_FLAGS) $(GLIBC_URL) -o hyperbola-keyring-20201208-1-any.pkg.tar.lzt

glibc-2.30-3-x86_64.pkg.tar.lz:
	@echo -e '\e[1;31mDownloading glibc-2.30-3-x86_64.pkg.tar.lz...\e[m'
	$(DLR) $(DLR_FLAGS) $(GLIBC_URL) -o glibc-2.30-3-x86_64.pkg.tar.lz

fakeroot-1.24-5-x86_64.pkg.tar.lz:
	@echo -e '\e[1;31mDownloading fakeroot-1.24-5-x86_64.pkg.tar.lz...\e[m'
	$(DLR) $(DLR_FLAGS) $(FRTCP_URL) -o fakeroot-1.24-5-x86_64.pkg.tar.lz

base.tar.gz:
	@echo -e '\e[1;31mDownloading base.tar.gz...\e[m'
	$(DLR) $(DLR_FLAGS) $(BASE_URL) -o base.tar.gz

clean: cleanall

cleanall: cleanroot cleanproc cleantmp cleanpkg cleanbase

cleanroot: cleanproc
	-sudo rm -rf root.x86_64
	-rm root.x86_64.tmp

cleanproc:
	-sudo umount root.x86_64/sys
	-sudo umount root.x86_64/proc
	-sudo umount root.x86_64/sys
	-sudo umount root.x86_64/proc
	-rm proc-tmp.tmp

cleantmp:
	-rm *.tmp

cleanpkg:
	-rm glibc-2.30-3-x86_64.pkg.tar.lz
	-rm fakeroot-1.24-5-x86_64.pkg.tar.lz
	-rm hyperbola-keyring-20201208-1-any.pkg.tar.lzt

cleanbase:
	-rm base.tar.gz
