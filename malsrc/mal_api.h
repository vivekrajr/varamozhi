typedef int (*EXTERN_TRANS_FN)(unsigned char *, int, unsigned char **, int *);
extern EXTERN_TRANS_FN fn_eng_trans;
extern EXTERN_TRANS_FN fn_mal_trans;

#define FL_ALLOW_RDOT    0x01
#define FL_CARRY_COMMENT 0x02
#define FL_PROCESS_MACRO 0x04
#define FL_DEBUG         0x08
#define FL_DEFAULT       FL_PROCESS_MACRO

#if 0
#define mal_parse(txt) mozhi_kerala_parse((txt), DEFAULT)
char *mozhi_kerala_parse(char *txt, long flags);
#endif

