#include <linux/fs.h>
#include <linux/module.h>                         // MOD_DEVICE_TABLE,
#include <linux/init.h>
#include <linux/pci.h>                            // pci_device_id,
#include <linux/interrupt.h>                      
#include <linux/version.h>                        // KERNEL_VERSION,
#include <linux/platform_device.h>
#include <linux/blkdev.h>
#include <linux/hdreg.h>
#include <linux/vmalloc.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/pci.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/blkdev.h>
#include <linux/sched.h>
#include <linux/interrupt.h>
#include <linux/compiler.h>
#include <linux/workqueue.h>
#include <linux/bitops.h>
#include <linux/delay.h>
#include <linux/time.h>
#include <linux/hdreg.h>
#include <linux/dma-mapping.h>
#include <linux/completion.h>
#include <linux/scatterlist.h>
#include <linux/mm.h>  
#include <asm/io.h>
#include <asm/uaccess.h>
#include <iso646.h>

#define MMAP_SIZE 						PAGE_SIZE*1024
#define MAJOR_NUMBER 					91
#define DIR_BAR_NR 						0
#define CSR_BAR_NR 						2

// Please reference Qsys setting
#define ADDR_WM							0x80000000
#define ADDR_RM							0x84000000

#define ADDR_CRA						0x00000000	
#define	ADDR_CSR						0x02000000
#define ADDR_DES						0x02000020		

#define ADDR_VDMA_READ					0x02000000 
#define ADDR_VDMA_WRITE					0x04000000 

#define ADDR_EN_FILTER					0x06000000 

#define IOCTL_START_VDMA_READ 			0
#define IOCTL_START_VDMA_WRITE	  		1

#define DEMO_PCIE_VGA_FRAME0_ADDR		0x80000000
#define DEMO_PCIE_VGA_FRAME1_ADDR		0x84000000
#define VIP_FRAME_READER_ADDR			0x00000000

#define IMAGE_WIDTH						640
#define IMAGE_HEIGHT					480

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Driver PCIeHello");
MODULE_AUTHOR("TungLT");

//-- Hardware Handles
u32 __iomem * bar0;
u32 __iomem * bar2;

//-- Char Driver Interface
static int   access_count =  0;

static int     char_device_open    ( struct inode * , struct file *);
static int     char_device_release ( struct inode * , struct file *);
static ssize_t char_device_read    ( struct file * , char *,       size_t , loff_t *);
static ssize_t char_device_write   ( struct file * , const char *, size_t , loff_t *);
static int 	   char_device_mmap	   ( struct file * , struct vm_area_struct *);
static long    char_device_ioctl   ( struct file * , unsigned int , unsigned long );

static struct file_operations file_opts = {
	.read = char_device_read,
	.open = char_device_open,
	.write = char_device_write,
	.release = char_device_release,
	.unlocked_ioctl = char_device_ioctl,
	.mmap = char_device_mmap
};

u32 __read( u32* __iomem bar_base, u32 addr )
{ 
	return bar_base[ addr / 4 ];
}

void __write( u32* __iomem bar_base, u32 addr, u32 wdata )
{ 
	bar_base[ addr / 4 ] = wdata ;
	wmb();
	return;
}

static int char_device_open(struct inode *inodep, struct file *filep) {
	int i;
	access_count++;
	filep->private_data = kmalloc(MMAP_SIZE, GFP_KERNEL);
    if (filep->private_data == NULL)
        return -1;
    for(i = 0; i < 1024 * PAGE_SIZE; i += PAGE_SIZE) {
        SetPageReserved(virt_to_page(((unsigned long)filep->private_data) + i));
    }
	printk(KERN_ALERT "altera_driver: opened %d time(s)\n", access_count);
	return 0;
}

static int char_device_release(struct inode *inodep, struct file *filep) {
	int i;
    for(i = 0; i < 1024 * PAGE_SIZE; i += PAGE_SIZE) {
        ClearPageReserved(virt_to_page(((unsigned long)filep->private_data) + i));
    }
    kfree(filep->private_data);
	printk(KERN_ALERT "altera_driver: device closed.\n");
	return 0;
}

static ssize_t char_device_read(struct file *filep, char *buf, size_t len, loff_t *off) {
	u32 control_bits;
	u32* target_to;

	target_to = (u32*)filep->private_data;
	
	while (( __read( bar2, ADDR_CSR) & 0x04) != 0) {
		printk(" spin until there's room for another desciptor\n");
	}  // spin until there is room for another descriptor to be written to the SGDMA
	control_bits = (1<<14); //(1 << 24);  // 14bit is the IRQ, 24bit is the early done bit

	__write( bar2, ADDR_DES, ADDR_RM);
	__write( bar2, ADDR_DES + 4, __pa(target_to) );
	__write( bar2, ADDR_DES + 8, len);
	__write( bar2, ADDR_DES + 0xC, control_bits | (1<<31) );	// go

	return len;
}

static ssize_t char_device_write(struct file *filep, const char *buf, size_t len, loff_t *off) {
	u32 control_bits; 
	u32* copy_from;
	
	copy_from = (u32*)filep->private_data;
	
	while (( __read( bar2, ADDR_CSR) & 0x04) != 0) {
		printk(" spin until there's room for another desciptor\n");
	}  // spin until there is room for another descriptor to be written to the SGDMA
	control_bits = (1<<14); //(1 << 24);  // 14bit is the IRQ, 24bit is the early done bit

	__write( bar2, ADDR_DES, __pa(copy_from) );
	__write( bar2, ADDR_DES + 4, ADDR_WM );
	__write( bar2, ADDR_DES + 8, len);
	__write( bar2, ADDR_DES + 0xC, control_bits | (1<<31) );	// go

	return len;
}

static long char_device_ioctl(struct file *file,           
					   unsigned int ioctl_num,
                       unsigned long ioctl_param)
{
	u32 temp;
	switch(ioctl_num) {
		case IOCTL_START_VDMA_READ:
			temp = __read( bar0, ADDR_VDMA_READ+0xC);
			temp = temp | 0x4;
			__write( bar0, ADDR_VDMA_READ+0xC, temp );
			break;
		case IOCTL_START_VDMA_WRITE:
			temp = __read( bar0, ADDR_VDMA_WRITE+0xC);
			temp = temp | 0x4;
			__write( bar0, ADDR_VDMA_WRITE+0xC, temp );
			break;
		default:
			break;
	}
	return 0;
}

static int char_device_mmap(struct file *filp, struct vm_area_struct *vma) {
	unsigned long pfn;
    printk(KERN_INFO "de2i150_altera: device mmap\n");
    pfn = virt_to_phys((void *)filp->private_data)>>PAGE_SHIFT;
    if ( remap_pfn_range( vma, vma->vm_start, pfn,
        vma->vm_end - vma->vm_start, vma->vm_page_prot ) )
    {
        printk(KERN_INFO "de2i150_altera: device mmap failed\n");
        return -EAGAIN;
    }
    printk(KERN_INFO "de2i150_altera: device mmap OK\n");
    return 0;
}

static int Initialize_sgdma(void)
{
	u32 res, irq_mask, status;
	
	// clear the DMA controller
	res = __read( bar2, ADDR_CSR);
	__write( bar2, ADDR_CSR, 0x200);
	res = __read( bar2, ADDR_CSR);
	__write( bar2, ADDR_CSR+0x04, 0x02);  // issue reset dispatcher
	__write( bar2, ADDR_CSR, 0x0); 	  	  // clear all the status
	__write( bar2, ADDR_CSR+0x04, 0x10);  // set IRQ enable
	res = __read( bar2, ADDR_CSR);
	printk(" after reset %x\n", res);
	
	//enable_global_interrupt_mask (alt_u32 csr_base)
	irq_mask = __read( bar2, ADDR_CSR+0x04);
	irq_mask |= 0x10;
	__write( bar2, ADDR_CSR+0x04, irq_mask); // setting the IRQ enable flag at here 
	res = __read( bar2, ADDR_CSR+0x04);
	// clear the status
	status = __read( bar2, ADDR_CSR);
	__write( bar2, ADDR_CSR, 0x0); 		    // clear all the status
	status = __read( bar2, ADDR_CSR);
	
	return 0;
}

//-- PCI Device Interface
static struct pci_device_id pci_ids[] = {
	{ PCI_DEVICE(0x1172, 0xe001), },
	{ 0, }
};
MODULE_DEVICE_TABLE(pci, pci_ids);

static int pci_probe(struct pci_dev *dev, const struct pci_device_id *id);
static void pci_remove(struct pci_dev *dev);

static struct pci_driver pci_driver = {
	.name     = "alterahello",
	.id_table = pci_ids,
	.probe    = pci_probe,
	.remove   = pci_remove,
};

static int VIP_Config(void){
	int word = IMAGE_WIDTH*IMAGE_HEIGHT;
	int cycle = IMAGE_WIDTH*IMAGE_HEIGHT;
	int interlace = 0;
	
	// stop
	__write( bar0, VIP_FRAME_READER_ADDR, 0x00 ); // stop
	
	// frame 0 
	__write( bar0, VIP_FRAME_READER_ADDR+4*4, DEMO_PCIE_VGA_FRAME0_ADDR ); // frame0 base address
	__write( bar0, VIP_FRAME_READER_ADDR+5*4, word ); // frame0 word
	__write( bar0, VIP_FRAME_READER_ADDR+6*4, cycle ); // The number of single-cycle color patterns to read for the frame
	__write( bar0, VIP_FRAME_READER_ADDR+8*4, IMAGE_WIDTH ); // frame0 width
	__write( bar0, VIP_FRAME_READER_ADDR+9*4, IMAGE_HEIGHT ); // frame0 height
	__write( bar0, VIP_FRAME_READER_ADDR+10*4, interlace ); // frame0 height
	
	// frame1
	__write( bar0, VIP_FRAME_READER_ADDR+11*4, DEMO_PCIE_VGA_FRAME1_ADDR ); // frame1 base address
	__write( bar0, VIP_FRAME_READER_ADDR+12*4, word ); // frame1 word
	__write( bar0, VIP_FRAME_READER_ADDR+13*4, cycle ); // The number of single-cycle color patterns to read for the frame
	__write( bar0, VIP_FRAME_READER_ADDR+15*4, IMAGE_WIDTH ); // frame1 width
	__write( bar0, VIP_FRAME_READER_ADDR+16*4, IMAGE_HEIGHT ); // frame1 height
	__write( bar0, VIP_FRAME_READER_ADDR+17*4, interlace ); // frame1 height
	
	// select active frame
	__write( bar0, VIP_FRAME_READER_ADDR+3*4, 1 ); // frame select, 0 or 1
	
	// start
	__write( bar0, VIP_FRAME_READER_ADDR, 0x01 ); // start
	
	return 0;
}

static int pci_probe(struct pci_dev *dev, const struct pci_device_id *id) {
	int err; 
	//const int test_bar_nr = 0;

	//	long iosize_0,iosize_1;
	printk(KERN_DEBUG "altera : Device 0x%x has been found at"
		" bus %d dev %d func %d\n",
		dev->device, dev->bus->number, PCI_SLOT(dev->devfn),
		PCI_FUNC(dev->devfn));

	err = pci_enable_device (dev); 
	printk("pci_enable_device = %d rev=%d\n",err,dev->revision);

	if( err ) {
		printk(" pci device enable failed \n");
		return err;
	}

	// try to access FPGA via BAR
	printk(" pci/fpga device rev id = 0x%x\n",dev->revision);
	
	printk(KERN_DEBUG "bar0 start at: %llx\n", pci_resource_start(dev, DIR_BAR_NR));
	printk(KERN_DEBUG "bar0 len: %lld\n", pci_resource_len(dev, DIR_BAR_NR));
	bar0 = ioremap(pci_resource_start(dev, DIR_BAR_NR), pci_resource_len(dev, DIR_BAR_NR));
	
	printk(KERN_DEBUG "bar2 start at: %llx\n", pci_resource_start(dev, CSR_BAR_NR));
	printk(KERN_DEBUG "bar2 len: %lld\n", pci_resource_len(dev, CSR_BAR_NR));
	bar2 = ioremap(pci_resource_start(dev, CSR_BAR_NR), pci_resource_len(dev, CSR_BAR_NR));
	
	Initialize_sgdma();
	VIP_Config();
	
	return 0;
}

static void pci_remove(struct pci_dev *dev) {
	iounmap(bar0);
	iounmap(bar2);
	pci_disable_device(dev); 
}


//-- Global module registration
static int __init altera_driver_init(void) {
	int t = register_chrdev(MAJOR_NUMBER, "de2i150_altera", &file_opts);
	t = t | pci_register_driver(&pci_driver);

	if(t<0)
		printk(KERN_ALERT "altera_driver: error: cannot register char or pci.\n");
	else
		printk(KERN_ALERT "altera_driver: char+pci drivers registered.\n");

	return t;
}

static void __exit altera_driver_exit(void) {
	printk(KERN_ALERT "Goodbye from de2i150_altera.\n");

	unregister_chrdev(MAJOR_NUMBER, "de2i150_altera");
	pci_unregister_driver(&pci_driver);
}

module_init(altera_driver_init);
module_exit(altera_driver_exit);
