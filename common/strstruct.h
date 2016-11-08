#ifndef _STRSTRUCT_H
#define _STRSTRUCT_H

#include "status.h"

#define MAX_STR_LEN 32

typedef unsigned char UCHAR;
typedef unsigned int UINT;

typedef enum
{
     RO_STR,  /* this string will be untouched. user has to free it */
     RW_STR   /* .._free functions will free it. user can't assume
               * anything about the content of this string, once given as
               * parameter to str_.. functions. */
} STR_TYPE;

typedef struct
{
     UCHAR *str;
     unsigned int len;
     unsigned int max;
     STR_TYPE     type;
     UINT         links;
} STRSTRUCT_INFO;

typedef STRSTRUCT_INFO *STRSTRUCT;

#define str_get_data(str_struct)    (str_struct->str)
#define str_get_len(str_struct)     (str_struct->len)
#define str_get_char(str_struct, i) (str_struct->str[i])

STRSTRUCT str_create(UCHAR *p_ch, STR_TYPE type, STATUS *p_status);
STATUS    str_append(STRSTRUCT str_struct, UCHAR *p_ch);
STATUS    str_free(STRSTRUCT str_struct);
STATUS    str_chop(STRSTRUCT str_struct, UINT pos);
STRSTRUCT str_copy(STRSTRUCT str_struct, STATUS *p_status);
STRSTRUCT str_link(STRSTRUCT str_struct, STATUS *p_status);
STATUS    str_replace(STRSTRUCT str_struct, UCHAR *newstr, int newlen, STR_TYPE type);

#endif  /* _STRSTRUCT_H */
