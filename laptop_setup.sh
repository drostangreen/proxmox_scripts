#!/bin/bash

# Disable Sleep on Close
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
echo -e "HandleLidSwitch=ignore\nHandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf


sed -i.bak 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet consoleblank=300"/' /etc/default/grub
update-grub

echo "Will Reboot in 5 seconds"
sleep
reboot
