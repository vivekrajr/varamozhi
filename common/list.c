#include "list.h"
#include "status.h"
#include "stdlib.h"

LIST list_create(STATUS *p_status)
{
     LIST_HEAD *p_head;

     p_head = (LIST_HEAD*)malloc(sizeof(LIST_HEAD));
     if (p_head == NULL)
     {
          if (p_status != NULL)
          {
               *p_status = ST_MEM_ALLOC_FAIL;
          }
     }
     else
     {
          p_head->p_first_node = NULL;
          p_head->p_last_node  = NULL;
          p_head->p_cur_node   = NULL;
          p_head->length       = 0;
     }

     return p_head;
}

STATUS list_prepend(LIST_HEAD *p_head, LIST_OBJECT new_obj)
{
     LIST_NODE *p_new_node;

     p_new_node = (LIST_NODE *)malloc(sizeof(LIST_NODE));
     if (p_new_node == NULL)
     {
          return ST_MEM_ALLOC_FAIL;
     }

     p_new_node->object = new_obj;
     p_new_node->next   = p_head->p_first_node;
     p_new_node->prev   = NULL;

     if (p_head->p_first_node != NULL)
     {
          /* list is not empty */
          p_head->p_first_node->prev = p_new_node;
     }

     p_head->p_first_node = p_new_node;
     if (p_head->p_last_node == NULL)
     {
          /* first element in the list */
          p_head->p_last_node = p_new_node;
     }

     p_head->length++;

     return ST_SUCCESS;
}

STATUS list_append(LIST_HEAD *p_head, LIST_OBJECT new_obj)
{
     LIST_NODE *p_new_node;

     p_new_node = (LIST_NODE *)malloc(sizeof(LIST_NODE));
     if (p_new_node == NULL)
     {
          return ST_MEM_ALLOC_FAIL;
     }

     p_new_node->object = new_obj;
     p_new_node->next   = NULL;
     p_new_node->prev   = p_head->p_last_node;

     if (p_head->p_last_node != NULL)
     {
          /* list is not empty */
          p_head->p_last_node->next = p_new_node;
     }

     p_head->p_last_node = p_new_node;
     if (p_head->p_first_node == NULL)
     {
          /* first element in the list */
          p_head->p_first_node = p_new_node;
     }

     p_head->length++;

     return ST_SUCCESS;
}

LIST_OBJECT list_delete_first(LIST_HEAD *p_head, STATUS *p_status)
{
     LIST_OBJECT obj;
     LIST_NODE *p_node;

     if (p_head->p_first_node == NULL)
     {
          *p_status = ST_EMPTY_LIST;
          return NULL;
     }

     p_node = p_head->p_first_node;
     p_head->p_first_node = p_node->next;

     if (p_head->p_first_node != NULL)
     {
          p_head->p_first_node->prev = NULL;
     }

     if (p_head->p_cur_node == p_node)
     {
          p_head->p_cur_node = NULL;
     }

     if (p_head->p_last_node == p_node)
     {
          p_head->p_last_node = NULL;
     }

     obj = p_node->object;
     free(p_node);

     p_head->length--;

     *p_status = ST_SUCCESS;
     return obj;
}

LIST_OBJECT list_delete_last(LIST_HEAD *p_head, STATUS *p_status)
{
     LIST_OBJECT obj;
     LIST_NODE *p_node;

     if (p_head->p_last_node == NULL)
     {
          *p_status = ST_EMPTY_LIST;
          return NULL;
     }

     p_node = p_head->p_last_node;
     p_head->p_last_node = p_node->prev;

     if (p_head->p_last_node != NULL)
     {
          p_head->p_last_node->next = NULL;
     }

     if (p_head->p_cur_node == p_node)
     {
          p_head->p_cur_node = NULL;
     }

     if (p_head->p_first_node == p_node)
     {
          p_head->p_first_node = NULL;
     }

     obj = p_node->object;
     free(p_node);

     p_head->length--;

     *p_status = ST_SUCCESS;
     return obj;
}

STATUS list_concat(LIST_HEAD *p_head1, LIST_HEAD *p_head2)
{
     if (p_head1 == p_head2)
     {
          /* same list can not be concated */
          return ST_IDENTICAL;
     }

     if (p_head1->p_last_node == NULL)
     {
          /* no elements in first list */
          *p_head1 = *p_head2;
     }
     else if (p_head2->p_first_node != NULL)
     {
          /* second list contains one or more elements */
          p_head1->p_last_node->next  = p_head2->p_first_node;
          p_head2->p_first_node->prev = p_head1->p_last_node;
          p_head1->p_last_node        = p_head2->p_last_node;

          p_head1->length += p_head2->length;
     }
 
     /* second list is no longer valid */
     free(p_head2);

     return ST_SUCCESS;
}

STATUS list_delete_all(LIST_HEAD *p_head)
{
     LIST_NODE *p_node;
     LIST_NODE *p_next_node;

     for(p_node = p_head->p_first_node; p_node != NULL; )
     {
          p_next_node = p_node->next;
          free(p_node);
          p_node = p_next_node;
     }

     p_head->p_first_node = NULL;
     p_head->p_last_node  = NULL;
     p_head->p_cur_node   = NULL;
     p_head->length       = 0;

     return ST_SUCCESS;
}

STATUS list_free(LIST_HEAD *p_head)
{
     list_delete_all(p_head);
     free(p_head);

     return ST_SUCCESS;
}

STATUS list_goto_start(LIST_HEAD *p_head)
{
     p_head->p_cur_node = p_head->p_first_node;
     
     return (p_head->p_cur_node == NULL)? ST_END : ST_SUCCESS;
}

STATUS list_goto_end(LIST_HEAD *p_head)
{
     p_head->p_cur_node = p_head->p_last_node;
     
     return (p_head->p_cur_node == NULL)? ST_END : ST_SUCCESS;
}

STATUS list_goto_next(LIST_HEAD *p_head)
{
     if (p_head->p_cur_node != NULL)
     {
          p_head->p_cur_node = p_head->p_cur_node->next;
     }

     return (p_head->p_cur_node == NULL)? ST_END : ST_SUCCESS;
}

STATUS list_goto_prev(LIST_HEAD *p_head)
{
     if (p_head->p_cur_node != NULL)
     {
          p_head->p_cur_node = p_head->p_cur_node->prev;
     }

     return (p_head->p_cur_node == NULL)? ST_END : ST_SUCCESS;
}

LIST_OBJECT list_get_object(LIST_HEAD *p_head)
{
     return( (p_head->p_cur_node != NULL) ?
             p_head->p_cur_node->object : NULL );
}
