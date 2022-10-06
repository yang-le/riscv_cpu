#include "timer.h"

#if __riscv_xlen == 32
uint64_t get_time()
{
	uint32_t lo, hi, tmp;
	__asm__ __volatile__("1:\n"
			     "rdtimeh %0\n"
			     "rdtime %1\n"
			     "rdtimeh %2\n"
			     "bne %0, %2, 1b"
			     : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
	return ((uint64_t)hi << 32) | lo;
}
uint64_t get_cycle()
{
	uint32_t lo, hi, tmp;
	__asm__ __volatile__("1:\n"
			     "rdcycleh %0\n"
			     "rdcycle %1\n"
			     "rdcycleh %2\n"
			     "bne %0, %2, 1b"
			     : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
	return ((uint64_t)hi << 32) | lo;
}
#elif __riscv_xlen == 64
uint64_t get_time()
{
	uint64_t n;

	__asm__ __volatile__("rdtime %0" : "=r"(n));
	return n;
}
uint64_t get_cycle()
{
	uint64_t n;

	__asm__ __volatile__("rdcycle %0" : "=r"(n));
	return n;
}
#else
#error "Unexpected __riscv_xlen"
#endif
