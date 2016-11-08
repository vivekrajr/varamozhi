/* STRLIST data structure enables following operations on character sequences.
 * 1. Create
 * 2. Concat
 * 3. Length
 * 4. Retrieve
 * 5. Compare with a string
 */

#include <stdlib.h>
#include <string.h>
#include "strlist.h"
#include "status.h"

STRLIST strlist_create(UCHAR *p_ch, STR_TYPE type, STATUS *p_status)
{
     STRLIST_INFO *p_strlist_info;
     STRSTRUCT str;

     /* Three things are allocated here.
      * 1. info_header for this datastructure.
      * 2. a list to keep the substrings.
      * 3. first element in the list.
      *    it will carry the string 'str' in the list.
      */

     if ((p_strlist_info = (STRLIST_INFO *)malloc(sizeof(STRLIST_INFO))) == NULL)
     {
          *p_status = ST_MEM_ALLOC_FAIL;
          return NULL;
     }
     
     if ((p_strlist_info->list = list_create(p_status)) == NULL)
     {
          free(p_strlist_info);
          return NULL;
     }

     if (p_ch == NULL)
     {
          p_strlist_info->len = 0;
     }
     else
     {
          if ((str = str_create(p_ch, type, p_status)) == NULL)
          {
               list_free(p_strlist_info->list);
               free(p_strlist_info);
               return NULL;
          }

          *p_status = list_append(p_strlist_info->list, (LIST_OBJECT)str);

          if (*p_status != ST_SUCCESS)
          {
               str_free(str);
               list_free(p_strlist_info->list);
               free(p_strlist_info);
               return NULL;
          }

          p_strlist_info->len = str_get_len(str);
     }

     *p_status = ST_SUCCESS;
     return p_strlist_info;
}

STATUS strlist_free(STRLIST_INFO *p_strlist_info)
{
     /* this will be an internal static function.
      * Usually, will be called by strlist2string() */

     STATUS status;

     for(status = list_goto_start(p_strlist_info->list);
         status == ST_SUCCESS;
         status = list_goto_next(p_strlist_info->list))
     {
          str_free(list_get_object(p_strlist_info->list));
     }

     list_free(p_strlist_info->list);
     free(p_strlist_info);

     return ST_SUCCESS;
}

STATUS strlist_concat(STRLIST_INFO *p_info1, STRLIST_INFO *p_info2)
{
     /* this function will move(not copy) all substrings from
      * second list to first one. And the second list is destroyed */

     STATUS status;

     status = list_concat(p_info1->list, p_info2->list);
     if (status != ST_SUCCESS)
     {
          return status;
     }

     p_info1->len += p_info2->len;
     free(p_info2);

     return ST_SUCCESS;
}

UCHAR *strlist2string(STRLIST_INFO *p_info, STATUS *p_status)
{
     UCHAR    *str;
     UCHAR    *strpos;
     STATUS    status;
     STRSTRUCT substr;

     strpos = str = (UCHAR *)malloc(p_info->len + 1);
     if (strpos == NULL)
     {
          *p_status = ST_MEM_ALLOC_FAIL;
          return NULL;
     }

     /* copy each substring in the list to a single buffer */
     for(status = list_goto_start(p_info->list);
         status == ST_SUCCESS;
         status = list_goto_next(p_info->list))
     {
          substr = list_get_object(p_info->list);
          strncpy(strpos, str_get_data(substr), str_get_len(substr));
          strpos += str_get_len(substr);
     }
     *strpos = 0;

     /* we dont need the list any more */
     strlist_free(p_info);

     *p_status = ST_SUCCESS;
     return str;
}

STATUS strlist_pullup(STRLIST_INFO *p_info)
{
     UCHAR    *str;
     UCHAR    *strpos;
     STATUS    status;
     STRSTRUCT substr;
     STRSTRUCT bigstrobj;

     if ( list_get_length(p_info->list) <= 1 ) return ST_SUCCESS;

     strpos = str = (UCHAR *)malloc(p_info->len + 1);
     if (strpos == NULL)
     {
          return ST_MEM_ALLOC_FAIL;
     }

     /* copy each substring in the list to a single buffer */
     for(status = list_goto_start(p_info->list);
         status == ST_SUCCESS;
         status = list_goto_next(p_info->list))
     {
          substr = list_get_object(p_info->list);
          strncpy(strpos, str_get_data(substr), str_get_len(substr));
          strpos += str_get_len(substr);

          /* we have copied the data; delete the str_struct now */
          str_free(substr);
     }
     *strpos = 0;

     /* we now have:
      * 1. a list (p_info->list) with all elements deleted.
      * 2. a string (str) in which whole list is pulled up.
      * we need to put 2. in 1.
      */

     if ((bigstrobj = str_create(str, RW_STR, &status)) == NULL)
     {
          list_free(p_info->list);
          free(p_info);
          free(str);
          return status;
     }

     status = list_delete_all(p_info->list); /* expect no memory error */
     status = list_append(p_info->list, (LIST_OBJECT)bigstrobj);

     if (status != ST_SUCCESS)
     {
          str_free(bigstrobj);
          list_free(p_info->list);
          free(p_info);
          free(str);
          return status;
     }

     return ST_SUCCESS;
}

/* Act as strcmp but with string pointers as parameters and
 * return 0 if either of them is substring of the other.
 * *pstr1 and *pstr2 are changed to the last position compared
 * or when \0 is reached in either of them.
 */

int substrcmp(UCHAR **pstr1, UCHAR **pstr2)
{
     for(; ((**pstr1 != 0) && (**pstr2 != 0)); (*pstr1)++, (*pstr2)++)
     {
          if (**pstr1 != **pstr2) return (**pstr1 - **pstr2);
     }
     return 0;
}

int strlist_str_cmp(STRLIST_INFO *p_info, UCHAR *str)
{
     STATUS     status;
     int        compresult;
     UCHAR     *substr;
     STRSTRUCT  substrstruct;

     for(status = list_goto_start(p_info->list);
         status == ST_SUCCESS;
         status = list_goto_next(p_info->list))
     {
          substrstruct = list_get_object(p_info->list);
          substr       = str_get_data(substrstruct);
          compresult   = substrcmp(&substr, &str);

          /* if (substr is substring of str) or (substr == str)
           *     proceed to next iteration.
           * else return the same result as strcmp()
           */
          if (compresult != 0) return compresult;
          if (*substr != 0 && *str == 0) return 1;
     }
     if (*str != 0) return -1; /* strlist is substring of str  */
     else           return  0; /* strlist and str are the same */
}

UCHAR *strlist_str_get(STRLIST_INFO *p_info)
{
     STRSTRUCT s;

     if (ST_SUCCESS != strlist_pullup(p_info))
     {
          return NULL;
     }

     list_goto_start(p_info->list);

     s = list_get_object(p_info->list); /* got the string structure object */
     if ( s == NULL )
     {
     	return NULL;
     }
     else
     {
     	return str_get_data(s);
     }
}

STATUS strlist_replace(STRLIST_INFO *p_info, UCHAR *str, int len, STR_TYPE type)
{
     STRSTRUCT s;
     STATUS status;

     status = strlist_pullup(p_info);
     if (status != ST_SUCCESS) return status;

     status = list_goto_start(p_info->list);
     if ( status == ST_END && str == NULL )
        return ST_SUCCESS;

     if ( status == ST_END )
     {
     /* string list has an empty list.
      * so, add this string to that.
      */
          if ((s = str_create(str, type, &status)) == NULL)
          {
               list_free(p_info->list);
               free(p_info);
               return ST_MEM_ALLOC_FAIL;
          }

          status = list_append(p_info->list, (LIST_OBJECT)s );

          if (status != ST_SUCCESS)
          {
               str_free(s);
               list_free(p_info->list);
               free(p_info);
               return status;
          }
     }
     else
     {
     	/* str list is not empty */

     	s = list_get_object(p_info->list); /* got the string structure object */
    	status = str_replace(s, str, len, type);
     	if (status != ST_SUCCESS) return status;
     }
     p_info->len = len;
     return ST_SUCCESS;
}
