APP = user-led-test

# Add any other object files to this list below
APP_OBJS = linux_user_led_test.o

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CC) $(LDFLAGS) -o user-led-test $(APP_OBJS) $(LDLIBS)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

clean:
	-rm -f $(APP) *.elf *.gdb *.o
