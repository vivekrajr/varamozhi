#include <stdlib.h>
#include <string.h>
#include "status.h"
#include "strstruct.h"

#define INCR_FACTOR 2
#define DECR_FACTOR 3

/* size or max does not count the last \0 */

static UINT get_new_length(UINT old_max, UINT new_size)
{
     UINT i;

     if (old_max < new_size)
          for(i=old_max; i<new_size; i *= INCR_FACTOR);

     else if (old_max > new_size)
          for(i=old_max;
              (i/DECR_FACTOR) >= new_size && i > MAX_STR_LEN;
              i /= DECR_FACTOR);
     else
          i = old_max;
          
     return i;
}

static STATUS str_change_size_n_type(STRSTRUCT_INFO *p_str_info, UINT size)
{
     UINT new_max;
     UCHAR *p_ch_new;

     new_max = get_new_length(p_str_info->max, size);
     if (new_max != p_str_info->max || p_str_info->type == RO_STR)
     {
          p_str_info->max = new_max;
          /* for RO_STR, new_max can be old max value itself.
           * but it doesnt matter */

          if ((p_ch_new = (UCHAR *)malloc(new_max + 1)) == NULL)
          {
               return ST_MEM_ALLOC_FAIL;
          }
          strcpy(p_ch_new, p_str_info->str);

          if (p_str_info->type == RW_STR)
          {
               free(p_str_info->str);
          }
          else
          {
               p_str_info->type = RW_STR;
          }
          p_str_info->str = p_ch_new;
     }

     return ST_SUCCESS;
}

STRSTRUCT str_create(UCHAR *p_ch, STR_TYPE type, STATUS *p_status)
{
     STRSTRUCT_INFO *p_str_info;

     if ((p_str_info = (STRSTRUCT_INFO *)malloc(sizeof(STRSTRUCT_INFO))) == NULL)
     {
          *p_status = ST_MEM_ALLOC_FAIL;
          return NULL;
     }

     p_str_info->type = type;
     p_str_info->str  = p_ch;
     p_str_info->len  = strlen(p_ch);
     p_str_info->links= 1;
     p_str_info->max  = get_new_length(MAX_STR_LEN, p_str_info->len);

     *p_status = ST_SUCCESS;
     return p_str_info;
}

STRSTRUCT str_link(STRSTRUCT_INFO *p_str_info, STATUS *p_status)
{
     p_str_info->links++;

     *p_status = ST_SUCCESS;
     return p_str_info;
}

STRSTRUCT str_copy(STRSTRUCT_INFO *p_str_info1, STATUS *p_status)
{
     STRSTRUCT_INFO *p_str_info2;

     /* the info header */
     if ((p_str_info2 = (STRSTRUCT_INFO *)malloc(sizeof(STRSTRUCT_INFO))) == NULL)
     {
          *p_status = ST_MEM_ALLOC_FAIL;
          return NULL;
     }

     /* memory for the string */
     if ((p_str_info2->str = (UCHAR *)malloc(p_str_info1->max + 1)) == NULL)
     {
          free(p_str_info2);
          *p_status = ST_MEM_ALLOC_FAIL;
          return NULL;
     }

     strcpy(p_str_info2->str, p_str_info1->str);
     p_str_info2->max = p_str_info1->max;
     p_str_info2->len = p_str_info1->len;
     p_str_info2->type = RW_STR;
     p_str_info2->links = 1;

     *p_status = ST_SUCCESS;
     return p_str_info2;
}

STATUS str_append(STRSTRUCT_INFO *p_str_info, UCHAR * p_ch)
{
     size_t len_p_ch;
     STATUS status;

     len_p_ch = strlen(p_ch);
     status = str_change_size_n_type(p_str_info, p_str_info->len + len_p_ch);
     if (status != ST_SUCCESS)
     {
          return status;
     }
     else
     {
          strcpy(p_str_info->str + p_str_info->len, p_ch);
          p_str_info->len += len_p_ch;

          return ST_SUCCESS;
     }
}

STATUS str_chop(STRSTRUCT_INFO *p_str_info, UINT pos)
{
     STATUS status;

     status = str_change_size_n_type(p_str_info, pos);
     if (status != ST_SUCCESS)
     {
          return status;
     }
     else
     {
          p_str_info->str[pos] = 0;
          return ST_SUCCESS;
     }
}

STATUS str_free(STRSTRUCT_INFO *p_str_info)
{
     if (p_str_info->links > 1)
     {
          p_str_info->links--;
     }
     else
     {
          if (p_str_info->type == RW_STR)
          {
               free(p_str_info->str);
          }
          free(p_str_info);
     }

     return ST_SUCCESS;
}

STATUS str_replace(STRSTRUCT_INFO *p_str_info,
                   UCHAR *newstr, int newlen, STR_TYPE type)
{
     if (p_str_info->type == RW_STR)
     {
          free(p_str_info->str);
     }

     p_str_info->max  = get_new_length(p_str_info->max, newlen);
     p_str_info->len  = newlen;
     p_str_info->str  = newstr;
     p_str_info->type = type;

     return ST_SUCCESS;
}





