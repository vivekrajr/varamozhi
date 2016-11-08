/*

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

*/


%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "strlist.h"
#include "strpair.h"
#include "mal-type.h"
#include "mal-decl.h"

#define HAVE_PARTS(i) ((map[i][LEFT][0] != 0) || (map[i][RIGHT][0] != 0))
#define HAVE_CHILL(i) (map[i][CHILL][0] != 0)
#define HAVE_R_DOT(i) (map[i][R_DOT][0] != 0)
#define CAN_R_DOT(i)  (allowRdot && HAVE_R_DOT(i))

#define RULE_DUMP { if (debug) { fprintf(stderr, "rule at %s:%u\n", __FILE__, __LINE__ ); } }

static STRPAIR append_syllable_add2add(STRPAIR p, UINT secindex, APPEND_MODE mode);
static STRPAIR append_syllable_noadd2add(STRPAIR p, UINT secindex, APPEND_MODE mode);
static STRPAIR append_syllable_add2noadd(STRPAIR p, UINT secindex, APPEND_MODE mode);
static STRPAIR append_syllable_noadd2noadd(STRPAIR p, UINT secindex, APPEND_MODE mode);
static STRPAIR create_syllable(UINT index, CREATE_MODE mode);
static STRLIST create_nonsyllable(UINT index,  COMPONENT mode);
static STRLIST extern_fn(STRLIST slist, EXTERN_TRANS_FN func);
static void    yyerror(char msg[]);

static int dqcount;
static int sqcount;
static char* mal_out_text;
static STATUS status;
static BOOLEAN allowRdot;
static BOOLEAN processmacro;

extern BOOLEAN carrycomment; /* defined in yylex() */

Private         private;
EXTERN_TRANS_FN fn_eng_trans;
EXTERN_TRANS_FN fn_mal_trans;
STRSTRUCT       halfcooked;
BOOLEAN         debug;

%}

%union {
     int     val;
     UCHAR*  str;
     STRLIST slist;
     STRPAIR pair;
}


%token <val> AAA
%token <val> VOWEL
%token <val> SVARKOOT
%token <val> BAKKI
%token <val> GSs
%token <val> DA
%token <val> DDD
%token <val> THA

%token <val> YZH
%token <val> VVV

%token <val> lll
%token <val> nnn
%token <val> NNN
%token <val> MMM
%token <val> LLL
%token <val> RRR

%token <val> DQ
%token <val> SQ
%token <val> SYMBOL
%token <str> ENGLISH
%token <str> UNKNOWN

%type <val>  vowela vowelk vowelak
%type <slist> text text1 mal mal1 mal_ eng_ wordstr rest
%type <pair> word wordv
%type <pair> endGEN endYZH endTHA canadd canaddv noadd
%type <pair> addNNN noaddNNN addnnn noaddnnn addMMM noaddMMM addLLL noaddLLL
%type <pair> addRRR noaddRRR lastRRR addlll noaddlll

%%

/* - Alphabet contains Word, rest, ENGLISH.
     We need all strings with no two WORDs coming adjacent.

   - Reg Exp: z = r|e; t = z*(wz+)*w?

   - CFG: z  -> r
                e
          t1 -> <empty>
                t1 z
                t1 w z
          t  -> t1 w
                t1
     In order to keep the outputing seqence correct
     we have combined t1 and z.
*/


START     : text               { RULE_DUMP
                                 mal_out_text = strlist2string($1, &status);
                               }
          ;

text      : text1 mal_         { RULE_DUMP
                                 strlist_concat( $1, $2 );
                                 $$ = $1;
                               }
	  ;

text1     : text1 mal_ eng_    { RULE_DUMP
                                 strlist_concat( $1, $2 );
                                 strlist_concat( $1, $3 );
                                 $$ = $1;
                               }
          |                    { RULE_DUMP
                                 $$ = strlist_create(NULL, RO_STR, &status);
                               }
          ;

eng_      : ENGLISH            { 
                                 STRLIST s;
                                 RULE_DUMP
                                 s  = strlist_create( $1, RO_STR, &status );
                                 $$ = extern_fn( s, fn_eng_trans );
                               }
	  ;

mal_      : mal                { RULE_DUMP
                                 $$ = extern_fn( $1, fn_mal_trans );
                               }
	  ;

mal       : mal1 wordstr       { RULE_DUMP
                                 strlist_concat( $1, $2 );
                                 $$ = $1 ;
                               }
          | mal1               { RULE_DUMP
                                 $$ = $1
                               }
          ;

mal1      : mal1 rest          { RULE_DUMP
                                 strlist_concat( $1, $2 );
                                 $$ = $1 ;
                               }
          | mal1 wordstr rest  { RULE_DUMP 
                                 strlist_concat( $1, $2 );
                                 strlist_concat( $1, $3 );
                                 $$ = $1;
                               }
          |                    { RULE_DUMP
                                 $$ = strlist_create(NULL, RO_STR, &status);
                               }
          ;

wordstr   : word               { RULE_DUMP
                                 $$ = strpair2strlist($1);
                               }
          ;

/* symbols defined in mapfile as well as not found in mapfile */
rest      : SYMBOL             { RULE_DUMP
                                 $$ = create_nonsyllable($1, MAIN);
                               }
          | UNKNOWN            { RULE_DUMP
                                 $$ = strlist_create($1, RO_STR, &status);
                               }
          | DQ                 { RULE_DUMP
                                 $$ = (dqcount++ % 2) ?
                                      create_nonsyllable($1, LEFT):
                                      create_nonsyllable($1, RIGHT);
                               }
          | SQ                 { RULE_DUMP
                                 $$ = (sqcount++ % 2) ?
                                      create_nonsyllable($1, LEFT):
                                      create_nonsyllable($1, RIGHT);
                               }
          ;

word	  : wordv noadd        { RULE_DUMP $$ = strpair_concat($1, $2, AA_BB); }
          | wordv              { RULE_DUMP $$ = $1 }
    	  | noadd              { RULE_DUMP $$ = $1 }
          ;

wordv     : wordv canaddv      { RULE_DUMP $$ = strpair_concat($1, $2, AA_BB); }
          | wordv SVARKOOT     { RULE_DUMP $$ = append_syllable_add2add($1, $2, NONE); }
          | wordv vowela       { RULE_DUMP $$ = append_syllable_add2add($1, $2, WRAP_ELONG); }
          | canaddv            { RULE_DUMP $$ = $1 }
          | vowelak            { RULE_DUMP $$ = create_syllable($1, ADDABLE); }
          ;

canaddv   : canadd vowelk      { RULE_DUMP $$ = append_syllable_add2add($1, $2, WRAP); }
          | canadd AAA         { RULE_DUMP $$ = $1 }
          ;

vowelak   : vowela             { RULE_DUMP $$ = $1 }
          | SVARKOOT           { RULE_DUMP $$ = $1 }
          ;

vowelk    : VOWEL              { RULE_DUMP $$ = $1 }
          | SVARKOOT           { RULE_DUMP $$ = $1 }
          ;

vowela    : VOWEL              { RULE_DUMP $$ = $1 }
          | AAA                { RULE_DUMP $$ = $1 }
          ;

/* --------------------------------------------------------------- */

canadd    : addNNN       { RULE_DUMP  $$ = $1 }
          | addnnn       { RULE_DUMP  $$ = $1 }
          | addlll       { RULE_DUMP  $$ = $1 } 
          | addMMM       { RULE_DUMP  $$ = $1 }
          | addLLL       { RULE_DUMP  $$ = $1 }
          | addRRR       { RULE_DUMP  $$ = $1 }
          | endGEN       { RULE_DUMP  $$ = $1 }
          | endYZH       { RULE_DUMP  $$ = $1 }
          | endTHA       { RULE_DUMP  $$ = $1 }
          ;

noadd     : noaddNNN     { RULE_DUMP  $$ = $1 }
          | noaddnnn     { RULE_DUMP  $$ = $1 }
          | noaddlll     { RULE_DUMP  $$ = $1 }
          | noaddMMM     { RULE_DUMP  $$ = $1 }
          | noaddLLL     { RULE_DUMP  $$ = $1 }
          | lastRRR      { RULE_DUMP  $$ = $1 }
          | endGEN       { RULE_DUMP  $$ = append_syllable_add2add($1, samindex, NONE); }
          | endYZH       { RULE_DUMP  $$ = append_syllable_add2add($1, samindex, NONE); }
          | endTHA       { RULE_DUMP  $$ = append_syllable_add2add($1, samindex, NONE); }
          ;

/* --------------------------------------------------------------- */

addNNN    : NNN               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | addNNN NNN        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | noaddnnn NNN      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddlll NNN      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddMMM NNN      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddLLL NNN      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddRRR NNN      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | endGEN   NNN      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH NNN        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA NNN        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          ;

noaddNNN  : NNN               { RULE_DUMP  $$ = create_syllable($1, NOADD); }
          | addNNN NNN        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | noaddnnn NNN      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddlll NNN      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddMMM NNN      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddLLL NNN      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddRRR NNN      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, BEFORE_R_DOT); }
          | endGEN NNN        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endYZH NNN        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endTHA NNN        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          ;
/* --------------------------------------------------------------- */

addnnn    : nnn               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | noaddNNN nnn      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | addnnn nnn        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | noaddlll nnn      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | addMMM nnn        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | noaddLLL nnn      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddRRR nnn      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | endGEN nnn        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH nnn        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA nnn        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          ;

noaddnnn  : nnn               { RULE_DUMP  $$ = create_syllable($1, NOADD); }
          | noaddNNN nnn      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | addnnn nnn        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, SAMVRUTHO); }
          | noaddlll nnn      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | addMMM nnn        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, APPEND_CHILL); }
          | noaddLLL nnn      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddRRR nnn      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, BEFORE_R_DOT); }
          | endGEN nnn        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endYZH nnn        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endTHA nnn        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          ;

/* --------------------------------------------------------------- */

addlll    : lll               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | noaddNNN lll      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE);         }
          | noaddnnn lll      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE);         }
          | addlll   lll      { RULE_DUMP  $$ = append_syllable_add2add(  $1, $2, SAMVRUTHO);    }
          | noaddMMM lll      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE);         }
          | noaddLLL lll      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE);         }
          | noaddRRR lll      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | endGEN   lll      { RULE_DUMP  $$ = append_syllable_add2add(  $1, $2, WRAP);         }
          | endYZH   lll      { RULE_DUMP  $$ = append_syllable_add2add(  $1, $2, SAMVRUTHO);    }
          | endTHA   lll      { RULE_DUMP  $$ = append_syllable_add2add(  $1, $2, WRAP);         }
          ;

noaddlll  : lll               { RULE_DUMP  $$ = create_syllable($1, NOADD); }
          | noaddNNN lll      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddnnn lll      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | addlll   lll      { RULE_DUMP  $$ = append_syllable_add2noadd(  $1, $2, SAMVRUTHO);    }
          | noaddMMM lll      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddLLL lll      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddRRR lll      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, BEFORE_R_DOT); }
          | endGEN   lll      { RULE_DUMP  $$ = append_syllable_add2noadd(  $1, $2, WRAP);         }
          | endYZH   lll      { RULE_DUMP  $$ = append_syllable_add2noadd(  $1, $2, APPEND_CHILL); }
          | endTHA   lll      { RULE_DUMP  $$ = append_syllable_add2noadd(  $1, $2, WRAP);         }
          ;

/* --------------------------------------------------------------- */


addMMM     : MMM               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | noaddNNN MMM       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddnnn MMM       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | addlll MMM         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | addMMM MMM         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | noaddLLL MMM       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddRRR MMM       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | endGEN MMM         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH MMM         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA MMM         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          ;

noaddMMM   : MMM               { RULE_DUMP  $$ = create_syllable($1, NOADD); }
          | noaddNNN MMM       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddnnn MMM       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | addlll MMM         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, SAMVRUTHO); } 
          | addMMM MMM         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, SAMVRUTHO); }
          | noaddLLL MMM       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddRRR MMM       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, BEFORE_R_DOT); }
          | endGEN MMM         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endYZH MMM         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endTHA MMM         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          ;

/* --------------------------------------------------------------- */


addLLL     : LLL               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | noaddNNN LLL       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddnnn LLL       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddlll LLL       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | addLLL LLL         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | addMMM LLL         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | noaddRRR LLL       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | endGEN LLL         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH LLL         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA LLL         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          ;

noaddLLL   : LLL               { RULE_DUMP  $$ = create_syllable($1, NOADD); }
          | noaddNNN LLL       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddnnn LLL       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); }
          | noaddlll LLL       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); } 
          | noaddRRR LLL       { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, BEFORE_R_DOT); }
          | addMMM LLL         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, APPEND_CHILL); }
          | addLLL LLL         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, SAMVRUTHO); }
          | endGEN LLL         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endYZH LLL         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endTHA LLL         { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          ;

/* --------------------------------------------------------------- */

addRRR    : RRR               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | addNNN RRR        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addnnn RRR        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | noaddlll RRR      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | addMMM  RRR       { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addLLL  RRR       { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addRRR RRR        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | endGEN RRR        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH RRR        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA RRR        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          ;

noaddRRR  : RRR               { RULE_DUMP  $$ = create_syllable($1, NOADD_R_DOT); }
          | addNNN RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_WRAP); } 
          | addnnn RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_WRAP); }
          | noaddlll RRR      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_R_DOT); } 
          | addMMM RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_WRAP); }
          | addLLL RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_WRAP); }
          | addRRR RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_DOT_DOUBLE); }
          | endGEN RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_WRAP); }
          | endYZH RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_WRAP); }
          | endTHA RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, R_WRAP); }
          ;

lastRRR   : RRR               { RULE_DUMP  $$ = create_syllable($1, NOADD); }
          | addNNN RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); } 
          | addnnn RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | noaddlll RRR      { RULE_DUMP  $$ = append_syllable_noadd2noadd($1, $2, APPEND_CHILL); } 
          | addMMM  RRR       { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | addLLL  RRR       { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | addRRR RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, APPEND_CHILL); }
          | endGEN RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endYZH RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          | endTHA RRR        { RULE_DUMP  $$ = append_syllable_add2noadd($1, $2, WRAP); }
          ;

/* --------------------------------------------------------------- */

endGEN    : VVV               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | BAKKI             { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | GSs               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | DDD               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | DA                { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }

          | addNNN   VVV      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addNNN   DDD      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | addNNN   DA       { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | noaddNNN BAKKI    { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddNNN GSs      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }

          | addnnn   VVV      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | noaddnnn BAKKI    { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddnnn GSs      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddnnn DA       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddnnn DDD      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }

          | addlll   VVV      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addlll   BAKKI    { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | noaddlll GSs      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddlll DA       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddlll DDD      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }

          | noaddMMM VVV      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddMMM BAKKI    { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddMMM GSs      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddMMM DA       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddMMM DDD      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }

          | noaddLLL VVV      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddLLL BAKKI    { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddLLL GSs      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddLLL DA       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddLLL DDD      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }

          | noaddRRR VVV      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | noaddRRR BAKKI    { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | noaddRRR GSs      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | noaddRRR DA       { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | noaddRRR DDD      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }

          | endGEN VVV        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endGEN BAKKI      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endGEN GSs        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endGEN DA         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endGEN DDD        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }

          | endYZH VVV        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH BAKKI      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH GSs        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH DA         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH DDD        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }

          | endTHA VVV        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA BAKKI      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA GSs        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA DA         { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA DDD        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          ;

/* --------------------------------------------------------------- */

endYZH    : YZH               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | addNNN YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addnnn YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addlll YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addMMM YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addLLL YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | addRRR YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endGEN YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, POSSIBLE_DOUBLE); }
          | endTHA YZH        { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          ;

/* --------------------------------------------------------------- */

endTHA    : THA               { RULE_DUMP  $$ = create_syllable($1, ADDABLE); }
          | noaddNNN THA      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | addnnn   THA      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, SAMVRUTHO); }
          | noaddlll THA      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddMMM THA      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddLLL THA      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, NONE); }
          | noaddRRR THA      { RULE_DUMP  $$ = append_syllable_noadd2add($1, $2, BEFORE_R_DOT); }
          | endGEN   THA      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endYZH   THA      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, WRAP); }
          | endTHA   THA      { RULE_DUMP  $$ = append_syllable_add2add($1, $2, POSSIBLE_DOUBLE); }
          ;
%%


STRPAIR create_syllable(UINT index,  CREATE_MODE mode)
{
     STRPAIR p = NULL;

     switch (mode)
     {
     case ADDABLE:
          p = strpair_create(NULL, map[index][MAIN]);        
          break;

     case LEFT_ONLY:
          p = strpair_create(NULL, map[index][LEFT]);        
          break;

     case RIGHT_ONLY:
          p = strpair_create(NULL, map[index][RIGHT]);        
          break;

     case NOADD:
          if (HAVE_CHILL(index))
          {
               p = strpair_create(map[index][CHILL], NULL);
          }
          else
          {
               p = strpair_create(map[index][MAIN], map[samindex][MAIN] );  
               strpair_str_mix(p, NULL, AA_S);
          }
          break;

     case NOADD_R_DOT:
          if (CAN_R_DOT(index))
          {
               p = strpair_create(NULL, map[index][R_DOT]);
          }
          else
          {
               p = create_syllable(index, NOADD);
          }
          break;

     default:
          break;
     }

     return p;
}

STRPAIR append_syllable_noadd2noadd(STRPAIR p, UINT secindex, APPEND_MODE mode)
{
     switch (mode)
     {
     case APPEND_CHILL:
          if (HAVE_CHILL(secindex))
          {
               strpair_str_mix(p, map[secindex][CHILL], AA_S);
               strpair_str_mix(p, NULL, AA_S);
          }
          else
          {
               strpair_str_mix(p, map[secindex][MAIN], AA_S);
               strpair_str_mix(p, map[samindex][MAIN], AA_S);
               strpair_str_mix(p, NULL, AA_S);
          }
          break;

     case BEFORE_R_DOT:
          if (HAVE_CHILL(secindex))
          {
               strpair_str_mix(p, map[secindex][CHILL], A_SA);
               strpair_str_mix(p, NULL, AA_S);
          }
          else
          {
               strpair_str_mix(p, map[secindex][MAIN], A_SA);
               strpair_str_mix(p, map[samindex][MAIN], AA_S);
               strpair_str_mix(p, NULL, AA_S);
          }
          break;

     case APPEND_R_DOT:
          if (CAN_R_DOT(secindex))
          {
               strpair_str_mix(p, map[secindex][R_DOT], AA_S);
          }
          else
          {
               p = append_syllable_noadd2noadd(p, secindex, APPEND_CHILL);
          }
          break;

     default:
          break;
     }

     return p;
}

STRPAIR append_syllable_add2noadd(STRPAIR p, UINT secindex, APPEND_MODE mode)
{
     switch (mode)
     {
     case WRAP:
          if (HAVE_PARTS(secindex))
          {
               strpair_str_mix(p, map[secindex][LEFT], A_SA );
               strpair_str_mix(p, map[secindex][RIGHT], A_AS );
               strpair_str_mix(p, map[samindex][MAIN], AA_S);
               strpair_str_mix(p, NULL, AA_S);
          }
          else
          {
               p = append_syllable_add2noadd(p, secindex, APPEND_CHILL);
          }
          break;

     case APPEND_CHILL:
          if (HAVE_CHILL(secindex))
          {
               strpair_str_mix(p, map[samindex][MAIN], AA_S);
               strpair_str_mix(p, map[secindex][CHILL], AA_S);
               strpair_str_mix(p, NULL, AA_S);
          }
          else
          {
               p = append_syllable_add2noadd(p, secindex, SAMVRUTHO);
          }
          break;

     case R_WRAP:
          if (! HAVE_PARTS(secindex) && CAN_R_DOT(secindex))
          {
               strpair_str_mix(p, map[samindex][MAIN], AA_S);
               strpair_str_mix(p, map[secindex][R_DOT], AA_S);
          }
          else
          {
               p = append_syllable_add2noadd(p, secindex, WRAP);
          }
          break;

     case R_DOT_DOUBLE:
          if (CAN_R_DOT(secindex))
          {
               strpair_str_mix(p, map[samindex][MAIN], AA_S);
               strpair_str_mix(p, map[secindex][R_DOT], AA_S);
          }
          else
          {
               p = append_syllable_add2noadd(p, secindex, APPEND_CHILL);
          }
          break;

     case SAMVRUTHO:
          strpair_str_mix(p, map[samindex][MAIN], AA_S);
          strpair_str_mix(p, map[secindex][MAIN], AA_S);
          strpair_str_mix(p, map[samindex][MAIN], AA_S);
          strpair_str_mix(p, NULL, AA_S);
          break;

     case POSSIBLE_DOUBLE:
          if (0 == strpair_str_cmp( p, map[secindex][MAIN], RIGHT))
          {
               p = append_syllable_add2noadd(p, secindex, APPEND_CHILL);
          }
          else
          {
               p = append_syllable_add2noadd(p, secindex, WRAP);
          }

     default:
          break;
     }

     return p;
}

STRPAIR append_syllable_noadd2add(STRPAIR p, UINT secindex, APPEND_MODE mode)
{
     switch (mode)
     {
     case BEFORE_R_DOT:
          strpair_str_mix(p, map[secindex][MAIN], A_SA);
          break;

     case NONE:
     default:
          strpair_str_mix(p, map[secindex][MAIN], AA_S);
          break;
     }

     return p;
}


STRPAIR append_syllable_add2add(STRPAIR p, UINT secindex, APPEND_MODE mode)
{
     BOOLEAN append_with_samvrutho_first;

     switch (mode)
     {
     case POSSIBLE_DOUBLE:
          append_with_samvrutho_first =
               (0 == strpair_str_cmp( p, map[secindex][MAIN], RIGHT));
          break;

     case SAMVRUTHO:
          append_with_samvrutho_first = TRUE;
          break;

     case NONE:
          strpair_str_mix(p, map[secindex][MAIN], AA_S);
          return p;
          break;

     case WRAP_ELONG:
          strpair_str_mix( p, map[secindex][ELONG], A_AS);
          return p;
          break;

     case WRAP:
     default:
          append_with_samvrutho_first = FALSE;
          break;
     }

     if (!append_with_samvrutho_first && HAVE_PARTS(secindex))
     {
          strpair_str_mix( p, map[secindex][LEFT], A_SA );
          strpair_str_mix( p, map[secindex][RIGHT], A_AS );
     }
     else
     {
          strpair_str_mix(p, map[samindex][MAIN], AA_S);
          strpair_str_mix(p, map[secindex][MAIN], AA_S);
     }
     return p;
}

STRLIST create_nonsyllable(UINT index,  COMPONENT mode)
{
     switch (mode)
     {
     case LEFT:
          return strlist_create(map[index][LEFT], RO_STR, &status);        
          break;

     case RIGHT:
          return strlist_create(map[index][RIGHT], RO_STR, &status);        
          break;

     case MAIN:
          return strlist_create(map[index][MAIN], RO_STR, &status);        
          break;

     default:
          return NULL;
          break;
     }
}

STRLIST extern_fn(STRLIST slist, EXTERN_TRANS_FN func)
{
     STATUS status;
     UCHAR *str, *newstr;
     int   len,  newlen;

     if (func != NULL)
     {
          str = strlist_str_get(slist);
          len = strlist_len(slist);
          (*func)(str, len, &newstr, &newlen); /* ignore error */
          status = strlist_replace(slist, newstr, newlen, RW_STR);
     }

     return slist;
}

char* mal_parse(char* mal_in_text, long flags)
{

     struct yy_buffer_state *buffer_state;

     allowRdot    = (flags & FL_ALLOW_RDOT)    ? TRUE : FALSE;
     carrycomment = (flags & FL_CARRY_COMMENT) ? TRUE : FALSE;
     processmacro = (flags & FL_PROCESS_MACRO) ? TRUE : FALSE;
     debug        = (flags & FL_DEBUG)         ? TRUE : FALSE;

     /* macro processing */
     if ( processmacro )
     {
          /* phase 1 */

          buffer_state = macro_scan_bytes( mal_in_text,
                                           strlen(mal_in_text) + 1 );

          halfcooked = str_create("", RO_STR, &status);


          macro_switch_to_buffer( buffer_state );
          while( macrolex());
          macro_delete_buffer( buffer_state );


          if (debug)
          {
               char *halfcooked_str = str_get_data( halfcooked );
               if (strcmp(halfcooked_str, "\n") != 0)
               {
                    fprintf(stderr, "text-substitution output: %s", halfcooked_str);
               }
          }

#if 0

          /* phase 2 */

          /*  second pass spoils # functionality */

          /* if second pass is really required,
           * we can introduce a global variable and
           * prevent # getting removed in the first pass */

          buffer_state = macro_scan_bytes( str_get_data( halfcooked ),
                                           str_get_len( halfcooked ) + 1 );

          str_free( halfcooked );
          halfcooked = str_create("", RO_STR, &status);


          macro_switch_to_buffer( buffer_state );
          while( macrolex());
          macro_delete_buffer( buffer_state );

#endif /* 0 */


          buffer_state = yy_scan_bytes( str_get_data( halfcooked ),
                                        str_get_len( halfcooked ) + 1 );
          str_free( halfcooked );
     }
     else
     {
          /* printf( "macro not processed\n" ); */
          buffer_state = yy_scan_bytes( mal_in_text,
                                        strlen(mal_in_text) + 1 );
     }

     /* font processing */

     dqcount = sqcount = 1;
     mal_out_text      = NULL;

     yy_switch_to_buffer( buffer_state );
     while (yyparse());
     yy_delete_buffer( buffer_state );


     return mal_out_text;
}

void yyerror( char msg[] )
{
          fprintf(stderr, "%s\n", msg);
}
          

