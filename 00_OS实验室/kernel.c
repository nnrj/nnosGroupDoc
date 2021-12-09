#include "types.h"
void printchar(char c,char line_x,char col_y,char corlor);
void printstr(char *s,char start_line_x,char start_col_y,char corlor);
void printk(const char *message);
void entry(void)
{
   uint16_t *video_buffer = (uint16_t *)0xb8000;
   char *str="C kernel is Starting......\0";
   for (int i = 0; i < 80 * 25; i++)
   {
    video_buffer[i] = (video_buffer[i] & 0xff00) | ' ';
   }

   printchar('H',4,0,0x0c);
   printchar('e',4,1,0x0c);
   printchar('l',4,2,0x0c);
   printchar('l',4,3,0x0c);
   printchar('o',4,4,0x09);
   printstr(str,5,0,0x0c);
   
   
   
}
void printchar(char c,char line_x,char col_y,char corlor)
{
   *(char *)(0xb8000+line_x*160+2*col_y) =c;
   *(char *)(0xb8000+line_x*160+2*col_y+1) =corlor;
}

/*打印一个字符串,参数:字符串首地址,开始行号,开始列号,字符颜色*/
void printstr(char *s,char start_line_x,char start_col_y,char corlor)
{
   do
    {
    printchar(*s,start_line_x,start_col_y,corlor);
    start_col_y++;
    }
   while (*(s++)!='\0');
}

void printk(const char *message)
{
  unsigned short *video_buffer = (unsigned short *)0xb8000;
  
  for (int i = 0; message[i] != '\0'; i++)
  {
    video_buffer[i] = (video_buffer[i] & 0xff00) | message[i];
  }
}