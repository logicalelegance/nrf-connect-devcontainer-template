#ifndef BLINK_H_
#define BLINK_H_

#include <stdbool.h>
#include <stdint.h>

#define BLINK_ON_MS  100
#define BLINK_OFF_MS 900

/* Next LED state after the current one. */
bool blink_next_state(bool on);

/* How long to stay in the given LED state, in milliseconds. */
int32_t blink_hold_ms(bool on);

#endif /* BLINK_H_ */
