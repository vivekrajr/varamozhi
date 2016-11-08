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

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "txt2html.h"

int debug = 0;

#define RULE_DUMP(x) { if (debug) { fprintf(stderr, "rule at %s:%u for '%s'\n", __FILE__, __LINE__, (x)); } }

/* #include "./trans.h" */

void yyerror(char msg[]);
struct yy_buffer_state* yy_scan_bytes();
void                    yy_delete_buffer();
void                    yy_switch_to_buffer();
int  yylex();
char* concat(char *str, ...);
void freemem(char *str, ...);
char* search(char* left, char* right);

%}

%union {
     int   val;
     char* str;
}

%token <str> CHIL
%token <str> SAMV
%token <str> BASIC_V
%token <str> CONJUNCT_V
%token <str> SYMBOL
%token <str> ENGLISH
%token <str> FRACLEFT
%token <str> FRACRIGHT
%token <str> VLEFT
%token <str> VRIGHT
%token <str> PURE
%token <str> FRACPURE
%token <str> RDOT

%type <str> word endchil endg error vowel
%type <str> endsamv allsamv gensamv fracsamv
%type <str> genunit fracunit gennovow fracnovow
%type <str> eng eng_raw sym puredot fpuredot


%%

/* everything can come in any order and even empty */
START     : text

text      : endW
          | endS
          | endE
          | 
          ;


endW      : endS word_p
          | endE word_p
          | word_p
          ;

endE      : endS eng_p
          | endW eng_p
          | eng_p
          ;

endS      : endE sym_p
          | endW sym_p
          | sym_p
          ;


/* printing */
eng_p     : eng                              { write(STDOUT_FILENO, $1, strlen($1)); RULE_DUMP($1) }
          ;

sym_p     : sym                              { write(STDOUT_FILENO, $1, strlen($1)); RULE_DUMP($1) }
          ;

word_p    : word                             { write(STDOUT_FILENO, $1, strlen($1)); RULE_DUMP($1) }
          ;




eng       : eng_raw                          { $$ = concat("{", $1, "}", 0); freemem($1, 0); RULE_DUMP($$) }
          ;

eng_raw   : eng_raw ENGLISH                  { $$ = concat($1, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | ENGLISH                          { $$ = concat($1, 0); RULE_DUMP($$) }
          ;

sym       : sym SYMBOL                       { $$ = concat($1, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | SYMBOL                           { $$ = concat($1, 0); RULE_DUMP($$) }
          ;




word      : endchil                          { $$ = $1; RULE_DUMP($$) }
          | endg                             { $$ = $1; RULE_DUMP($$) }
          | endsamv                          { $$ = concat($1, SAMVRUTHO, 0); freemem($1, 0);RULE_DUMP($$) }
          ;

endchil   : CHIL                             { $$ = concat($1, 0); RULE_DUMP($$) }
          | endchil CHIL                     { $$ = concat($1, FALSEBLANK, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | endg    CHIL                     { $$ = concat($1, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | endsamv CHIL                     { $$ = concat($1, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | error CHIL                       { $$ = concat($2, 0); yyerrok; RULE_DUMP($$) }
          ;

endg      : vowel                            { $$ = concat($1, 0); RULE_DUMP($$) }
          | endchil vowel                    { $$ = concat($1, FALSEBLANK, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | endg    BASIC_V                  { $$ = concat($1, FALSEBLANK, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | endg    CONJUNCT_V               { $$ = concat($1, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | endsamv vowel                    { $$ = concat($1, FALSEBLANK, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | genunit                          { $$ = $1; RULE_DUMP($$) }
          | endchil genunit                  { $$ = concat($1, FALSEBLANK, $2, 0); freemem($1, $2, 0); RULE_DUMP($$) }
          | endg    genunit                  { $$ = concat($1, $2, 0); freemem($1, $2, 0); RULE_DUMP($$) }
          | endsamv genunit                  { $$ = concat($1, $2, 0); freemem($1, $2, 0); RULE_DUMP($$) }
          | fracunit                         { $$ = $1; RULE_DUMP($$) }
          | endchil fracunit                 { $$ = concat($1, FALSEBLANK, $2, 0);   freemem($1, $2, 0); RULE_DUMP($$) }
          | endg    fracunit                 { $$ = concat($1, $2, 0);               freemem($1, $2, 0); RULE_DUMP($$) }
          | endsamv fracunit                 { $$ = concat($1, SAMVRUTHO, $2, 0);    freemem($1, $2, 0); RULE_DUMP($$) }
          ;

allsamv   : fracsamv                         { $$ = $1; RULE_DUMP($$) }
          | gensamv                          { $$ = $1; RULE_DUMP($$) }
          ;

endsamv   : allsamv                          { $$ = $1; RULE_DUMP($$) }
          | endchil allsamv                  { $$ = concat($1, $2, 0);               freemem($1, $2, 0); RULE_DUMP($$) }
          | endg    allsamv                  { $$ = concat($1, $2, 0);               freemem($1, $2, 0); RULE_DUMP($$) }
          | endsamv fracsamv                 { $$ = concat($1, SAMVRUTHO, $2, 0);    freemem($1, $2, 0); RULE_DUMP($$) }
          | endsamv gensamv                  { $$ = concat($1, $2, 0);               freemem($1, $2, 0); RULE_DUMP($$) }
          ;

gensamv   : gennovow SAMV                    { $$ = $1; RULE_DUMP($$) }
          | error SAMV                       { $$ = concat(ZWC, 0); yyerrok; RULE_DUMP($$) }
          ;

fracsamv  : fracnovow SAMV                   { $$ = $1; RULE_DUMP($$) }
          ;

genunit   : gennovow                         { $$ = concat($1, AAA, 0);              freemem($1, 0); RULE_DUMP($$) }
          | VLEFT  gennovow                  { $$ = concat($2, $1, 0);               freemem($2, 0); RULE_DUMP($$) }
          | gennovow VRIGHT                  { $$ = concat($1, $2, 0);               freemem($1, 0); RULE_DUMP($$) }
          | VLEFT  gennovow VRIGHT           { $$ = concat($2, search($1, $3), 0);   freemem($2, 0); RULE_DUMP($$) }
/* error */
          | VLEFT error                      { $$ = concat(ZWC, $1, 0); yyerrok; RULE_DUMP($$) }
          | error VRIGHT                     { $$ = concat(ZWC, $2, 0); yyerrok; RULE_DUMP($$) }
          | VLEFT  error VRIGHT              { $$ = concat(ZWC, search($1, $3), 0); freemem($2, 0); yyerrok; RULE_DUMP($$) }
          ;

fracunit  : fracnovow                        { $$ = concat($1, AAA, 0); freemem($1, 0); RULE_DUMP($$) }
          | VLEFT  fracnovow                 { $$ = concat($2, $1, 0); freemem($2, 0); RULE_DUMP($$) }
          | fracnovow VRIGHT                 { $$ = concat($1, $2, 0); freemem($1, 0); RULE_DUMP($$) }
          | VLEFT  fracnovow VRIGHT          { $$ = concat($2, search($1, $3), 0); freemem($2, 0); RULE_DUMP($$) }
          ;

gennovow  : puredot                          { $$ = $1; RULE_DUMP($$) }
          | puredot   FRACRIGHT              { $$ = concat($1, $2, 0);     freemem($1, 0); RULE_DUMP($$) }
          | FRACLEFT  puredot                { $$ = concat($2, $1, 0);     freemem($2, 0); RULE_DUMP($$) }
          | FRACLEFT  puredot  FRACRIGHT     { $$ = concat($2, $1, $3, 0); freemem($2, 0); RULE_DUMP($$) }
          | puredot   FRACRIGHT FRACRIGHT    { $$ = concat($1, $2, $3, 0); freemem($1, 0); RULE_DUMP($$) }
/* error */
          | FRACLEFT  error                  { $$ = concat(ZWC, $1, 0); yyerrok; RULE_DUMP($$) }
          | error FRACRIGHT                  { $$ = concat(ZWC, $2, 0); yyerrok; RULE_DUMP($$) }
          ;

fracnovow : fpuredot                         { $$ = $1; RULE_DUMP($$) }
          | fpuredot  FRACRIGHT              { $$ = concat($1, $2, 0);     freemem($1, 0); RULE_DUMP($$) }
          | FRACLEFT  fpuredot               { $$ = concat($2, $1, 0);     freemem($2, 0); RULE_DUMP($$) }
          | FRACLEFT  fpuredot  FRACRIGHT    { $$ = concat($2, $1, $3, 0); freemem($2, 0); RULE_DUMP($$) }
          ;

puredot   : PURE RDOT                        { $$ = concat($2, $1, 0); RULE_DUMP($$) }
          | PURE                             { $$ = concat($1, 0);RULE_DUMP($$) }
          ;

fpuredot  : FRACPURE RDOT                    { $$ = concat($2, $1, 0); RULE_DUMP($$) }
          | FRACPURE                         { $$ = concat($1, 0);RULE_DUMP($$) }
          ;

vowel     : BASIC_V
          | CONJUNCT_V
          ;
%%

char* concat(char *s0, ...)
{
     va_list ap;
     char *str;
     char *fullstr;
     int len = 0;

     va_start(ap, s0);

     for(str = s0; str; str = va_arg(ap, char *))
     {
          len += strlen(str);
     }

     va_end(ap);


     fullstr = (char *)calloc(len + 1, 1);
     fullstr[0]=0;


     va_start(ap, s0);

     for(str = s0; str; str = va_arg(ap, char *))
     {
          strcat(fullstr, str);
     }

     va_end(ap);

     return fullstr;
}

void freemem(char *s0, ...)
{
     va_list ap;
     char *str;


     va_start(ap, s0);
     for(str = s0; str; str = va_arg(ap, char *))
     {
          free(str);
     }
     va_end(ap);
}

char* search(char* left, char* right) {
     
     char* leftright;
     int i;

     leftright = concat(left, right, 0);
     for(i=0; i < 2; i++) {
          if (strcmp(combfont[i][0], leftright) == 0) {
               freemem(leftright, 0);
               return combfont[i][1];
          }
     }

     freemem(leftright, 0);
     return "";
}

void yyerror( char msg[] ){}
          

#define BUFSIZE 614400
int main(int argc, char **argv) {
     
     
     int c;
     extern char *optarg;
     extern int optind;
     int errflg = 0;

/*   yydebug = 1; */

/*   while (!feof(stdin)) { */
/*        yyparse(); */
/*   } */

     char text[BUFSIZE];
     unsigned long int readcount;
     struct yy_buffer_state *buffer_state;


     while ((c = getopt(argc, argv, "g")) != EOF)
     {
          switch (c) {
               
          case 'g':
               debug = 1;
               break;
          case '?':
               errflg++;
          }
     }
 
     if (errflg) {
          fprintf(stderr, "usage: lamvi_mozhi_* [-g]\n");
          exit (2);
     }
 



     while ((readcount = saferead(STDIN_FILENO, text, BUFSIZE-1)) > 0)
     {
          text[readcount] = '\0';

          buffer_state = yy_scan_bytes( text, strlen(text) + 1 );
          yy_switch_to_buffer( buffer_state );
          while( yyparse());
          yy_delete_buffer( buffer_state );
     }
     
     return 0; /* to avoid a warning */
}
