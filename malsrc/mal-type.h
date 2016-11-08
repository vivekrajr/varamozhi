#include "mal_api.h"


typedef char *record[6];
typedef record MapTable[];

typedef struct
{
     MapTable               *map;
     unsigned int            samindex;

/* processing font info */
     int                     (*yylex)(void);
     struct yy_buffer_state* (*yy_scan_bytes)();
     void                    (*yy_delete_buffer)();
     void                    (*yy_switch_to_buffer)();

/* processing macro info */
     int                     (*macrolex)(void);
     struct yy_buffer_state* (*macro_scan_bytes)();
     void                    (*macro_delete_buffer)();
     void                    (*macro_switch_to_buffer)();
     
} Private;

typedef enum
{
     WRAP,                /* will try to wrap first */
     WRAP_RIGHT,          /* wrap only the right part */
     WRAP_ELONG,          /* wrap elongation */
     POSSIBLE_DOUBLE,     /* check whether double or not */
     SAMVRUTHO,           /* will try to append with samvrutho */
     APPEND_CHILL,        /* will append CHILL of the syllable added */

     BEFORE_R_DOT,
     APPEND_R_DOT,
     R_DOT_DOUBLE,
     R_WRAP,
     NONE

} APPEND_MODE;

typedef enum
{
     LEFT_ONLY,
     RIGHT_ONLY,
     ADDABLE,
     NOADD,
     NOADD_R_DOT
  
} CREATE_MODE;

typedef enum
{
     MAIN  = 1,
     LEFT  = 2,
     RIGHT = 3,
     CHILL = 4,
     ELONG = 4,
     R_DOT = 5

} COMPONENT;

#ifndef _WINNT_H
typedef enum
{
     FALSE = 0,
     TRUE  = 1

} BOOLEAN;
#endif  /* _WINNT_H */


