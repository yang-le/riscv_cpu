#pragma once

typedef char			int8_t;
typedef unsigned char		uint8_t;

typedef short			int16_t;
typedef unsigned short		uint16_t;

typedef int			int32_t;
typedef unsigned int		uint32_t;

#if __riscv_xlen == 32
typedef long long		int64_t;
typedef unsigned long long	uint64_t;
#elif __riscv_xlen == 64
typedef long			int64_t;
typedef unsigned long		uint64_t;
#else
#error "Unexpected __riscv_xlen"
#endif

typedef unsigned long		size_t;
typedef long			ssize_t;

#define NULL			((void *)0)
