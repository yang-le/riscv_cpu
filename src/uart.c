#define UART_BASE 0x1000

#define UART_CTRL (*(volatile unsigned char *)(UART_BASE + 0))
#define UART_TXD (*(volatile unsigned char *)(UART_BASE + 1))
#define UART_RXD (*(volatile unsigned char *)(UART_BASE + 2))
#define UART_BDL (*(volatile unsigned char *)(UART_BASE + 3))
#define UART_BDH (*(volatile unsigned char *)(UART_BASE + 4))

#define TX_ENABLE 0x01
#define TX_READY 0x02
#define TX_VALID 0x04
#define RX_ENABLE 0x10
#define RX_READY 0x20
#define RX_VALID 0x40
#define UART_ECHO 0x80

void uart_init()
{
	UART_CTRL |= TX_ENABLE | RX_ENABLE;
}

void uart_tx(char c)
{
	while (!(UART_CTRL & TX_READY));
	UART_TXD = c;
	UART_CTRL |= TX_VALID;
	while(UART_CTRL & TX_READY);
	UART_CTRL &= ~TX_VALID;
}

char uart_rx()
{
    while (UART_CTRL & RX_VALID);
    while (!(UART_CTRL & RX_VALID));
    return UART_RXD;
}
