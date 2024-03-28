long user_stack [4096 >> 2];

struct {
	long * a;
	short b;
}stack_start = { & user_stack [4096 >> 2], 0x10};

void start(void) {
	for (;;) {
	}
}
