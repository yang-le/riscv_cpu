#pragma once

#include "uart.h"

void putc(char c);
void puts(const char* s);
char getc();
const char* gets();
