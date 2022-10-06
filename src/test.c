#include "char.h"
#include "timer.h"

const char* conv_u64_str(uint64_t time)
{
	static char buf[16] = {0};
	
	int i = 14;
	for (; (i >= 0) && (time > 0); --i, time /= 10)
		buf[i] = time % 10;
	
	return buf + i + 1;
}

int main()
{
	uart_init();

	while(1) {
		uint64_t t = get_time();
		puts(conv_u64_str(t));
		puts(" Hello FPGA!\n");
		const char *input = gets();
		int i = 1000000;
		while(i--);
		puts("Your input is ");
		puts(input);
		puts("Your input is ");
		puts(input);
	}

	return 0;
}
