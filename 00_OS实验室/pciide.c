#include <stdio.h>
typedef unsigned char BYTE;
typedef unsigned int  WORD;
typedef unsigned long DWORD;
/* PCI设备索引。bus/dev/func 共16位，为了方便处理可放在一个WORD中 */
#define PDI_BUS_SHIFT        8
#define PDI_BUS_SIZE         8
#define PDI_BUS_MAX          0xFF
#define PDI_BUS_MASK         0xFF00
#define PDI_DEVICE_SHIFT     3
#define PDI_DEVICE_SIZE      5
#define PDI_DEVICE_MAX       0x1F
#define PDI_DEVICE_MASK      0x00F8
#define PDI_FUNCTION_SHIFT   0
#define PDI_FUNCTION_SIZE    3
#define PDI_FUNCTION_MAX     0x7
#define PDI_FUNCTION_MASK    0x0007
#define MK_PDI(bus,dev,func) (WORD)((bus&PDI_BUS_MAX)<<PDI_BUS_SHIFT | (dev&PDI_DEVICE_MAX)<<PDI_DEVICE_SHIFT | (func&PDI_FUNCTION_MAX) )
/* PCI配置空间寄存器 */
#define PCI_CONFIG_ADDRESS   0xCF8
#define PCI_CONFIG_DATA      0xCFC
/* 填充PCI_CONFIG_ADDRESS */
#define MK_PCICFGADDR(bus,dev,func) (DWORD)(0x80000000L | (DWORD)MK_PDI(bus,dev,func) << 8)
/* 读32位端口 */
/*DWORD inpd(int portid)
{
    DWORD dwRet;
    asm mov dx, portid;
    asm lea bx, dwRet;
    __emit__(
    0x66,0x50,      // push EAX
    0x66,0xED,      // in EAX,DX
    0x66,0x89,0x07, // mov [BX],EAX
    0x66,0x58);     // pop EAX
    return dwRet;
}
/* 写32位端口 */
/*void outpd(int portid, DWORD dwVal)
{
    asm mov dx, portid;
    asm lea bx, dwVal;
    __emit__(
    0x66,0x50,      // push EAX
    0x66,0x8B,0x07, // mov EAX,[BX]
    0x66,0xEF,      // out DX,EAX
    0x66,0x58);     // pop EAX
    return;
}*/
static inline void out32(unsigned short port,unsigned long data)
{   asm volatile("outl %0, %1"
                 :
			     : "a"(data), "d"(port));
}			
static inline unsigned long in32(unsigned short port)
{   unsigned long data;
	asm volatile("inl %1, %0"
	             : "=a"(data)
				 : "d"(port));
	return  data;
}	
	
int main(void)
{
    int bus, dev, func;
    int i;
    DWORD dwAddr;
    DWORD dwData;
    FILE* hF;
    char szFile[0x10];
    printf("\n");
    printf("Bus#\tDevice#\tFunc#\tVendor\tDevice\tClass\tIRQ\tIntPin\n");
    /* 枚举PCI设备 */
    for(bus = 0; bus <= PDI_BUS_MAX; ++bus)
    {
        for(dev = 0; dev <= PDI_DEVICE_MAX; ++dev)
        {
            for(func = 0; func <= PDI_FUNCTION_MAX; ++func)
            {
                /* 计算地址 */
                dwAddr = MK_PCICFGADDR(bus, dev, func);
                /* 获取厂商ID */
                out32(PCI_CONFIG_ADDRESS, dwAddr);
                dwData = in32(PCI_CONFIG_DATA);
                /* 判断设备是否存在。FFFFh是非法厂商ID */
                if ((WORD)dwData != 0xFFFF)
                {
                    /* bus/dev/func */
                    printf("%2.2X\t%2.2X\t%1X\t", bus, dev, func);
                    /* Vendor/Device */
                    printf("%4.4X\t%4.4X\t", (WORD)dwData, dwData>>16);
                    /* Class Code */
                    out32(PCI_CONFIG_ADDRESS, dwAddr | 0x8);
                    dwData = in32(PCI_CONFIG_DATA);
                    printf("%6.6lX\t", dwData>>8);
                    /* IRQ/intPin */
                    out32(PCI_CONFIG_ADDRESS, dwAddr | 0x3C);
                    dwData = in32(PCI_CONFIG_DATA);
                    printf("%d\t", (BYTE)dwData);
                    printf("%d", (BYTE)(dwData>>8));
                    printf("\n");
                    /* 写文件 */
                    sprintf(szFile, "PCI%2.2X%2.2X%X.bin", bus, dev, func);
                    hF = fopen(szFile, "wb");
                    if (hF != NULL)
                    {
                        /* 256字节的PCI配置空间 */
                        for (i = 0; i < 0x100; i += 4)
                        {
                            /* Read */
                            out32(PCI_CONFIG_ADDRESS, dwAddr | i);
                            dwData = in32(PCI_CONFIG_DATA);
                            /* Write */
                            fwrite(&dwData, sizeof(dwData), 1, hF);
                        }
                        fclose(hF);
                    }
                }
            }
        }
    }
    return 0;
}