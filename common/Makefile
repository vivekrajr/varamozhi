
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

SRC = list.c strstruct.c strlist.c strpair.c txt2html.c
OBJ = list.o strstruct.o strlist.o strpair.o txt2html.o
TESTSRC = $(SRC) str_test.c
TESTOBJ = $(OBJ) str_test.o
SRCDIR  = ..

all:	libstr.a

libstr.a: $(OBJ)
	$(AR) $@ $(OBJ)
	-@ (ranlib $@ || true)

test: $(TESTOBJ)
	$(CC) $(CFLAGS) -o str_test $(TESTOBJ)

pure: $(TESTOBJ)
	purify $(CC) $(PFLAGS) -o str_pure $(TESTOBJ)

clean:
	 $(RM) core $(TESTOBJ) str_pure str_test libstr.a .pure

depend:
	makedepend $(SRC)

# DO NOT DELETE

