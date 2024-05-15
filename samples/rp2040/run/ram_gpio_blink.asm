.addr 0x20000000; // flash to RAM
.const BLINK_PIN, 0;

	MOVS R0, 1;
	LSLS R0, R0, RESETS_IO_BANK0_BIT; // SIO doesn't get reset
	BL resets_unreset_wait;
	MOVS R0, BLINK_PIN;
	MOVS R1, 1;
	BL gpio_init_out;
halt:
	WFE;
	B halt;

.include "../resets.asm";
.include "../pins/gpio.asm";
