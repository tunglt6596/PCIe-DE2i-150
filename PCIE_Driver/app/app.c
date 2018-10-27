#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#define PAGE_SIZE						4096
#define MMAP_SIZE						PAGE_SIZE*1024

/*Array size to write and read*/
#define MAX_SIZE_IN						640*480
#define MAX_SIZE_OUT					640*480

/*Operator code for ioctl*/
#define IOCTL_START_VDMA_READ 			0
#define IOCTL_STOP_VDMA_READ 			1
#define IOCTL_START_VDMA_WRITE	  		2
#define IOCTL_STOP_VDMA_WRITE	  		3
#define IOCTL_START_FILTER	  			4
#define IOCTL_STOP_FILTER	  			5

int main() {
	FILE *fi;
	int dev; 
	
	dev = open("/dev/de2i150_altera", O_RDWR);
	if(dev < 0)
    {
        perror("Open device file failed");
        return -1;
    }
	
	unsigned int *mem = NULL;
	int i;
	
	mem = mmap(NULL, MMAP_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dev, 0);
	if (mem == MAP_FAILED)
    {
        perror("mmap operation failed");
        return -1;
    }
	
	fi = fopen("video_in.bin", "rb");
	
	ioctl(dev, IOCTL_START_VDMA_READ, 0);
	ioctl(dev, IOCTL_START_VDMA_WRITE, 0);

	while(1) 
	{
		fseek(fi, 0, SEEK_SET);
		while(!feof(fi)) 
		{
			fread(mem, sizeof(unsigned int), MAX_SIZE_IN, fi);
        
			write(dev, NULL, MAX_SIZE_IN*sizeof(unsigned int));
			usleep(35000);
		}
	}
	
	fclose(fi);
	close(dev);
	
	return 0;
}

