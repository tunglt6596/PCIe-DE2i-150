#!/bin/sh
sudo insmod ./driver/altera_driver.ko
sudo mknod /dev/de2i150_altera c 91 1
sudo chmod 777 /dev/de2i150_altera

