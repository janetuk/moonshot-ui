ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

bin_PROGRAMS = src/moonshot


AM_CPPFLAGS = \
	-include config.h \
	$(moonshot_CFLAGS)

AM_VALAFLAGS = \
	--pkg gtk+-2.0

src_moonshot_SOURCES = \
        src/moonshot-window.vala

src_moonshot_LDADD = \
        $(moonshot_LIBS)
