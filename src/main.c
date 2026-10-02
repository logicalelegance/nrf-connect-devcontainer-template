#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>

#include "blink.h"

static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);

int main(void)
{
	bool on = false;

	if (!gpio_is_ready_dt(&led) || gpio_pin_configure_dt(&led, GPIO_OUTPUT_INACTIVE) < 0) {
		return 0;
	}

	while (1) {
		on = blink_next_state(on);
		gpio_pin_set_dt(&led, on);
		k_msleep(blink_hold_ms(on));
	}
	return 0;
}
