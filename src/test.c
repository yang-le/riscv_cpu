#include "uart.h"

void putc(char c)
{
	if (c == '\n')
		uart_tx('\r');
	uart_tx(c);
}

void puts(const char* s)
{
	while(*s)
		putc(*s++);
}

char getc()
{
	char c = uart_rx();
	if (c == '\r')
		c = '\n';
	return c;
}

char* gets()
{
	static char buf[64] = {0};

	while(1)
		for (int i = 0; i < sizeof(buf) - 1; ++i) {
			buf[i] = getc();
			if (buf[i] == '\n') {
				buf[i + 1] = 0;
				return buf;
			}
		}
}

int main()
{
	uart_init();

	while(1) {
		puts("Hello FPGA!\n");
		char *input = gets();
		int i = 1000000;
		while(i--);
		puts("Your input is ");
		puts(input);
		puts("Your input is ");
		puts(input);
	}

	return 0;
}
