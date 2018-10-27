
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include "PCIE.h"

#define xDMA_CHECK

#define DEMO_PCIE_USER_BAR			PCIE_BAR0


#define DEMO_PCIE_VGA_FRAME0_ADDR					(0x08000000 + 0x1000000)
#define DEMO_PCIE_VGA_FRAME1_ADDR					(0x08000000 + 0x2000000)
#define VGA_WIDTH									640
#define VGA_HEIGHT									480
#define VGA_BYTE_PER_PIXEL							4
#define VGA_FRAME_PIXEL_NUM							(VGA_WIDTH*VGA_HEIGHT)
#define VGA_FRAME_MEM_SIZE							(VGA_FRAME_PIXEL_NUM*VGA_BYTE_PER_PIXEL)
#define VIP_FRAME_READER_ADDR						0x200

typedef enum{
	CH_RED = 0,
	CH_GREEN,
	CH_BLUE
}COLOR_CH;

// color bat pattern
unsigned char PAT_GEN(int mode, int i){
	unsigned char Value;
	int x, y, ch;
	y = i/(VGA_WIDTH*VGA_BYTE_PER_PIXEL) ;
	x = i%(VGA_WIDTH*VGA_BYTE_PER_PIXEL);
	ch = i%VGA_BYTE_PER_PIXEL; // 
	

	Value = 0;
	

	if (y < VGA_HEIGHT/4){
		// gray
		Value = x;
	}else if (y < VGA_HEIGHT*2/4){
		// red
		if (ch == CH_RED)
			Value = x;
	}else if (y < VGA_HEIGHT*3/4){
		// green
		if (ch == CH_GREEN)
			Value = x;
	}else{
		// blue
		if (ch == CH_BLUE)
			Value = x;
	}
	
	if (mode & 0x01)
		Value = Value ^ 0xFF; // invert
		
	return Value;
}


BOOL VIP_SetActiveFrame(PCIE_HANDLE hPCIe, int nActiveFrame){
	BOOL bPass;
	// select active frame
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+3*4, nActiveFrame); 
	return bPass;
}

BOOL VIP_Config(PCIE_HANDLE hPCIe, int Width, int Height){
	BOOL bPass;
	int word = Width*Height;
	int cycle = Width*Height;
	int interlace = 0;
	

	// stop
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR, 0x00); // stop
	
	// frame 0 
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+4*4, DEMO_PCIE_VGA_FRAME0_ADDR); // frame0 base address
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+5*4, word); // frame0 word
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+6*4, cycle); // The number of single-cycle color patterns to read for the frame
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+8*4, Width); // frame0 width
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+9*4, Height); // frame0 height
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+10*4, interlace); // frame0 height
	
	// frame1
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+11*4, DEMO_PCIE_VGA_FRAME1_ADDR); // frame1 base address
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+12*4, word); // frame1 word
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+13*4, cycle); // The number of single-cycle color patterns to read for the frame
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+15*4, Width); // frame1 width
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+16*4, Height); // frame1 height
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+17*4, interlace); // frame1 height
	
	// select active frame
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR+3*4, 0); // frame select, 0 or 1
	
	// start
	bPass = PCIE_Write32(hPCIe, DEMO_PCIE_USER_BAR, VIP_FRAME_READER_ADDR, 0x01); // start
	
	return bPass;
}

BOOL VGA_Display(PCIE_HANDLE hPCIe, BOOL bInvert, int nActiveFrame){
	BOOL bPass = TRUE;
	int i;
	const int nPatternSize = VGA_FRAME_MEM_SIZE;
	const PCIE_LOCAL_ADDRESS LocalAddr = (nActiveFrame==0)?DEMO_PCIE_VGA_FRAME0_ADDR:DEMO_PCIE_VGA_FRAME1_ADDR;
	unsigned char *pPattern;
	char szError[256];
	
#ifdef DMA_CHECK	
	unsigned char ExpectedData;
#endif	

	pPattern = (unsigned char *)malloc(nPatternSize);
	if (!pPattern){
		bPass = FALSE;
		sprintf(szError, "DMA Memory:malloc failed\r\n");
	}
	
	// init test pattern
	if (bPass){
		for(i=0;i<nPatternSize && bPass;i++)
			*(pPattern+i) = PAT_GEN(bInvert, i);
	}
	
	// write test pattern
	if (bPass){
		bPass = PCIE_DmaWrite(hPCIe, LocalAddr, pPattern, nPatternSize);
		if (!bPass)
			sprintf(szError, "DMA Memory:PCIE_DmaWrite failed\r\n");
	}		
#ifdef DMA_CHECK
	// read back test pattern and verify
	if (bPass){
		memset(pPattern, 0x00, nPatternSize);
		bPass = PCIE_DmaRead(hPCIe, LocalAddr, pPattern, nPatternSize);

		if (!bPass){
			sprintf(szError, "DMA Memory:PCIE_DmaRead failed\r\n");
		}else{
			for(i=0;i<nPatternSize && bPass;i++){
				ExpectedData = PAT_GEN(bInvert, i);
				if (*(pPattern+i) != ExpectedData){
					bPass = FALSE;
					sprintf(szError, "DMA Memory:Read-back verify unmatch, index = %d, read=%xh, expected=%xh\r\n", i, *(pPattern+i), ExpectedData);
				}
			}
		}
	}
#endif

	// free resource
	if (pPattern)
		free(pPattern);
		
	if (bPass){
		bPass = VIP_SetActiveFrame(hPCIe, nActiveFrame);
		if (!bPass)
			sprintf(szError, "Faied to set active frame\r\n");
	}
	
	if (!bPass)
		printf("%s", szError);
	else
		printf("DMA-Memory (Size = %d byes) pass\r\n", nPatternSize);


	return bPass;
}




int main(void)
{
	void *lib_handle;
	PCIE_HANDLE hPCIE;
	int nActiveFrame = 0;
	BOOL bInvert = FALSE;
	BOOL bSuccess;

	printf("== Terasic: PCIe VGA Demo Program ==\r\n");

	lib_handle = PCIE_Load();
	if (!lib_handle){
		printf("PCIE_Load failed!\r\n");
		return 0;
	}

	hPCIE = PCIE_Open(0,0,0);
	if (!hPCIE){
		printf("PCIE_Open failed\r\n");
	}else{
		if (!VIP_Config(hPCIE, VGA_WIDTH, VGA_HEIGHT)){
			printf("VIP_Config failed\r\n");
		}else{
			do{
				bSuccess = VGA_Display(hPCIE, bInvert, nActiveFrame);
				if (!bSuccess)
					printf("VGA_Display failed\r\n");
				nActiveFrame = (nActiveFrame+1)%2;
				bInvert = bInvert?FALSE:TRUE;

			}while(bSuccess);
		}
		PCIE_Close(hPCIE);

	}

	PCIE_Unload(lib_handle);
	return 0;
}
