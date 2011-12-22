#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*Assume 64 bit search prefixes*/

#define TERMS_MAX 30
#define CHARTABLE_MAX 100

#define str_bits_cmp(T, s1, s2) (*(T*)(s1) == *(T*)(s2))

typedef char TXS_chartable_t[256];

#define txs_search_from_sv(sv) SvPVX(sv)
#define terms_from_search(srch) \
    (((char*)srch) + sizeof(struct TXS_Search))
struct TXS_String {
    int len;
    char *str;
};

struct TXS_Search {
    HV *trie;
	AV *orig_terms;
    int term_count;
    int min_len;
    TXS_chartable_t chartable[CHARTABLE_MAX]; 
};

SV* prefix_search_build(AV *mortal_av)
{
    int i = 0;
    int max = av_len(mortal_av);
    int my_len = sizeof(struct TXS_Search) + ( (sizeof(struct TXS_String)) * (max+1) );
    
    SV *mysv = newSV(my_len);
	AV *av_terms;
    
    struct TXS_Search *srch = SvPVX(mysv);
    struct TXS_String *terms = terms_from_search(srch);
    Zero(srch->chartable, CHARTABLE_MAX, TXS_chartable_t);
    
    srch->min_len = 100;
    srch->term_count = 0;
	
    srch->trie = newHV();
	srch->orig_terms = newAV();
	av_terms = srch->orig_terms;
	
	for(i = 0; i <= max; i++) {
		SV **old_sv = av_fetch(mortal_av, i, 0);
		if(!old_sv) {
			die("Terms list is partially empty at index %d", i);
		}
		if(SvROK(*old_sv)) {
			die("Found reference SV at index %d", i);
		}
		av_store(av_terms, i, newSVsv(*old_sv));
	}
    
	//warn("Have %d terms", max+1);
	
    for(i = 0; i <= max; i++) {
        struct TXS_String *strp = &terms[i];
        
        SV **a_term = av_fetch(av_terms, i, 0);
        int term_len;
        char *term_s = SvPV(*a_term, term_len);        
    
        strp->len = term_len;
        strp->str = term_s;
		//warn("Len is %d", strp->len);
        
        int j;
        for(j = term_len; j; j--) {
            hv_store(srch->trie, term_s, j, &PL_sv_undef, 0);
        }
        for(j = 0; j < term_len; j++) {
            srch->chartable[j][term_s[j]] = 1;
        }
        
        if(srch->min_len > term_len) {
            srch->min_len = term_len;
        }
    }
    
    srch->term_count = max;
    return newRV_noinc(mysv);
}

static int Optimized_8 = 0;
static int Optimized_4 = 0;
static int Optimized_2 = 0;
static int Optimized_chartable = 0;
static int Optimized_hash = 0;

SV* prefix_search(SV* mysv, char *input)
{
    int i = 1;
    int j, k;
	
	SV *ret = &PL_sv_undef;
	
    register struct TXS_String *strp;
    register int strp_len;
    register int input_len = strlen(input);
    if(!SvROK(mysv)) {
        die("Not a valid search blob");
    }
    struct TXS_Search *srch = txs_search_from_sv(SvRV(mysv));
    struct TXS_String *terms = terms_from_search(srch);
    
	//warn("Input: %s", input);
	
    if(input_len < srch->min_len) {
        //warn("Input length is smaller than minimum length");
		goto GT_RET;
    }
    
    for(i = 1; i <= srch->min_len; i++) {
        if(!srch->chartable[ i-1 ][input[ i-1 ]]) {
            Optimized_chartable++;
            return NULL;
        }
        if(!hv_exists(srch->trie, input, i)) {
            Optimized_hash++;
			goto GT_RET;
        }
    }
    
    for(i = 0; i <= srch->term_count; i++) {
        strp = &terms[i];
		
        if(input_len < strp->len) {
			//warn("Term with length %d too long", strp->len);
            continue;
        }
        /*
        For some reason, this isn't as fast as i would have hoped for?
        switch(strp->len) {
            case 8:
                Optimized_8++;
                if(!str_bits_cmp(uint64_t, input, strp->str)) {
                    continue;
                } else {
                    return strp->str;
                }
                break;
            case 4:
                Optimized_4++;
                if(!str_bits_cmp(uint32_t, input, strp->str)) {
                    continue;
                } else {
                    return strp->str;
                }
                break;
            case 2:
                Optimized_2++;
                if(!str_bits_cmp(uint16_t, input, strp->str)) {
                    continue;
                } else {
                    return strp->str;
                }
                break;
            default:
                break;
        }

        if(strp->len > 8) {
            if(!str_bits_cmp(uint64_t, input, strp->str)) {
                continue;
            }
            goto GT_CMP;
        }
        
        else if(strp->len > 4) {
            if(!str_bits_cmp(uint32_t, input, strp->str)) {
                continue;
            } else {
            
                goto GT_CMP;
            }
        }
        
        else if(strp->len > 2) {
            if(!str_bits_cmp(uint16_t, input, strp->str)) {
                continue;
            } else {
                goto GT_CMP;
            }
        }
        */
        GT_CMP:
        
        if(strncmp(input, strp->str, strp->len) == 0) {
			ret = newSVpv(strp->str, strp->len);
			goto GT_RET;
        }
    }
    
	GT_RET:
	//if(ret != &PL_sv_undef) {
	//	warn("Found i=%d, match=%s\n", i, SvPV_nolen(ret));
	//}
    return ret;        
}

#define _print_optimized(v) printf("%s: %d\n", #v, (v))

void print_optimized(char* foo)
{
    _print_optimized(Optimized_2);
    _print_optimized(Optimized_4);
    _print_optimized(Optimized_8);
    _print_optimized(Optimized_chartable);
    _print_optimized(Optimized_hash);
}
MODULE = Text::Prefix::XS	PACKAGE = Text::Prefix::XS

PROTOTYPES: DISABLE


SV *
prefix_search_build (av_terms)
	AV *	av_terms

SV *
prefix_search (mysv, input)
	SV *	mysv
	char *	input

void
print_optimized (foo)
	char *	foo
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	print_optimized(foo);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

