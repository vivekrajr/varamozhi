#include <stdio.h>
extern struct _reent *_impure_ptr;
extern struct _reent *__imp_reent_data;
__attribute__((stdcall))
int dll_entry(int handle, int reason, void *ptr)
{ return 1; }
