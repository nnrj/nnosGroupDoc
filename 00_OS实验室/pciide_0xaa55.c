
#include<stdio.h>
#include<stdint.h>

#define MK_PDI(bus,dev,func) (((bus) << 8 )|((dev) << 3)|(func))
#define MK_PCIaddr(bus,dev,func) (0xf8000000L | MK_PDI(bus, dev, func)<<8)

uint8_t inb(uint16_t port)
{
	uint8_t ret;
	asm volatile ( "inb %1, %0" : "=a"(ret) : "Nd"(port) );
	return ret;
}

void outb(uint16_t port, uint8_t data)
{
	asm volatile ( "outb %0, %1" : : "a"(data), "Nd"(port) );
}

uint8_t GetData(uint8_t addr)
{
	outb(0xcf8, addr);
	return inb(0xcfc);
}

int main()
{
	int bus, dev, func;
	uint32_t addr;
	uint8_t data;
	printf("Bus#\tDev#\tFunc#");
	printf("\n");
	for (bus = 0; bus <= 0x63; ++bus)
	{
		for (dev = 0; dev <= 0x1F; ++dev)
		{
			for (func = 0; func <= 0x7; ++func)
			{
				addr = MK_PCIaddr(bus, dev, func);
				data = GetData(addr);
				printf("%2.2x\t%2.2x\t%2.2x\t", bus, dev, func);
				printf("\n"); 
			}
		}
	}
	return 0;
}
