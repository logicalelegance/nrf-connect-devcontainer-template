#include "blink.h"

bool blink_next_state(bool on)
{
	return !on;
}

int32_t blink_hold_ms(bool on)
{
	return on ? BLINK_ON_MS : BLINK_OFF_MS;
}
