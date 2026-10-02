#include <zephyr/ztest.h>

#include "blink.h"

ZTEST(blink, test_toggles)
{
	zassert_true(blink_next_state(false));
	zassert_false(blink_next_state(true));
}

ZTEST(blink, test_hold_times)
{
	zassert_equal(blink_hold_ms(true), BLINK_ON_MS);
	zassert_equal(blink_hold_ms(false), BLINK_OFF_MS);
}

ZTEST_SUITE(blink, NULL, NULL, NULL, NULL, NULL);
