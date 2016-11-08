extern unsigned char *malfont;
extern unsigned int   malfontlen;

int txt2html(unsigned char *src, long srclen, unsigned char *dst, long dstlen);
int nl2br(unsigned char *src, long srclen, unsigned char *dst, long dstlen);
int txt2htmlfont(unsigned char *str, int len, unsigned char **pnewstr, int *plen);
int txt2html_nofont( unsigned char *str, int len, unsigned char **pnewstr, int *plen );
int txt2html_unicode( unsigned char *str, int len, unsigned char **pnewstr, int *plen );
ssize_t saferead(int fildes, char *buf, size_t nbyte);
