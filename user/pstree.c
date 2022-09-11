#include "kernel/param.h"
#include "kernel/types.h"
#include "user/uproc.h"
#include "user/user.h"


void pstree(struct uproc* uproc, int pid, int tab){
    struct uproc *p;

    if(pid < 0 || pid > NPROC)
        return;
    for(int i = 0; i < tab; i++){
        printf("    ");
    }

    printf("%d ", pid);

    for(p = uproc; p < &uproc[NPROC]; p++){
        if (p->ppid == pid){
            pstree(p, p->pid, tab + 1);
        }
    }

    return;
}

int main (int argc, char **argv) {

	struct uproc uproc[NPROC];
	int nprocs;

	nprocs = getprocs(&uproc[0]);
	if (nprocs < 0)
		exit(-1);

	pstree(uproc, 0, 0);
	

	exit(0);
}	