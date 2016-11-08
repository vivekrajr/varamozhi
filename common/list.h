#ifndef _LIST_H
#define _LIST_H

#include "status.h"

typedef void * LIST_OBJECT;

typedef struct _list_node
{
     LIST_OBJECT object;
     struct _list_node *next;
     struct _list_node *prev;
} LIST_NODE;

typedef struct _list_head
{
     LIST_NODE *p_first_node;
     LIST_NODE *p_last_node;
     LIST_NODE *p_cur_node;
     int        length;
} LIST_HEAD;

typedef LIST_HEAD *LIST;

LIST   list_create(STATUS *p_status);
STATUS list_prepend(LIST list, LIST_OBJECT new_obj);
STATUS list_append(LIST list, LIST_OBJECT new_obj);
LIST_OBJECT list_delete_first(LIST list, STATUS *p_status);
LIST_OBJECT list_delete_last(LIST list, STATUS *p_status);
STATUS list_concat(LIST list1, LIST list2);
STATUS list_free(LIST list);
STATUS list_delete_all(LIST list);
STATUS list_goto_start(LIST list);
STATUS list_goto_end(LIST list);
STATUS list_goto_next(LIST list);
STATUS list_goto_prev(LIST list);
LIST_OBJECT list_get_object(LIST list);

#define list_get_length(l) ((l)->length)

#endif  /* _LIST_H */
