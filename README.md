# Simple Scripts to Make Proxmox a little easier

## How to Use
Each script has -h for help
- Each one tells you which flags are required
- May require some mods to fit your environment but they are laid out in comments

## What's this for anyway?
I created this for my other project you can find here https://github.com/drostangreen/k8s_ansible
Terraform wasn't working the way I wanted so I saw an opportunity for more learning in scripting.

## What Works and What doesn't
Templates tested with most major distros
- Ubuntu
- Debian
- Fedora
- Rocky (likely also RHEL and AlmaLinux but currently untested)
- OpenSuse

Planning on adding Arch as well

## BSD's are not currently supported
- FreeBSD (should be a simple mod)
- OpenBSD (need to research more into Cloud Init on OpenBSD if it is supported)
- Never used NetBSD and don't think its use case matches this but may be willing to add in future
