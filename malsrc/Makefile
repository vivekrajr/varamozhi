
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

MACRO   = macro_$(MAP)
OBJ     = mal.tab.o lex.$(MAP).o lex.$(MACRO).o $(MAP)_default.o
LIBS    = lib$(MAP).dll lib$(MAP)_dll.a
MAPFILE = $(MAPDIR)/$(MAP).map
SRCZIP  = $(MAP).zip
SRCDIR  = ..

#
#--------------------------- Build ------------------------------------
#

#all: $(LIBS)
#$(LIBS): $(MALLIB)

all: $(MALLIB)

$(MALLIB): $(OBJ)
	$(AR) $@ $(OBJ) ../common/*.o
	-@ (ranlib $@ || true)

$(OBJ): mal-type.h mal-decl.h 

mal.tab.c mal.tab.h: mal.y
	$(PARSER) mal.y

lex.$(MAP).c: $(MAP).l 
	$(SCANNER) -P$(MAP) $(MAP).l 

lex.$(MACRO).c: $(MACRO).l
	$(SCANNER) -P$(MACRO) $(MACRO).l

$(MAP)_default.c $(MAP).l $(MACRO).l: lex.pre.tmplt lex.post.tmplt $(MAPFILE) table.pl macro.l.tmpl
	perl -w ./table.pl $(MAPFILE) $(MAP).l $(MAP)_default.c

#
#-------------------------- Cleaning ----------------------------------
#

clean : 
	$(RM) -rf $(IFEXE) *.tab.[ch] lex.*.c *_default.c *.o lib*.a core *.flc lex.*.c *.zip *.l *.exe *.exe.stackdump


#include Makefile.DLLs