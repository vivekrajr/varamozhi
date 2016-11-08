#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define PRE       "" /* "<PRE>" */
#define PRELEN    0 /* no need; 5 otherwise */
#define ENDPRE    "" /* "</PRE>" */
#define ENDPRELEN 0  /* no need; 5 otherwise */
#define NULLLEN   1
#define MAX_HTMLCHAR_SIZE 7 /* for  &nbsp; */

int txt2html(unsigned char *src, long srclen, unsigned char *dst, long dstlen)
{
     /* does not look for end '\0' and does not put it. */

     int si, di, substrlen;
     unsigned char *substr;
     unsigned char tmpstr[7]; /* for chars above 160 to form &#160; style */

     unsigned char* lt  = "&lt;";
     unsigned char* gt  = "&gt;";
     unsigned char* amp = "&amp;";
#if 0
     unsigned char* sp  = "&nbsp;";
#endif /* 0 */
     unsigned char* nl  = "<br/>\n";

     di = 0;
     si = 0;

     if (dstlen < PRELEN + ENDPRELEN + NULLLEN)
          goto term;

     strcpy(dst, PRE);
     dst += PRELEN;
     di  += PRELEN;

     for(; si < srclen && di < dstlen; si++, src++)
     {
	  if (*src >= 160)
	  {
	       substrlen = 6;
	       sprintf( tmpstr, "&#%d;", *src );
	       substr    = tmpstr;
	  }
	  else
          switch (*src)
          {
          case '<':
               substrlen = 4;
               substr    = lt;
               break;
          case '>':
               substrlen = 4;
               substr    = gt;
               break;
          case '&':
               substrlen = 5;
               substr    = amp;
               break;
          case '\n':
               substrlen = 5;
               substr    = nl;
               break;
#if 0
          case ' ':
               substrlen = 6;
               substr    = sp;
               break;
#endif /* 0 */
          default:
               substrlen = 1;
               substr    = src;
          }

          if (substrlen + di <= dstlen - ENDPRELEN - NULLLEN)
          {
               strncpy(dst, substr, substrlen);
               dst += substrlen;
               di  += substrlen;
          }
          else
          {
               break;
          }
     }

     strcpy(dst, ENDPRE);
     dst += ENDPRELEN;
     di  += ENDPRELEN;

 term:
     if (si < srclen)
     {
          return -si; /* destination overflow */
          /* returns next source char to be processed with a - sign */
     }
     else
     {
          return di;
     }
}

int nl2br(unsigned char *src, long srclen, unsigned char *dst, long dstlen)
{
     /* does not look for end '\0' and does not put it. */

     int si, di, substrlen;
     unsigned char *substr;

     unsigned char* nl  = "<br/>\n";

     di = 0;
     si = 0;

     if (dstlen < PRELEN + ENDPRELEN + NULLLEN)
          goto term;

     strcpy(dst, PRE);
     dst += PRELEN;
     di  += PRELEN;

     for(; si < srclen && di < dstlen; si++, src++)
     {
          switch (*src)
          {
          case '\n':
               substrlen = 5;
               substr    = nl;
               break;
          default:
               substrlen = 1;
               substr    = src;
          }

          if (substrlen + di <= dstlen - ENDPRELEN - NULLLEN)
          {
               strncpy(dst, substr, substrlen);
               dst += substrlen;
               di  += substrlen;
          }
          else
          {
               break;
          }
     }

     strcpy(dst, ENDPRE);
     dst += ENDPRELEN;
     di  += ENDPRELEN;

 term:
     if (si < srclen)
     {
          return -si; /* destination overflow */
          /* returns next source char to be processed with a - sign */
     }
     else
     {
          return di;
     }
}


unsigned char *malfont = NULL;
unsigned int   malfontlen = 0;

int txt2htmlfont(unsigned char *str, int len, unsigned char **pnewstr, int *plen)
{
     /* len is not counting \0 and this function does not look for it.
      * output will have \0 inplace and return *plen is not counting \0 */

#define FONT_HEAD_ETC_LEN 14
#define FONT_TAIL_LEN      7

     int fontheadlen;
     int fontlen;
     int txtlen;
     int htmllen;
     unsigned char *newstr;

     if (len == 0 || str == NULL) 
     {
          *pnewstr = NULL;
          *plen    = 0;
          return 0;
     }

     fontheadlen = (malfontlen == 0 ? strlen( malfont ) : malfontlen)
          + FONT_HEAD_ETC_LEN;
     fontlen     = fontheadlen + FONT_TAIL_LEN;
     txtlen      = len * MAX_HTMLCHAR_SIZE;
     newstr      = (unsigned char *)malloc( fontlen + txtlen + 1 );
     
     sprintf( newstr, "<FONT FACE=\"%s\">", malfont );
     htmllen = txt2html( str, len, newstr + fontheadlen, txtlen );
     if (htmllen >= 0)
     {
          strncpy( newstr + fontheadlen + htmllen, "</FONT>", FONT_TAIL_LEN );
          htmllen += fontlen;
          newstr[htmllen] = '\0';

          *pnewstr = newstr;
          *plen    = htmllen;
     }
     else
     {
          free( newstr );
          *pnewstr = NULL;
          *plen    = 0;
     }
     return htmllen;
}

int txt2html_nofont( unsigned char *str, int len, unsigned char **pnewstr, int *plen )
{
     int txtlen;
     int htmllen;
     unsigned char *newstr;

     txtlen  = len *  MAX_HTMLCHAR_SIZE;
     newstr  = (unsigned char *)malloc( txtlen + 1 );
     htmllen = txt2html( str, len, newstr, txtlen );

     if (htmllen >= 0)
     {
          newstr[htmllen] = '\0';

          *pnewstr = newstr;
          *plen    = htmllen;
     }
     else
     {
          free( newstr );
          *pnewstr = NULL;
          *plen    = 0;
     }
     return htmllen;
}


int txt2html_unicode( unsigned char *str, int len, unsigned char **pnewstr, int *plen )
{
     int txtlen;
     int htmllen;
     unsigned char *newstr;

     txtlen  = len *  MAX_HTMLCHAR_SIZE;
     newstr  = (unsigned char *)malloc( txtlen + 1 );
     htmllen = nl2br( str, len, newstr, txtlen );

     if (htmllen >= 0)
     {
          newstr[htmllen] = '\0';

          *pnewstr = newstr;
          *plen    = htmllen;
     }
     else
     {
          free( newstr );
          *pnewstr = NULL;
          *plen    = 0;
     }
     return htmllen;
}


ssize_t saferead(int fildes, char *buf, size_t nbyte)
{
     const int decr = 100;
     ssize_t rc = 1;
     ssize_t count;
     size_t read_size;
     

     read_size = (nbyte > decr)? (nbyte - decr) : nbyte;

     count = read(fildes, buf, read_size);
     if (count == read_size)
     {
          for (; ((count < nbyte) && (read(fildes, buf+count, 1) > 0)) && !isspace(buf[count]); count++);
     }

     if (count >= 0)
     {
          buf[count] = '\0';
     }

     return count;
}


#ifdef TEST
main ()
{
     unsigned char str[100];
     unsigned char *dst;
     int  len;
     int retval;

     scanf("%s", str);
     malfont = "Kerala";

     retval = txt2htmlfont(str, strlen(str), &dst, &len);
     printf("%s\n", dst);
     printf("return %d\n", retval);
     free(dst);

     retval = txt2html_nofont(str, strlen(str), &dst, &len);
     printf("%s\n", dst);
     printf("return %d\n", retval);
     free(dst);
    
}
#endif
