#ifndef _STATUS_H
#define _STATUS_H

typedef enum
{
     ST_MEM_ALLOC_FAIL = 1,
     ST_END,
     ST_IDENTICAL,
     ST_EMPTY_LIST,
     ST_INVALID_OPERATION,
     ST_INVALID_FLAG,
     ST_SUCCESS
} STATUS;

typedef enum
{
     FL_DEFAULT = 1,
     FL_FREE_OBJECTS = 2
} FLAG;

#endif  /* _STATUS_H */
