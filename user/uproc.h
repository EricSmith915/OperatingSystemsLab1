enum uprocstate { U_UNUSED, U_USED, U_SLEEPING, U_RUNNABLE, U_RUNNING, _ZOMBIE };

struct uproc {
	int pid;	//Process ID
	enum uprocstate state;	//Process State
	int size;	//Size of process memory
	int ppid;	//Parent ID
	char name[16];	//Process command name
};
