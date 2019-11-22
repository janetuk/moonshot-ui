
CFLAGS_DBUS = $(shell pkg-config --cflags --libs dbus-1)
CFLAGS_DBUS_GLIB = $(shell pkg-config --cflags --libs dbus-glib-1)
CFLAGS_GIO  = $(shell pkg-config --cflags --libs gio-2.0)

CFLAGS = -g -Wall


all: client server


client: client.c
	gcc $< -o $@ $(CFLAGS) $(CFLAGS_GIO) $(CFLAGS_DBUS_GLIB) $(CFLAGS_DBUS)

server: server.c
	gcc $< -o $@ $(CFLAGS) $(CFLAGS_GIO) $(CFLAGS_DBUS_GLIB) $(CFLAGS_DBUS)

clean:
	rm -f client
	rm -f server


.PHONY: all clean