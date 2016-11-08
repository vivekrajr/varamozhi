
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

#
#------------------------- Seting variables ---------------------------
#

include Makefile.in

#
#-------------------- Make function interface of mal ------------------
#

all pure:
	cd common; make
	cd map;    make
	cd malsrc; make $@
	cd lamsrc; make
	cd test;   make

#unicode thoolika mathrubhumi kerala manorama karthika:
#	MAP = mozhi_$@
#	cd common; make
#	cd map;    make
#	cd malsrc; make
#	cd test;   make

#
#-------------------------- Cleaning ----------------------------------
#

clean: cleano
	cd test;   make clean
	cd lamsrc; make clean

cleano: 
	cd test;   make cleano
	cd lamsrc; make cleano
	cd malsrc; make clean
	cd map;    make clean
	cd common; make clean

distclean: clean
	$(RM) $(BINDIR)/*

#
