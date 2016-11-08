
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

CFLAGS += -D $(MAP)
SRCDIR  = ..
OBJS    = malvi_$(MAP).o $(MALSRC)/lib$(MAP).a $(COMMON)/libstr.a

ifeq ($(OS), windows)
EXE     =  malvi_$(MAP).exe
else
EXE     =  malvi_$(MAP)
endif

#
#--------------------------- Build ------------------------------------
#
$(EXE): $(OBJS) $(MALSRC)/mal_api.h $(COMMON)/txt2html.h
	$(CC) $(CFLAGS) -o $@ $(OBJS)
	$(ESC)strip -s $@

malvi_$(MAP).o: malvi.c
	$(CC) $(CFLAGS) -c -o $@ $^

pure: malvi
	purify $(CC) $(PFLAGS) -o pmalvi $(OBJS)

clean: cleano
	$(RM) malvi_*

cleano:
	$(RM) malvi_*.o core .nfs* *.exe.stackdump
