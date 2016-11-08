
#    Varamozhi: A tool for transliteration of Malayalam text between
#               English and Malayalam scripts
#
#    Copyright (C) 1998-2008  Cibu C. J. <cibucj@gmail.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

include ../Makefile.in
FONTFILE  =  $(SRCDIR)/map/schm_font/$(FONT).map
OBJ       =  lex.$(FONT).o lam.tab.o $(COMMON)/libstr.a
TRANS_H   =  $(FONT)_trans.h
CFLAGS   +=  -include $(TRANS_H)
SRCDIR    =  ..

ifeq ($(OS), windows)
EXE       =  lamvi_$(FONT).exe
else
EXE       =  lamvi_$(FONT)
endif

#
#--------------------------- Build ------------------------------------
#
$(EXE): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^
	$(ESC)strip -s $@

lex.$(FONT).o: lam.tab.h $(TRANS_H)

lam.tab.o: $(TRANS_H)

lam.tab.c lam.tab.h: lam.y
	$(PARSER) lam.y

$(TRANS_H) $(FONT).l: lam.lex.pre lam.lex.post $(FONTFILE) table_lam.pl
	perl -w ./table_lam.pl $(FONTFILE) $(FONT).l $(TRANS_H)

lex.$(FONT).c: $(FONT).l
	$(SCANNER) -o$@ $(FONT).l


#
#-------------------------- Cleaning ----------------------------------
#

clean : cleano
	$(RM) -rf lamvi_*


cleano : 
	$(RM) -rf lam.tab.[cho] lex.*.[co] lam *.l *_trans.h lamdir core lamvi_*.o
