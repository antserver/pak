#
#   pak-freebsd-default.mk -- Makefile to build Embedthis Pak for freebsd
#

NAME                  := pak
VERSION               := 0.8.2
PROFILE               ?= default
ARCH                  ?= $(shell uname -m | sed 's/i.86/x86/;s/x86_64/x64/;s/arm.*/arm/;s/mips.*/mips/')
CC_ARCH               ?= $(shell echo $(ARCH) | sed 's/x86/i686/;s/x64/x86_64/')
OS                    ?= freebsd
CC                    ?= gcc
CONFIG                ?= $(OS)-$(ARCH)-$(PROFILE)
LBIN                  ?= $(CONFIG)/bin
PATH                  := $(LBIN):$(PATH)

ME_COM_EJS            ?= 1
ME_COM_EST            ?= 1
ME_COM_HTTP           ?= 1
ME_COM_MATRIXSSL      ?= 0
ME_COM_NANOSSL        ?= 0
ME_COM_OPENSSL        ?= 0
ME_COM_PCRE           ?= 1
ME_COM_SQLITE         ?= 0
ME_COM_SSL            ?= 1
ME_COM_VXWORKS        ?= 0
ME_COM_WINSDK         ?= 1
ME_COM_ZLIB           ?= 1

ifeq ($(ME_COM_EST),1)
    ME_COM_SSL := 1
endif
ifeq ($(ME_COM_MATRIXSSL),1)
    ME_COM_SSL := 1
endif
ifeq ($(ME_COM_NANOSSL),1)
    ME_COM_SSL := 1
endif
ifeq ($(ME_COM_OPENSSL),1)
    ME_COM_SSL := 1
endif
ifeq ($(ME_COM_EJS),1)
    ME_COM_ZLIB := 1
endif

ME_COM_COMPILER_PATH  ?= gcc
ME_COM_LIB_PATH       ?= ar
ME_COM_MATRIXSSL_PATH ?= /usr/src/matrixssl
ME_COM_NANOSSL_PATH   ?= /usr/src/nanossl
ME_COM_OPENSSL_PATH   ?= [object Object]

CFLAGS                += -fPIC -w
DFLAGS                += -D_REENTRANT -DPIC $(patsubst %,-D%,$(filter ME_%,$(MAKEFLAGS))) -DME_COM_EJS=$(ME_COM_EJS) -DME_COM_EST=$(ME_COM_EST) -DME_COM_HTTP=$(ME_COM_HTTP) -DME_COM_MATRIXSSL=$(ME_COM_MATRIXSSL) -DME_COM_NANOSSL=$(ME_COM_NANOSSL) -DME_COM_OPENSSL=$(ME_COM_OPENSSL) -DME_COM_PCRE=$(ME_COM_PCRE) -DME_COM_SQLITE=$(ME_COM_SQLITE) -DME_COM_SSL=$(ME_COM_SSL) -DME_COM_VXWORKS=$(ME_COM_VXWORKS) -DME_COM_WINSDK=$(ME_COM_WINSDK) -DME_COM_ZLIB=$(ME_COM_ZLIB) 
IFLAGS                += "-I$(CONFIG)/inc"
LDFLAGS               += 
LIBPATHS              += -L$(CONFIG)/bin
LIBS                  += -ldl -lpthread -lm

DEBUG                 ?= debug
CFLAGS-debug          ?= -g
DFLAGS-debug          ?= -DME_DEBUG
LDFLAGS-debug         ?= -g
DFLAGS-release        ?= 
CFLAGS-release        ?= -O2
LDFLAGS-release       ?= 
CFLAGS                += $(CFLAGS-$(DEBUG))
DFLAGS                += $(DFLAGS-$(DEBUG))
LDFLAGS               += $(LDFLAGS-$(DEBUG))

ME_ROOT_PREFIX        ?= 
ME_BASE_PREFIX        ?= $(ME_ROOT_PREFIX)/usr/local
ME_DATA_PREFIX        ?= $(ME_ROOT_PREFIX)/
ME_STATE_PREFIX       ?= $(ME_ROOT_PREFIX)/var
ME_APP_PREFIX         ?= $(ME_BASE_PREFIX)/lib/$(NAME)
ME_VAPP_PREFIX        ?= $(ME_APP_PREFIX)/$(VERSION)
ME_BIN_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/bin
ME_INC_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/include
ME_LIB_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/lib
ME_MAN_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/share/man
ME_SBIN_PREFIX        ?= $(ME_ROOT_PREFIX)/usr/local/sbin
ME_ETC_PREFIX         ?= $(ME_ROOT_PREFIX)/etc/$(NAME)
ME_WEB_PREFIX         ?= $(ME_ROOT_PREFIX)/var/www/$(NAME)-default
ME_LOG_PREFIX         ?= $(ME_ROOT_PREFIX)/var/log/$(NAME)
ME_SPOOL_PREFIX       ?= $(ME_ROOT_PREFIX)/var/spool/$(NAME)
ME_CACHE_PREFIX       ?= $(ME_ROOT_PREFIX)/var/spool/$(NAME)/cache
ME_SRC_PREFIX         ?= $(ME_ROOT_PREFIX)$(NAME)-$(VERSION)


ifeq ($(ME_COM_EST),1)
    TARGETS           += $(CONFIG)/bin/ca.crt
endif
ifeq ($(ME_COM_EJS),1)
    TARGETS           += $(CONFIG)/bin/ejs.mod
endif
ifeq ($(ME_COM_EST),1)
    TARGETS           += $(CONFIG)/bin/libest.so
endif
TARGETS               += $(CONFIG)/bin/libmprssl.so
TARGETS               += $(CONFIG)/bin/pak

unexport CDPATH

ifndef SHOW
.SILENT:
endif

all build compile: prep $(TARGETS)

.PHONY: prep

prep:
	@echo "      [Info] Use "make SHOW=1" to trace executed commands."
	@if [ "$(CONFIG)" = "" ] ; then echo WARNING: CONFIG not set ; exit 255 ; fi
	@if [ "$(ME_APP_PREFIX)" = "" ] ; then echo WARNING: ME_APP_PREFIX not set ; exit 255 ; fi
	@[ ! -x $(CONFIG)/bin ] && mkdir -p $(CONFIG)/bin; true
	@[ ! -x $(CONFIG)/inc ] && mkdir -p $(CONFIG)/inc; true
	@[ ! -x $(CONFIG)/obj ] && mkdir -p $(CONFIG)/obj; true
	@[ ! -f $(CONFIG)/inc/osdep.h ] && cp src/paks/osdep/osdep.h $(CONFIG)/inc/osdep.h ; true
	@if ! diff $(CONFIG)/inc/osdep.h src/paks/osdep/osdep.h >/dev/null ; then\
		cp src/paks/osdep/osdep.h $(CONFIG)/inc/osdep.h  ; \
	fi; true
	@[ ! -f $(CONFIG)/inc/me.h ] && cp projects/pak-freebsd-default-me.h $(CONFIG)/inc/me.h ; true
	@if ! diff $(CONFIG)/inc/me.h projects/pak-freebsd-default-me.h >/dev/null ; then\
		cp projects/pak-freebsd-default-me.h $(CONFIG)/inc/me.h  ; \
	fi; true
	@if [ -f "$(CONFIG)/.makeflags" ] ; then \
		if [ "$(MAKEFLAGS)" != " ` cat $(CONFIG)/.makeflags`" ] ; then \
			echo "   [Warning] Make flags have changed since the last build: "`cat $(CONFIG)/.makeflags`"" ; \
		fi ; \
	fi
	@echo $(MAKEFLAGS) >$(CONFIG)/.makeflags

clean:
	rm -f "$(CONFIG)/obj/ejsLib.o"
	rm -f "$(CONFIG)/obj/ejsc.o"
	rm -f "$(CONFIG)/obj/estLib.o"
	rm -f "$(CONFIG)/obj/httpLib.o"
	rm -f "$(CONFIG)/obj/mprLib.o"
	rm -f "$(CONFIG)/obj/mprSsl.o"
	rm -f "$(CONFIG)/obj/pak.o"
	rm -f "$(CONFIG)/obj/pcre.o"
	rm -f "$(CONFIG)/obj/zlib.o"
	rm -f "$(CONFIG)/bin/ca.crt"
	rm -f "$(CONFIG)/bin/ejsc"
	rm -f "$(CONFIG)/bin/libejs.so"
	rm -f "$(CONFIG)/bin/libest.so"
	rm -f "$(CONFIG)/bin/libhttp.so"
	rm -f "$(CONFIG)/bin/libmpr.so"
	rm -f "$(CONFIG)/bin/libmprssl.so"
	rm -f "$(CONFIG)/bin/libpcre.so"
	rm -f "$(CONFIG)/bin/libzlib.so"
	rm -f "$(CONFIG)/bin/pak"

clobber: clean
	rm -fr ./$(CONFIG)


ifeq ($(ME_COM_EST),1)
#
#   ca-crt
#
DEPS_1 += src/paks/est/ca.crt

$(CONFIG)/bin/ca.crt: $(DEPS_1)
	@echo '      [Copy] $(CONFIG)/bin/ca.crt'
	mkdir -p "$(CONFIG)/bin"
	cp src/paks/est/ca.crt $(CONFIG)/bin/ca.crt
endif

#
#   mpr.h
#
$(CONFIG)/inc/mpr.h: $(DEPS_2)
	@echo '      [Copy] $(CONFIG)/inc/mpr.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/mpr/mpr.h $(CONFIG)/inc/mpr.h

#
#   me.h
#
$(CONFIG)/inc/me.h: $(DEPS_3)
	@echo '      [Copy] $(CONFIG)/inc/me.h'

#
#   osdep.h
#
$(CONFIG)/inc/osdep.h: $(DEPS_4)
	@echo '      [Copy] $(CONFIG)/inc/osdep.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/osdep/osdep.h $(CONFIG)/inc/osdep.h

#
#   mprLib.o
#
DEPS_5 += $(CONFIG)/inc/me.h
DEPS_5 += $(CONFIG)/inc/mpr.h
DEPS_5 += $(CONFIG)/inc/osdep.h

$(CONFIG)/obj/mprLib.o: \
    src/paks/mpr/mprLib.c $(DEPS_5)
	@echo '   [Compile] $(CONFIG)/obj/mprLib.o'
	$(CC) -c -o $(CONFIG)/obj/mprLib.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/paks/mpr/mprLib.c

#
#   libmpr
#
DEPS_6 += $(CONFIG)/inc/mpr.h
DEPS_6 += $(CONFIG)/inc/me.h
DEPS_6 += $(CONFIG)/inc/osdep.h
DEPS_6 += $(CONFIG)/obj/mprLib.o

$(CONFIG)/bin/libmpr.so: $(DEPS_6)
	@echo '      [Link] $(CONFIG)/bin/libmpr.so'
	$(CC) -shared -o $(CONFIG)/bin/libmpr.so $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/mprLib.o" $(LIBS) 

#
#   pcre.h
#
$(CONFIG)/inc/pcre.h: $(DEPS_7)
	@echo '      [Copy] $(CONFIG)/inc/pcre.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/pcre/pcre.h $(CONFIG)/inc/pcre.h

#
#   pcre.o
#
DEPS_8 += $(CONFIG)/inc/me.h
DEPS_8 += $(CONFIG)/inc/pcre.h

$(CONFIG)/obj/pcre.o: \
    src/paks/pcre/pcre.c $(DEPS_8)
	@echo '   [Compile] $(CONFIG)/obj/pcre.o'
	$(CC) -c -o $(CONFIG)/obj/pcre.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/paks/pcre/pcre.c

ifeq ($(ME_COM_PCRE),1)
#
#   libpcre
#
DEPS_9 += $(CONFIG)/inc/pcre.h
DEPS_9 += $(CONFIG)/inc/me.h
DEPS_9 += $(CONFIG)/obj/pcre.o

$(CONFIG)/bin/libpcre.so: $(DEPS_9)
	@echo '      [Link] $(CONFIG)/bin/libpcre.so'
	$(CC) -shared -o $(CONFIG)/bin/libpcre.so $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/pcre.o" $(LIBS) 
endif

#
#   http.h
#
$(CONFIG)/inc/http.h: $(DEPS_10)
	@echo '      [Copy] $(CONFIG)/inc/http.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/http/http.h $(CONFIG)/inc/http.h

#
#   httpLib.o
#
DEPS_11 += $(CONFIG)/inc/me.h
DEPS_11 += $(CONFIG)/inc/http.h
DEPS_11 += $(CONFIG)/inc/mpr.h

$(CONFIG)/obj/httpLib.o: \
    src/paks/http/httpLib.c $(DEPS_11)
	@echo '   [Compile] $(CONFIG)/obj/httpLib.o'
	$(CC) -c -o $(CONFIG)/obj/httpLib.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/paks/http/httpLib.c

ifeq ($(ME_COM_HTTP),1)
#
#   libhttp
#
DEPS_12 += $(CONFIG)/inc/mpr.h
DEPS_12 += $(CONFIG)/inc/me.h
DEPS_12 += $(CONFIG)/inc/osdep.h
DEPS_12 += $(CONFIG)/obj/mprLib.o
DEPS_12 += $(CONFIG)/bin/libmpr.so
DEPS_12 += $(CONFIG)/inc/pcre.h
DEPS_12 += $(CONFIG)/obj/pcre.o
ifeq ($(ME_COM_PCRE),1)
    DEPS_12 += $(CONFIG)/bin/libpcre.so
endif
DEPS_12 += $(CONFIG)/inc/http.h
DEPS_12 += $(CONFIG)/obj/httpLib.o

LIBS_12 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_12 += -lpcre
endif

$(CONFIG)/bin/libhttp.so: $(DEPS_12)
	@echo '      [Link] $(CONFIG)/bin/libhttp.so'
	$(CC) -shared -o $(CONFIG)/bin/libhttp.so $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/httpLib.o" $(LIBPATHS_12) $(LIBS_12) $(LIBS_12) $(LIBS) 
endif

#
#   zlib.h
#
$(CONFIG)/inc/zlib.h: $(DEPS_13)
	@echo '      [Copy] $(CONFIG)/inc/zlib.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/zlib/zlib.h $(CONFIG)/inc/zlib.h

#
#   zlib.o
#
DEPS_14 += $(CONFIG)/inc/me.h
DEPS_14 += $(CONFIG)/inc/zlib.h

$(CONFIG)/obj/zlib.o: \
    src/paks/zlib/zlib.c $(DEPS_14)
	@echo '   [Compile] $(CONFIG)/obj/zlib.o'
	$(CC) -c -o $(CONFIG)/obj/zlib.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/paks/zlib/zlib.c

ifeq ($(ME_COM_ZLIB),1)
#
#   libzlib
#
DEPS_15 += $(CONFIG)/inc/zlib.h
DEPS_15 += $(CONFIG)/inc/me.h
DEPS_15 += $(CONFIG)/obj/zlib.o

$(CONFIG)/bin/libzlib.so: $(DEPS_15)
	@echo '      [Link] $(CONFIG)/bin/libzlib.so'
	$(CC) -shared -o $(CONFIG)/bin/libzlib.so $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/zlib.o" $(LIBS) 
endif

#
#   ejs.h
#
$(CONFIG)/inc/ejs.h: $(DEPS_16)
	@echo '      [Copy] $(CONFIG)/inc/ejs.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/ejs/ejs.h $(CONFIG)/inc/ejs.h

#
#   ejs.slots.h
#
$(CONFIG)/inc/ejs.slots.h: $(DEPS_17)
	@echo '      [Copy] $(CONFIG)/inc/ejs.slots.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/ejs/ejs.slots.h $(CONFIG)/inc/ejs.slots.h

#
#   ejsByteGoto.h
#
$(CONFIG)/inc/ejsByteGoto.h: $(DEPS_18)
	@echo '      [Copy] $(CONFIG)/inc/ejsByteGoto.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/ejs/ejsByteGoto.h $(CONFIG)/inc/ejsByteGoto.h

#
#   ejsLib.o
#
DEPS_19 += $(CONFIG)/inc/me.h
DEPS_19 += $(CONFIG)/inc/ejs.h
DEPS_19 += $(CONFIG)/inc/mpr.h
DEPS_19 += $(CONFIG)/inc/pcre.h
DEPS_19 += $(CONFIG)/inc/osdep.h
DEPS_19 += $(CONFIG)/inc/http.h
DEPS_19 += $(CONFIG)/inc/ejs.slots.h
DEPS_19 += $(CONFIG)/inc/zlib.h

$(CONFIG)/obj/ejsLib.o: \
    src/paks/ejs/ejsLib.c $(DEPS_19)
	@echo '   [Compile] $(CONFIG)/obj/ejsLib.o'
	$(CC) -c -o $(CONFIG)/obj/ejsLib.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/paks/ejs/ejsLib.c

ifeq ($(ME_COM_EJS),1)
#
#   libejs
#
DEPS_20 += $(CONFIG)/inc/mpr.h
DEPS_20 += $(CONFIG)/inc/me.h
DEPS_20 += $(CONFIG)/inc/osdep.h
DEPS_20 += $(CONFIG)/obj/mprLib.o
DEPS_20 += $(CONFIG)/bin/libmpr.so
DEPS_20 += $(CONFIG)/inc/pcre.h
DEPS_20 += $(CONFIG)/obj/pcre.o
ifeq ($(ME_COM_PCRE),1)
    DEPS_20 += $(CONFIG)/bin/libpcre.so
endif
DEPS_20 += $(CONFIG)/inc/http.h
DEPS_20 += $(CONFIG)/obj/httpLib.o
ifeq ($(ME_COM_HTTP),1)
    DEPS_20 += $(CONFIG)/bin/libhttp.so
endif
DEPS_20 += $(CONFIG)/inc/zlib.h
DEPS_20 += $(CONFIG)/obj/zlib.o
ifeq ($(ME_COM_ZLIB),1)
    DEPS_20 += $(CONFIG)/bin/libzlib.so
endif
DEPS_20 += $(CONFIG)/inc/ejs.h
DEPS_20 += $(CONFIG)/inc/ejs.slots.h
DEPS_20 += $(CONFIG)/inc/ejsByteGoto.h
DEPS_20 += $(CONFIG)/obj/ejsLib.o

ifeq ($(ME_COM_HTTP),1)
    LIBS_20 += -lhttp
endif
LIBS_20 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_20 += -lpcre
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_20 += -lzlib
endif

$(CONFIG)/bin/libejs.so: $(DEPS_20)
	@echo '      [Link] $(CONFIG)/bin/libejs.so'
	$(CC) -shared -o $(CONFIG)/bin/libejs.so $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/ejsLib.o" $(LIBPATHS_20) $(LIBS_20) $(LIBS_20) $(LIBS) 
endif

#
#   ejsc.o
#
DEPS_21 += $(CONFIG)/inc/me.h
DEPS_21 += $(CONFIG)/inc/ejs.h

$(CONFIG)/obj/ejsc.o: \
    src/paks/ejs/ejsc.c $(DEPS_21)
	@echo '   [Compile] $(CONFIG)/obj/ejsc.o'
	$(CC) -c -o $(CONFIG)/obj/ejsc.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/paks/ejs/ejsc.c

ifeq ($(ME_COM_EJS),1)
#
#   ejsc
#
DEPS_22 += $(CONFIG)/inc/mpr.h
DEPS_22 += $(CONFIG)/inc/me.h
DEPS_22 += $(CONFIG)/inc/osdep.h
DEPS_22 += $(CONFIG)/obj/mprLib.o
DEPS_22 += $(CONFIG)/bin/libmpr.so
DEPS_22 += $(CONFIG)/inc/pcre.h
DEPS_22 += $(CONFIG)/obj/pcre.o
ifeq ($(ME_COM_PCRE),1)
    DEPS_22 += $(CONFIG)/bin/libpcre.so
endif
DEPS_22 += $(CONFIG)/inc/http.h
DEPS_22 += $(CONFIG)/obj/httpLib.o
ifeq ($(ME_COM_HTTP),1)
    DEPS_22 += $(CONFIG)/bin/libhttp.so
endif
DEPS_22 += $(CONFIG)/inc/zlib.h
DEPS_22 += $(CONFIG)/obj/zlib.o
ifeq ($(ME_COM_ZLIB),1)
    DEPS_22 += $(CONFIG)/bin/libzlib.so
endif
DEPS_22 += $(CONFIG)/inc/ejs.h
DEPS_22 += $(CONFIG)/inc/ejs.slots.h
DEPS_22 += $(CONFIG)/inc/ejsByteGoto.h
DEPS_22 += $(CONFIG)/obj/ejsLib.o
DEPS_22 += $(CONFIG)/bin/libejs.so
DEPS_22 += $(CONFIG)/obj/ejsc.o

LIBS_22 += -lejs
ifeq ($(ME_COM_HTTP),1)
    LIBS_22 += -lhttp
endif
LIBS_22 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_22 += -lpcre
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_22 += -lzlib
endif

$(CONFIG)/bin/ejsc: $(DEPS_22)
	@echo '      [Link] $(CONFIG)/bin/ejsc'
	$(CC) -o $(CONFIG)/bin/ejsc $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/ejsc.o" $(LIBPATHS_22) $(LIBS_22) $(LIBS_22) $(LIBS) $(LIBS) 
endif

ifeq ($(ME_COM_EJS),1)
#
#   ejs.mod
#
DEPS_23 += src/paks/ejs/ejs.es
DEPS_23 += $(CONFIG)/inc/mpr.h
DEPS_23 += $(CONFIG)/inc/me.h
DEPS_23 += $(CONFIG)/inc/osdep.h
DEPS_23 += $(CONFIG)/obj/mprLib.o
DEPS_23 += $(CONFIG)/bin/libmpr.so
DEPS_23 += $(CONFIG)/inc/pcre.h
DEPS_23 += $(CONFIG)/obj/pcre.o
ifeq ($(ME_COM_PCRE),1)
    DEPS_23 += $(CONFIG)/bin/libpcre.so
endif
DEPS_23 += $(CONFIG)/inc/http.h
DEPS_23 += $(CONFIG)/obj/httpLib.o
ifeq ($(ME_COM_HTTP),1)
    DEPS_23 += $(CONFIG)/bin/libhttp.so
endif
DEPS_23 += $(CONFIG)/inc/zlib.h
DEPS_23 += $(CONFIG)/obj/zlib.o
ifeq ($(ME_COM_ZLIB),1)
    DEPS_23 += $(CONFIG)/bin/libzlib.so
endif
DEPS_23 += $(CONFIG)/inc/ejs.h
DEPS_23 += $(CONFIG)/inc/ejs.slots.h
DEPS_23 += $(CONFIG)/inc/ejsByteGoto.h
DEPS_23 += $(CONFIG)/obj/ejsLib.o
DEPS_23 += $(CONFIG)/bin/libejs.so
DEPS_23 += $(CONFIG)/obj/ejsc.o
DEPS_23 += $(CONFIG)/bin/ejsc

$(CONFIG)/bin/ejs.mod: $(DEPS_23)
	( \
	cd src/paks/ejs; \
	../../../$(CONFIG)/bin/ejsc --out ../../../$(CONFIG)/bin/ejs.mod --optimize 9 --bind --require null ejs.es ; \
	)
endif


#
#   est.h
#
$(CONFIG)/inc/est.h: $(DEPS_24)
	@echo '      [Copy] $(CONFIG)/inc/est.h'
	mkdir -p "$(CONFIG)/inc"
	cp src/paks/est/est.h $(CONFIG)/inc/est.h

#
#   estLib.o
#
DEPS_25 += $(CONFIG)/inc/me.h
DEPS_25 += $(CONFIG)/inc/est.h
DEPS_25 += $(CONFIG)/inc/osdep.h

$(CONFIG)/obj/estLib.o: \
    src/paks/est/estLib.c $(DEPS_25)
	@echo '   [Compile] $(CONFIG)/obj/estLib.o'
	$(CC) -c -o $(CONFIG)/obj/estLib.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/paks/est/estLib.c

ifeq ($(ME_COM_EST),1)
#
#   libest
#
DEPS_26 += $(CONFIG)/inc/est.h
DEPS_26 += $(CONFIG)/inc/me.h
DEPS_26 += $(CONFIG)/inc/osdep.h
DEPS_26 += $(CONFIG)/obj/estLib.o

$(CONFIG)/bin/libest.so: $(DEPS_26)
	@echo '      [Link] $(CONFIG)/bin/libest.so'
	$(CC) -shared -o $(CONFIG)/bin/libest.so $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/estLib.o" $(LIBS) 
endif

#
#   mprSsl.o
#
DEPS_27 += $(CONFIG)/inc/me.h
DEPS_27 += $(CONFIG)/inc/mpr.h
DEPS_27 += $(CONFIG)/inc/est.h

$(CONFIG)/obj/mprSsl.o: \
    src/paks/mpr/mprSsl.c $(DEPS_27)
	@echo '   [Compile] $(CONFIG)/obj/mprSsl.o'
	$(CC) -c -o $(CONFIG)/obj/mprSsl.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) "-I$(ME_COM_MATRIXSSL_PATH)" "-I$(ME_COM_MATRIXSSL_PATH)/matrixssl" "-I$(ME_COM_NANOSSL_PATH)/src" src/paks/mpr/mprSsl.c

#
#   libmprssl
#
DEPS_28 += $(CONFIG)/inc/mpr.h
DEPS_28 += $(CONFIG)/inc/me.h
DEPS_28 += $(CONFIG)/inc/osdep.h
DEPS_28 += $(CONFIG)/obj/mprLib.o
DEPS_28 += $(CONFIG)/bin/libmpr.so
DEPS_28 += $(CONFIG)/inc/est.h
DEPS_28 += $(CONFIG)/obj/estLib.o
ifeq ($(ME_COM_EST),1)
    DEPS_28 += $(CONFIG)/bin/libest.so
endif
DEPS_28 += $(CONFIG)/obj/mprSsl.o

LIBS_28 += -lmpr
ifeq ($(ME_COM_EST),1)
    LIBS_28 += -lest
endif
ifeq ($(ME_COM_MATRIXSSL),1)
    LIBS_28 += -lmatrixssl
    LIBPATHS_28 += -L$(ME_COM_MATRIXSSL_PATH)
endif
ifeq ($(ME_COM_NANOSSL),1)
    LIBS_28 += -lssls
    LIBPATHS_28 += -L$(ME_COM_NANOSSL_PATH)/bin
endif

$(CONFIG)/bin/libmprssl.so: $(DEPS_28)
	@echo '      [Link] $(CONFIG)/bin/libmprssl.so'
	$(CC) -shared -o $(CONFIG)/bin/libmprssl.so $(LDFLAGS) $(LIBPATHS)   "$(CONFIG)/obj/mprSsl.o" $(LIBPATHS_28) $(LIBS_28) $(LIBS_28) $(LIBS) 

#
#   pak.mod
#
DEPS_29 += src/Package.es
DEPS_29 += src/pak.es
DEPS_29 += src/paks/ejs-version/Version.es
DEPS_29 += $(CONFIG)/inc/mpr.h
DEPS_29 += $(CONFIG)/inc/me.h
DEPS_29 += $(CONFIG)/inc/osdep.h
DEPS_29 += $(CONFIG)/obj/mprLib.o
DEPS_29 += $(CONFIG)/bin/libmpr.so
DEPS_29 += $(CONFIG)/inc/pcre.h
DEPS_29 += $(CONFIG)/obj/pcre.o
ifeq ($(ME_COM_PCRE),1)
    DEPS_29 += $(CONFIG)/bin/libpcre.so
endif
DEPS_29 += $(CONFIG)/inc/http.h
DEPS_29 += $(CONFIG)/obj/httpLib.o
ifeq ($(ME_COM_HTTP),1)
    DEPS_29 += $(CONFIG)/bin/libhttp.so
endif
DEPS_29 += $(CONFIG)/inc/zlib.h
DEPS_29 += $(CONFIG)/obj/zlib.o
ifeq ($(ME_COM_ZLIB),1)
    DEPS_29 += $(CONFIG)/bin/libzlib.so
endif
DEPS_29 += $(CONFIG)/inc/ejs.h
DEPS_29 += $(CONFIG)/inc/ejs.slots.h
DEPS_29 += $(CONFIG)/inc/ejsByteGoto.h
DEPS_29 += $(CONFIG)/obj/ejsLib.o
ifeq ($(ME_COM_EJS),1)
    DEPS_29 += $(CONFIG)/bin/libejs.so
endif
DEPS_29 += $(CONFIG)/obj/ejsc.o
ifeq ($(ME_COM_EJS),1)
    DEPS_29 += $(CONFIG)/bin/ejsc
endif

$(CONFIG)/bin/pak.mod: $(DEPS_29)
	( \
	cd .; \
	$(LBIN)/ejsc --out ./$(CONFIG)/bin/pak.mod --optimize 9 ./src/Package.es ./src/pak.es ./src/paks/ejs-version/Version.es ; \
	)

#
#   pak.o
#
DEPS_30 += $(CONFIG)/inc/me.h
DEPS_30 += $(CONFIG)/inc/ejs.h

$(CONFIG)/obj/pak.o: \
    src/pak.c $(DEPS_30)
	@echo '   [Compile] $(CONFIG)/obj/pak.o'
	$(CC) -c -o $(CONFIG)/obj/pak.o $(LDFLAGS) -fPIC $(DFLAGS) $(IFLAGS) src/pak.c

#
#   pak
#
DEPS_31 += $(CONFIG)/inc/mpr.h
DEPS_31 += $(CONFIG)/inc/me.h
DEPS_31 += $(CONFIG)/inc/osdep.h
DEPS_31 += $(CONFIG)/obj/mprLib.o
DEPS_31 += $(CONFIG)/bin/libmpr.so
DEPS_31 += $(CONFIG)/inc/pcre.h
DEPS_31 += $(CONFIG)/obj/pcre.o
ifeq ($(ME_COM_PCRE),1)
    DEPS_31 += $(CONFIG)/bin/libpcre.so
endif
DEPS_31 += $(CONFIG)/inc/http.h
DEPS_31 += $(CONFIG)/obj/httpLib.o
ifeq ($(ME_COM_HTTP),1)
    DEPS_31 += $(CONFIG)/bin/libhttp.so
endif
DEPS_31 += $(CONFIG)/inc/zlib.h
DEPS_31 += $(CONFIG)/obj/zlib.o
ifeq ($(ME_COM_ZLIB),1)
    DEPS_31 += $(CONFIG)/bin/libzlib.so
endif
DEPS_31 += $(CONFIG)/inc/ejs.h
DEPS_31 += $(CONFIG)/inc/ejs.slots.h
DEPS_31 += $(CONFIG)/inc/ejsByteGoto.h
DEPS_31 += $(CONFIG)/obj/ejsLib.o
ifeq ($(ME_COM_EJS),1)
    DEPS_31 += $(CONFIG)/bin/libejs.so
endif
DEPS_31 += $(CONFIG)/obj/ejsc.o
ifeq ($(ME_COM_EJS),1)
    DEPS_31 += $(CONFIG)/bin/ejsc
endif
DEPS_31 += $(CONFIG)/bin/pak.mod
DEPS_31 += $(CONFIG)/obj/pak.o

ifeq ($(ME_COM_EJS),1)
    LIBS_31 += -lejs
endif
ifeq ($(ME_COM_HTTP),1)
    LIBS_31 += -lhttp
endif
LIBS_31 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_31 += -lpcre
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_31 += -lzlib
endif

$(CONFIG)/bin/pak: $(DEPS_31)
	@echo '      [Link] $(CONFIG)/bin/pak'
	$(CC) -o $(CONFIG)/bin/pak $(LDFLAGS) $(LIBPATHS) "$(CONFIG)/obj/pak.o" $(LIBPATHS_31) $(LIBS_31) $(LIBS_31) $(LIBS) $(LIBS) 

#
#   stop
#
stop: $(DEPS_32)

#
#   installBinary
#
installBinary: $(DEPS_33)
	( \
	cd .; \
	mkdir -p "$(ME_APP_PREFIX)" ; \
	rm -f "$(ME_APP_PREFIX)/latest" ; \
	ln -s "0.8.2" "$(ME_APP_PREFIX)/latest" ; \
	mkdir -p "$(ME_VAPP_PREFIX)/bin" ; \
	cp $(CONFIG)/bin/pak $(ME_VAPP_PREFIX)/bin/pak ; \
	mkdir -p "$(ME_BIN_PREFIX)" ; \
	rm -f "$(ME_BIN_PREFIX)/pak" ; \
	ln -s "$(ME_VAPP_PREFIX)/bin/pak" "$(ME_BIN_PREFIX)/pak" ; \
	cp $(CONFIG)/bin/libejs.so $(ME_VAPP_PREFIX)/bin/libejs.so ; \
	cp $(CONFIG)/bin/libest.so $(ME_VAPP_PREFIX)/bin/libest.so ; \
	cp $(CONFIG)/bin/libhttp.so $(ME_VAPP_PREFIX)/bin/libhttp.so ; \
	cp $(CONFIG)/bin/libmpr.so $(ME_VAPP_PREFIX)/bin/libmpr.so ; \
	cp $(CONFIG)/bin/libmprssl.so $(ME_VAPP_PREFIX)/bin/libmprssl.so ; \
	cp $(CONFIG)/bin/libpcre.so $(ME_VAPP_PREFIX)/bin/libpcre.so ; \
	cp $(CONFIG)/bin/libzlib.so $(ME_VAPP_PREFIX)/bin/libzlib.so ; \
	cp $(CONFIG)/bin/ca.crt $(ME_VAPP_PREFIX)/bin/ca.crt ; \
	cp $(CONFIG)/bin/ejs.mod $(ME_VAPP_PREFIX)/bin/ejs.mod ; \
	cp $(CONFIG)/bin/pak.mod $(ME_VAPP_PREFIX)/bin/pak.mod ; \
	mkdir -p "$(ME_VAPP_PREFIX)/doc/man/man1" ; \
	cp doc/man/pak.1 $(ME_VAPP_PREFIX)/doc/man/man1/pak.1 ; \
	mkdir -p "$(ME_MAN_PREFIX)/man1" ; \
	rm -f "$(ME_MAN_PREFIX)/man1/pak.1" ; \
	ln -s "$(ME_VAPP_PREFIX)/doc/man/man1/pak.1" "$(ME_MAN_PREFIX)/man1/pak.1" ; \
	)

#
#   start
#
start: $(DEPS_34)

#
#   install
#
DEPS_35 += stop
DEPS_35 += installBinary
DEPS_35 += start

install: $(DEPS_35)

#
#   uninstall
#
DEPS_36 += stop

uninstall: $(DEPS_36)
	( \
	cd .; \
	rm -fr "$(ME_VAPP_PREFIX)" ; \
	rm -f "$(ME_APP_PREFIX)/latest" ; \
	rmdir -p "$(ME_APP_PREFIX)" 2>/dev/null ; true ; \
	)

#
#   version
#
version: $(DEPS_37)

