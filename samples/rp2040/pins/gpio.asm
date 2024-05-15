// Prepares the pin specified by `pin` for GPIO input.
// Environment: pin (in, R0)
gpio_init_in:
	MOVS R2, 1;
	LSLS R2, R2, R0;
	LDR R3, _SIO_BASE;
	// do this first so we don't accidentally output
	STR R2, [R3 + 0x28]; // SIO:GPIO_OE_CLR
	MOVS R2, 0x08;
	MULS R2, R0;
	LDR R3, _IO_BANK0_BASE;
	ADDS R3, R3, R2;
	MOVS R1, 5; // SIO function
	STR R1, [R3 + 0x04]; // IO_BANK0:GPIO*_CTRL
	BX LR;

// Prepares the pin specified by `pin` for GPIO output and initializes it to a value of `value`. A zero value
// disables the pin, any nonzero value enables it.
// Environment: pin (in, R0), value (in, R1)
gpio_init_out:
	MOVS R2, 1;
	LSLS R2, R2, R0;
	LDR R3, _SIO_BASE;
	// set the output value before enabling
	CMP R1, 0;
	BNE _gpio_init_out_high;
	STR R2, [R3 + 0x18]; // SIO:GPIO_OUT_CLR
	B _gpio_init_out_oe;
_gpio_init_out_high:
	STR R2, [R3 + 0x14]; // SIO:GPIO_OUT_SET
_gpio_init_out_oe:
	// set output enable and finally switch to SIO
	STR R2, [R3 + 0x24]; // SIO:GPIO_OE_SET
	MOVS R2, 0x08;
	MULS R2, R0;
	LDR R3, _IO_BANK0_BASE;
	ADDS R3, R3, R2;
	MOVS R1, 5; // SIO function
	STR R1, [R3 + 0x04]; // IO_BANK0:GPIO*_CTRL
	BX LR;

// Reads the GPIO pin specified by `pin` and returns its current level in `value` (either zero or one).
// Environment: pin (in, R0), value (out, R0)
gpio_read:
	LDR R3, _SIO_BASE;
	LDR R1, [R3 + 0x04]; // SIO:GPIO_IN
	LSRS R1, R1, R0;
	MOVS R0, 1;
	ANDS R0, R1;
	BX LR;

// Writes the value in `value` to the pin specified by `pin`. Behavior is unspecified if `pin` is not configured for
// GPIO output (see `gpio_init_out`).
// Environment: pin (in, R0), value (in, R1)
gpio_write:
	MOVS R2, 1;
	LSLS R2, R2, R0;
	LDR R3, _SIO_BASE;
	CMP R1, 0;
	BNE _gpio_write_high;
	STR R2, [R3 + 0x18]; // SIO:GPIO_OUT_CLR
	BX LR;
_gpio_write_high:
	STR R2, [R3 + 0x14]; // SIO:GPIO_OUT_SET
	BX LR;

// Inverts the output value of the GPIO pin specified by `pin`. The same constraints apply as for `gpio_write`.
// Environment: pin (in, R0)
gpio_flip:
	MOVS R2, 1;
	LSLS R2, R2, R0;
	LDR R3, _SIO_BASE;
	STR R2, [R3 + 0x1C]; // SIO:GPIO_OUT_XOR
	BX LR;

.align 4;
_SIO_BASE:
	.du32 0xD0000000;
_IO_BANK0_BASE:
	.du32 0x40014000;

.export gpio_init_in;
.export gpio_init_out;
.export gpio_read;
.export gpio_write;
.export gpio_flip;
