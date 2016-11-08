#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include "mal_api.h"
#include "txt2html.h"

#ifdef mozhi_chamundi
#define FONTNAME "Chamheav" 
#define FONTAPI  mozhi_chamundi_parse

#elif mozhi_chowara
#define FONTNAME "Chowara" 
#define FONTAPI  mozhi_chowara_parse

#elif mozhi_deshavani
#define FONTNAME "DVmalayalam" 
#define FONTAPI  mozhi_deshavani_parse

#elif mozhi_janaranjani
#define FONTNAME "Janaranjani" 
#define FONTAPI  mozhi_janaranjani_parse

#elif mozhi_jjayan
#define FONTNAME "J*Mlm*Jaya-Normal" 
#define FONTAPI  mozhi_jjayan_parse

#elif mozhi_kairali
#define FONTNAME "PMLTKairali" 
#define FONTAPI  mozhi_kairali_parse

#elif mozhi_kalakaumudi
#define FONTNAME "Kalakaumudi"
#define FONTAPI  mozhi_kalakaumudi_parse

#elif mozhi_karthika
#define FONTNAME "ML-TTKarthika"
#define FONTAPI  mozhi_karthika_parse

#elif mozhi_karthikaw
#define FONTNAME "MLW-TTKarthika" 
#define FONTAPI  mozhi_karthikaw_parse

#elif mozhi_karthikabw
#define FONTNAME "MLBW-TTKarthika"
#define FONTAPI  mozhi_karthikabw_parse

#elif mozhi_kaveri
#define FONTNAME "RE_iNFOM-Kaveri" 
#define FONTAPI  mozhi_kaveri_parse

#elif mozhi_kerala
#define FONTNAME "Kerala" 
#define FONTAPI  mozhi_kerala_parse

#elif mozhi_kruthi
#define FONTNAME "Kruthi" 
#define FONTAPI  mozhi_kruthi_parse

#elif mozhi_malayalam
#define FONTNAME "Malayalam" 
#define FONTAPI  mozhi_malayalam_parse

#elif mozhi_malayalamabe
#define FONTNAME "MalayalamAbe" 
#define FONTAPI  mozhi_malayalamabe_parse

#elif mozhi_manorama
#define FONTNAME "Manorama" 
#define FONTAPI  mozhi_manorama_parse

#elif mozhi_mathrubhumi
#define FONTNAME "Matweb" 
#define FONTAPI  mozhi_mathrubhumi_parse

#elif mozhi_panchami
#define FONTNAME "Panchami" 
#define FONTAPI  mozhi_panchami_parse

#elif mozhi_shree
#define FONTNAME "Shree-Mal-0502" 
#define FONTAPI  mozhi_shree_parse

#elif mozhi_thoolika
#define FONTNAME "Thoolika" 
#define FONTAPI  mozhi_thoolika_parse

#elif mozhi_unicode
#define FONTNAME "AnjaliOldLipi" 
#define FONTAPI  mozhi_unicode_parse

/* Below: not supported in current editor */

#elif mozhi_deepa
#define FONTNAME "Deepa" 
#define FONTAPI  mozhi_deepa_parse

#elif mozhi_jsaroja
#define FONTNAME "J*Saroja" 
#define FONTAPI  mozhi_jsaroja_parse

#elif mozhi_jacob
#define FONTNAME "Jacobs-Mal-Normal" 
#define FONTAPI  mozhi_jacob_parse

#elif mozhi_veena
#define FONTNAME "Ssoft's-Veena-ML" 
#define FONTAPI  mozhi_veena_parse

#elif mozhi_haritha
#define FONTNAME "Haritha" 
#define FONTAPI  mozhi_haritha_parse

#elif itrans_unicode
#define FONTNAME "Courier New" 
#define FONTAPI  itrans_unicode_parse

#elif itrans_mathrubhumi
#define FONTNAME "Matweb" 
#define FONTAPI  itrans_mathrubhumi_parse

#elif mozhi_mtex
#define FONTNAME "Tahoma"
#define FONTAPI  mozhi_mtex_parse
#endif

#define BUFSIZE 614400
/* #define BUFSIZE 2 */

/* Don't put newlines in this preamble because it will spoil the newline count in editor.pl */

static char* unicode_preamble = "";
static char* unicode_tail = "";

char *FONTAPI(char *txt, long flags); 

int main(int argc, char **argv) {
     
     int c;
     extern char *optarg;
     extern int optind;
     int errflg = 0;
     char text[BUFSIZE];
     unsigned long int readcount;
     char *mtext;
     long flags = FL_DEFAULT;
     char* prefix = "";
     char* suffix = "";
     
     while ((c = getopt(argc, argv, "bcrghuf")) != EOF)
     {
          switch (c) {
               
          case 'h':
               malfont = FONTNAME;
               malfontlen = strlen( malfont );
               fn_mal_trans = txt2htmlfont;
               /* fn_eng_trans = txt2html_nofont; */
               fn_eng_trans = NULL;
               break;
          case 'r':
               flags |= FL_ALLOW_RDOT;
               break;
 
           case 'b': /* basic */
               flags &= ~FL_PROCESS_MACRO;
               break;
 
          case 'c':
               flags |= FL_CARRY_COMMENT; /* carry comment seqenceses as such */
               break;
 
          case 'g':
               flags |= FL_DEBUG;
               break;
 
          case 'f':
               write(STDOUT_FILENO, FONTNAME, strlen(FONTNAME));
               exit(0);
               break;
 
          case 'u':
               prefix = unicode_preamble;
               suffix = unicode_tail;
               fn_mal_trans = txt2html_unicode;
               fn_eng_trans = NULL;
               break;

          case '?':
               errflg++;
          }
     }
 
     if (errflg) {
          fprintf(stderr, "usage: malvi_mozhi_* [-brhcuf]\n");
          exit (2);
     }
 

     write(STDOUT_FILENO, prefix, strlen(prefix));
     while ((readcount = saferead(STDIN_FILENO, text, BUFSIZE-1)) > 0)
     {
          text[readcount] = '\0';

          mtext = FONTAPI(text, flags);
          write(STDOUT_FILENO, mtext, strlen(mtext));
          free(mtext); 
     }
     write(STDOUT_FILENO, suffix, strlen(suffix));
     return 0;
}

