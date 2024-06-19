#!/bin/sh
# disable kernel logs on tty (login screen)
sysctl kernel.printk='0 4 0 5'
# change led settings
echo panic | tee /sys/class/leds/blue_led/trigger
echo default-on | tee /sys/class/leds/green_led/trigger
