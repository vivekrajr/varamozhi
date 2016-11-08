#ifndef _STRLIST_H
#define _STRLIST_H

#include "list.h"
#include "strstruct.h"

typedef struct _strlist_INFO
{
     LIST         list;
     unsigned int len;
} STRLIST_INFO;

typedef STRLIST_INFO *STRLIST;

STRLIST strlist_create(UCHAR *str,  STR_TYPE type, STATUS *p_status);
STATUS  strlist_concat(STRLIST strlist1, STRLIST strlist2);
STATUS  strlist_pullup(STRLIST strlist);
UCHAR  *strlist2string(STRLIST strlist, STATUS *p_status);
STATUS  strlist_free(STRLIST_INFO *p_strlist_info);
int     strlist_str_cmp(STRLIST_INFO *p_info, UCHAR *str);
UCHAR  *strlist_str_get(STRLIST strlist);
STATUS  strlist_replace(STRLIST slist, UCHAR *str, int len, STR_TYPE type);

#define strlist_len(strlist) (strlist->len)

#endif  /* _STRLIST_H */
