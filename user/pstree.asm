
user/_pstree:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <pstree>:


void pstree(struct uproc* uproc, int pid, int tab){
    struct uproc *p;

    if(pid < 0 || pid > NPROC)
   0:	04000793          	li	a5,64
   4:	08b7e463          	bltu	a5,a1,8c <pstree+0x8c>
void pstree(struct uproc* uproc, int pid, int tab){
   8:	7139                	addi	sp,sp,-64
   a:	fc06                	sd	ra,56(sp)
   c:	f822                	sd	s0,48(sp)
   e:	f426                	sd	s1,40(sp)
  10:	f04a                	sd	s2,32(sp)
  12:	ec4e                	sd	s3,24(sp)
  14:	e852                	sd	s4,16(sp)
  16:	e456                	sd	s5,8(sp)
  18:	0080                	addi	s0,sp,64
  1a:	84aa                	mv	s1,a0
  1c:	8a32                	mv	s4,a2
  1e:	89ae                	mv	s3,a1
        return;
    for(int i = 0; i < tab; i++){
  20:	00c05f63          	blez	a2,3e <pstree+0x3e>
  24:	4901                	li	s2,0
        printf("    ");
  26:	00001a97          	auipc	s5,0x1
  2a:	842a8a93          	addi	s5,s5,-1982 # 868 <malloc+0xe8>
  2e:	8556                	mv	a0,s5
  30:	00000097          	auipc	ra,0x0
  34:	698080e7          	jalr	1688(ra) # 6c8 <printf>
    for(int i = 0; i < tab; i++){
  38:	2905                	addiw	s2,s2,1
  3a:	ff2a1ae3          	bne	s4,s2,2e <pstree+0x2e>
    }

    printf("%d ", pid);
  3e:	85ce                	mv	a1,s3
  40:	00001517          	auipc	a0,0x1
  44:	83050513          	addi	a0,a0,-2000 # 870 <malloc+0xf0>
  48:	00000097          	auipc	ra,0x0
  4c:	680080e7          	jalr	1664(ra) # 6c8 <printf>

    for(p = uproc; p < &uproc[NPROC]; p++){
  50:	6905                	lui	s2,0x1
  52:	80090913          	addi	s2,s2,-2048 # 800 <malloc+0x80>
  56:	9926                	add	s2,s2,s1
        if (p->ppid == pid){
            pstree(p, p->pid, tab + 1);
  58:	2a05                	addiw	s4,s4,1
  5a:	a029                	j	64 <pstree+0x64>
    for(p = uproc; p < &uproc[NPROC]; p++){
  5c:	02048493          	addi	s1,s1,32
  60:	01248d63          	beq	s1,s2,7a <pstree+0x7a>
        if (p->ppid == pid){
  64:	44dc                	lw	a5,12(s1)
  66:	ff379be3          	bne	a5,s3,5c <pstree+0x5c>
            pstree(p, p->pid, tab + 1);
  6a:	8652                	mv	a2,s4
  6c:	408c                	lw	a1,0(s1)
  6e:	8526                	mv	a0,s1
  70:	00000097          	auipc	ra,0x0
  74:	f90080e7          	jalr	-112(ra) # 0 <pstree>
  78:	b7d5                	j	5c <pstree+0x5c>
        }
    }

    return;
}
  7a:	70e2                	ld	ra,56(sp)
  7c:	7442                	ld	s0,48(sp)
  7e:	74a2                	ld	s1,40(sp)
  80:	7902                	ld	s2,32(sp)
  82:	69e2                	ld	s3,24(sp)
  84:	6a42                	ld	s4,16(sp)
  86:	6aa2                	ld	s5,8(sp)
  88:	6121                	addi	sp,sp,64
  8a:	8082                	ret
  8c:	8082                	ret

000000000000008e <main>:

int main (int argc, char **argv) {
  8e:	1101                	addi	sp,sp,-32
  90:	ec06                	sd	ra,24(sp)
  92:	e822                	sd	s0,16(sp)
  94:	1000                	addi	s0,sp,32
  96:	81010113          	addi	sp,sp,-2032

	struct uproc uproc[NPROC];
	int nprocs;

	nprocs = getprocs(&uproc[0]);
  9a:	77fd                	lui	a5,0xfffff
  9c:	7f078793          	addi	a5,a5,2032 # fffffffffffff7f0 <__global_pointer$+0xffffffffffffe707>
  a0:	00f40533          	add	a0,s0,a5
  a4:	00000097          	auipc	ra,0x0
  a8:	342080e7          	jalr	834(ra) # 3e6 <getprocs>
	if (nprocs < 0)
  ac:	02054263          	bltz	a0,d0 <main+0x42>
		exit(-1);

	pstree(uproc, 0, 0);
  b0:	4601                	li	a2,0
  b2:	4581                	li	a1,0
  b4:	77fd                	lui	a5,0xfffff
  b6:	7f078793          	addi	a5,a5,2032 # fffffffffffff7f0 <__global_pointer$+0xffffffffffffe707>
  ba:	00f40533          	add	a0,s0,a5
  be:	00000097          	auipc	ra,0x0
  c2:	f42080e7          	jalr	-190(ra) # 0 <pstree>
	

	exit(0);
  c6:	4501                	li	a0,0
  c8:	00000097          	auipc	ra,0x0
  cc:	27e080e7          	jalr	638(ra) # 346 <exit>
		exit(-1);
  d0:	557d                	li	a0,-1
  d2:	00000097          	auipc	ra,0x0
  d6:	274080e7          	jalr	628(ra) # 346 <exit>

00000000000000da <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  da:	1141                	addi	sp,sp,-16
  dc:	e422                	sd	s0,8(sp)
  de:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  e0:	87aa                	mv	a5,a0
  e2:	0585                	addi	a1,a1,1
  e4:	0785                	addi	a5,a5,1
  e6:	fff5c703          	lbu	a4,-1(a1)
  ea:	fee78fa3          	sb	a4,-1(a5)
  ee:	fb75                	bnez	a4,e2 <strcpy+0x8>
    ;
  return os;
}
  f0:	6422                	ld	s0,8(sp)
  f2:	0141                	addi	sp,sp,16
  f4:	8082                	ret

00000000000000f6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  f6:	1141                	addi	sp,sp,-16
  f8:	e422                	sd	s0,8(sp)
  fa:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  fc:	00054783          	lbu	a5,0(a0)
 100:	cb91                	beqz	a5,114 <strcmp+0x1e>
 102:	0005c703          	lbu	a4,0(a1)
 106:	00f71763          	bne	a4,a5,114 <strcmp+0x1e>
    p++, q++;
 10a:	0505                	addi	a0,a0,1
 10c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 10e:	00054783          	lbu	a5,0(a0)
 112:	fbe5                	bnez	a5,102 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 114:	0005c503          	lbu	a0,0(a1)
}
 118:	40a7853b          	subw	a0,a5,a0
 11c:	6422                	ld	s0,8(sp)
 11e:	0141                	addi	sp,sp,16
 120:	8082                	ret

0000000000000122 <strlen>:

uint
strlen(const char *s)
{
 122:	1141                	addi	sp,sp,-16
 124:	e422                	sd	s0,8(sp)
 126:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 128:	00054783          	lbu	a5,0(a0)
 12c:	cf91                	beqz	a5,148 <strlen+0x26>
 12e:	0505                	addi	a0,a0,1
 130:	87aa                	mv	a5,a0
 132:	4685                	li	a3,1
 134:	9e89                	subw	a3,a3,a0
 136:	00f6853b          	addw	a0,a3,a5
 13a:	0785                	addi	a5,a5,1
 13c:	fff7c703          	lbu	a4,-1(a5)
 140:	fb7d                	bnez	a4,136 <strlen+0x14>
    ;
  return n;
}
 142:	6422                	ld	s0,8(sp)
 144:	0141                	addi	sp,sp,16
 146:	8082                	ret
  for(n = 0; s[n]; n++)
 148:	4501                	li	a0,0
 14a:	bfe5                	j	142 <strlen+0x20>

000000000000014c <memset>:

void*
memset(void *dst, int c, uint n)
{
 14c:	1141                	addi	sp,sp,-16
 14e:	e422                	sd	s0,8(sp)
 150:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 152:	ca19                	beqz	a2,168 <memset+0x1c>
 154:	87aa                	mv	a5,a0
 156:	1602                	slli	a2,a2,0x20
 158:	9201                	srli	a2,a2,0x20
 15a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 15e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 162:	0785                	addi	a5,a5,1
 164:	fee79de3          	bne	a5,a4,15e <memset+0x12>
  }
  return dst;
}
 168:	6422                	ld	s0,8(sp)
 16a:	0141                	addi	sp,sp,16
 16c:	8082                	ret

000000000000016e <strchr>:

char*
strchr(const char *s, char c)
{
 16e:	1141                	addi	sp,sp,-16
 170:	e422                	sd	s0,8(sp)
 172:	0800                	addi	s0,sp,16
  for(; *s; s++)
 174:	00054783          	lbu	a5,0(a0)
 178:	cb99                	beqz	a5,18e <strchr+0x20>
    if(*s == c)
 17a:	00f58763          	beq	a1,a5,188 <strchr+0x1a>
  for(; *s; s++)
 17e:	0505                	addi	a0,a0,1
 180:	00054783          	lbu	a5,0(a0)
 184:	fbfd                	bnez	a5,17a <strchr+0xc>
      return (char*)s;
  return 0;
 186:	4501                	li	a0,0
}
 188:	6422                	ld	s0,8(sp)
 18a:	0141                	addi	sp,sp,16
 18c:	8082                	ret
  return 0;
 18e:	4501                	li	a0,0
 190:	bfe5                	j	188 <strchr+0x1a>

0000000000000192 <gets>:

char*
gets(char *buf, int max)
{
 192:	711d                	addi	sp,sp,-96
 194:	ec86                	sd	ra,88(sp)
 196:	e8a2                	sd	s0,80(sp)
 198:	e4a6                	sd	s1,72(sp)
 19a:	e0ca                	sd	s2,64(sp)
 19c:	fc4e                	sd	s3,56(sp)
 19e:	f852                	sd	s4,48(sp)
 1a0:	f456                	sd	s5,40(sp)
 1a2:	f05a                	sd	s6,32(sp)
 1a4:	ec5e                	sd	s7,24(sp)
 1a6:	1080                	addi	s0,sp,96
 1a8:	8baa                	mv	s7,a0
 1aa:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ac:	892a                	mv	s2,a0
 1ae:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1b0:	4aa9                	li	s5,10
 1b2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1b4:	89a6                	mv	s3,s1
 1b6:	2485                	addiw	s1,s1,1
 1b8:	0344d863          	bge	s1,s4,1e8 <gets+0x56>
    cc = read(0, &c, 1);
 1bc:	4605                	li	a2,1
 1be:	faf40593          	addi	a1,s0,-81
 1c2:	4501                	li	a0,0
 1c4:	00000097          	auipc	ra,0x0
 1c8:	19a080e7          	jalr	410(ra) # 35e <read>
    if(cc < 1)
 1cc:	00a05e63          	blez	a0,1e8 <gets+0x56>
    buf[i++] = c;
 1d0:	faf44783          	lbu	a5,-81(s0)
 1d4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1d8:	01578763          	beq	a5,s5,1e6 <gets+0x54>
 1dc:	0905                	addi	s2,s2,1
 1de:	fd679be3          	bne	a5,s6,1b4 <gets+0x22>
  for(i=0; i+1 < max; ){
 1e2:	89a6                	mv	s3,s1
 1e4:	a011                	j	1e8 <gets+0x56>
 1e6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1e8:	99de                	add	s3,s3,s7
 1ea:	00098023          	sb	zero,0(s3)
  return buf;
}
 1ee:	855e                	mv	a0,s7
 1f0:	60e6                	ld	ra,88(sp)
 1f2:	6446                	ld	s0,80(sp)
 1f4:	64a6                	ld	s1,72(sp)
 1f6:	6906                	ld	s2,64(sp)
 1f8:	79e2                	ld	s3,56(sp)
 1fa:	7a42                	ld	s4,48(sp)
 1fc:	7aa2                	ld	s5,40(sp)
 1fe:	7b02                	ld	s6,32(sp)
 200:	6be2                	ld	s7,24(sp)
 202:	6125                	addi	sp,sp,96
 204:	8082                	ret

0000000000000206 <stat>:

int
stat(const char *n, struct stat *st)
{
 206:	1101                	addi	sp,sp,-32
 208:	ec06                	sd	ra,24(sp)
 20a:	e822                	sd	s0,16(sp)
 20c:	e426                	sd	s1,8(sp)
 20e:	e04a                	sd	s2,0(sp)
 210:	1000                	addi	s0,sp,32
 212:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 214:	4581                	li	a1,0
 216:	00000097          	auipc	ra,0x0
 21a:	170080e7          	jalr	368(ra) # 386 <open>
  if(fd < 0)
 21e:	02054563          	bltz	a0,248 <stat+0x42>
 222:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 224:	85ca                	mv	a1,s2
 226:	00000097          	auipc	ra,0x0
 22a:	178080e7          	jalr	376(ra) # 39e <fstat>
 22e:	892a                	mv	s2,a0
  close(fd);
 230:	8526                	mv	a0,s1
 232:	00000097          	auipc	ra,0x0
 236:	13c080e7          	jalr	316(ra) # 36e <close>
  return r;
}
 23a:	854a                	mv	a0,s2
 23c:	60e2                	ld	ra,24(sp)
 23e:	6442                	ld	s0,16(sp)
 240:	64a2                	ld	s1,8(sp)
 242:	6902                	ld	s2,0(sp)
 244:	6105                	addi	sp,sp,32
 246:	8082                	ret
    return -1;
 248:	597d                	li	s2,-1
 24a:	bfc5                	j	23a <stat+0x34>

000000000000024c <atoi>:

int
atoi(const char *s)
{
 24c:	1141                	addi	sp,sp,-16
 24e:	e422                	sd	s0,8(sp)
 250:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 252:	00054683          	lbu	a3,0(a0)
 256:	fd06879b          	addiw	a5,a3,-48
 25a:	0ff7f793          	zext.b	a5,a5
 25e:	4625                	li	a2,9
 260:	02f66863          	bltu	a2,a5,290 <atoi+0x44>
 264:	872a                	mv	a4,a0
  n = 0;
 266:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 268:	0705                	addi	a4,a4,1
 26a:	0025179b          	slliw	a5,a0,0x2
 26e:	9fa9                	addw	a5,a5,a0
 270:	0017979b          	slliw	a5,a5,0x1
 274:	9fb5                	addw	a5,a5,a3
 276:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 27a:	00074683          	lbu	a3,0(a4)
 27e:	fd06879b          	addiw	a5,a3,-48
 282:	0ff7f793          	zext.b	a5,a5
 286:	fef671e3          	bgeu	a2,a5,268 <atoi+0x1c>
  return n;
}
 28a:	6422                	ld	s0,8(sp)
 28c:	0141                	addi	sp,sp,16
 28e:	8082                	ret
  n = 0;
 290:	4501                	li	a0,0
 292:	bfe5                	j	28a <atoi+0x3e>

0000000000000294 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 294:	1141                	addi	sp,sp,-16
 296:	e422                	sd	s0,8(sp)
 298:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 29a:	02b57463          	bgeu	a0,a1,2c2 <memmove+0x2e>
    while(n-- > 0)
 29e:	00c05f63          	blez	a2,2bc <memmove+0x28>
 2a2:	1602                	slli	a2,a2,0x20
 2a4:	9201                	srli	a2,a2,0x20
 2a6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2aa:	872a                	mv	a4,a0
      *dst++ = *src++;
 2ac:	0585                	addi	a1,a1,1
 2ae:	0705                	addi	a4,a4,1
 2b0:	fff5c683          	lbu	a3,-1(a1)
 2b4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2b8:	fee79ae3          	bne	a5,a4,2ac <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2bc:	6422                	ld	s0,8(sp)
 2be:	0141                	addi	sp,sp,16
 2c0:	8082                	ret
    dst += n;
 2c2:	00c50733          	add	a4,a0,a2
    src += n;
 2c6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2c8:	fec05ae3          	blez	a2,2bc <memmove+0x28>
 2cc:	fff6079b          	addiw	a5,a2,-1
 2d0:	1782                	slli	a5,a5,0x20
 2d2:	9381                	srli	a5,a5,0x20
 2d4:	fff7c793          	not	a5,a5
 2d8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2da:	15fd                	addi	a1,a1,-1
 2dc:	177d                	addi	a4,a4,-1
 2de:	0005c683          	lbu	a3,0(a1)
 2e2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2e6:	fee79ae3          	bne	a5,a4,2da <memmove+0x46>
 2ea:	bfc9                	j	2bc <memmove+0x28>

00000000000002ec <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e422                	sd	s0,8(sp)
 2f0:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2f2:	ca05                	beqz	a2,322 <memcmp+0x36>
 2f4:	fff6069b          	addiw	a3,a2,-1
 2f8:	1682                	slli	a3,a3,0x20
 2fa:	9281                	srli	a3,a3,0x20
 2fc:	0685                	addi	a3,a3,1
 2fe:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 300:	00054783          	lbu	a5,0(a0)
 304:	0005c703          	lbu	a4,0(a1)
 308:	00e79863          	bne	a5,a4,318 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 30c:	0505                	addi	a0,a0,1
    p2++;
 30e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 310:	fed518e3          	bne	a0,a3,300 <memcmp+0x14>
  }
  return 0;
 314:	4501                	li	a0,0
 316:	a019                	j	31c <memcmp+0x30>
      return *p1 - *p2;
 318:	40e7853b          	subw	a0,a5,a4
}
 31c:	6422                	ld	s0,8(sp)
 31e:	0141                	addi	sp,sp,16
 320:	8082                	ret
  return 0;
 322:	4501                	li	a0,0
 324:	bfe5                	j	31c <memcmp+0x30>

0000000000000326 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 326:	1141                	addi	sp,sp,-16
 328:	e406                	sd	ra,8(sp)
 32a:	e022                	sd	s0,0(sp)
 32c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 32e:	00000097          	auipc	ra,0x0
 332:	f66080e7          	jalr	-154(ra) # 294 <memmove>
}
 336:	60a2                	ld	ra,8(sp)
 338:	6402                	ld	s0,0(sp)
 33a:	0141                	addi	sp,sp,16
 33c:	8082                	ret

000000000000033e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 33e:	4885                	li	a7,1
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <exit>:
.global exit
exit:
 li a7, SYS_exit
 346:	4889                	li	a7,2
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <wait>:
.global wait
wait:
 li a7, SYS_wait
 34e:	488d                	li	a7,3
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 356:	4891                	li	a7,4
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <read>:
.global read
read:
 li a7, SYS_read
 35e:	4895                	li	a7,5
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <write>:
.global write
write:
 li a7, SYS_write
 366:	48c1                	li	a7,16
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <close>:
.global close
close:
 li a7, SYS_close
 36e:	48d5                	li	a7,21
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <kill>:
.global kill
kill:
 li a7, SYS_kill
 376:	4899                	li	a7,6
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <exec>:
.global exec
exec:
 li a7, SYS_exec
 37e:	489d                	li	a7,7
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <open>:
.global open
open:
 li a7, SYS_open
 386:	48bd                	li	a7,15
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 38e:	48c5                	li	a7,17
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 396:	48c9                	li	a7,18
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 39e:	48a1                	li	a7,8
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <link>:
.global link
link:
 li a7, SYS_link
 3a6:	48cd                	li	a7,19
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3ae:	48d1                	li	a7,20
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3b6:	48a5                	li	a7,9
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <dup>:
.global dup
dup:
 li a7, SYS_dup
 3be:	48a9                	li	a7,10
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3c6:	48ad                	li	a7,11
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ce:	48b1                	li	a7,12
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3d6:	48b5                	li	a7,13
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3de:	48b9                	li	a7,14
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 3e6:	48d9                	li	a7,22
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3ee:	1101                	addi	sp,sp,-32
 3f0:	ec06                	sd	ra,24(sp)
 3f2:	e822                	sd	s0,16(sp)
 3f4:	1000                	addi	s0,sp,32
 3f6:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3fa:	4605                	li	a2,1
 3fc:	fef40593          	addi	a1,s0,-17
 400:	00000097          	auipc	ra,0x0
 404:	f66080e7          	jalr	-154(ra) # 366 <write>
}
 408:	60e2                	ld	ra,24(sp)
 40a:	6442                	ld	s0,16(sp)
 40c:	6105                	addi	sp,sp,32
 40e:	8082                	ret

0000000000000410 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 410:	7139                	addi	sp,sp,-64
 412:	fc06                	sd	ra,56(sp)
 414:	f822                	sd	s0,48(sp)
 416:	f426                	sd	s1,40(sp)
 418:	f04a                	sd	s2,32(sp)
 41a:	ec4e                	sd	s3,24(sp)
 41c:	0080                	addi	s0,sp,64
 41e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 420:	c299                	beqz	a3,426 <printint+0x16>
 422:	0805c963          	bltz	a1,4b4 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 426:	2581                	sext.w	a1,a1
  neg = 0;
 428:	4881                	li	a7,0
 42a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 42e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 430:	2601                	sext.w	a2,a2
 432:	00000517          	auipc	a0,0x0
 436:	4a650513          	addi	a0,a0,1190 # 8d8 <digits>
 43a:	883a                	mv	a6,a4
 43c:	2705                	addiw	a4,a4,1
 43e:	02c5f7bb          	remuw	a5,a1,a2
 442:	1782                	slli	a5,a5,0x20
 444:	9381                	srli	a5,a5,0x20
 446:	97aa                	add	a5,a5,a0
 448:	0007c783          	lbu	a5,0(a5)
 44c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 450:	0005879b          	sext.w	a5,a1
 454:	02c5d5bb          	divuw	a1,a1,a2
 458:	0685                	addi	a3,a3,1
 45a:	fec7f0e3          	bgeu	a5,a2,43a <printint+0x2a>
  if(neg)
 45e:	00088c63          	beqz	a7,476 <printint+0x66>
    buf[i++] = '-';
 462:	fd070793          	addi	a5,a4,-48
 466:	00878733          	add	a4,a5,s0
 46a:	02d00793          	li	a5,45
 46e:	fef70823          	sb	a5,-16(a4)
 472:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 476:	02e05863          	blez	a4,4a6 <printint+0x96>
 47a:	fc040793          	addi	a5,s0,-64
 47e:	00e78933          	add	s2,a5,a4
 482:	fff78993          	addi	s3,a5,-1
 486:	99ba                	add	s3,s3,a4
 488:	377d                	addiw	a4,a4,-1
 48a:	1702                	slli	a4,a4,0x20
 48c:	9301                	srli	a4,a4,0x20
 48e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 492:	fff94583          	lbu	a1,-1(s2)
 496:	8526                	mv	a0,s1
 498:	00000097          	auipc	ra,0x0
 49c:	f56080e7          	jalr	-170(ra) # 3ee <putc>
  while(--i >= 0)
 4a0:	197d                	addi	s2,s2,-1
 4a2:	ff3918e3          	bne	s2,s3,492 <printint+0x82>
}
 4a6:	70e2                	ld	ra,56(sp)
 4a8:	7442                	ld	s0,48(sp)
 4aa:	74a2                	ld	s1,40(sp)
 4ac:	7902                	ld	s2,32(sp)
 4ae:	69e2                	ld	s3,24(sp)
 4b0:	6121                	addi	sp,sp,64
 4b2:	8082                	ret
    x = -xx;
 4b4:	40b005bb          	negw	a1,a1
    neg = 1;
 4b8:	4885                	li	a7,1
    x = -xx;
 4ba:	bf85                	j	42a <printint+0x1a>

00000000000004bc <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4bc:	7119                	addi	sp,sp,-128
 4be:	fc86                	sd	ra,120(sp)
 4c0:	f8a2                	sd	s0,112(sp)
 4c2:	f4a6                	sd	s1,104(sp)
 4c4:	f0ca                	sd	s2,96(sp)
 4c6:	ecce                	sd	s3,88(sp)
 4c8:	e8d2                	sd	s4,80(sp)
 4ca:	e4d6                	sd	s5,72(sp)
 4cc:	e0da                	sd	s6,64(sp)
 4ce:	fc5e                	sd	s7,56(sp)
 4d0:	f862                	sd	s8,48(sp)
 4d2:	f466                	sd	s9,40(sp)
 4d4:	f06a                	sd	s10,32(sp)
 4d6:	ec6e                	sd	s11,24(sp)
 4d8:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4da:	0005c903          	lbu	s2,0(a1)
 4de:	18090f63          	beqz	s2,67c <vprintf+0x1c0>
 4e2:	8aaa                	mv	s5,a0
 4e4:	8b32                	mv	s6,a2
 4e6:	00158493          	addi	s1,a1,1
  state = 0;
 4ea:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4ec:	02500a13          	li	s4,37
 4f0:	4c55                	li	s8,21
 4f2:	00000c97          	auipc	s9,0x0
 4f6:	38ec8c93          	addi	s9,s9,910 # 880 <malloc+0x100>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4fa:	02800d93          	li	s11,40
  putc(fd, 'x');
 4fe:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 500:	00000b97          	auipc	s7,0x0
 504:	3d8b8b93          	addi	s7,s7,984 # 8d8 <digits>
 508:	a839                	j	526 <vprintf+0x6a>
        putc(fd, c);
 50a:	85ca                	mv	a1,s2
 50c:	8556                	mv	a0,s5
 50e:	00000097          	auipc	ra,0x0
 512:	ee0080e7          	jalr	-288(ra) # 3ee <putc>
 516:	a019                	j	51c <vprintf+0x60>
    } else if(state == '%'){
 518:	01498d63          	beq	s3,s4,532 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 51c:	0485                	addi	s1,s1,1
 51e:	fff4c903          	lbu	s2,-1(s1)
 522:	14090d63          	beqz	s2,67c <vprintf+0x1c0>
    if(state == 0){
 526:	fe0999e3          	bnez	s3,518 <vprintf+0x5c>
      if(c == '%'){
 52a:	ff4910e3          	bne	s2,s4,50a <vprintf+0x4e>
        state = '%';
 52e:	89d2                	mv	s3,s4
 530:	b7f5                	j	51c <vprintf+0x60>
      if(c == 'd'){
 532:	11490c63          	beq	s2,s4,64a <vprintf+0x18e>
 536:	f9d9079b          	addiw	a5,s2,-99
 53a:	0ff7f793          	zext.b	a5,a5
 53e:	10fc6e63          	bltu	s8,a5,65a <vprintf+0x19e>
 542:	f9d9079b          	addiw	a5,s2,-99
 546:	0ff7f713          	zext.b	a4,a5
 54a:	10ec6863          	bltu	s8,a4,65a <vprintf+0x19e>
 54e:	00271793          	slli	a5,a4,0x2
 552:	97e6                	add	a5,a5,s9
 554:	439c                	lw	a5,0(a5)
 556:	97e6                	add	a5,a5,s9
 558:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 55a:	008b0913          	addi	s2,s6,8
 55e:	4685                	li	a3,1
 560:	4629                	li	a2,10
 562:	000b2583          	lw	a1,0(s6)
 566:	8556                	mv	a0,s5
 568:	00000097          	auipc	ra,0x0
 56c:	ea8080e7          	jalr	-344(ra) # 410 <printint>
 570:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 572:	4981                	li	s3,0
 574:	b765                	j	51c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 576:	008b0913          	addi	s2,s6,8
 57a:	4681                	li	a3,0
 57c:	4629                	li	a2,10
 57e:	000b2583          	lw	a1,0(s6)
 582:	8556                	mv	a0,s5
 584:	00000097          	auipc	ra,0x0
 588:	e8c080e7          	jalr	-372(ra) # 410 <printint>
 58c:	8b4a                	mv	s6,s2
      state = 0;
 58e:	4981                	li	s3,0
 590:	b771                	j	51c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 592:	008b0913          	addi	s2,s6,8
 596:	4681                	li	a3,0
 598:	866a                	mv	a2,s10
 59a:	000b2583          	lw	a1,0(s6)
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	e70080e7          	jalr	-400(ra) # 410 <printint>
 5a8:	8b4a                	mv	s6,s2
      state = 0;
 5aa:	4981                	li	s3,0
 5ac:	bf85                	j	51c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5ae:	008b0793          	addi	a5,s6,8
 5b2:	f8f43423          	sd	a5,-120(s0)
 5b6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5ba:	03000593          	li	a1,48
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	e2e080e7          	jalr	-466(ra) # 3ee <putc>
  putc(fd, 'x');
 5c8:	07800593          	li	a1,120
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e20080e7          	jalr	-480(ra) # 3ee <putc>
 5d6:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5d8:	03c9d793          	srli	a5,s3,0x3c
 5dc:	97de                	add	a5,a5,s7
 5de:	0007c583          	lbu	a1,0(a5)
 5e2:	8556                	mv	a0,s5
 5e4:	00000097          	auipc	ra,0x0
 5e8:	e0a080e7          	jalr	-502(ra) # 3ee <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5ec:	0992                	slli	s3,s3,0x4
 5ee:	397d                	addiw	s2,s2,-1
 5f0:	fe0914e3          	bnez	s2,5d8 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5f4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5f8:	4981                	li	s3,0
 5fa:	b70d                	j	51c <vprintf+0x60>
        s = va_arg(ap, char*);
 5fc:	008b0913          	addi	s2,s6,8
 600:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 604:	02098163          	beqz	s3,626 <vprintf+0x16a>
        while(*s != 0){
 608:	0009c583          	lbu	a1,0(s3)
 60c:	c5ad                	beqz	a1,676 <vprintf+0x1ba>
          putc(fd, *s);
 60e:	8556                	mv	a0,s5
 610:	00000097          	auipc	ra,0x0
 614:	dde080e7          	jalr	-546(ra) # 3ee <putc>
          s++;
 618:	0985                	addi	s3,s3,1
        while(*s != 0){
 61a:	0009c583          	lbu	a1,0(s3)
 61e:	f9e5                	bnez	a1,60e <vprintf+0x152>
        s = va_arg(ap, char*);
 620:	8b4a                	mv	s6,s2
      state = 0;
 622:	4981                	li	s3,0
 624:	bde5                	j	51c <vprintf+0x60>
          s = "(null)";
 626:	00000997          	auipc	s3,0x0
 62a:	25298993          	addi	s3,s3,594 # 878 <malloc+0xf8>
        while(*s != 0){
 62e:	85ee                	mv	a1,s11
 630:	bff9                	j	60e <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 632:	008b0913          	addi	s2,s6,8
 636:	000b4583          	lbu	a1,0(s6)
 63a:	8556                	mv	a0,s5
 63c:	00000097          	auipc	ra,0x0
 640:	db2080e7          	jalr	-590(ra) # 3ee <putc>
 644:	8b4a                	mv	s6,s2
      state = 0;
 646:	4981                	li	s3,0
 648:	bdd1                	j	51c <vprintf+0x60>
        putc(fd, c);
 64a:	85d2                	mv	a1,s4
 64c:	8556                	mv	a0,s5
 64e:	00000097          	auipc	ra,0x0
 652:	da0080e7          	jalr	-608(ra) # 3ee <putc>
      state = 0;
 656:	4981                	li	s3,0
 658:	b5d1                	j	51c <vprintf+0x60>
        putc(fd, '%');
 65a:	85d2                	mv	a1,s4
 65c:	8556                	mv	a0,s5
 65e:	00000097          	auipc	ra,0x0
 662:	d90080e7          	jalr	-624(ra) # 3ee <putc>
        putc(fd, c);
 666:	85ca                	mv	a1,s2
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	d84080e7          	jalr	-636(ra) # 3ee <putc>
      state = 0;
 672:	4981                	li	s3,0
 674:	b565                	j	51c <vprintf+0x60>
        s = va_arg(ap, char*);
 676:	8b4a                	mv	s6,s2
      state = 0;
 678:	4981                	li	s3,0
 67a:	b54d                	j	51c <vprintf+0x60>
    }
  }
}
 67c:	70e6                	ld	ra,120(sp)
 67e:	7446                	ld	s0,112(sp)
 680:	74a6                	ld	s1,104(sp)
 682:	7906                	ld	s2,96(sp)
 684:	69e6                	ld	s3,88(sp)
 686:	6a46                	ld	s4,80(sp)
 688:	6aa6                	ld	s5,72(sp)
 68a:	6b06                	ld	s6,64(sp)
 68c:	7be2                	ld	s7,56(sp)
 68e:	7c42                	ld	s8,48(sp)
 690:	7ca2                	ld	s9,40(sp)
 692:	7d02                	ld	s10,32(sp)
 694:	6de2                	ld	s11,24(sp)
 696:	6109                	addi	sp,sp,128
 698:	8082                	ret

000000000000069a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 69a:	715d                	addi	sp,sp,-80
 69c:	ec06                	sd	ra,24(sp)
 69e:	e822                	sd	s0,16(sp)
 6a0:	1000                	addi	s0,sp,32
 6a2:	e010                	sd	a2,0(s0)
 6a4:	e414                	sd	a3,8(s0)
 6a6:	e818                	sd	a4,16(s0)
 6a8:	ec1c                	sd	a5,24(s0)
 6aa:	03043023          	sd	a6,32(s0)
 6ae:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6b2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6b6:	8622                	mv	a2,s0
 6b8:	00000097          	auipc	ra,0x0
 6bc:	e04080e7          	jalr	-508(ra) # 4bc <vprintf>
}
 6c0:	60e2                	ld	ra,24(sp)
 6c2:	6442                	ld	s0,16(sp)
 6c4:	6161                	addi	sp,sp,80
 6c6:	8082                	ret

00000000000006c8 <printf>:

void
printf(const char *fmt, ...)
{
 6c8:	711d                	addi	sp,sp,-96
 6ca:	ec06                	sd	ra,24(sp)
 6cc:	e822                	sd	s0,16(sp)
 6ce:	1000                	addi	s0,sp,32
 6d0:	e40c                	sd	a1,8(s0)
 6d2:	e810                	sd	a2,16(s0)
 6d4:	ec14                	sd	a3,24(s0)
 6d6:	f018                	sd	a4,32(s0)
 6d8:	f41c                	sd	a5,40(s0)
 6da:	03043823          	sd	a6,48(s0)
 6de:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6e2:	00840613          	addi	a2,s0,8
 6e6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ea:	85aa                	mv	a1,a0
 6ec:	4505                	li	a0,1
 6ee:	00000097          	auipc	ra,0x0
 6f2:	dce080e7          	jalr	-562(ra) # 4bc <vprintf>
}
 6f6:	60e2                	ld	ra,24(sp)
 6f8:	6442                	ld	s0,16(sp)
 6fa:	6125                	addi	sp,sp,96
 6fc:	8082                	ret

00000000000006fe <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6fe:	1141                	addi	sp,sp,-16
 700:	e422                	sd	s0,8(sp)
 702:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 704:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 708:	00000797          	auipc	a5,0x0
 70c:	1e87b783          	ld	a5,488(a5) # 8f0 <freep>
 710:	a02d                	j	73a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 712:	4618                	lw	a4,8(a2)
 714:	9f2d                	addw	a4,a4,a1
 716:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 71a:	6398                	ld	a4,0(a5)
 71c:	6310                	ld	a2,0(a4)
 71e:	a83d                	j	75c <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 720:	ff852703          	lw	a4,-8(a0)
 724:	9f31                	addw	a4,a4,a2
 726:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 728:	ff053683          	ld	a3,-16(a0)
 72c:	a091                	j	770 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 72e:	6398                	ld	a4,0(a5)
 730:	00e7e463          	bltu	a5,a4,738 <free+0x3a>
 734:	00e6ea63          	bltu	a3,a4,748 <free+0x4a>
{
 738:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 73a:	fed7fae3          	bgeu	a5,a3,72e <free+0x30>
 73e:	6398                	ld	a4,0(a5)
 740:	00e6e463          	bltu	a3,a4,748 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 744:	fee7eae3          	bltu	a5,a4,738 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 748:	ff852583          	lw	a1,-8(a0)
 74c:	6390                	ld	a2,0(a5)
 74e:	02059813          	slli	a6,a1,0x20
 752:	01c85713          	srli	a4,a6,0x1c
 756:	9736                	add	a4,a4,a3
 758:	fae60de3          	beq	a2,a4,712 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 75c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 760:	4790                	lw	a2,8(a5)
 762:	02061593          	slli	a1,a2,0x20
 766:	01c5d713          	srli	a4,a1,0x1c
 76a:	973e                	add	a4,a4,a5
 76c:	fae68ae3          	beq	a3,a4,720 <free+0x22>
    p->s.ptr = bp->s.ptr;
 770:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 772:	00000717          	auipc	a4,0x0
 776:	16f73f23          	sd	a5,382(a4) # 8f0 <freep>
}
 77a:	6422                	ld	s0,8(sp)
 77c:	0141                	addi	sp,sp,16
 77e:	8082                	ret

0000000000000780 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 780:	7139                	addi	sp,sp,-64
 782:	fc06                	sd	ra,56(sp)
 784:	f822                	sd	s0,48(sp)
 786:	f426                	sd	s1,40(sp)
 788:	f04a                	sd	s2,32(sp)
 78a:	ec4e                	sd	s3,24(sp)
 78c:	e852                	sd	s4,16(sp)
 78e:	e456                	sd	s5,8(sp)
 790:	e05a                	sd	s6,0(sp)
 792:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 794:	02051493          	slli	s1,a0,0x20
 798:	9081                	srli	s1,s1,0x20
 79a:	04bd                	addi	s1,s1,15
 79c:	8091                	srli	s1,s1,0x4
 79e:	0014899b          	addiw	s3,s1,1
 7a2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7a4:	00000517          	auipc	a0,0x0
 7a8:	14c53503          	ld	a0,332(a0) # 8f0 <freep>
 7ac:	c515                	beqz	a0,7d8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ae:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7b0:	4798                	lw	a4,8(a5)
 7b2:	02977f63          	bgeu	a4,s1,7f0 <malloc+0x70>
 7b6:	8a4e                	mv	s4,s3
 7b8:	0009871b          	sext.w	a4,s3
 7bc:	6685                	lui	a3,0x1
 7be:	00d77363          	bgeu	a4,a3,7c4 <malloc+0x44>
 7c2:	6a05                	lui	s4,0x1
 7c4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7c8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7cc:	00000917          	auipc	s2,0x0
 7d0:	12490913          	addi	s2,s2,292 # 8f0 <freep>
  if(p == (char*)-1)
 7d4:	5afd                	li	s5,-1
 7d6:	a895                	j	84a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7d8:	00000797          	auipc	a5,0x0
 7dc:	12078793          	addi	a5,a5,288 # 8f8 <base>
 7e0:	00000717          	auipc	a4,0x0
 7e4:	10f73823          	sd	a5,272(a4) # 8f0 <freep>
 7e8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ea:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7ee:	b7e1                	j	7b6 <malloc+0x36>
      if(p->s.size == nunits)
 7f0:	02e48c63          	beq	s1,a4,828 <malloc+0xa8>
        p->s.size -= nunits;
 7f4:	4137073b          	subw	a4,a4,s3
 7f8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7fa:	02071693          	slli	a3,a4,0x20
 7fe:	01c6d713          	srli	a4,a3,0x1c
 802:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 804:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 808:	00000717          	auipc	a4,0x0
 80c:	0ea73423          	sd	a0,232(a4) # 8f0 <freep>
      return (void*)(p + 1);
 810:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 814:	70e2                	ld	ra,56(sp)
 816:	7442                	ld	s0,48(sp)
 818:	74a2                	ld	s1,40(sp)
 81a:	7902                	ld	s2,32(sp)
 81c:	69e2                	ld	s3,24(sp)
 81e:	6a42                	ld	s4,16(sp)
 820:	6aa2                	ld	s5,8(sp)
 822:	6b02                	ld	s6,0(sp)
 824:	6121                	addi	sp,sp,64
 826:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 828:	6398                	ld	a4,0(a5)
 82a:	e118                	sd	a4,0(a0)
 82c:	bff1                	j	808 <malloc+0x88>
  hp->s.size = nu;
 82e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 832:	0541                	addi	a0,a0,16
 834:	00000097          	auipc	ra,0x0
 838:	eca080e7          	jalr	-310(ra) # 6fe <free>
  return freep;
 83c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 840:	d971                	beqz	a0,814 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 842:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 844:	4798                	lw	a4,8(a5)
 846:	fa9775e3          	bgeu	a4,s1,7f0 <malloc+0x70>
    if(p == freep)
 84a:	00093703          	ld	a4,0(s2)
 84e:	853e                	mv	a0,a5
 850:	fef719e3          	bne	a4,a5,842 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 854:	8552                	mv	a0,s4
 856:	00000097          	auipc	ra,0x0
 85a:	b78080e7          	jalr	-1160(ra) # 3ce <sbrk>
  if(p == (char*)-1)
 85e:	fd5518e3          	bne	a0,s5,82e <malloc+0xae>
        return 0;
 862:	4501                	li	a0,0
 864:	bf45                	j	814 <malloc+0x94>
