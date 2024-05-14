.const RESETS_ADC_BIT, 0; .export RESETS_ADC_BIT;
.const RESETS_BUSCTRL_BIT, 1; .export RESETS_BUSCTRL_BIT;
.const RESETS_DMA_BIT, 2; .export RESETS_DMA_BIT;
.const RESETS_I2C0_BIT, 3; .export RESETS_I2C0_BIT;
.const RESETS_I2C1_BIT, 4; .export RESETS_I2C1_BIT;
.const RESETS_IO_BANK0_BIT, 5; .export RESETS_IO_BANK0_BIT;
.const RESETS_IO_QSPI_BIT, 6; .export RESETS_IO_QSPI_BIT;
.const RESETS_JTAG_BIT, 7; .export RESETS_JTAG_BIT;
.const RESETS_PADS_BANK0_BIT, 8; .export RESETS_PADS_BANK0_BIT;
.const RESETS_PADS_QSPI_BIT, 9; .export RESETS_PADS_QSPI_BIT;
.const RESETS_PIO0_BIT, 10; .export RESETS_PIO0_BIT;
.const RESETS_PIO1_BIT, 11; .export RESETS_PIO1_BIT;
.const RESETS_PLL_SYS_BIT, 12; .export RESETS_PLL_SYS_BIT;
.const RESETS_PLL_USB_BIT, 13; .export RESETS_PLL_USB_BIT;
.const RESETS_PWM_BIT, 14; .export RESETS_PWM_BIT;
.const RESETS_RTC_BIT, 15; .export RESETS_RTC_BIT;
.const RESETS_SPI0_BIT, 16; .export RESETS_SPI0_BIT;
.const RESETS_SPI1_BIT, 17; .export RESETS_SPI1_BIT;
.const RESETS_SYSCFG_BIT, 18; .export RESETS_SYSCFG_BIT;
.const RESETS_SYSINFO_BIT, 19; .export RESETS_SYSINFO_BIT;
.const RESETS_TBMAN_BIT, 20; .export RESETS_TBMAN_BIT;
.const RESETS_TIMER_BIT, 21; .export RESETS_TIMER_BIT;
.const RESETS_UART0_BIT, 22; .export RESETS_UART0_BIT;
.const RESETS_UART1_BIT, 23; .export RESETS_UART1_BIT;
.const RESETS_USBCTRL_BIT, 24; .export RESETS_USBCTRL_BIT;

// Places peripherals specified by the bitmask `mask` into reset. Returns a bitmask `changed` representing which of
// the requested peripherals are placed into reset. This function does not perform a cycling reset, that is the
// peripherals are not taken out of reset automatically, and this function does not wait for the reset to complete.
// Environment: mask (in, R0), changed (out, R0)
resets_reset:
	LDR R1, _RESETS_MASK;
	ANDS R0, R1;
	LDR R1, _RESETS_BASE;
	MOVS R2, 2;
	LSLS R2, R2, 12;
	ADDS R2, R2, R1;
	LDR R1, [R1 + 0x00]; // RESETS:RESET
	STR R0, [R2 + 0x00]; // RESETS:RESET (atomic set)
	MVNS R1, R1;
	ANDS R0, R1;
	BX LR;

// Takes peripherals specified by the bitmask `mask` out of reset. Returns a bitmask `ready` representing which of the
// requested peripherals are immediately ready to be used, but does not wait for any of them to become ready (see
// `resets_unreset_wait` or `resets_wait` for this purpose). This result is instantly out of date.
// Environment: mask (in, R0), ready (out, R0)
resets_unreset:
	LDR R1, _RESETS_MASK;
	ANDS R0, R1;
	LDR R1, _RESETS_BASE;
	MOVS R2, 3;
	LSLS R2, R2, 12;
	ADDS R2, R2, R1; // RESETS_BASE with atomic bitwise clear
	STR R0, [R2 + 0x00]; // RESETS:RESET
	LDR R1, [R1 + 0x08]; // RESETS:RESET_DONE
	ANDS R0, R1;
	BX LR;

// Takes peripherals specified by the bitmask `mask` out of reset and waits until all of them are ready to be used.
// Only valid peripheral bits are used. If another thread concurrently places one of the selected peripherals back
// into reset this function may block forever.
// Environment: mask (in, R0)
resets_unreset_wait:
	LDR R1, _RESETS_MASK;
	ANDS R0, R1;
	LDR R1, _RESETS_BASE;
	MOVS R2, 3;
	LSLS R2, R2, 12;
	ADDS R2, R2, R1; // RESETS_BASE with atomic bitwise clear
	STR R0, [R2 + 0x00]; // RESETS:RESET
_resets_unreset_wait_loop:
	LDR R2, [R1 + 0x08]; // RESETS:RESET_DONE
	ANDS R2, R0;
	CMP R2, R0;
	BNE _resets_unreset_wait_loop;
	BX LR;

// Waits for the peripherals specified by the bitmask `mask` to become ready for use. Peripherals which haven't been
// taken out of reset are ignored. Returns a bitmask `ready` representing which of the requested peripherals are now
// ready (in contrast to those which have been requested but were not taken out of reset). This function is typically
// used after a number of `resets_unreset` calls (which do not wait) or if you want to take a number of peripherals
// out of reset but only need to use some of them immediately. If another thread concurrently resets/unresets a
// requested peripheral then this function will stop/begin (respectively) to wait for that peripheral to become ready.
// Environment: mask (in, R0), ready (out, R0)
resets_wait:
	LDR R1, _RESETS_MASK;
	ANDS R0, R1;
	LDR R1, _RESETS_BASE;
_resets_wait_loop:
	LDR R2, [R1 + 0x00]; // RESETS:RESET
	LDR R3, [R1 + 0x08]; // RESETS:RESET_DONE
	MVNS R2, R2;
	ANDS R2, R0; // which peripherals are we actually waiting for
	ANDS R3, R0; // which peripherals are ready
	CMP R2, R3;
	BNE _resets_wait_loop; // both sets must match
	MOVS R0, R3; // out of the peripherals we care about, the ones which are ready
	BX LR;

.align 4;
_RESETS_MASK:
	.du32 (1 << (RESETS_USBCTRL_BIT + 1)) - 1;
_RESETS_BASE:
	.du32 0x4000C000;

.export resets_reset;
.export resets_unreset;
.export resets_unreset_wait;
.export resets_wait;
