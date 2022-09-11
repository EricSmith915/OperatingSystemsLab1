#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[]){
	if(argc < 2)
		printf("Enter a valid amount for sleep.\n");
		
	int time = atoi(argv[1]);
	
	if (time > 0){
		sleep(time);
	} else {
		printf("Enter a valid amount of time,\n");
	}
	
	exit(1);
}
