#ifndef _STRPAIR_H
#define _STRPAIR_H

#include "strlist.h"
#include "status.h"

typedef struct _strpair_info
{
     STRLIST lstr;
     STRLIST rstr;
} STRPAIR_INFO;

typedef enum
{
    AA_BB,
    A_BAB,
    AB_BA,
    AA_S,
    A_SA,
    A_AS
} STRPAIR_CONCAT_MODE;

typedef enum
{
    LEFTSTR,
    RIGHTSTR
} STRPAIR_PART;

typedef STRPAIR_INFO *STRPAIR;

STRPAIR strpair_create(UCHAR *lside,  UCHAR *rside);
STRPAIR strpair_concat(STRPAIR strpair1, STRPAIR strpair2, STRPAIR_CONCAT_MODE mode);
STRPAIR strpair_str_mix(STRPAIR strpair, UCHAR *str, STRPAIR_CONCAT_MODE mode);
int     strpair_str_cmp(STRPAIR strpair, UCHAR *str, STRPAIR_PART side);
UCHAR  *strpair2string(STRPAIR strpair);
STRLIST strpair2strlist(STRPAIR_INFO *p_info);

#endif  /* _STRPAIR_H */





