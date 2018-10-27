# Embedded System project - IT4797 - SoICT - HUST

* Study to use PCIe IP Core, SG-DMA IP Core,... with Intel FPGA.
* Write an IP Core to implement convolution operator by kernel 3x3 and input image 640x480, compatible with Avalon Video Streaming Interface.  
* Display video via VGA, run demo with Gaussian, Sobel, Prewitt, Mean filter.

## Getting Started

* PCIE_Display: Quartus project, I've used 17.1 version to build it, you can use both Lite/Standard Edition versions without any problem. Note: ip_repo sub-folder contains my convolution IP Core, verilog HDL code.
* PCIE_Driver: PCIe device driver to control SG-DMA, Frame Reader...

### Prerequisites

* I use Ubuntu 14.04 for DE2i-150. Kernel version is 4.4.0. You can check with this command:

```
$ uname -r
``` 

* Please add this two options into grub booting commands:

```
/etc/grub.conf: vmalloc=512MB intel_iommu=off
```

* With Ubuntu 14.04, you change this line in /etc/default/grub:

```
GRUB_CMDLINE_LINUX="vmalloc=512MB intel_iommu=off"
``` 

* If you're using another kernel version, maybe you need to modify device driver. To build device devicer:

```
$ cd driver
$ make
```

* To build application:

```
$ cd app
$ make
```

### Installing

* Run quick_start.sh with sudo permission to install device driver and create device file automatically.
```
$ sudo ./quick_start.sh
```
* Or you can install device driver and create device file manually.
```
$ cd driver
$ sudo insmod altera_driver.ko
$ sudo mknod /dev/de2i150_altera c 91 1
$ sudo chmod 777 /dev/de2i150_altera
```
* Go to PCIE_Driver/app, run app.
```
$ cd app
$ sudo ./app
```
* Connect screen to VGA FPGA port, you'll see the results.
 
## Running the tests

* Change states of SWs 0 to 7 to see changes on screen. If all 7 SWs are 0, the original video is displayed. Else:
- 0000001: Gaussian filter, sigma equals 1.
- 0000010: Gaussian filter, sigma equals 2.
- 0000100: Sobel filter, x axis.
- 0001000: Sobel filter, y axis.
- 0010000: Prewitt filter, x axis.
- 0100000: Prewitt filter, y axis.
- 1000000: Mean filter.

## Deployment

Some videos demo:

```
https://www.youtube.com/watch?v=xrvb_FH-_Zc
```

```
https://www.youtube.com/watch?v=viAXmyh9PdA
```

```
https://www.youtube.com/watch?v=bKAL7i8swpI
```

## Versioning

1.0

## Authors

* Student Tung Le Thanh and lecturer Tien Nguyen Duc. 

## License

This project is not licenced.

## Acknowledgments

* MsC Tien Nguyen Duc, who supervised and supported me in this project.

