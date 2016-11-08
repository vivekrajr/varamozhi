/* STRPAIR data structure enables following operations on a pair of character sequences.
 * 1. Create
 * 2. Concat in the modes: _AABB, A_BAB, AB_BA
 * 3. Convert to a string
 * 4. Compare a string pair with a string
 */

#include <stdlib.h>
#include "strpair.h"
#include "strlist.h"
#include "status.h"

STRPAIR strpair_create(UCHAR *p_left, UCHAR *p_right)
{
     STRPAIR_INFO *p_strpair_info;
     STATUS status;

     /* Following are allocated here.
      * 1. info_header for this datastructure.
      * 2. lists to keep left and right strings.
      */

     if ((p_strpair_info = (STRPAIR_INFO *)malloc(sizeof(STRPAIR_INFO))) == NULL)
     {
          status = ST_MEM_ALLOC_FAIL;
          return NULL;
     }
     
     if ((p_strpair_info->lstr = strlist_create(p_left, RO_STR, &status)) == NULL)
     {
          free(p_strpair_info);
          return NULL;
     }

     if ((p_strpair_info->rstr = strlist_create(p_right, RO_STR, &status)) == NULL)
     {
          strlist_free(p_strpair_info->lstr);
          free(p_strpair_info);
          return NULL;
     }

     status = ST_SUCCESS;
     return p_strpair_info;
}

STRPAIR_INFO *strpair_concat(STRPAIR_INFO *p_info1,
                             STRPAIR_INFO *p_info2,
                             STRPAIR_CONCAT_MODE mode)
{
     /* this function will move(not copy) all substrings from
      * second pair to first one. And the second pair is destroyed */

     STATUS status;

     switch(mode)
     {
     case AA_BB:
         strlist_concat(p_info1->lstr, p_info1->rstr);
         strlist_concat(p_info2->lstr, p_info2->rstr);
         p_info1->rstr = p_info2->lstr;
         break;

     case A_BAB:
         strlist_concat(p_info2->lstr, p_info1->rstr);
         strlist_concat(p_info2->lstr, p_info2->rstr);
         p_info1->rstr = p_info2->lstr;
         break;

     case AB_BA:
         strlist_concat(p_info1->lstr, p_info2->lstr);
         strlist_concat(p_info2->rstr, p_info1->rstr);
         p_info1->rstr = p_info2->rstr;
         break;

     default:
          status = ST_INVALID_FLAG;
          return NULL;
     }

     /* second pair is destroyed */
     free(p_info2);

     status = ST_SUCCESS;
     return p_info1;
}

STRPAIR_INFO *strpair_str_mix(STRPAIR_INFO *p_info,
                              UCHAR *str,
                              STRPAIR_CONCAT_MODE mode)
{
     STRLIST tmpstrlist;
     STATUS status;

     switch(mode)
     {
     case AA_S:
       status = strlist_concat(p_info->lstr, p_info->rstr);
       p_info->rstr = strlist_create(str, RO_STR, &status);
       break;
  
     case A_SA:
       tmpstrlist = strlist_create(str, RO_STR, &status);
       status = strlist_concat(tmpstrlist, p_info->rstr);
       p_info->rstr = tmpstrlist;
       break;

     case A_AS:
       tmpstrlist = strlist_create(str, RO_STR, &status);
       status = strlist_concat(p_info->rstr, tmpstrlist);
       break;

     default:
       status = ST_INVALID_FLAG;
     }

     return p_info;
}

int strpair_str_cmp(STRPAIR_INFO *p_info, UCHAR *str, STRPAIR_PART side)
{
    STATUS status = ST_SUCCESS;

    switch (side)
    {
    case LEFTSTR:
      return strlist_str_cmp(p_info->lstr, str);
      break;

    case RIGHTSTR:
      return strlist_str_cmp(p_info->rstr, str);
      break;

    default:
      status = ST_INVALID_FLAG;
      return 0;
    }
}

UCHAR *strpair2string(STRPAIR_INFO *p_info)
{
     UCHAR *str;
     STATUS status;

     strlist_concat(p_info->lstr, p_info->rstr);
     str = strlist2string(p_info->lstr, &status);

     /* we dont need the pair any more */
     free(p_info);

     return str;
}

STRLIST strpair2strlist(STRPAIR_INFO *p_info)
{
     STRLIST slist;

     strlist_concat(p_info->lstr, p_info->rstr);
     slist = p_info->lstr;

     /* we dont need the pair any more */
     free(p_info);

     return slist;
}
