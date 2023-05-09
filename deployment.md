---
title: Deployment
layout: page
---
# Prerequisites
## KVM access
Faasten runs functions in [Firecracker microVMs](https://firecracker-microvm.github.io/) which
uses [KVM](https://www.linux-kvm.org/page/Main_Page) as the hypervisor.
```shell
# check that kvm is enabled
ls /dev/kvm
# access KVM as non-root
sudo usermod -G -a kvm "username"
# reboot so that the modification above takes effect
sudo reboot
```
## Docker access
MicroVMs require a root file-system to run.
Faasten builds root file-systems using Docker as the root. A root file-system should be built per
supported language runtime.
```shell
# from faasten project's root directory
cd rootfs
# currently only python3 runtime is complete
sudo ./mk_rtimage.sh python3 python3.ext4
```
# Bootstrap Faasten

