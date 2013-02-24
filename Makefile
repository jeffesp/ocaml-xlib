#  This file is a build script for the OCaml-Xlib bindings.
#  Copyright (C) 2008, 2009 Florent Monnier
##contact:
##	@printf "fmonnier%s"'linux-nantes.org\n' "@"
# 
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# The Software is provided "AS IS", without warranty of any kind, express or
# implied, including but not limited to the warranties of merchantability,
# fitness for a particular purpose and noninfringement. In no event shall
# the authors or copyright holders be liable for any claim, damages or other
# liability, whether in an action of contract, tort or otherwise, arising
# from, out of or in connection with the Software or the use or other dealings
# in the Software.

PREFIX := "$(shell ocamlc -where)/Xlib"
SHARE_DOC_DIR := /usr/local/share/doc

OCAMLOPT := ocamlopt.opt -g
OCAMLC := ocamlc.opt -g
OCAMLMKLIB := ocamlmklib

all: cma opt
cma: Xlib.cma  keysym.cma  keysym_match.cma
opt: Xlib.cmxa keysym.cmxa keysym_match.cmxa
x: cma opt
GLX glx: GLX.cma GLX.cmxa
GLX_P2T glx_p2t: GLX_P2T.cma GLX_P2T.cmxa
Xt xt: Xt.cma Xt.cmxa
alls everything: all opt xt glx glx_p2t

.PHONY: all alls opt everything clean cleaner cleandoc clean-doc
.PHONY: Xt xt GLX glx GLX_P2T glx_p2t
.PHONY: dist snapshot
.PHONY: install install_x install_glx install_glx_p2t install_xt install_all

# {{{ mlcpp 
#  Makes use of a minimal preprocessor for OCaml source files.
#  It is similar to cpp, but this replacement for cpp is because
#  cpp versions in different environments may have different
#  behaviour with unexpected reactions which will break OCaml code.

MLPP=./mlcpp.exe

$(MLPP): mlcpp.ml
	$(OCAMLOPT) str.cmxa $< -o $@

clean-mlcpp: $(MLPP)
	rm -f $(MLPP)
# }}}

# Xlib
wrap_xlib.o: wrap_xlib.c
	$(OCAMLC) -c $<

dll_xlib_stubs.so lib_xlib_stubs.a: wrap_xlib.o
	$(OCAMLMKLIB)  -o  _xlib_stubs  $< \
	    -L/usr/X11R6/lib -lX11 \
	    -L`$(OCAMLC) -where` -lbigarray

Xlib.cmi: Xlib.ml $(MLPP)
	$(OCAMLC) -c -pp '$(MLPP) -C -D MLI=1' -intf $<
Xlib.mli: Xlib.ml $(MLPP)
	$(MLPP) -C -D MLI=1 $< > $@

Xlib.cmo: Xlib.ml Xlib.cmi $(MLPP)
	$(OCAMLC) -c -pp '$(MLPP) -C -D ML=1' $<

Xlib.cma: Xlib.cmo  dll_xlib_stubs.so
	$(OCAMLC) -a  -o $@  $<  -dllib -l_xlib_stubs \
	    -ccopt -L/usr/X11R6/lib  -cclib -lX11

Xlib.cmx: Xlib.ml Xlib.cmi $(MLPP)
	$(OCAMLOPT) -c -pp '$(MLPP) -C -D ML=1' $<

Xlib.cmxa Xlib.a: Xlib.cmx  dll_xlib_stubs.so
	$(OCAMLOPT) -a  -o $@  $<  -cclib -l_xlib_stubs \
	    -ccopt -L.  -ccopt -L/usr/X11R6/lib  -cclib -lX11 \
	    -cclib -lbigarray
Xlib.a: Xlib.cmxa

XLIB_INSTALL_SOLIB := dll_xlib_stubs.so
XLIB_INSTALL_FILES := lib_xlib_stubs.a  \
                      Xlib.cmi  Xlib.a  Xlib.cma  Xlib.cmx  Xlib.cmxa \
                      Xlib.mli

# KeySyms
%.cmi: %.mli
	$(OCAMLC) $<

keysym.mli: keysym.ml
	$(OCAMLC) -i $< > $@

keysym.ml: keysym.h.ml  keysymdef.h.ml $(MLPP)
	@echo "(* DO NOT EDIT THIS FILE *)" > $@
	$(MLPP) $< >> $@

keysym.cma: keysym.ml keysym.cmi
	$(OCAMLC) -a -o $@ $<

keysym.cmxa: keysym.ml
	$(OCAMLOPT) -a  -o $@ $<

keysym_match.mli: keysym_match.ml
	# -w u : disable warnings for unused (redundant) match cases
	$(OCAMLC) -i -w u $< > $@

keysym_match.ml: keysym_match.h.ml  keysymdef_match.h.ml $(MLPP)
	@echo "(* DO NOT EDIT THIS FILE *)" > $@
	$(MLPP) $< >> $@

keysym_match.cma: keysym_match.ml keysym_match.cmi
	# -w u : disable warnings for unused (redundant) match cases
	$(OCAMLC) -a -w u -o $@ $<

keysym_match.cmxa: keysym_match.ml
	# -w u : disable warnings for unused (redundant) match cases
	$(OCAMLOPT) -a -w -u -o $@ $<

KEYSYM_INSTALL_FILES := keysym.cma  keysym_match.cma \
                        keysym.cmxa keysym_match.cmxa \
                        keysym.cmi  keysym_match.cmi \
                        keysym.a    keysym_match.a


# GLX
wrap_glx.o: wrap_glx.c wrap_glx.h wrap_xlib.h
	$(OCAMLC) -c $<

  # glx symbols seems to reside in libGL
dll_glx_stubs.so lib_glx_stubs.a: wrap_glx.o
	$(OCAMLMKLIB)  -o  _glx_stubs  $< \
	    -L/usr/X11R6/lib  -lGL

GLX.cmi: GLX.mli Xlib.cmi
	$(OCAMLC) -c $<
GLX.mli: GLX.ml Xlib.cmi
	$(OCAMLC) -i $< > $@

#GLX.cmi: GLX.ml $(MLPP)
#	$(OCAMLC) -c -pp '$(MLPP) -C -D MLI=1' -intf $<
#GLX.mli: GLX.ml $(MLPP)
#	$(MLPP) -C -D MLI=1 $< > $@

GLX.cmo: GLX.ml GLX.cmi
	$(OCAMLC) -c $<

GLX.cma: GLX.cmo  dll_glx_stubs.so
	$(OCAMLC) -a  -o $@  $<  -dllib -l_glx_stubs \
	    -ccopt -L/usr/X11R6/lib  -cclib -lGL

GLX.cmx: GLX.ml GLX.cmi
	$(OCAMLOPT) -c $<

GLX.cmxa: GLX.cmx  dll_glx_stubs.so
	$(OCAMLOPT) -a  -o $@  $<  -cclib -l_glx_stubs \
	    -ccopt -L/usr/X11R6/lib  -cclib -lGL

GLX_INSTALL_SOLIB := dll_glx_stubs.so
GLX_INSTALL_FILES := lib_glx_stubs.a  \
                     GLX.cmi  GLX.a  GLX.cma  GLX.cmx  GLX.cmxa

clean_glx:
	rm -f \
	  $(GLX_INSTALL_SOLIB) \
	  $(GLX_INSTALL_FILES)


# GLX_P2T
wrap_glx_p2t.o: wrap_glx_p2t.c wrap_xlib.h wrap_glx.h
	$(OCAMLC) -c $<

dll_glx_p2t_stubs.so lib_glx_p2t_stubs.a: wrap_glx_p2t.o
	$(OCAMLMKLIB)  -o  _glx_p2t_stubs  $< \
	    -L/usr/X11R6/lib  -lGL

GLX_P2T.mli: GLX_P2T.ml GLX.cmi
	$(OCAMLC) -i $< > $@

GLX_P2T.cmi: GLX_P2T.mli GLX.cmi Xlib.cmi
	$(OCAMLC) -c $<

GLX_P2T.cmo: GLX_P2T.ml GLX_P2T.cmi
	$(OCAMLC) -c $<

GLX_P2T.cma: GLX_P2T.cmo  dll_glx_p2t_stubs.so Xlib.cmi
	$(OCAMLC) -a  -o $@  $<  -dllib -l_glx_p2t_stubs \
	    -ccopt -L/usr/X11R6/lib  -cclib -lGL

GLX_P2T.cmx: GLX_P2T.ml GLX_P2T.cmi
	$(OCAMLOPT) -c $<

GLX_P2T.cmxa: GLX_P2T.cmx  dll_glx_p2t_stubs.so
	$(OCAMLOPT) -a  -o $@  $<  -cclib -l_glx_p2t_stubs \
	    -ccopt -L/usr/X11R6/lib  -cclib -lGL

GLX_P2T_INSTALL_SOLIB := dll_glx_p2t_stubs.so
GLX_P2T_INSTALL_FILES := lib_glx_p2t_stubs.a  \
                         GLX_P2T.cma  GLX_P2T.cmi \
                         GLX_P2T.cmxa  GLX_P2T.a  GLX_P2T.cmx

clean_glx_p2t:
	rm -f \
	  $(GLX_P2T_INSTALL_SOLIB) \
	  $(GLX_P2T_INSTALL_FILES)


# Intrinsic
wrap_xt.o: wrap_xt.c
	$(OCAMLC) -c $<

dll_xt_stubs.so lib_xt_stubs.a: wrap_xt.o
	$(OCAMLMKLIB)  -o  _xt_stubs  $< \
	    -L/usr/X11R6/lib -lX11 -lXt -lXaw

Xt.mli: Xt.ml Xlib.cmi
	$(OCAMLC) -i $< > $@

Xt.cmi: Xt.mli
	$(OCAMLC) -c $<

Xt.cmo: Xt.ml Xt.cmi
	$(OCAMLC) -c $<

Xt.cma: Xt.cmo  dll_xt_stubs.so
	$(OCAMLC) -a  -o $@  $<  -dllib -l_xt_stubs \
	    -ccopt -L/usr/X11R6/lib  -cclib -lX11  -cclib -lXt  -cclib -lXaw

Xt.cmx: Xt.ml Xt.cmi
	$(OCAMLOPT) -c $<

Xt.cmxa: Xt.cmx  dll_xt_stubs.so
	$(OCAMLOPT) -a  -o $@  $<  -cclib -l_xt_stubs \
	    -ccopt -L/usr/X11R6/lib  -cclib -lX11  -cclib -lXt  -cclib -lXaw

XT_INSTALL_SOLIB := dll_xt_stubs.so
XT_INSTALL_FILES := lib_xt_stubs.a  \
                    Xt.cmi  Xt.a  Xt.cma  Xt.cmx  Xt.cmxa

# Clean
clean:
	rm -f *.[oa] *.so *.cm[ixoa] *.cmxa
	rm -f *.opt *.byte
	rm -f  keysym.ml  keysym_match.ml
	rm -f  Xlib.mli     \
	       GLX.mli      \
	       Xt.mli       \
	       keysym.mli   \
	       keysym_match.mli
	rm -f test_img.ppm

cleaner: clean cleandoc clean-mlcpp
	rm -f *~

# DOC
doc: Xlib.cmi GLX.cmi GLX_P2T.cmi Xlib.mli GLX.ml GLX_P2T.ml keysym.mli  keysym_match.mli Xt.mli _style.css
	if [ ! -d doc ]; then mkdir doc ; fi
	# remove "-css-style _style.css" if it hurts you too much :)
	ocamldoc -html -colorize-code -css-style _style.css -d doc \
	      Xlib.mli  keysym.mli  keysym_match.mli  Xt.mli \
	      GLX.ml  GLX_P2T.ml
	cp _style.css doc/

install-doc: doc
	mv -f doc $(SHARE_DOC_DIR)/OCaml-Xlib

cleandoc clean-doc:
	if [ -d doc ]; then rm -f doc/*; rmdir doc; fi


# Installs
install: install_x
install_all: install_x install_glx install_glx_p2t install_xt
install_alls: install_all

# Install X
install_x: cma opt \
   $(XLIB_INSTALL_SOLIB) \
   $(XLIB_INSTALL_FILES) \
   $(KEYSYM_INSTALL_FILES)

	if [ ! -d $(PREFIX) ]; then install -d $(PREFIX) ; fi

	install -m 0755  \
	    $(XLIB_INSTALL_SOLIB) \
	    $(PREFIX)/

	install -m 0644  \
	    $(XLIB_INSTALL_FILES) \
	    $(KEYSYM_INSTALL_FILES) \
	    $(PREFIX)/

	install -m 0644 META $(PREFIX)/

# Install GLX
install_glx: glx \
   $(GLX_INSTALL_SOLIB) \
   $(GLX_INSTALL_FILES)

	if [ ! -d $(PREFIX) ]; then install -d $(PREFIX) ; fi

	install -m 0755  \
	    $(GLX_INSTALL_SOLIB) \
	    $(PREFIX)/

	install -m 0644  \
	    $(GLX_INSTALL_FILES) \
	    $(PREFIX)/

# Install GLX_P2T
install_glx_p2t: glx_p2t \
   $(GLX_P2T_INSTALL_SOLIB) \
   $(GLX_P2T_INSTALL_FILES)

	if [ ! -d $(PREFIX) ]; then install -d $(PREFIX) ; fi

	install -m 0755  \
	    $(GLX_P2T_INSTALL_SOLIB) \
	    $(PREFIX)/

	install -m 0644  \
	    $(GLX_P2T_INSTALL_FILES) \
	    $(PREFIX)/

# Install XT
install_xt: xt \
  $(XT_INSTALL_SOLIB) \
  $(XT_INSTALL_FILES)

	if [ ! -d $(PREFIX) ]; then install -d $(PREFIX) ; fi

	install -m 0755  \
	    $(XT_INSTALL_SOLIB) \
	    $(PREFIX)/

	install -m 0644  \
	    $(XT_INSTALL_FILES) \
	    $(PREFIX)/

uninstall:
	rm $(PREFIX)/*
	rmdir $(PREFIX)/

# Dist
VERSION := $(shell date +"%Y%m%d")
DIST_DIR := "OCamlXlib-$(VERSION)"
DIST_FILES := \
    Xlib.ml                   \
    keysym.h.ml               \
    keysymdef.h.ml            \
    keysym_match.h.ml         \
    keysymdef_match.h.ml      \
    keysym.README.txt         \
    GLX.ml                    \
    GLX_P2T.ml                \
    Xt.ml                     \
    Makefile                  \
    mlcpp.ml                  \
    _style.css                \
    wrap_xlib.c               \
    wrap_xlib.h               \
    wrap_glx.c                \
    wrap_glx.h                \
    wrap_glx_p2t.c            \
    wrap_xt.c                 \
    README.txt                \
    LICENSE.txt               \
    META

EXMPL_FILES := \
    wikipedia_example.ml      \
    wikipedia_example.sh      \
    double_buffer.ml          \
    double_buffer.sh          \
    glxdemo.ml                \
    glxdemo.sh                \
    intrinsic.ml              \
    intrinsic.sh              \
    xcolor.ml                 \
    xcolor.sh                 \
    xppm.ml                   \
    xppm.sh                   \
    error.ml                  \
    error.sh                  \
    pixmap_to_gl.ml           \
    pixmap_to_gl.sh           \
    simple_text.ml            \
    simple_text.sh            \
    texture_from_pixmap.c     \
    texture_from_pixmap.ml    \
    texture_from_pixmap.sh    \
    install_glmlite_in_tmp.sh \
    test-utf16.ml

snapshot:
	$(MAKE) dist -e VERSION=`date +"%Y%m%d"`

dist: $(DIST_FILES)  $(EXMPL_FILES)
	if [ -d $(DIST_DIR)/ ]; then rm -rf $(DIST_DIR)/*; else mkdir $(DIST_DIR)/; fi
	for file in `echo $(DIST_FILES)`; do cp $$file  $(DIST_DIR)/ ; done
	for file in `echo $(EXMPL_FILES)`; do cp $$file  $(DIST_DIR)/ ; done
	sed -i -e "s/@VERSION@/$(VERSION)/" $(DIST_DIR)/META
	cp ./keysym.h ./keysymdef.h $(DIST_DIR)/
	mv LICENSE.txt $(DIST_DIR)/
	tar cf  $(DIST_DIR).tar  $(DIST_DIR)/
	gzip -9 $(DIST_DIR).tar
	test -f $(DIST_DIR).tgz || rm -f $(DIST_DIR).tgz
	mv $(DIST_DIR).tar.gz  $(DIST_DIR).tgz
	ls -lh  $(DIST_DIR).tgz

# vim: fdm=marker
