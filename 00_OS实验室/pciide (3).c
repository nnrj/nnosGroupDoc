#include "stdio.h"
#include "types.h"
typedef unsigned long DWORD;
typedef unsigned int WORD;
#define MK_PDI(bus,dev,func) (WORD)((bus<<8)|(dev<<3)|(func))
#define MK_PCIaddr(bus,dev,func) (DWORD)(0xf8000000L|(DWORD)MK_PDI(bus,dev,func)<<8)
#define PCI_CONFIG_ADDRESS 0xCF8 
#define PCI_CONFIG_DATA 0xCFC
static inline uint8_t inb(uint16_t port)
{
  uint8_t data;
  asm volatile("inb %1,%0"
               : "=a"(data)
               : "d"(port));
  return data;
}

static inline void outb(uint16_t port, uint8_t data)
{
  asm volatile("outb %0,%1"
               :
               : "a"(data), "d"(port));
}

static inline void insl(int port, void *addr, int cnt)
{
  asm volatile("cld; rep insl"
               : "=D"(addr), "=c"(cnt)
               : "d"(port), "0"(addr), "1"(cnt)
               : "memory", "cc");
}


DWORD GetData(DWORD addr)
{
DWORD data;
outb(PCI_CONFIG_ADDRESS,addr);
data = inb(PCI_CONFIG_DATA);
return data;
}
int main()
{
int bus,dev,func;
DWORD addr,addr1,addr2,addr3;
DWORD data,data1,data2,data3;
printf("Bus#\tDev#\tFunc#");
printf("\n");
for (bus = 0; bus <= 0x63; ++bus)
{
for (dev = 0; dev <= 0x1F; ++dev)
{
for (func = 0; func <= 0x7; ++func)
{
addr = MK_PCIaddr(bus,dev,func);
data = GetData(addr);
if((WORD)data!=0xFFFF) 
{
printf("%2.2x\t%2.2x\t%2.2x\t",bus,dev,func);
printf("\n"); 
}
}
}
}
return 0;
}
