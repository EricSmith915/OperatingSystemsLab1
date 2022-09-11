#include "kernel/param.h"
#include "kernel/types.h"
#include "user/uproc.h"
#include "user/user.h"

int main (int argc, char **argv) {

	struct uproc uproc[NPROC];
	struct uproc *p;
	int nprocs;

	struct uproc *addr = uproc;
	nprocs = getprocs(addr);
	printf("%d", nprocs);

	if (nprocs < 0){
		exit(-1);
	}

  	for(p = uproc; p < &uproc[NPROC]; p++){
    	printf("%d %d %s %s", p->pid, p->size, p->state, p->name);
    	printf("\n");
  	}
	

	exit(0);
}	
