
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	c3e78793          	addi	a5,a5,-962 # 80005ca0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	32a080e7          	jalr	810(ra) # 80002454 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	e8a080e7          	jalr	-374(ra) # 8000205a <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	1f2080e7          	jalr	498(ra) # 800023fe <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	1be080e7          	jalr	446(ra) # 800024aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	da6080e7          	jalr	-602(ra) # 800021e6 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	ea678793          	addi	a5,a5,-346 # 80021318 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	958080e7          	jalr	-1704(ra) # 800021e6 <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	740080e7          	jalr	1856(ra) # 8000205a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	898080e7          	jalr	-1896(ra) # 80002750 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	e20080e7          	jalr	-480(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fe0080e7          	jalr	-32(ra) # 80001ea8 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	7f8080e7          	jalr	2040(ra) # 80002728 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	818080e7          	jalr	-2024(ra) # 80002750 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	d8a080e7          	jalr	-630(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	d98080e7          	jalr	-616(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	f5a080e7          	jalr	-166(ra) # 80002eaa <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	5e8080e7          	jalr	1512(ra) # 80003540 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	59a080e7          	jalr	1434(ra) # 800044fa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e98080e7          	jalr	-360(ra) # 80005e00 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	cfe080e7          	jalr	-770(ra) # 80001c6e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	87ca0a13          	addi	s4,s4,-1924 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	16848493          	addi	s1,s1,360
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00015997          	auipc	s3,0x15
    80001924:	7b098993          	addi	s3,s3,1968 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	16848493          	addi	s1,s1,360
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	eba7a783          	lw	a5,-326(a5) # 800088a0 <first.2>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	d78080e7          	jalr	-648(ra) # 80002768 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	ea07a023          	sw	zero,-352(a5) # 800088a0 <first.2>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	ab6080e7          	jalr	-1354(ra) # 800034c0 <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
allocpid() {
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e7278793          	addi	a5,a5,-398 # 800088a4 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a58080e7          	jalr	-1448(ra) # 8000151c <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a32080e7          	jalr	-1486(ra) # 8000151c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e8080e7          	jalr	-1560(ra) # 8000151c <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8a080e7          	jalr	-374(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	51c90913          	addi	s2,s2,1308 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	16848493          	addi	s1,s1,360
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a889                	j	80001c30 <allocproc+0x90>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef2080e7          	jalr	-270(ra) # 80000ae0 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c131                	beqz	a0,80001c3e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c0a:	c531                	beqz	a0,80001c56 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b6080e7          	jalr	182(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f08080e7          	jalr	-248(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	03a080e7          	jalr	58(ra) # 80000c84 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x90>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	ef0080e7          	jalr	-272(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	022080e7          	jalr	34(ra) # 80000c84 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x90>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f28080e7          	jalr	-216(ra) # 80001ba0 <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	3aa7b323          	sd	a0,934(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	c2258593          	addi	a1,a1,-990 # 800088b0 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6b4080e7          	jalr	1716(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	55058593          	addi	a1,a1,1360 # 80008200 <digits+0x1c0>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	15a080e7          	jalr	346(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	54c50513          	addi	a0,a0,1356 # 80008210 <digits+0x1d0>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	22a080e7          	jalr	554(ra) # 80003ef6 <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fa6080e7          	jalr	-90(ra) # 80000c84 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c98080e7          	jalr	-872(ra) # 80001996 <myproc>
    80001d06:	892a                	mv	s2,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
    80001d0a:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d0e:	00904f63          	bgtz	s1,80001d2c <growproc+0x3c>
  } else if(n < 0){
    80001d12:	0204cd63          	bltz	s1,80001d4c <growproc+0x5c>
  p->sz = sz;
    80001d16:	1782                	slli	a5,a5,0x20
    80001d18:	9381                	srli	a5,a5,0x20
    80001d1a:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d1e:	4501                	li	a0,0
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2c:	00f4863b          	addw	a2,s1,a5
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	1582                	slli	a1,a1,0x20
    80001d36:	9181                	srli	a1,a1,0x20
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6cc080e7          	jalr	1740(ra) # 80001406 <uvmalloc>
    80001d42:	0005079b          	sext.w	a5,a0
    80001d46:	fbe1                	bnez	a5,80001d16 <growproc+0x26>
      return -1;
    80001d48:	557d                	li	a0,-1
    80001d4a:	bfd9                	j	80001d20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4c:	00f4863b          	addw	a2,s1,a5
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	1582                	slli	a1,a1,0x20
    80001d56:	9181                	srli	a1,a1,0x20
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	664080e7          	jalr	1636(ra) # 800013be <uvmdealloc>
    80001d62:	0005079b          	sext.w	a5,a0
    80001d66:	bf45                	j	80001d16 <growproc+0x26>

0000000080001d68 <fork>:
{
    80001d68:	7139                	addi	sp,sp,-64
    80001d6a:	fc06                	sd	ra,56(sp)
    80001d6c:	f822                	sd	s0,48(sp)
    80001d6e:	f426                	sd	s1,40(sp)
    80001d70:	f04a                	sd	s2,32(sp)
    80001d72:	ec4e                	sd	s3,24(sp)
    80001d74:	e852                	sd	s4,16(sp)
    80001d76:	e456                	sd	s5,8(sp)
    80001d78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	c1c080e7          	jalr	-996(ra) # 80001996 <myproc>
    80001d82:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	e1c080e7          	jalr	-484(ra) # 80001ba0 <allocproc>
    80001d8c:	10050c63          	beqz	a0,80001ea4 <fork+0x13c>
    80001d90:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d92:	048ab603          	ld	a2,72(s5)
    80001d96:	692c                	ld	a1,80(a0)
    80001d98:	050ab503          	ld	a0,80(s5)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	7ba080e7          	jalr	1978(ra) # 80001556 <uvmcopy>
    80001da4:	04054863          	bltz	a0,80001df4 <fork+0x8c>
  np->sz = p->sz;
    80001da8:	048ab783          	ld	a5,72(s5)
    80001dac:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db0:	058ab683          	ld	a3,88(s5)
    80001db4:	87b6                	mv	a5,a3
    80001db6:	058a3703          	ld	a4,88(s4)
    80001dba:	12068693          	addi	a3,a3,288
    80001dbe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc2:	6788                	ld	a0,8(a5)
    80001dc4:	6b8c                	ld	a1,16(a5)
    80001dc6:	6f90                	ld	a2,24(a5)
    80001dc8:	01073023          	sd	a6,0(a4)
    80001dcc:	e708                	sd	a0,8(a4)
    80001dce:	eb0c                	sd	a1,16(a4)
    80001dd0:	ef10                	sd	a2,24(a4)
    80001dd2:	02078793          	addi	a5,a5,32
    80001dd6:	02070713          	addi	a4,a4,32
    80001dda:	fed792e3          	bne	a5,a3,80001dbe <fork+0x56>
  np->trapframe->a0 = 0;
    80001dde:	058a3783          	ld	a5,88(s4)
    80001de2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de6:	0d0a8493          	addi	s1,s5,208
    80001dea:	0d0a0913          	addi	s2,s4,208
    80001dee:	150a8993          	addi	s3,s5,336
    80001df2:	a00d                	j	80001e14 <fork+0xac>
    freeproc(np);
    80001df4:	8552                	mv	a0,s4
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	d52080e7          	jalr	-686(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001dfe:	8552                	mv	a0,s4
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	e84080e7          	jalr	-380(ra) # 80000c84 <release>
    return -1;
    80001e08:	597d                	li	s2,-1
    80001e0a:	a059                	j	80001e90 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e0c:	04a1                	addi	s1,s1,8
    80001e0e:	0921                	addi	s2,s2,8
    80001e10:	01348b63          	beq	s1,s3,80001e26 <fork+0xbe>
    if(p->ofile[i])
    80001e14:	6088                	ld	a0,0(s1)
    80001e16:	d97d                	beqz	a0,80001e0c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e18:	00002097          	auipc	ra,0x2
    80001e1c:	774080e7          	jalr	1908(ra) # 8000458c <filedup>
    80001e20:	00a93023          	sd	a0,0(s2)
    80001e24:	b7e5                	j	80001e0c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e26:	150ab503          	ld	a0,336(s5)
    80001e2a:	00002097          	auipc	ra,0x2
    80001e2e:	8d2080e7          	jalr	-1838(ra) # 800036fc <idup>
    80001e32:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e36:	4641                	li	a2,16
    80001e38:	158a8593          	addi	a1,s5,344
    80001e3c:	158a0513          	addi	a0,s4,344
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	fd6080e7          	jalr	-42(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e48:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e36080e7          	jalr	-458(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e56:	0000f497          	auipc	s1,0xf
    80001e5a:	46248493          	addi	s1,s1,1122 # 800112b8 <wait_lock>
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	d70080e7          	jalr	-656(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e68:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e16080e7          	jalr	-490(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d58080e7          	jalr	-680(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e80:	478d                	li	a5,3
    80001e82:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e86:	8552                	mv	a0,s4
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	dfc080e7          	jalr	-516(ra) # 80000c84 <release>
}
    80001e90:	854a                	mv	a0,s2
    80001e92:	70e2                	ld	ra,56(sp)
    80001e94:	7442                	ld	s0,48(sp)
    80001e96:	74a2                	ld	s1,40(sp)
    80001e98:	7902                	ld	s2,32(sp)
    80001e9a:	69e2                	ld	s3,24(sp)
    80001e9c:	6a42                	ld	s4,16(sp)
    80001e9e:	6aa2                	ld	s5,8(sp)
    80001ea0:	6121                	addi	sp,sp,64
    80001ea2:	8082                	ret
    return -1;
    80001ea4:	597d                	li	s2,-1
    80001ea6:	b7ed                	j	80001e90 <fork+0x128>

0000000080001ea8 <scheduler>:
{
    80001ea8:	7139                	addi	sp,sp,-64
    80001eaa:	fc06                	sd	ra,56(sp)
    80001eac:	f822                	sd	s0,48(sp)
    80001eae:	f426                	sd	s1,40(sp)
    80001eb0:	f04a                	sd	s2,32(sp)
    80001eb2:	ec4e                	sd	s3,24(sp)
    80001eb4:	e852                	sd	s4,16(sp)
    80001eb6:	e456                	sd	s5,8(sp)
    80001eb8:	e05a                	sd	s6,0(sp)
    80001eba:	0080                	addi	s0,sp,64
    80001ebc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ebe:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec0:	00779a93          	slli	s5,a5,0x7
    80001ec4:	0000f717          	auipc	a4,0xf
    80001ec8:	3dc70713          	addi	a4,a4,988 # 800112a0 <pid_lock>
    80001ecc:	9756                	add	a4,a4,s5
    80001ece:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed2:	0000f717          	auipc	a4,0xf
    80001ed6:	40670713          	addi	a4,a4,1030 # 800112d8 <cpus+0x8>
    80001eda:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001edc:	498d                	li	s3,3
        p->state = RUNNING;
    80001ede:	4b11                	li	s6,4
        c->proc = p;
    80001ee0:	079e                	slli	a5,a5,0x7
    80001ee2:	0000fa17          	auipc	s4,0xf
    80001ee6:	3bea0a13          	addi	s4,s4,958 # 800112a0 <pid_lock>
    80001eea:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eec:	00015917          	auipc	s2,0x15
    80001ef0:	1e490913          	addi	s2,s2,484 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001efc:	10079073          	csrw	sstatus,a5
    80001f00:	0000f497          	auipc	s1,0xf
    80001f04:	7d048493          	addi	s1,s1,2000 # 800116d0 <proc>
    80001f08:	a811                	j	80001f1c <scheduler+0x74>
      release(&p->lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d78080e7          	jalr	-648(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f14:	16848493          	addi	s1,s1,360
    80001f18:	fd248ee3          	beq	s1,s2,80001ef4 <scheduler+0x4c>
      acquire(&p->lock);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	cb2080e7          	jalr	-846(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f26:	4c9c                	lw	a5,24(s1)
    80001f28:	ff3791e3          	bne	a5,s3,80001f0a <scheduler+0x62>
        p->state = RUNNING;
    80001f2c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f30:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f34:	06048593          	addi	a1,s1,96
    80001f38:	8556                	mv	a0,s5
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	784080e7          	jalr	1924(ra) # 800026be <swtch>
        c->proc = 0;
    80001f42:	020a3823          	sd	zero,48(s4)
    80001f46:	b7d1                	j	80001f0a <scheduler+0x62>

0000000080001f48 <sched>:
{
    80001f48:	7179                	addi	sp,sp,-48
    80001f4a:	f406                	sd	ra,40(sp)
    80001f4c:	f022                	sd	s0,32(sp)
    80001f4e:	ec26                	sd	s1,24(sp)
    80001f50:	e84a                	sd	s2,16(sp)
    80001f52:	e44e                	sd	s3,8(sp)
    80001f54:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	a40080e7          	jalr	-1472(ra) # 80001996 <myproc>
    80001f5e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	bf6080e7          	jalr	-1034(ra) # 80000b56 <holding>
    80001f68:	c93d                	beqz	a0,80001fde <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f6a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f6c:	2781                	sext.w	a5,a5
    80001f6e:	079e                	slli	a5,a5,0x7
    80001f70:	0000f717          	auipc	a4,0xf
    80001f74:	33070713          	addi	a4,a4,816 # 800112a0 <pid_lock>
    80001f78:	97ba                	add	a5,a5,a4
    80001f7a:	0a87a703          	lw	a4,168(a5)
    80001f7e:	4785                	li	a5,1
    80001f80:	06f71763          	bne	a4,a5,80001fee <sched+0xa6>
  if(p->state == RUNNING)
    80001f84:	4c98                	lw	a4,24(s1)
    80001f86:	4791                	li	a5,4
    80001f88:	06f70b63          	beq	a4,a5,80001ffe <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f90:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f92:	efb5                	bnez	a5,8000200e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f94:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f96:	0000f917          	auipc	s2,0xf
    80001f9a:	30a90913          	addi	s2,s2,778 # 800112a0 <pid_lock>
    80001f9e:	2781                	sext.w	a5,a5
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	97ca                	add	a5,a5,s2
    80001fa4:	0ac7a983          	lw	s3,172(a5)
    80001fa8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	0000f597          	auipc	a1,0xf
    80001fb2:	32a58593          	addi	a1,a1,810 # 800112d8 <cpus+0x8>
    80001fb6:	95be                	add	a1,a1,a5
    80001fb8:	06048513          	addi	a0,s1,96
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	702080e7          	jalr	1794(ra) # 800026be <swtch>
    80001fc4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	993e                	add	s2,s2,a5
    80001fcc:	0b392623          	sw	s3,172(s2)
}
    80001fd0:	70a2                	ld	ra,40(sp)
    80001fd2:	7402                	ld	s0,32(sp)
    80001fd4:	64e2                	ld	s1,24(sp)
    80001fd6:	6942                	ld	s2,16(sp)
    80001fd8:	69a2                	ld	s3,8(sp)
    80001fda:	6145                	addi	sp,sp,48
    80001fdc:	8082                	ret
    panic("sched p->lock");
    80001fde:	00006517          	auipc	a0,0x6
    80001fe2:	23a50513          	addi	a0,a0,570 # 80008218 <digits+0x1d8>
    80001fe6:	ffffe097          	auipc	ra,0xffffe
    80001fea:	554080e7          	jalr	1364(ra) # 8000053a <panic>
    panic("sched locks");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	23a50513          	addi	a0,a0,570 # 80008228 <digits+0x1e8>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	544080e7          	jalr	1348(ra) # 8000053a <panic>
    panic("sched running");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	23a50513          	addi	a0,a0,570 # 80008238 <digits+0x1f8>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	534080e7          	jalr	1332(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	23a50513          	addi	a0,a0,570 # 80008248 <digits+0x208>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	524080e7          	jalr	1316(ra) # 8000053a <panic>

000000008000201e <yield>:
{
    8000201e:	1101                	addi	sp,sp,-32
    80002020:	ec06                	sd	ra,24(sp)
    80002022:	e822                	sd	s0,16(sp)
    80002024:	e426                	sd	s1,8(sp)
    80002026:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	96e080e7          	jalr	-1682(ra) # 80001996 <myproc>
    80002030:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	b9e080e7          	jalr	-1122(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    8000203a:	478d                	li	a5,3
    8000203c:	cc9c                	sw	a5,24(s1)
  sched();
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	f0a080e7          	jalr	-246(ra) # 80001f48 <sched>
  release(&p->lock);
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	c3c080e7          	jalr	-964(ra) # 80000c84 <release>
}
    80002050:	60e2                	ld	ra,24(sp)
    80002052:	6442                	ld	s0,16(sp)
    80002054:	64a2                	ld	s1,8(sp)
    80002056:	6105                	addi	sp,sp,32
    80002058:	8082                	ret

000000008000205a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000205a:	7179                	addi	sp,sp,-48
    8000205c:	f406                	sd	ra,40(sp)
    8000205e:	f022                	sd	s0,32(sp)
    80002060:	ec26                	sd	s1,24(sp)
    80002062:	e84a                	sd	s2,16(sp)
    80002064:	e44e                	sd	s3,8(sp)
    80002066:	1800                	addi	s0,sp,48
    80002068:	89aa                	mv	s3,a0
    8000206a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	92a080e7          	jalr	-1750(ra) # 80001996 <myproc>
    80002074:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	b5a080e7          	jalr	-1190(ra) # 80000bd0 <acquire>
  release(lk);
    8000207e:	854a                	mv	a0,s2
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	c04080e7          	jalr	-1020(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002088:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000208c:	4789                	li	a5,2
    8000208e:	cc9c                	sw	a5,24(s1)

  sched();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	eb8080e7          	jalr	-328(ra) # 80001f48 <sched>

  // Tidy up.
  p->chan = 0;
    80002098:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	be6080e7          	jalr	-1050(ra) # 80000c84 <release>
  acquire(lk);
    800020a6:	854a                	mv	a0,s2
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b28080e7          	jalr	-1240(ra) # 80000bd0 <acquire>
}
    800020b0:	70a2                	ld	ra,40(sp)
    800020b2:	7402                	ld	s0,32(sp)
    800020b4:	64e2                	ld	s1,24(sp)
    800020b6:	6942                	ld	s2,16(sp)
    800020b8:	69a2                	ld	s3,8(sp)
    800020ba:	6145                	addi	sp,sp,48
    800020bc:	8082                	ret

00000000800020be <wait>:
{
    800020be:	715d                	addi	sp,sp,-80
    800020c0:	e486                	sd	ra,72(sp)
    800020c2:	e0a2                	sd	s0,64(sp)
    800020c4:	fc26                	sd	s1,56(sp)
    800020c6:	f84a                	sd	s2,48(sp)
    800020c8:	f44e                	sd	s3,40(sp)
    800020ca:	f052                	sd	s4,32(sp)
    800020cc:	ec56                	sd	s5,24(sp)
    800020ce:	e85a                	sd	s6,16(sp)
    800020d0:	e45e                	sd	s7,8(sp)
    800020d2:	e062                	sd	s8,0(sp)
    800020d4:	0880                	addi	s0,sp,80
    800020d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	8be080e7          	jalr	-1858(ra) # 80001996 <myproc>
    800020e0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020e2:	0000f517          	auipc	a0,0xf
    800020e6:	1d650513          	addi	a0,a0,470 # 800112b8 <wait_lock>
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	ae6080e7          	jalr	-1306(ra) # 80000bd0 <acquire>
    havekids = 0;
    800020f2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020f4:	4a15                	li	s4,5
        havekids = 1;
    800020f6:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020f8:	00015997          	auipc	s3,0x15
    800020fc:	fd898993          	addi	s3,s3,-40 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002100:	0000fc17          	auipc	s8,0xf
    80002104:	1b8c0c13          	addi	s8,s8,440 # 800112b8 <wait_lock>
    havekids = 0;
    80002108:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000210a:	0000f497          	auipc	s1,0xf
    8000210e:	5c648493          	addi	s1,s1,1478 # 800116d0 <proc>
    80002112:	a0bd                	j	80002180 <wait+0xc2>
          pid = np->pid;
    80002114:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002118:	000b0e63          	beqz	s6,80002134 <wait+0x76>
    8000211c:	4691                	li	a3,4
    8000211e:	02c48613          	addi	a2,s1,44
    80002122:	85da                	mv	a1,s6
    80002124:	05093503          	ld	a0,80(s2)
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	532080e7          	jalr	1330(ra) # 8000165a <copyout>
    80002130:	02054563          	bltz	a0,8000215a <wait+0x9c>
          freeproc(np);
    80002134:	8526                	mv	a0,s1
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	a12080e7          	jalr	-1518(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b44080e7          	jalr	-1212(ra) # 80000c84 <release>
          release(&wait_lock);
    80002148:	0000f517          	auipc	a0,0xf
    8000214c:	17050513          	addi	a0,a0,368 # 800112b8 <wait_lock>
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b34080e7          	jalr	-1228(ra) # 80000c84 <release>
          return pid;
    80002158:	a09d                	j	800021be <wait+0x100>
            release(&np->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b28080e7          	jalr	-1240(ra) # 80000c84 <release>
            release(&wait_lock);
    80002164:	0000f517          	auipc	a0,0xf
    80002168:	15450513          	addi	a0,a0,340 # 800112b8 <wait_lock>
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b18080e7          	jalr	-1256(ra) # 80000c84 <release>
            return -1;
    80002174:	59fd                	li	s3,-1
    80002176:	a0a1                	j	800021be <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002178:	16848493          	addi	s1,s1,360
    8000217c:	03348463          	beq	s1,s3,800021a4 <wait+0xe6>
      if(np->parent == p){
    80002180:	7c9c                	ld	a5,56(s1)
    80002182:	ff279be3          	bne	a5,s2,80002178 <wait+0xba>
        acquire(&np->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a48080e7          	jalr	-1464(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002190:	4c9c                	lw	a5,24(s1)
    80002192:	f94781e3          	beq	a5,s4,80002114 <wait+0x56>
        release(&np->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	aec080e7          	jalr	-1300(ra) # 80000c84 <release>
        havekids = 1;
    800021a0:	8756                	mv	a4,s5
    800021a2:	bfd9                	j	80002178 <wait+0xba>
    if(!havekids || p->killed){
    800021a4:	c701                	beqz	a4,800021ac <wait+0xee>
    800021a6:	02892783          	lw	a5,40(s2)
    800021aa:	c79d                	beqz	a5,800021d8 <wait+0x11a>
      release(&wait_lock);
    800021ac:	0000f517          	auipc	a0,0xf
    800021b0:	10c50513          	addi	a0,a0,268 # 800112b8 <wait_lock>
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	ad0080e7          	jalr	-1328(ra) # 80000c84 <release>
      return -1;
    800021bc:	59fd                	li	s3,-1
}
    800021be:	854e                	mv	a0,s3
    800021c0:	60a6                	ld	ra,72(sp)
    800021c2:	6406                	ld	s0,64(sp)
    800021c4:	74e2                	ld	s1,56(sp)
    800021c6:	7942                	ld	s2,48(sp)
    800021c8:	79a2                	ld	s3,40(sp)
    800021ca:	7a02                	ld	s4,32(sp)
    800021cc:	6ae2                	ld	s5,24(sp)
    800021ce:	6b42                	ld	s6,16(sp)
    800021d0:	6ba2                	ld	s7,8(sp)
    800021d2:	6c02                	ld	s8,0(sp)
    800021d4:	6161                	addi	sp,sp,80
    800021d6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d8:	85e2                	mv	a1,s8
    800021da:	854a                	mv	a0,s2
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	e7e080e7          	jalr	-386(ra) # 8000205a <sleep>
    havekids = 0;
    800021e4:	b715                	j	80002108 <wait+0x4a>

00000000800021e6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e6:	7139                	addi	sp,sp,-64
    800021e8:	fc06                	sd	ra,56(sp)
    800021ea:	f822                	sd	s0,48(sp)
    800021ec:	f426                	sd	s1,40(sp)
    800021ee:	f04a                	sd	s2,32(sp)
    800021f0:	ec4e                	sd	s3,24(sp)
    800021f2:	e852                	sd	s4,16(sp)
    800021f4:	e456                	sd	s5,8(sp)
    800021f6:	0080                	addi	s0,sp,64
    800021f8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021fa:	0000f497          	auipc	s1,0xf
    800021fe:	4d648493          	addi	s1,s1,1238 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002202:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002204:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	00015917          	auipc	s2,0x15
    8000220a:	eca90913          	addi	s2,s2,-310 # 800170d0 <tickslock>
    8000220e:	a811                	j	80002222 <wakeup+0x3c>
      }
      release(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a72080e7          	jalr	-1422(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000221a:	16848493          	addi	s1,s1,360
    8000221e:	03248663          	beq	s1,s2,8000224a <wakeup+0x64>
    if(p != myproc()){
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	774080e7          	jalr	1908(ra) # 80001996 <myproc>
    8000222a:	fea488e3          	beq	s1,a0,8000221a <wakeup+0x34>
      acquire(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	9a0080e7          	jalr	-1632(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002238:	4c9c                	lw	a5,24(s1)
    8000223a:	fd379be3          	bne	a5,s3,80002210 <wakeup+0x2a>
    8000223e:	709c                	ld	a5,32(s1)
    80002240:	fd4798e3          	bne	a5,s4,80002210 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002244:	0154ac23          	sw	s5,24(s1)
    80002248:	b7e1                	j	80002210 <wakeup+0x2a>
    }
  }
}
    8000224a:	70e2                	ld	ra,56(sp)
    8000224c:	7442                	ld	s0,48(sp)
    8000224e:	74a2                	ld	s1,40(sp)
    80002250:	7902                	ld	s2,32(sp)
    80002252:	69e2                	ld	s3,24(sp)
    80002254:	6a42                	ld	s4,16(sp)
    80002256:	6aa2                	ld	s5,8(sp)
    80002258:	6121                	addi	sp,sp,64
    8000225a:	8082                	ret

000000008000225c <reparent>:
{
    8000225c:	7179                	addi	sp,sp,-48
    8000225e:	f406                	sd	ra,40(sp)
    80002260:	f022                	sd	s0,32(sp)
    80002262:	ec26                	sd	s1,24(sp)
    80002264:	e84a                	sd	s2,16(sp)
    80002266:	e44e                	sd	s3,8(sp)
    80002268:	e052                	sd	s4,0(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	46248493          	addi	s1,s1,1122 # 800116d0 <proc>
      pp->parent = initproc;
    80002276:	00007a17          	auipc	s4,0x7
    8000227a:	db2a0a13          	addi	s4,s4,-590 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227e:	00015997          	auipc	s3,0x15
    80002282:	e5298993          	addi	s3,s3,-430 # 800170d0 <tickslock>
    80002286:	a029                	j	80002290 <reparent+0x34>
    80002288:	16848493          	addi	s1,s1,360
    8000228c:	01348d63          	beq	s1,s3,800022a6 <reparent+0x4a>
    if(pp->parent == p){
    80002290:	7c9c                	ld	a5,56(s1)
    80002292:	ff279be3          	bne	a5,s2,80002288 <reparent+0x2c>
      pp->parent = initproc;
    80002296:	000a3503          	ld	a0,0(s4)
    8000229a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	f4a080e7          	jalr	-182(ra) # 800021e6 <wakeup>
    800022a4:	b7d5                	j	80002288 <reparent+0x2c>
}
    800022a6:	70a2                	ld	ra,40(sp)
    800022a8:	7402                	ld	s0,32(sp)
    800022aa:	64e2                	ld	s1,24(sp)
    800022ac:	6942                	ld	s2,16(sp)
    800022ae:	69a2                	ld	s3,8(sp)
    800022b0:	6a02                	ld	s4,0(sp)
    800022b2:	6145                	addi	sp,sp,48
    800022b4:	8082                	ret

00000000800022b6 <exit>:
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	e052                	sd	s4,0(sp)
    800022c4:	1800                	addi	s0,sp,48
    800022c6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	6ce080e7          	jalr	1742(ra) # 80001996 <myproc>
    800022d0:	89aa                	mv	s3,a0
  if(p == initproc)
    800022d2:	00007797          	auipc	a5,0x7
    800022d6:	d567b783          	ld	a5,-682(a5) # 80009028 <initproc>
    800022da:	0d050493          	addi	s1,a0,208
    800022de:	15050913          	addi	s2,a0,336
    800022e2:	02a79363          	bne	a5,a0,80002308 <exit+0x52>
    panic("init exiting");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f7a50513          	addi	a0,a0,-134 # 80008260 <digits+0x220>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	24c080e7          	jalr	588(ra) # 8000053a <panic>
      fileclose(f);
    800022f6:	00002097          	auipc	ra,0x2
    800022fa:	2e8080e7          	jalr	744(ra) # 800045de <fileclose>
      p->ofile[fd] = 0;
    800022fe:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002302:	04a1                	addi	s1,s1,8
    80002304:	01248563          	beq	s1,s2,8000230e <exit+0x58>
    if(p->ofile[fd]){
    80002308:	6088                	ld	a0,0(s1)
    8000230a:	f575                	bnez	a0,800022f6 <exit+0x40>
    8000230c:	bfdd                	j	80002302 <exit+0x4c>
  begin_op();
    8000230e:	00002097          	auipc	ra,0x2
    80002312:	e08080e7          	jalr	-504(ra) # 80004116 <begin_op>
  iput(p->cwd);
    80002316:	1509b503          	ld	a0,336(s3)
    8000231a:	00001097          	auipc	ra,0x1
    8000231e:	5da080e7          	jalr	1498(ra) # 800038f4 <iput>
  end_op();
    80002322:	00002097          	auipc	ra,0x2
    80002326:	e72080e7          	jalr	-398(ra) # 80004194 <end_op>
  p->cwd = 0;
    8000232a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232e:	0000f497          	auipc	s1,0xf
    80002332:	f8a48493          	addi	s1,s1,-118 # 800112b8 <wait_lock>
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	898080e7          	jalr	-1896(ra) # 80000bd0 <acquire>
  reparent(p);
    80002340:	854e                	mv	a0,s3
    80002342:	00000097          	auipc	ra,0x0
    80002346:	f1a080e7          	jalr	-230(ra) # 8000225c <reparent>
  wakeup(p->parent);
    8000234a:	0389b503          	ld	a0,56(s3)
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	e98080e7          	jalr	-360(ra) # 800021e6 <wakeup>
  acquire(&p->lock);
    80002356:	854e                	mv	a0,s3
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	878080e7          	jalr	-1928(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002360:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002364:	4795                	li	a5,5
    80002366:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	918080e7          	jalr	-1768(ra) # 80000c84 <release>
  sched();
    80002374:	00000097          	auipc	ra,0x0
    80002378:	bd4080e7          	jalr	-1068(ra) # 80001f48 <sched>
  panic("zombie exit");
    8000237c:	00006517          	auipc	a0,0x6
    80002380:	ef450513          	addi	a0,a0,-268 # 80008270 <digits+0x230>
    80002384:	ffffe097          	auipc	ra,0xffffe
    80002388:	1b6080e7          	jalr	438(ra) # 8000053a <panic>

000000008000238c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000238c:	7179                	addi	sp,sp,-48
    8000238e:	f406                	sd	ra,40(sp)
    80002390:	f022                	sd	s0,32(sp)
    80002392:	ec26                	sd	s1,24(sp)
    80002394:	e84a                	sd	s2,16(sp)
    80002396:	e44e                	sd	s3,8(sp)
    80002398:	1800                	addi	s0,sp,48
    8000239a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	33448493          	addi	s1,s1,820 # 800116d0 <proc>
    800023a4:	00015997          	auipc	s3,0x15
    800023a8:	d2c98993          	addi	s3,s3,-724 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	822080e7          	jalr	-2014(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023b6:	589c                	lw	a5,48(s1)
    800023b8:	01278d63          	beq	a5,s2,800023d2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8c6080e7          	jalr	-1850(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c6:	16848493          	addi	s1,s1,360
    800023ca:	ff3491e3          	bne	s1,s3,800023ac <kill+0x20>
  }
  return -1;
    800023ce:	557d                	li	a0,-1
    800023d0:	a829                	j	800023ea <kill+0x5e>
      p->killed = 1;
    800023d2:	4785                	li	a5,1
    800023d4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d6:	4c98                	lw	a4,24(s1)
    800023d8:	4789                	li	a5,2
    800023da:	00f70f63          	beq	a4,a5,800023f8 <kill+0x6c>
      release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8a4080e7          	jalr	-1884(ra) # 80000c84 <release>
      return 0;
    800023e8:	4501                	li	a0,0
}
    800023ea:	70a2                	ld	ra,40(sp)
    800023ec:	7402                	ld	s0,32(sp)
    800023ee:	64e2                	ld	s1,24(sp)
    800023f0:	6942                	ld	s2,16(sp)
    800023f2:	69a2                	ld	s3,8(sp)
    800023f4:	6145                	addi	sp,sp,48
    800023f6:	8082                	ret
        p->state = RUNNABLE;
    800023f8:	478d                	li	a5,3
    800023fa:	cc9c                	sw	a5,24(s1)
    800023fc:	b7cd                	j	800023de <kill+0x52>

00000000800023fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
    8000240e:	84aa                	mv	s1,a0
    80002410:	892e                	mv	s2,a1
    80002412:	89b2                	mv	s3,a2
    80002414:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	580080e7          	jalr	1408(ra) # 80001996 <myproc>
  if(user_dst){
    8000241e:	c08d                	beqz	s1,80002440 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002420:	86d2                	mv	a3,s4
    80002422:	864e                	mv	a2,s3
    80002424:	85ca                	mv	a1,s2
    80002426:	6928                	ld	a0,80(a0)
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	232080e7          	jalr	562(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002430:	70a2                	ld	ra,40(sp)
    80002432:	7402                	ld	s0,32(sp)
    80002434:	64e2                	ld	s1,24(sp)
    80002436:	6942                	ld	s2,16(sp)
    80002438:	69a2                	ld	s3,8(sp)
    8000243a:	6a02                	ld	s4,0(sp)
    8000243c:	6145                	addi	sp,sp,48
    8000243e:	8082                	ret
    memmove((char *)dst, src, len);
    80002440:	000a061b          	sext.w	a2,s4
    80002444:	85ce                	mv	a1,s3
    80002446:	854a                	mv	a0,s2
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	8e0080e7          	jalr	-1824(ra) # 80000d28 <memmove>
    return 0;
    80002450:	8526                	mv	a0,s1
    80002452:	bff9                	j	80002430 <either_copyout+0x32>

0000000080002454 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	892a                	mv	s2,a0
    80002466:	84ae                	mv	s1,a1
    80002468:	89b2                	mv	s3,a2
    8000246a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	52a080e7          	jalr	1322(ra) # 80001996 <myproc>
  if(user_src){
    80002474:	c08d                	beqz	s1,80002496 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002476:	86d2                	mv	a3,s4
    80002478:	864e                	mv	a2,s3
    8000247a:	85ca                	mv	a1,s2
    8000247c:	6928                	ld	a0,80(a0)
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	268080e7          	jalr	616(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6a02                	ld	s4,0(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
    memmove(dst, (char*)src, len);
    80002496:	000a061b          	sext.w	a2,s4
    8000249a:	85ce                	mv	a1,s3
    8000249c:	854a                	mv	a0,s2
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	88a080e7          	jalr	-1910(ra) # 80000d28 <memmove>
    return 0;
    800024a6:	8526                	mv	a0,s1
    800024a8:	bff9                	j	80002486 <either_copyin+0x32>

00000000800024aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024aa:	715d                	addi	sp,sp,-80
    800024ac:	e486                	sd	ra,72(sp)
    800024ae:	e0a2                	sd	s0,64(sp)
    800024b0:	fc26                	sd	s1,56(sp)
    800024b2:	f84a                	sd	s2,48(sp)
    800024b4:	f44e                	sd	s3,40(sp)
    800024b6:	f052                	sd	s4,32(sp)
    800024b8:	ec56                	sd	s5,24(sp)
    800024ba:	e85a                	sd	s6,16(sp)
    800024bc:	e45e                	sd	s7,8(sp)
    800024be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	c0850513          	addi	a0,a0,-1016 # 800080c8 <digits+0x88>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	0bc080e7          	jalr	188(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d0:	0000f497          	auipc	s1,0xf
    800024d4:	35848493          	addi	s1,s1,856 # 80011828 <proc+0x158>
    800024d8:	00015917          	auipc	s2,0x15
    800024dc:	d5090913          	addi	s2,s2,-688 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024e0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024e2:	00006997          	auipc	s3,0x6
    800024e6:	d9e98993          	addi	s3,s3,-610 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024ea:	00006a97          	auipc	s5,0x6
    800024ee:	d9ea8a93          	addi	s5,s5,-610 # 80008288 <digits+0x248>
    printf("\n");
    800024f2:	00006a17          	auipc	s4,0x6
    800024f6:	bd6a0a13          	addi	s4,s4,-1066 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024fa:	00006b97          	auipc	s7,0x6
    800024fe:	e16b8b93          	addi	s7,s7,-490 # 80008310 <states.1>
    80002502:	a00d                	j	80002524 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002504:	ed86a583          	lw	a1,-296(a3)
    80002508:	8556                	mv	a0,s5
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	07a080e7          	jalr	122(ra) # 80000584 <printf>
    printf("\n");
    80002512:	8552                	mv	a0,s4
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	070080e7          	jalr	112(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251c:	16848493          	addi	s1,s1,360
    80002520:	03248263          	beq	s1,s2,80002544 <procdump+0x9a>
    if(p->state == UNUSED)
    80002524:	86a6                	mv	a3,s1
    80002526:	ec04a783          	lw	a5,-320(s1)
    8000252a:	dbed                	beqz	a5,8000251c <procdump+0x72>
      state = "???";
    8000252c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252e:	fcfb6be3          	bltu	s6,a5,80002504 <procdump+0x5a>
    80002532:	02079713          	slli	a4,a5,0x20
    80002536:	01d75793          	srli	a5,a4,0x1d
    8000253a:	97de                	add	a5,a5,s7
    8000253c:	6390                	ld	a2,0(a5)
    8000253e:	f279                	bnez	a2,80002504 <procdump+0x5a>
      state = "???";
    80002540:	864e                	mv	a2,s3
    80002542:	b7c9                	j	80002504 <procdump+0x5a>
  }
}
    80002544:	60a6                	ld	ra,72(sp)
    80002546:	6406                	ld	s0,64(sp)
    80002548:	74e2                	ld	s1,56(sp)
    8000254a:	7942                	ld	s2,48(sp)
    8000254c:	79a2                	ld	s3,40(sp)
    8000254e:	7a02                	ld	s4,32(sp)
    80002550:	6ae2                	ld	s5,24(sp)
    80002552:	6b42                	ld	s6,16(sp)
    80002554:	6ba2                	ld	s7,8(sp)
    80002556:	6161                	addi	sp,sp,80
    80002558:	8082                	ret

000000008000255a <procinfo>:


#include "../user/uproc.h"
int
procinfo(struct uproc* uproc){
    8000255a:	715d                	addi	sp,sp,-80
    8000255c:	e486                	sd	ra,72(sp)
    8000255e:	e0a2                	sd	s0,64(sp)
    80002560:	fc26                	sd	s1,56(sp)
    80002562:	f84a                	sd	s2,48(sp)
    80002564:	f44e                	sd	s3,40(sp)
    80002566:	f052                	sd	s4,32(sp)
    80002568:	ec56                	sd	s5,24(sp)
    8000256a:	e85a                	sd	s6,16(sp)
    8000256c:	e45e                	sd	s7,8(sp)
    8000256e:	e062                	sd	s8,0(sp)
    80002570:	0880                	addi	s0,sp,80
    80002572:	8a2a                	mv	s4,a0
  struct uproc *up = uproc;
  int counter = 0;
  int pass = 0;

  //Initialization of value which will be used for pagetable in copyout
  struct proc* scproc = myproc();
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	422080e7          	jalr	1058(ra) # 80001996 <myproc>
    8000257c:	8b2a                	mv	s6,a0

  for(p = proc; p < &proc[NPROC]; p++){
    8000257e:	0000f497          	auipc	s1,0xf
    80002582:	16a48493          	addi	s1,s1,362 # 800116e8 <proc+0x18>
    80002586:	00015a97          	auipc	s5,0x15
    8000258a:	b62a8a93          	addi	s5,s5,-1182 # 800170e8 <bcache>
    //Checks if the state is unused, and does not add it to return uproc
    if(p->state == UNUSED)
    8000258e:	4911                	li	s2,4
      continue;
    //Checks if the state is useed, and adds it to the uproc array if it is.
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state]){
    80002590:	00006b97          	auipc	s7,0x6
    80002594:	d80b8b93          	addi	s7,s7,-640 # 80008310 <states.1>
    80002598:	a0bd                	j	80002606 <procinfo+0xac>
      //Temp variable to keep track of parent proc
      struct proc* parent = (p->parent);

      //Series of copy out statements which will copy out pid, state, size, ppid, and name to user space.
      if(copyout(scproc->pagetable, (uint64)&up->pid, (char*)&p->pid, sizeof(p->pid) < 0)){
        printf("PID failed\n");
    8000259a:	00006517          	auipc	a0,0x6
    8000259e:	cfe50513          	addi	a0,a0,-770 # 80008298 <digits+0x258>
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	fe2080e7          	jalr	-30(ra) # 80000584 <printf>
        return -1;
    800025aa:	557d                	li	a0,-1
    800025ac:	a8ed                	j	800026a6 <procinfo+0x14c>
      }
      if(copyout(scproc->pagetable, (uint64)&up->state, (char*)&p->state, sizeof(p->state)) < 0){
        printf("state failed\n");
    800025ae:	00006517          	auipc	a0,0x6
    800025b2:	cfa50513          	addi	a0,a0,-774 # 800082a8 <digits+0x268>
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	fce080e7          	jalr	-50(ra) # 80000584 <printf>
        return -1;
    800025be:	557d                	li	a0,-1
    800025c0:	a0dd                	j	800026a6 <procinfo+0x14c>
      }
      if (copyout(scproc->pagetable, (uint64)&up->size, (char*)&p->sz, sizeof(p->sz)) < 0){
        printf("Size failed\n");
    800025c2:	00006517          	auipc	a0,0x6
    800025c6:	cf650513          	addi	a0,a0,-778 # 800082b8 <digits+0x278>
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fba080e7          	jalr	-70(ra) # 80000584 <printf>
        return -1;
    800025d2:	557d                	li	a0,-1
    800025d4:	a8c9                	j	800026a6 <procinfo+0x14c>
      }
      if (copyout(scproc->pagetable, (uint64)&up->ppid, (char*)&parent->pid, sizeof(parent->pid)) < 0){
        printf("PPID failed\n");
    800025d6:	00006517          	auipc	a0,0x6
    800025da:	cf250513          	addi	a0,a0,-782 # 800082c8 <digits+0x288>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	fa6080e7          	jalr	-90(ra) # 80000584 <printf>
        return -1;
    800025e6:	557d                	li	a0,-1
    800025e8:	a87d                	j	800026a6 <procinfo+0x14c>
      }
      if (copyout(scproc->pagetable, (uint64)&up->name, (char*)&p->name, sizeof(p->name)) < 0){
        printf("Name failed\n");
    800025ea:	00006517          	auipc	a0,0x6
    800025ee:	cee50513          	addi	a0,a0,-786 # 800082d8 <digits+0x298>
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	f92080e7          	jalr	-110(ra) # 80000584 <printf>
        return -1;
    800025fa:	557d                	li	a0,-1
    800025fc:	a06d                	j	800026a6 <procinfo+0x14c>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fe:	16848493          	addi	s1,s1,360
    80002602:	0b548163          	beq	s1,s5,800026a4 <procinfo+0x14a>
    if(p->state == UNUSED)
    80002606:	409c                	lw	a5,0(s1)
    80002608:	fff7871b          	addiw	a4,a5,-1
    8000260c:	fee969e3          	bltu	s2,a4,800025fe <procinfo+0xa4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state]){
    80002610:	02079713          	slli	a4,a5,0x20
    80002614:	01d75793          	srli	a5,a4,0x1d
    80002618:	97de                	add	a5,a5,s7
    8000261a:	7b9c                	ld	a5,48(a5)
    8000261c:	d3ed                	beqz	a5,800025fe <procinfo+0xa4>
      struct proc* parent = (p->parent);
    8000261e:	0204bc03          	ld	s8,32(s1)
      if(copyout(scproc->pagetable, (uint64)&up->pid, (char*)&p->pid, sizeof(p->pid) < 0)){
    80002622:	4681                	li	a3,0
    80002624:	01848613          	addi	a2,s1,24
    80002628:	85d2                	mv	a1,s4
    8000262a:	050b3503          	ld	a0,80(s6)
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	02c080e7          	jalr	44(ra) # 8000165a <copyout>
    80002636:	f135                	bnez	a0,8000259a <procinfo+0x40>
      if(copyout(scproc->pagetable, (uint64)&up->state, (char*)&p->state, sizeof(p->state)) < 0){
    80002638:	86ca                	mv	a3,s2
    8000263a:	8626                	mv	a2,s1
    8000263c:	004a0593          	addi	a1,s4,4
    80002640:	050b3503          	ld	a0,80(s6)
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	016080e7          	jalr	22(ra) # 8000165a <copyout>
    8000264c:	f60541e3          	bltz	a0,800025ae <procinfo+0x54>
      if (copyout(scproc->pagetable, (uint64)&up->size, (char*)&p->sz, sizeof(p->sz)) < 0){
    80002650:	46a1                	li	a3,8
    80002652:	03048613          	addi	a2,s1,48
    80002656:	008a0593          	addi	a1,s4,8
    8000265a:	050b3503          	ld	a0,80(s6)
    8000265e:	fffff097          	auipc	ra,0xfffff
    80002662:	ffc080e7          	jalr	-4(ra) # 8000165a <copyout>
    80002666:	f4054ee3          	bltz	a0,800025c2 <procinfo+0x68>
      if (copyout(scproc->pagetable, (uint64)&up->ppid, (char*)&parent->pid, sizeof(parent->pid)) < 0){
    8000266a:	86ca                	mv	a3,s2
    8000266c:	030c0613          	addi	a2,s8,48
    80002670:	00ca0593          	addi	a1,s4,12
    80002674:	050b3503          	ld	a0,80(s6)
    80002678:	fffff097          	auipc	ra,0xfffff
    8000267c:	fe2080e7          	jalr	-30(ra) # 8000165a <copyout>
    80002680:	f4054be3          	bltz	a0,800025d6 <procinfo+0x7c>
      if (copyout(scproc->pagetable, (uint64)&up->name, (char*)&p->name, sizeof(p->name)) < 0){
    80002684:	46c1                	li	a3,16
    80002686:	14048613          	addi	a2,s1,320
    8000268a:	010a0593          	addi	a1,s4,16
    8000268e:	050b3503          	ld	a0,80(s6)
    80002692:	fffff097          	auipc	ra,0xfffff
    80002696:	fc8080e7          	jalr	-56(ra) # 8000165a <copyout>
    8000269a:	f40548e3          	bltz	a0,800025ea <procinfo+0x90>
      }
      up++;
    8000269e:	020a0a13          	addi	s4,s4,32
    800026a2:	bfb1                	j	800025fe <procinfo+0xa4>
    } 
    pass++;
  }
  return counter;
    800026a4:	4501                	li	a0,0
}
    800026a6:	60a6                	ld	ra,72(sp)
    800026a8:	6406                	ld	s0,64(sp)
    800026aa:	74e2                	ld	s1,56(sp)
    800026ac:	7942                	ld	s2,48(sp)
    800026ae:	79a2                	ld	s3,40(sp)
    800026b0:	7a02                	ld	s4,32(sp)
    800026b2:	6ae2                	ld	s5,24(sp)
    800026b4:	6b42                	ld	s6,16(sp)
    800026b6:	6ba2                	ld	s7,8(sp)
    800026b8:	6c02                	ld	s8,0(sp)
    800026ba:	6161                	addi	sp,sp,80
    800026bc:	8082                	ret

00000000800026be <swtch>:
    800026be:	00153023          	sd	ra,0(a0)
    800026c2:	00253423          	sd	sp,8(a0)
    800026c6:	e900                	sd	s0,16(a0)
    800026c8:	ed04                	sd	s1,24(a0)
    800026ca:	03253023          	sd	s2,32(a0)
    800026ce:	03353423          	sd	s3,40(a0)
    800026d2:	03453823          	sd	s4,48(a0)
    800026d6:	03553c23          	sd	s5,56(a0)
    800026da:	05653023          	sd	s6,64(a0)
    800026de:	05753423          	sd	s7,72(a0)
    800026e2:	05853823          	sd	s8,80(a0)
    800026e6:	05953c23          	sd	s9,88(a0)
    800026ea:	07a53023          	sd	s10,96(a0)
    800026ee:	07b53423          	sd	s11,104(a0)
    800026f2:	0005b083          	ld	ra,0(a1)
    800026f6:	0085b103          	ld	sp,8(a1)
    800026fa:	6980                	ld	s0,16(a1)
    800026fc:	6d84                	ld	s1,24(a1)
    800026fe:	0205b903          	ld	s2,32(a1)
    80002702:	0285b983          	ld	s3,40(a1)
    80002706:	0305ba03          	ld	s4,48(a1)
    8000270a:	0385ba83          	ld	s5,56(a1)
    8000270e:	0405bb03          	ld	s6,64(a1)
    80002712:	0485bb83          	ld	s7,72(a1)
    80002716:	0505bc03          	ld	s8,80(a1)
    8000271a:	0585bc83          	ld	s9,88(a1)
    8000271e:	0605bd03          	ld	s10,96(a1)
    80002722:	0685bd83          	ld	s11,104(a1)
    80002726:	8082                	ret

0000000080002728 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002728:	1141                	addi	sp,sp,-16
    8000272a:	e406                	sd	ra,8(sp)
    8000272c:	e022                	sd	s0,0(sp)
    8000272e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002730:	00006597          	auipc	a1,0x6
    80002734:	c4058593          	addi	a1,a1,-960 # 80008370 <states.0+0x30>
    80002738:	00015517          	auipc	a0,0x15
    8000273c:	99850513          	addi	a0,a0,-1640 # 800170d0 <tickslock>
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	400080e7          	jalr	1024(ra) # 80000b40 <initlock>
}
    80002748:	60a2                	ld	ra,8(sp)
    8000274a:	6402                	ld	s0,0(sp)
    8000274c:	0141                	addi	sp,sp,16
    8000274e:	8082                	ret

0000000080002750 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002750:	1141                	addi	sp,sp,-16
    80002752:	e422                	sd	s0,8(sp)
    80002754:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002756:	00003797          	auipc	a5,0x3
    8000275a:	4ba78793          	addi	a5,a5,1210 # 80005c10 <kernelvec>
    8000275e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002762:	6422                	ld	s0,8(sp)
    80002764:	0141                	addi	sp,sp,16
    80002766:	8082                	ret

0000000080002768 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002768:	1141                	addi	sp,sp,-16
    8000276a:	e406                	sd	ra,8(sp)
    8000276c:	e022                	sd	s0,0(sp)
    8000276e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002770:	fffff097          	auipc	ra,0xfffff
    80002774:	226080e7          	jalr	550(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002778:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000277c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002782:	00005697          	auipc	a3,0x5
    80002786:	87e68693          	addi	a3,a3,-1922 # 80007000 <_trampoline>
    8000278a:	00005717          	auipc	a4,0x5
    8000278e:	87670713          	addi	a4,a4,-1930 # 80007000 <_trampoline>
    80002792:	8f15                	sub	a4,a4,a3
    80002794:	040007b7          	lui	a5,0x4000
    80002798:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000279a:	07b2                	slli	a5,a5,0xc
    8000279c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000279e:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027a4:	18002673          	csrr	a2,satp
    800027a8:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027aa:	6d30                	ld	a2,88(a0)
    800027ac:	6138                	ld	a4,64(a0)
    800027ae:	6585                	lui	a1,0x1
    800027b0:	972e                	add	a4,a4,a1
    800027b2:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027b4:	6d38                	ld	a4,88(a0)
    800027b6:	00000617          	auipc	a2,0x0
    800027ba:	13860613          	addi	a2,a2,312 # 800028ee <usertrap>
    800027be:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027c0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027c2:	8612                	mv	a2,tp
    800027c4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027ca:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027ce:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027d6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027d8:	6f18                	ld	a4,24(a4)
    800027da:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027de:	692c                	ld	a1,80(a0)
    800027e0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027e2:	00005717          	auipc	a4,0x5
    800027e6:	8ae70713          	addi	a4,a4,-1874 # 80007090 <userret>
    800027ea:	8f15                	sub	a4,a4,a3
    800027ec:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ee:	577d                	li	a4,-1
    800027f0:	177e                	slli	a4,a4,0x3f
    800027f2:	8dd9                	or	a1,a1,a4
    800027f4:	02000537          	lui	a0,0x2000
    800027f8:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800027fa:	0536                	slli	a0,a0,0xd
    800027fc:	9782                	jalr	a5
}
    800027fe:	60a2                	ld	ra,8(sp)
    80002800:	6402                	ld	s0,0(sp)
    80002802:	0141                	addi	sp,sp,16
    80002804:	8082                	ret

0000000080002806 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002806:	1101                	addi	sp,sp,-32
    80002808:	ec06                	sd	ra,24(sp)
    8000280a:	e822                	sd	s0,16(sp)
    8000280c:	e426                	sd	s1,8(sp)
    8000280e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002810:	00015497          	auipc	s1,0x15
    80002814:	8c048493          	addi	s1,s1,-1856 # 800170d0 <tickslock>
    80002818:	8526                	mv	a0,s1
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	3b6080e7          	jalr	950(ra) # 80000bd0 <acquire>
  ticks++;
    80002822:	00007517          	auipc	a0,0x7
    80002826:	80e50513          	addi	a0,a0,-2034 # 80009030 <ticks>
    8000282a:	411c                	lw	a5,0(a0)
    8000282c:	2785                	addiw	a5,a5,1
    8000282e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002830:	00000097          	auipc	ra,0x0
    80002834:	9b6080e7          	jalr	-1610(ra) # 800021e6 <wakeup>
  release(&tickslock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	44a080e7          	jalr	1098(ra) # 80000c84 <release>
}
    80002842:	60e2                	ld	ra,24(sp)
    80002844:	6442                	ld	s0,16(sp)
    80002846:	64a2                	ld	s1,8(sp)
    80002848:	6105                	addi	sp,sp,32
    8000284a:	8082                	ret

000000008000284c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000284c:	1101                	addi	sp,sp,-32
    8000284e:	ec06                	sd	ra,24(sp)
    80002850:	e822                	sd	s0,16(sp)
    80002852:	e426                	sd	s1,8(sp)
    80002854:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002856:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000285a:	00074d63          	bltz	a4,80002874 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000285e:	57fd                	li	a5,-1
    80002860:	17fe                	slli	a5,a5,0x3f
    80002862:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002864:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002866:	06f70363          	beq	a4,a5,800028cc <devintr+0x80>
  }
}
    8000286a:	60e2                	ld	ra,24(sp)
    8000286c:	6442                	ld	s0,16(sp)
    8000286e:	64a2                	ld	s1,8(sp)
    80002870:	6105                	addi	sp,sp,32
    80002872:	8082                	ret
     (scause & 0xff) == 9){
    80002874:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002878:	46a5                	li	a3,9
    8000287a:	fed792e3          	bne	a5,a3,8000285e <devintr+0x12>
    int irq = plic_claim();
    8000287e:	00003097          	auipc	ra,0x3
    80002882:	49a080e7          	jalr	1178(ra) # 80005d18 <plic_claim>
    80002886:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002888:	47a9                	li	a5,10
    8000288a:	02f50763          	beq	a0,a5,800028b8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000288e:	4785                	li	a5,1
    80002890:	02f50963          	beq	a0,a5,800028c2 <devintr+0x76>
    return 1;
    80002894:	4505                	li	a0,1
    } else if(irq){
    80002896:	d8f1                	beqz	s1,8000286a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002898:	85a6                	mv	a1,s1
    8000289a:	00006517          	auipc	a0,0x6
    8000289e:	ade50513          	addi	a0,a0,-1314 # 80008378 <states.0+0x38>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	ce2080e7          	jalr	-798(ra) # 80000584 <printf>
      plic_complete(irq);
    800028aa:	8526                	mv	a0,s1
    800028ac:	00003097          	auipc	ra,0x3
    800028b0:	490080e7          	jalr	1168(ra) # 80005d3c <plic_complete>
    return 1;
    800028b4:	4505                	li	a0,1
    800028b6:	bf55                	j	8000286a <devintr+0x1e>
      uartintr();
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	0da080e7          	jalr	218(ra) # 80000992 <uartintr>
    800028c0:	b7ed                	j	800028aa <devintr+0x5e>
      virtio_disk_intr();
    800028c2:	00004097          	auipc	ra,0x4
    800028c6:	906080e7          	jalr	-1786(ra) # 800061c8 <virtio_disk_intr>
    800028ca:	b7c5                	j	800028aa <devintr+0x5e>
    if(cpuid() == 0){
    800028cc:	fffff097          	auipc	ra,0xfffff
    800028d0:	09e080e7          	jalr	158(ra) # 8000196a <cpuid>
    800028d4:	c901                	beqz	a0,800028e4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028d6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028da:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028dc:	14479073          	csrw	sip,a5
    return 2;
    800028e0:	4509                	li	a0,2
    800028e2:	b761                	j	8000286a <devintr+0x1e>
      clockintr();
    800028e4:	00000097          	auipc	ra,0x0
    800028e8:	f22080e7          	jalr	-222(ra) # 80002806 <clockintr>
    800028ec:	b7ed                	j	800028d6 <devintr+0x8a>

00000000800028ee <usertrap>:
{
    800028ee:	1101                	addi	sp,sp,-32
    800028f0:	ec06                	sd	ra,24(sp)
    800028f2:	e822                	sd	s0,16(sp)
    800028f4:	e426                	sd	s1,8(sp)
    800028f6:	e04a                	sd	s2,0(sp)
    800028f8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fa:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028fe:	1007f793          	andi	a5,a5,256
    80002902:	e3ad                	bnez	a5,80002964 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002904:	00003797          	auipc	a5,0x3
    80002908:	30c78793          	addi	a5,a5,780 # 80005c10 <kernelvec>
    8000290c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002910:	fffff097          	auipc	ra,0xfffff
    80002914:	086080e7          	jalr	134(ra) # 80001996 <myproc>
    80002918:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000291a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000291c:	14102773          	csrr	a4,sepc
    80002920:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002922:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002926:	47a1                	li	a5,8
    80002928:	04f71c63          	bne	a4,a5,80002980 <usertrap+0x92>
    if(p->killed)
    8000292c:	551c                	lw	a5,40(a0)
    8000292e:	e3b9                	bnez	a5,80002974 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002930:	6cb8                	ld	a4,88(s1)
    80002932:	6f1c                	ld	a5,24(a4)
    80002934:	0791                	addi	a5,a5,4
    80002936:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002938:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000293c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002940:	10079073          	csrw	sstatus,a5
    syscall();
    80002944:	00000097          	auipc	ra,0x0
    80002948:	2e0080e7          	jalr	736(ra) # 80002c24 <syscall>
  if(p->killed)
    8000294c:	549c                	lw	a5,40(s1)
    8000294e:	ebc1                	bnez	a5,800029de <usertrap+0xf0>
  usertrapret();
    80002950:	00000097          	auipc	ra,0x0
    80002954:	e18080e7          	jalr	-488(ra) # 80002768 <usertrapret>
}
    80002958:	60e2                	ld	ra,24(sp)
    8000295a:	6442                	ld	s0,16(sp)
    8000295c:	64a2                	ld	s1,8(sp)
    8000295e:	6902                	ld	s2,0(sp)
    80002960:	6105                	addi	sp,sp,32
    80002962:	8082                	ret
    panic("usertrap: not from user mode");
    80002964:	00006517          	auipc	a0,0x6
    80002968:	a3450513          	addi	a0,a0,-1484 # 80008398 <states.0+0x58>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	bce080e7          	jalr	-1074(ra) # 8000053a <panic>
      exit(-1);
    80002974:	557d                	li	a0,-1
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	940080e7          	jalr	-1728(ra) # 800022b6 <exit>
    8000297e:	bf4d                	j	80002930 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002980:	00000097          	auipc	ra,0x0
    80002984:	ecc080e7          	jalr	-308(ra) # 8000284c <devintr>
    80002988:	892a                	mv	s2,a0
    8000298a:	c501                	beqz	a0,80002992 <usertrap+0xa4>
  if(p->killed)
    8000298c:	549c                	lw	a5,40(s1)
    8000298e:	c3a1                	beqz	a5,800029ce <usertrap+0xe0>
    80002990:	a815                	j	800029c4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002992:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002996:	5890                	lw	a2,48(s1)
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	a2050513          	addi	a0,a0,-1504 # 800083b8 <states.0+0x78>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	be4080e7          	jalr	-1052(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ac:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b0:	00006517          	auipc	a0,0x6
    800029b4:	a3850513          	addi	a0,a0,-1480 # 800083e8 <states.0+0xa8>
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	bcc080e7          	jalr	-1076(ra) # 80000584 <printf>
    p->killed = 1;
    800029c0:	4785                	li	a5,1
    800029c2:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029c4:	557d                	li	a0,-1
    800029c6:	00000097          	auipc	ra,0x0
    800029ca:	8f0080e7          	jalr	-1808(ra) # 800022b6 <exit>
  if(which_dev == 2)
    800029ce:	4789                	li	a5,2
    800029d0:	f8f910e3          	bne	s2,a5,80002950 <usertrap+0x62>
    yield();
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	64a080e7          	jalr	1610(ra) # 8000201e <yield>
    800029dc:	bf95                	j	80002950 <usertrap+0x62>
  int which_dev = 0;
    800029de:	4901                	li	s2,0
    800029e0:	b7d5                	j	800029c4 <usertrap+0xd6>

00000000800029e2 <kerneltrap>:
{
    800029e2:	7179                	addi	sp,sp,-48
    800029e4:	f406                	sd	ra,40(sp)
    800029e6:	f022                	sd	s0,32(sp)
    800029e8:	ec26                	sd	s1,24(sp)
    800029ea:	e84a                	sd	s2,16(sp)
    800029ec:	e44e                	sd	s3,8(sp)
    800029ee:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029fc:	1004f793          	andi	a5,s1,256
    80002a00:	cb85                	beqz	a5,80002a30 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a06:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a08:	ef85                	bnez	a5,80002a40 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	e42080e7          	jalr	-446(ra) # 8000284c <devintr>
    80002a12:	cd1d                	beqz	a0,80002a50 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a14:	4789                	li	a5,2
    80002a16:	06f50a63          	beq	a0,a5,80002a8a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1e:	10049073          	csrw	sstatus,s1
}
    80002a22:	70a2                	ld	ra,40(sp)
    80002a24:	7402                	ld	s0,32(sp)
    80002a26:	64e2                	ld	s1,24(sp)
    80002a28:	6942                	ld	s2,16(sp)
    80002a2a:	69a2                	ld	s3,8(sp)
    80002a2c:	6145                	addi	sp,sp,48
    80002a2e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	9d850513          	addi	a0,a0,-1576 # 80008408 <states.0+0xc8>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b02080e7          	jalr	-1278(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	9f050513          	addi	a0,a0,-1552 # 80008430 <states.0+0xf0>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	af2080e7          	jalr	-1294(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002a50:	85ce                	mv	a1,s3
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	9fe50513          	addi	a0,a0,-1538 # 80008450 <states.0+0x110>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b2a080e7          	jalr	-1238(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a66:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	9f650513          	addi	a0,a0,-1546 # 80008460 <states.0+0x120>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b12080e7          	jalr	-1262(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	9fe50513          	addi	a0,a0,-1538 # 80008478 <states.0+0x138>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	ab8080e7          	jalr	-1352(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	f0c080e7          	jalr	-244(ra) # 80001996 <myproc>
    80002a92:	d541                	beqz	a0,80002a1a <kerneltrap+0x38>
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	f02080e7          	jalr	-254(ra) # 80001996 <myproc>
    80002a9c:	4d18                	lw	a4,24(a0)
    80002a9e:	4791                	li	a5,4
    80002aa0:	f6f71de3          	bne	a4,a5,80002a1a <kerneltrap+0x38>
    yield();
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	57a080e7          	jalr	1402(ra) # 8000201e <yield>
    80002aac:	b7bd                	j	80002a1a <kerneltrap+0x38>

0000000080002aae <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	1000                	addi	s0,sp,32
    80002ab8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	edc080e7          	jalr	-292(ra) # 80001996 <myproc>
  switch (n) {
    80002ac2:	4795                	li	a5,5
    80002ac4:	0497e163          	bltu	a5,s1,80002b06 <argraw+0x58>
    80002ac8:	048a                	slli	s1,s1,0x2
    80002aca:	00006717          	auipc	a4,0x6
    80002ace:	9e670713          	addi	a4,a4,-1562 # 800084b0 <states.0+0x170>
    80002ad2:	94ba                	add	s1,s1,a4
    80002ad4:	409c                	lw	a5,0(s1)
    80002ad6:	97ba                	add	a5,a5,a4
    80002ad8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ada:	6d3c                	ld	a5,88(a0)
    80002adc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret
    return p->trapframe->a1;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	7fa8                	ld	a0,120(a5)
    80002aec:	bfcd                	j	80002ade <argraw+0x30>
    return p->trapframe->a2;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	63c8                	ld	a0,128(a5)
    80002af2:	b7f5                	j	80002ade <argraw+0x30>
    return p->trapframe->a3;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	67c8                	ld	a0,136(a5)
    80002af8:	b7dd                	j	80002ade <argraw+0x30>
    return p->trapframe->a4;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	6bc8                	ld	a0,144(a5)
    80002afe:	b7c5                	j	80002ade <argraw+0x30>
    return p->trapframe->a5;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6fc8                	ld	a0,152(a5)
    80002b04:	bfe9                	j	80002ade <argraw+0x30>
  panic("argraw");
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	98250513          	addi	a0,a0,-1662 # 80008488 <states.0+0x148>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a2c080e7          	jalr	-1492(ra) # 8000053a <panic>

0000000080002b16 <fetchaddr>:
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	e04a                	sd	s2,0(sp)
    80002b20:	1000                	addi	s0,sp,32
    80002b22:	84aa                	mv	s1,a0
    80002b24:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	e70080e7          	jalr	-400(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b2e:	653c                	ld	a5,72(a0)
    80002b30:	02f4f863          	bgeu	s1,a5,80002b60 <fetchaddr+0x4a>
    80002b34:	00848713          	addi	a4,s1,8
    80002b38:	02e7e663          	bltu	a5,a4,80002b64 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b3c:	46a1                	li	a3,8
    80002b3e:	8626                	mv	a2,s1
    80002b40:	85ca                	mv	a1,s2
    80002b42:	6928                	ld	a0,80(a0)
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	ba2080e7          	jalr	-1118(ra) # 800016e6 <copyin>
    80002b4c:	00a03533          	snez	a0,a0
    80002b50:	40a00533          	neg	a0,a0
}
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6902                	ld	s2,0(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret
    return -1;
    80002b60:	557d                	li	a0,-1
    80002b62:	bfcd                	j	80002b54 <fetchaddr+0x3e>
    80002b64:	557d                	li	a0,-1
    80002b66:	b7fd                	j	80002b54 <fetchaddr+0x3e>

0000000080002b68 <fetchstr>:
{
    80002b68:	7179                	addi	sp,sp,-48
    80002b6a:	f406                	sd	ra,40(sp)
    80002b6c:	f022                	sd	s0,32(sp)
    80002b6e:	ec26                	sd	s1,24(sp)
    80002b70:	e84a                	sd	s2,16(sp)
    80002b72:	e44e                	sd	s3,8(sp)
    80002b74:	1800                	addi	s0,sp,48
    80002b76:	892a                	mv	s2,a0
    80002b78:	84ae                	mv	s1,a1
    80002b7a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	e1a080e7          	jalr	-486(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b84:	86ce                	mv	a3,s3
    80002b86:	864a                	mv	a2,s2
    80002b88:	85a6                	mv	a1,s1
    80002b8a:	6928                	ld	a0,80(a0)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	be8080e7          	jalr	-1048(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002b94:	00054763          	bltz	a0,80002ba2 <fetchstr+0x3a>
  return strlen(buf);
    80002b98:	8526                	mv	a0,s1
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	2ae080e7          	jalr	686(ra) # 80000e48 <strlen>
}
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6145                	addi	sp,sp,48
    80002bae:	8082                	ret

0000000080002bb0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ef2080e7          	jalr	-270(ra) # 80002aae <argraw>
    80002bc4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bc6:	4501                	li	a0,0
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6105                	addi	sp,sp,32
    80002bd0:	8082                	ret

0000000080002bd2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd2:	1101                	addi	sp,sp,-32
    80002bd4:	ec06                	sd	ra,24(sp)
    80002bd6:	e822                	sd	s0,16(sp)
    80002bd8:	e426                	sd	s1,8(sp)
    80002bda:	1000                	addi	s0,sp,32
    80002bdc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	ed0080e7          	jalr	-304(ra) # 80002aae <argraw>
    80002be6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002be8:	4501                	li	a0,0
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	e04a                	sd	s2,0(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
    80002c02:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	eaa080e7          	jalr	-342(ra) # 80002aae <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c0c:	864a                	mv	a2,s2
    80002c0e:	85a6                	mv	a1,s1
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	f58080e7          	jalr	-168(ra) # 80002b68 <fetchstr>
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6902                	ld	s2,0(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <syscall>:
[SYS_getprocs] sys_getprocs,
};

void
syscall(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	e04a                	sd	s2,0(sp)
    80002c2e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	d66080e7          	jalr	-666(ra) # 80001996 <myproc>
    80002c38:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3a:	05853903          	ld	s2,88(a0)
    80002c3e:	0a893783          	ld	a5,168(s2)
    80002c42:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c46:	37fd                	addiw	a5,a5,-1
    80002c48:	4755                	li	a4,21
    80002c4a:	00f76f63          	bltu	a4,a5,80002c68 <syscall+0x44>
    80002c4e:	00369713          	slli	a4,a3,0x3
    80002c52:	00006797          	auipc	a5,0x6
    80002c56:	87678793          	addi	a5,a5,-1930 # 800084c8 <syscalls>
    80002c5a:	97ba                	add	a5,a5,a4
    80002c5c:	639c                	ld	a5,0(a5)
    80002c5e:	c789                	beqz	a5,80002c68 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c60:	9782                	jalr	a5
    80002c62:	06a93823          	sd	a0,112(s2)
    80002c66:	a839                	j	80002c84 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c68:	15848613          	addi	a2,s1,344
    80002c6c:	588c                	lw	a1,48(s1)
    80002c6e:	00006517          	auipc	a0,0x6
    80002c72:	82250513          	addi	a0,a0,-2014 # 80008490 <states.0+0x150>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	90e080e7          	jalr	-1778(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c7e:	6cbc                	ld	a5,88(s1)
    80002c80:	577d                	li	a4,-1
    80002c82:	fbb8                	sd	a4,112(a5)
  }
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6902                	ld	s2,0(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c98:	fec40593          	addi	a1,s0,-20
    80002c9c:	4501                	li	a0,0
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	f12080e7          	jalr	-238(ra) # 80002bb0 <argint>
    return -1;
    80002ca6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca8:	00054963          	bltz	a0,80002cba <sys_exit+0x2a>
  exit(n);
    80002cac:	fec42503          	lw	a0,-20(s0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	606080e7          	jalr	1542(ra) # 800022b6 <exit>
  return 0;  // not reached
    80002cb8:	4781                	li	a5,0
}
    80002cba:	853e                	mv	a0,a5
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e406                	sd	ra,8(sp)
    80002cc8:	e022                	sd	s0,0(sp)
    80002cca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	cca080e7          	jalr	-822(ra) # 80001996 <myproc>
}
    80002cd4:	5908                	lw	a0,48(a0)
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_fork>:

uint64
sys_fork(void)
{
    80002cde:	1141                	addi	sp,sp,-16
    80002ce0:	e406                	sd	ra,8(sp)
    80002ce2:	e022                	sd	s0,0(sp)
    80002ce4:	0800                	addi	s0,sp,16
  return fork();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	082080e7          	jalr	130(ra) # 80001d68 <fork>
}
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cfe:	fe840593          	addi	a1,s0,-24
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	ece080e7          	jalr	-306(ra) # 80002bd2 <argaddr>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d10:	0007c863          	bltz	a5,80002d20 <sys_wait+0x2a>
  return wait(p);
    80002d14:	fe843503          	ld	a0,-24(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	3a6080e7          	jalr	934(ra) # 800020be <wait>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d32:	fdc40593          	addi	a1,s0,-36
    80002d36:	4501                	li	a0,0
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	e78080e7          	jalr	-392(ra) # 80002bb0 <argint>
    80002d40:	87aa                	mv	a5,a0
    return -1;
    80002d42:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d44:	0207c063          	bltz	a5,80002d64 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	c4e080e7          	jalr	-946(ra) # 80001996 <myproc>
    80002d50:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d52:	fdc42503          	lw	a0,-36(s0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	f9a080e7          	jalr	-102(ra) # 80001cf0 <growproc>
    80002d5e:	00054863          	bltz	a0,80002d6e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d62:	8526                	mv	a0,s1
}
    80002d64:	70a2                	ld	ra,40(sp)
    80002d66:	7402                	ld	s0,32(sp)
    80002d68:	64e2                	ld	s1,24(sp)
    80002d6a:	6145                	addi	sp,sp,48
    80002d6c:	8082                	ret
    return -1;
    80002d6e:	557d                	li	a0,-1
    80002d70:	bfd5                	j	80002d64 <sys_sbrk+0x3c>

0000000080002d72 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d72:	7139                	addi	sp,sp,-64
    80002d74:	fc06                	sd	ra,56(sp)
    80002d76:	f822                	sd	s0,48(sp)
    80002d78:	f426                	sd	s1,40(sp)
    80002d7a:	f04a                	sd	s2,32(sp)
    80002d7c:	ec4e                	sd	s3,24(sp)
    80002d7e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d80:	fcc40593          	addi	a1,s0,-52
    80002d84:	4501                	li	a0,0
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	e2a080e7          	jalr	-470(ra) # 80002bb0 <argint>
    return -1;
    80002d8e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d90:	06054563          	bltz	a0,80002dfa <sys_sleep+0x88>
  acquire(&tickslock);
    80002d94:	00014517          	auipc	a0,0x14
    80002d98:	33c50513          	addi	a0,a0,828 # 800170d0 <tickslock>
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	e34080e7          	jalr	-460(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002da4:	00006917          	auipc	s2,0x6
    80002da8:	28c92903          	lw	s2,652(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002dac:	fcc42783          	lw	a5,-52(s0)
    80002db0:	cf85                	beqz	a5,80002de8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db2:	00014997          	auipc	s3,0x14
    80002db6:	31e98993          	addi	s3,s3,798 # 800170d0 <tickslock>
    80002dba:	00006497          	auipc	s1,0x6
    80002dbe:	27648493          	addi	s1,s1,630 # 80009030 <ticks>
    if(myproc()->killed){
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	bd4080e7          	jalr	-1068(ra) # 80001996 <myproc>
    80002dca:	551c                	lw	a5,40(a0)
    80002dcc:	ef9d                	bnez	a5,80002e0a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dce:	85ce                	mv	a1,s3
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	288080e7          	jalr	648(ra) # 8000205a <sleep>
  while(ticks - ticks0 < n){
    80002dda:	409c                	lw	a5,0(s1)
    80002ddc:	412787bb          	subw	a5,a5,s2
    80002de0:	fcc42703          	lw	a4,-52(s0)
    80002de4:	fce7efe3          	bltu	a5,a4,80002dc2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002de8:	00014517          	auipc	a0,0x14
    80002dec:	2e850513          	addi	a0,a0,744 # 800170d0 <tickslock>
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	e94080e7          	jalr	-364(ra) # 80000c84 <release>
  return 0;
    80002df8:	4781                	li	a5,0
}
    80002dfa:	853e                	mv	a0,a5
    80002dfc:	70e2                	ld	ra,56(sp)
    80002dfe:	7442                	ld	s0,48(sp)
    80002e00:	74a2                	ld	s1,40(sp)
    80002e02:	7902                	ld	s2,32(sp)
    80002e04:	69e2                	ld	s3,24(sp)
    80002e06:	6121                	addi	sp,sp,64
    80002e08:	8082                	ret
      release(&tickslock);
    80002e0a:	00014517          	auipc	a0,0x14
    80002e0e:	2c650513          	addi	a0,a0,710 # 800170d0 <tickslock>
    80002e12:	ffffe097          	auipc	ra,0xffffe
    80002e16:	e72080e7          	jalr	-398(ra) # 80000c84 <release>
      return -1;
    80002e1a:	57fd                	li	a5,-1
    80002e1c:	bff9                	j	80002dfa <sys_sleep+0x88>

0000000080002e1e <sys_kill>:

uint64
sys_kill(void)
{
    80002e1e:	1101                	addi	sp,sp,-32
    80002e20:	ec06                	sd	ra,24(sp)
    80002e22:	e822                	sd	s0,16(sp)
    80002e24:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e26:	fec40593          	addi	a1,s0,-20
    80002e2a:	4501                	li	a0,0
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	d84080e7          	jalr	-636(ra) # 80002bb0 <argint>
    80002e34:	87aa                	mv	a5,a0
    return -1;
    80002e36:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e38:	0007c863          	bltz	a5,80002e48 <sys_kill+0x2a>
  return kill(pid);
    80002e3c:	fec42503          	lw	a0,-20(s0)
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	54c080e7          	jalr	1356(ra) # 8000238c <kill>
}
    80002e48:	60e2                	ld	ra,24(sp)
    80002e4a:	6442                	ld	s0,16(sp)
    80002e4c:	6105                	addi	sp,sp,32
    80002e4e:	8082                	ret

0000000080002e50 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e50:	1101                	addi	sp,sp,-32
    80002e52:	ec06                	sd	ra,24(sp)
    80002e54:	e822                	sd	s0,16(sp)
    80002e56:	e426                	sd	s1,8(sp)
    80002e58:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e5a:	00014517          	auipc	a0,0x14
    80002e5e:	27650513          	addi	a0,a0,630 # 800170d0 <tickslock>
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	d6e080e7          	jalr	-658(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002e6a:	00006497          	auipc	s1,0x6
    80002e6e:	1c64a483          	lw	s1,454(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e72:	00014517          	auipc	a0,0x14
    80002e76:	25e50513          	addi	a0,a0,606 # 800170d0 <tickslock>
    80002e7a:	ffffe097          	auipc	ra,0xffffe
    80002e7e:	e0a080e7          	jalr	-502(ra) # 80000c84 <release>
  return xticks;
}
    80002e82:	02049513          	slli	a0,s1,0x20
    80002e86:	9101                	srli	a0,a0,0x20
    80002e88:	60e2                	ld	ra,24(sp)
    80002e8a:	6442                	ld	s0,16(sp)
    80002e8c:	64a2                	ld	s1,8(sp)
    80002e8e:	6105                	addi	sp,sp,32
    80002e90:	8082                	ret

0000000080002e92 <sys_getprocs>:


//Added getprocs function
int
sys_getprocs(struct uproc* uproc)
{
    80002e92:	1141                	addi	sp,sp,-16
    80002e94:	e406                	sd	ra,8(sp)
    80002e96:	e022                	sd	s0,0(sp)
    80002e98:	0800                	addi	s0,sp,16
  //Get procs calls a helper method, procinfo passing in a uproc pointer
  return procinfo(uproc);
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	6c0080e7          	jalr	1728(ra) # 8000255a <procinfo>
}
    80002ea2:	60a2                	ld	ra,8(sp)
    80002ea4:	6402                	ld	s0,0(sp)
    80002ea6:	0141                	addi	sp,sp,16
    80002ea8:	8082                	ret

0000000080002eaa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eaa:	7179                	addi	sp,sp,-48
    80002eac:	f406                	sd	ra,40(sp)
    80002eae:	f022                	sd	s0,32(sp)
    80002eb0:	ec26                	sd	s1,24(sp)
    80002eb2:	e84a                	sd	s2,16(sp)
    80002eb4:	e44e                	sd	s3,8(sp)
    80002eb6:	e052                	sd	s4,0(sp)
    80002eb8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eba:	00005597          	auipc	a1,0x5
    80002ebe:	6c658593          	addi	a1,a1,1734 # 80008580 <syscalls+0xb8>
    80002ec2:	00014517          	auipc	a0,0x14
    80002ec6:	22650513          	addi	a0,a0,550 # 800170e8 <bcache>
    80002eca:	ffffe097          	auipc	ra,0xffffe
    80002ece:	c76080e7          	jalr	-906(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed2:	0001c797          	auipc	a5,0x1c
    80002ed6:	21678793          	addi	a5,a5,534 # 8001f0e8 <bcache+0x8000>
    80002eda:	0001c717          	auipc	a4,0x1c
    80002ede:	47670713          	addi	a4,a4,1142 # 8001f350 <bcache+0x8268>
    80002ee2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ee6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eea:	00014497          	auipc	s1,0x14
    80002eee:	21648493          	addi	s1,s1,534 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ef6:	00005a17          	auipc	s4,0x5
    80002efa:	692a0a13          	addi	s4,s4,1682 # 80008588 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002efe:	2b893783          	ld	a5,696(s2)
    80002f02:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f04:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f08:	85d2                	mv	a1,s4
    80002f0a:	01048513          	addi	a0,s1,16
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	4c2080e7          	jalr	1218(ra) # 800043d0 <initsleeplock>
    bcache.head.next->prev = b;
    80002f16:	2b893783          	ld	a5,696(s2)
    80002f1a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f1c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f20:	45848493          	addi	s1,s1,1112
    80002f24:	fd349de3          	bne	s1,s3,80002efe <binit+0x54>
  }
}
    80002f28:	70a2                	ld	ra,40(sp)
    80002f2a:	7402                	ld	s0,32(sp)
    80002f2c:	64e2                	ld	s1,24(sp)
    80002f2e:	6942                	ld	s2,16(sp)
    80002f30:	69a2                	ld	s3,8(sp)
    80002f32:	6a02                	ld	s4,0(sp)
    80002f34:	6145                	addi	sp,sp,48
    80002f36:	8082                	ret

0000000080002f38 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f38:	7179                	addi	sp,sp,-48
    80002f3a:	f406                	sd	ra,40(sp)
    80002f3c:	f022                	sd	s0,32(sp)
    80002f3e:	ec26                	sd	s1,24(sp)
    80002f40:	e84a                	sd	s2,16(sp)
    80002f42:	e44e                	sd	s3,8(sp)
    80002f44:	1800                	addi	s0,sp,48
    80002f46:	892a                	mv	s2,a0
    80002f48:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f4a:	00014517          	auipc	a0,0x14
    80002f4e:	19e50513          	addi	a0,a0,414 # 800170e8 <bcache>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	c7e080e7          	jalr	-898(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f5a:	0001c497          	auipc	s1,0x1c
    80002f5e:	4464b483          	ld	s1,1094(s1) # 8001f3a0 <bcache+0x82b8>
    80002f62:	0001c797          	auipc	a5,0x1c
    80002f66:	3ee78793          	addi	a5,a5,1006 # 8001f350 <bcache+0x8268>
    80002f6a:	02f48f63          	beq	s1,a5,80002fa8 <bread+0x70>
    80002f6e:	873e                	mv	a4,a5
    80002f70:	a021                	j	80002f78 <bread+0x40>
    80002f72:	68a4                	ld	s1,80(s1)
    80002f74:	02e48a63          	beq	s1,a4,80002fa8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f78:	449c                	lw	a5,8(s1)
    80002f7a:	ff279ce3          	bne	a5,s2,80002f72 <bread+0x3a>
    80002f7e:	44dc                	lw	a5,12(s1)
    80002f80:	ff3799e3          	bne	a5,s3,80002f72 <bread+0x3a>
      b->refcnt++;
    80002f84:	40bc                	lw	a5,64(s1)
    80002f86:	2785                	addiw	a5,a5,1
    80002f88:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f8a:	00014517          	auipc	a0,0x14
    80002f8e:	15e50513          	addi	a0,a0,350 # 800170e8 <bcache>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	cf2080e7          	jalr	-782(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f9a:	01048513          	addi	a0,s1,16
    80002f9e:	00001097          	auipc	ra,0x1
    80002fa2:	46c080e7          	jalr	1132(ra) # 8000440a <acquiresleep>
      return b;
    80002fa6:	a8b9                	j	80003004 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa8:	0001c497          	auipc	s1,0x1c
    80002fac:	3f04b483          	ld	s1,1008(s1) # 8001f398 <bcache+0x82b0>
    80002fb0:	0001c797          	auipc	a5,0x1c
    80002fb4:	3a078793          	addi	a5,a5,928 # 8001f350 <bcache+0x8268>
    80002fb8:	00f48863          	beq	s1,a5,80002fc8 <bread+0x90>
    80002fbc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fbe:	40bc                	lw	a5,64(s1)
    80002fc0:	cf81                	beqz	a5,80002fd8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc2:	64a4                	ld	s1,72(s1)
    80002fc4:	fee49de3          	bne	s1,a4,80002fbe <bread+0x86>
  panic("bget: no buffers");
    80002fc8:	00005517          	auipc	a0,0x5
    80002fcc:	5c850513          	addi	a0,a0,1480 # 80008590 <syscalls+0xc8>
    80002fd0:	ffffd097          	auipc	ra,0xffffd
    80002fd4:	56a080e7          	jalr	1386(ra) # 8000053a <panic>
      b->dev = dev;
    80002fd8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fdc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fe0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe4:	4785                	li	a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	10050513          	addi	a0,a0,256 # 800170e8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	c94080e7          	jalr	-876(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002ff8:	01048513          	addi	a0,s1,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	40e080e7          	jalr	1038(ra) # 8000440a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003004:	409c                	lw	a5,0(s1)
    80003006:	cb89                	beqz	a5,80003018 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003008:	8526                	mv	a0,s1
    8000300a:	70a2                	ld	ra,40(sp)
    8000300c:	7402                	ld	s0,32(sp)
    8000300e:	64e2                	ld	s1,24(sp)
    80003010:	6942                	ld	s2,16(sp)
    80003012:	69a2                	ld	s3,8(sp)
    80003014:	6145                	addi	sp,sp,48
    80003016:	8082                	ret
    virtio_disk_rw(b, 0);
    80003018:	4581                	li	a1,0
    8000301a:	8526                	mv	a0,s1
    8000301c:	00003097          	auipc	ra,0x3
    80003020:	f26080e7          	jalr	-218(ra) # 80005f42 <virtio_disk_rw>
    b->valid = 1;
    80003024:	4785                	li	a5,1
    80003026:	c09c                	sw	a5,0(s1)
  return b;
    80003028:	b7c5                	j	80003008 <bread+0xd0>

000000008000302a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003036:	0541                	addi	a0,a0,16
    80003038:	00001097          	auipc	ra,0x1
    8000303c:	46c080e7          	jalr	1132(ra) # 800044a4 <holdingsleep>
    80003040:	cd01                	beqz	a0,80003058 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003042:	4585                	li	a1,1
    80003044:	8526                	mv	a0,s1
    80003046:	00003097          	auipc	ra,0x3
    8000304a:	efc080e7          	jalr	-260(ra) # 80005f42 <virtio_disk_rw>
}
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	64a2                	ld	s1,8(sp)
    80003054:	6105                	addi	sp,sp,32
    80003056:	8082                	ret
    panic("bwrite");
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	55050513          	addi	a0,a0,1360 # 800085a8 <syscalls+0xe0>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	4da080e7          	jalr	1242(ra) # 8000053a <panic>

0000000080003068 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	e04a                	sd	s2,0(sp)
    80003072:	1000                	addi	s0,sp,32
    80003074:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003076:	01050913          	addi	s2,a0,16
    8000307a:	854a                	mv	a0,s2
    8000307c:	00001097          	auipc	ra,0x1
    80003080:	428080e7          	jalr	1064(ra) # 800044a4 <holdingsleep>
    80003084:	c92d                	beqz	a0,800030f6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003086:	854a                	mv	a0,s2
    80003088:	00001097          	auipc	ra,0x1
    8000308c:	3d8080e7          	jalr	984(ra) # 80004460 <releasesleep>

  acquire(&bcache.lock);
    80003090:	00014517          	auipc	a0,0x14
    80003094:	05850513          	addi	a0,a0,88 # 800170e8 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	b38080e7          	jalr	-1224(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800030a0:	40bc                	lw	a5,64(s1)
    800030a2:	37fd                	addiw	a5,a5,-1
    800030a4:	0007871b          	sext.w	a4,a5
    800030a8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030aa:	eb05                	bnez	a4,800030da <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ac:	68bc                	ld	a5,80(s1)
    800030ae:	64b8                	ld	a4,72(s1)
    800030b0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030b2:	64bc                	ld	a5,72(s1)
    800030b4:	68b8                	ld	a4,80(s1)
    800030b6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b8:	0001c797          	auipc	a5,0x1c
    800030bc:	03078793          	addi	a5,a5,48 # 8001f0e8 <bcache+0x8000>
    800030c0:	2b87b703          	ld	a4,696(a5)
    800030c4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030c6:	0001c717          	auipc	a4,0x1c
    800030ca:	28a70713          	addi	a4,a4,650 # 8001f350 <bcache+0x8268>
    800030ce:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030d0:	2b87b703          	ld	a4,696(a5)
    800030d4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030d6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030da:	00014517          	auipc	a0,0x14
    800030de:	00e50513          	addi	a0,a0,14 # 800170e8 <bcache>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	ba2080e7          	jalr	-1118(ra) # 80000c84 <release>
}
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	64a2                	ld	s1,8(sp)
    800030f0:	6902                	ld	s2,0(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret
    panic("brelse");
    800030f6:	00005517          	auipc	a0,0x5
    800030fa:	4ba50513          	addi	a0,a0,1210 # 800085b0 <syscalls+0xe8>
    800030fe:	ffffd097          	auipc	ra,0xffffd
    80003102:	43c080e7          	jalr	1084(ra) # 8000053a <panic>

0000000080003106 <bpin>:

void
bpin(struct buf *b) {
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	1000                	addi	s0,sp,32
    80003110:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003112:	00014517          	auipc	a0,0x14
    80003116:	fd650513          	addi	a0,a0,-42 # 800170e8 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	ab6080e7          	jalr	-1354(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003122:	40bc                	lw	a5,64(s1)
    80003124:	2785                	addiw	a5,a5,1
    80003126:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003128:	00014517          	auipc	a0,0x14
    8000312c:	fc050513          	addi	a0,a0,-64 # 800170e8 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b54080e7          	jalr	-1196(ra) # 80000c84 <release>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <bunpin>:

void
bunpin(struct buf *b) {
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000314e:	00014517          	auipc	a0,0x14
    80003152:	f9a50513          	addi	a0,a0,-102 # 800170e8 <bcache>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	a7a080e7          	jalr	-1414(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000315e:	40bc                	lw	a5,64(s1)
    80003160:	37fd                	addiw	a5,a5,-1
    80003162:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003164:	00014517          	auipc	a0,0x14
    80003168:	f8450513          	addi	a0,a0,-124 # 800170e8 <bcache>
    8000316c:	ffffe097          	auipc	ra,0xffffe
    80003170:	b18080e7          	jalr	-1256(ra) # 80000c84 <release>
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret

000000008000317e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	e04a                	sd	s2,0(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000318c:	00d5d59b          	srliw	a1,a1,0xd
    80003190:	0001c797          	auipc	a5,0x1c
    80003194:	6347a783          	lw	a5,1588(a5) # 8001f7c4 <sb+0x1c>
    80003198:	9dbd                	addw	a1,a1,a5
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	d9e080e7          	jalr	-610(ra) # 80002f38 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031a2:	0074f713          	andi	a4,s1,7
    800031a6:	4785                	li	a5,1
    800031a8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ac:	14ce                	slli	s1,s1,0x33
    800031ae:	90d9                	srli	s1,s1,0x36
    800031b0:	00950733          	add	a4,a0,s1
    800031b4:	05874703          	lbu	a4,88(a4)
    800031b8:	00e7f6b3          	and	a3,a5,a4
    800031bc:	c69d                	beqz	a3,800031ea <bfree+0x6c>
    800031be:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031c0:	94aa                	add	s1,s1,a0
    800031c2:	fff7c793          	not	a5,a5
    800031c6:	8f7d                	and	a4,a4,a5
    800031c8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	120080e7          	jalr	288(ra) # 800042ec <log_write>
  brelse(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	e92080e7          	jalr	-366(ra) # 80003068 <brelse>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6902                	ld	s2,0(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret
    panic("freeing free block");
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	3ce50513          	addi	a0,a0,974 # 800085b8 <syscalls+0xf0>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	348080e7          	jalr	840(ra) # 8000053a <panic>

00000000800031fa <balloc>:
{
    800031fa:	711d                	addi	sp,sp,-96
    800031fc:	ec86                	sd	ra,88(sp)
    800031fe:	e8a2                	sd	s0,80(sp)
    80003200:	e4a6                	sd	s1,72(sp)
    80003202:	e0ca                	sd	s2,64(sp)
    80003204:	fc4e                	sd	s3,56(sp)
    80003206:	f852                	sd	s4,48(sp)
    80003208:	f456                	sd	s5,40(sp)
    8000320a:	f05a                	sd	s6,32(sp)
    8000320c:	ec5e                	sd	s7,24(sp)
    8000320e:	e862                	sd	s8,16(sp)
    80003210:	e466                	sd	s9,8(sp)
    80003212:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003214:	0001c797          	auipc	a5,0x1c
    80003218:	5987a783          	lw	a5,1432(a5) # 8001f7ac <sb+0x4>
    8000321c:	cbc1                	beqz	a5,800032ac <balloc+0xb2>
    8000321e:	8baa                	mv	s7,a0
    80003220:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003222:	0001cb17          	auipc	s6,0x1c
    80003226:	586b0b13          	addi	s6,s6,1414 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000322c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003230:	6c89                	lui	s9,0x2
    80003232:	a831                	j	8000324e <balloc+0x54>
    brelse(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	e32080e7          	jalr	-462(ra) # 80003068 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000323e:	015c87bb          	addw	a5,s9,s5
    80003242:	00078a9b          	sext.w	s5,a5
    80003246:	004b2703          	lw	a4,4(s6)
    8000324a:	06eaf163          	bgeu	s5,a4,800032ac <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000324e:	41fad79b          	sraiw	a5,s5,0x1f
    80003252:	0137d79b          	srliw	a5,a5,0x13
    80003256:	015787bb          	addw	a5,a5,s5
    8000325a:	40d7d79b          	sraiw	a5,a5,0xd
    8000325e:	01cb2583          	lw	a1,28(s6)
    80003262:	9dbd                	addw	a1,a1,a5
    80003264:	855e                	mv	a0,s7
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	cd2080e7          	jalr	-814(ra) # 80002f38 <bread>
    8000326e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	004b2503          	lw	a0,4(s6)
    80003274:	000a849b          	sext.w	s1,s5
    80003278:	8762                	mv	a4,s8
    8000327a:	faa4fde3          	bgeu	s1,a0,80003234 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000327e:	00777693          	andi	a3,a4,7
    80003282:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003286:	41f7579b          	sraiw	a5,a4,0x1f
    8000328a:	01d7d79b          	srliw	a5,a5,0x1d
    8000328e:	9fb9                	addw	a5,a5,a4
    80003290:	4037d79b          	sraiw	a5,a5,0x3
    80003294:	00f90633          	add	a2,s2,a5
    80003298:	05864603          	lbu	a2,88(a2)
    8000329c:	00c6f5b3          	and	a1,a3,a2
    800032a0:	cd91                	beqz	a1,800032bc <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a2:	2705                	addiw	a4,a4,1
    800032a4:	2485                	addiw	s1,s1,1
    800032a6:	fd471ae3          	bne	a4,s4,8000327a <balloc+0x80>
    800032aa:	b769                	j	80003234 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032ac:	00005517          	auipc	a0,0x5
    800032b0:	32450513          	addi	a0,a0,804 # 800085d0 <syscalls+0x108>
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	286080e7          	jalr	646(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032bc:	97ca                	add	a5,a5,s2
    800032be:	8e55                	or	a2,a2,a3
    800032c0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	026080e7          	jalr	38(ra) # 800042ec <log_write>
        brelse(bp);
    800032ce:	854a                	mv	a0,s2
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	d98080e7          	jalr	-616(ra) # 80003068 <brelse>
  bp = bread(dev, bno);
    800032d8:	85a6                	mv	a1,s1
    800032da:	855e                	mv	a0,s7
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	c5c080e7          	jalr	-932(ra) # 80002f38 <bread>
    800032e4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032e6:	40000613          	li	a2,1024
    800032ea:	4581                	li	a1,0
    800032ec:	05850513          	addi	a0,a0,88
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	9dc080e7          	jalr	-1572(ra) # 80000ccc <memset>
  log_write(bp);
    800032f8:	854a                	mv	a0,s2
    800032fa:	00001097          	auipc	ra,0x1
    800032fe:	ff2080e7          	jalr	-14(ra) # 800042ec <log_write>
  brelse(bp);
    80003302:	854a                	mv	a0,s2
    80003304:	00000097          	auipc	ra,0x0
    80003308:	d64080e7          	jalr	-668(ra) # 80003068 <brelse>
}
    8000330c:	8526                	mv	a0,s1
    8000330e:	60e6                	ld	ra,88(sp)
    80003310:	6446                	ld	s0,80(sp)
    80003312:	64a6                	ld	s1,72(sp)
    80003314:	6906                	ld	s2,64(sp)
    80003316:	79e2                	ld	s3,56(sp)
    80003318:	7a42                	ld	s4,48(sp)
    8000331a:	7aa2                	ld	s5,40(sp)
    8000331c:	7b02                	ld	s6,32(sp)
    8000331e:	6be2                	ld	s7,24(sp)
    80003320:	6c42                	ld	s8,16(sp)
    80003322:	6ca2                	ld	s9,8(sp)
    80003324:	6125                	addi	sp,sp,96
    80003326:	8082                	ret

0000000080003328 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003328:	7179                	addi	sp,sp,-48
    8000332a:	f406                	sd	ra,40(sp)
    8000332c:	f022                	sd	s0,32(sp)
    8000332e:	ec26                	sd	s1,24(sp)
    80003330:	e84a                	sd	s2,16(sp)
    80003332:	e44e                	sd	s3,8(sp)
    80003334:	e052                	sd	s4,0(sp)
    80003336:	1800                	addi	s0,sp,48
    80003338:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000333a:	47ad                	li	a5,11
    8000333c:	04b7fe63          	bgeu	a5,a1,80003398 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003340:	ff45849b          	addiw	s1,a1,-12
    80003344:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003348:	0ff00793          	li	a5,255
    8000334c:	0ae7e463          	bltu	a5,a4,800033f4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003350:	08052583          	lw	a1,128(a0)
    80003354:	c5b5                	beqz	a1,800033c0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003356:	00092503          	lw	a0,0(s2)
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	bde080e7          	jalr	-1058(ra) # 80002f38 <bread>
    80003362:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003364:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003368:	02049713          	slli	a4,s1,0x20
    8000336c:	01e75593          	srli	a1,a4,0x1e
    80003370:	00b784b3          	add	s1,a5,a1
    80003374:	0004a983          	lw	s3,0(s1)
    80003378:	04098e63          	beqz	s3,800033d4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000337c:	8552                	mv	a0,s4
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	cea080e7          	jalr	-790(ra) # 80003068 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003386:	854e                	mv	a0,s3
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6a02                	ld	s4,0(sp)
    80003394:	6145                	addi	sp,sp,48
    80003396:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003398:	02059793          	slli	a5,a1,0x20
    8000339c:	01e7d593          	srli	a1,a5,0x1e
    800033a0:	00b504b3          	add	s1,a0,a1
    800033a4:	0504a983          	lw	s3,80(s1)
    800033a8:	fc099fe3          	bnez	s3,80003386 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ac:	4108                	lw	a0,0(a0)
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	e4c080e7          	jalr	-436(ra) # 800031fa <balloc>
    800033b6:	0005099b          	sext.w	s3,a0
    800033ba:	0534a823          	sw	s3,80(s1)
    800033be:	b7e1                	j	80003386 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033c0:	4108                	lw	a0,0(a0)
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	e38080e7          	jalr	-456(ra) # 800031fa <balloc>
    800033ca:	0005059b          	sext.w	a1,a0
    800033ce:	08b92023          	sw	a1,128(s2)
    800033d2:	b751                	j	80003356 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033d4:	00092503          	lw	a0,0(s2)
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	e22080e7          	jalr	-478(ra) # 800031fa <balloc>
    800033e0:	0005099b          	sext.w	s3,a0
    800033e4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033e8:	8552                	mv	a0,s4
    800033ea:	00001097          	auipc	ra,0x1
    800033ee:	f02080e7          	jalr	-254(ra) # 800042ec <log_write>
    800033f2:	b769                	j	8000337c <bmap+0x54>
  panic("bmap: out of range");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	1f450513          	addi	a0,a0,500 # 800085e8 <syscalls+0x120>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	13e080e7          	jalr	318(ra) # 8000053a <panic>

0000000080003404 <iget>:
{
    80003404:	7179                	addi	sp,sp,-48
    80003406:	f406                	sd	ra,40(sp)
    80003408:	f022                	sd	s0,32(sp)
    8000340a:	ec26                	sd	s1,24(sp)
    8000340c:	e84a                	sd	s2,16(sp)
    8000340e:	e44e                	sd	s3,8(sp)
    80003410:	e052                	sd	s4,0(sp)
    80003412:	1800                	addi	s0,sp,48
    80003414:	89aa                	mv	s3,a0
    80003416:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003418:	0001c517          	auipc	a0,0x1c
    8000341c:	3b050513          	addi	a0,a0,944 # 8001f7c8 <itable>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	7b0080e7          	jalr	1968(ra) # 80000bd0 <acquire>
  empty = 0;
    80003428:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000342a:	0001c497          	auipc	s1,0x1c
    8000342e:	3b648493          	addi	s1,s1,950 # 8001f7e0 <itable+0x18>
    80003432:	0001e697          	auipc	a3,0x1e
    80003436:	e3e68693          	addi	a3,a3,-450 # 80021270 <log>
    8000343a:	a039                	j	80003448 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000343c:	02090b63          	beqz	s2,80003472 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003440:	08848493          	addi	s1,s1,136
    80003444:	02d48a63          	beq	s1,a3,80003478 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003448:	449c                	lw	a5,8(s1)
    8000344a:	fef059e3          	blez	a5,8000343c <iget+0x38>
    8000344e:	4098                	lw	a4,0(s1)
    80003450:	ff3716e3          	bne	a4,s3,8000343c <iget+0x38>
    80003454:	40d8                	lw	a4,4(s1)
    80003456:	ff4713e3          	bne	a4,s4,8000343c <iget+0x38>
      ip->ref++;
    8000345a:	2785                	addiw	a5,a5,1
    8000345c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000345e:	0001c517          	auipc	a0,0x1c
    80003462:	36a50513          	addi	a0,a0,874 # 8001f7c8 <itable>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	81e080e7          	jalr	-2018(ra) # 80000c84 <release>
      return ip;
    8000346e:	8926                	mv	s2,s1
    80003470:	a03d                	j	8000349e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003472:	f7f9                	bnez	a5,80003440 <iget+0x3c>
    80003474:	8926                	mv	s2,s1
    80003476:	b7e9                	j	80003440 <iget+0x3c>
  if(empty == 0)
    80003478:	02090c63          	beqz	s2,800034b0 <iget+0xac>
  ip->dev = dev;
    8000347c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003480:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003484:	4785                	li	a5,1
    80003486:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000348a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000348e:	0001c517          	auipc	a0,0x1c
    80003492:	33a50513          	addi	a0,a0,826 # 8001f7c8 <itable>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	7ee080e7          	jalr	2030(ra) # 80000c84 <release>
}
    8000349e:	854a                	mv	a0,s2
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6a02                	ld	s4,0(sp)
    800034ac:	6145                	addi	sp,sp,48
    800034ae:	8082                	ret
    panic("iget: no inodes");
    800034b0:	00005517          	auipc	a0,0x5
    800034b4:	15050513          	addi	a0,a0,336 # 80008600 <syscalls+0x138>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	082080e7          	jalr	130(ra) # 8000053a <panic>

00000000800034c0 <fsinit>:
fsinit(int dev) {
    800034c0:	7179                	addi	sp,sp,-48
    800034c2:	f406                	sd	ra,40(sp)
    800034c4:	f022                	sd	s0,32(sp)
    800034c6:	ec26                	sd	s1,24(sp)
    800034c8:	e84a                	sd	s2,16(sp)
    800034ca:	e44e                	sd	s3,8(sp)
    800034cc:	1800                	addi	s0,sp,48
    800034ce:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034d0:	4585                	li	a1,1
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	a66080e7          	jalr	-1434(ra) # 80002f38 <bread>
    800034da:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034dc:	0001c997          	auipc	s3,0x1c
    800034e0:	2cc98993          	addi	s3,s3,716 # 8001f7a8 <sb>
    800034e4:	02000613          	li	a2,32
    800034e8:	05850593          	addi	a1,a0,88
    800034ec:	854e                	mv	a0,s3
    800034ee:	ffffe097          	auipc	ra,0xffffe
    800034f2:	83a080e7          	jalr	-1990(ra) # 80000d28 <memmove>
  brelse(bp);
    800034f6:	8526                	mv	a0,s1
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	b70080e7          	jalr	-1168(ra) # 80003068 <brelse>
  if(sb.magic != FSMAGIC)
    80003500:	0009a703          	lw	a4,0(s3)
    80003504:	102037b7          	lui	a5,0x10203
    80003508:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000350c:	02f71263          	bne	a4,a5,80003530 <fsinit+0x70>
  initlog(dev, &sb);
    80003510:	0001c597          	auipc	a1,0x1c
    80003514:	29858593          	addi	a1,a1,664 # 8001f7a8 <sb>
    80003518:	854a                	mv	a0,s2
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	b56080e7          	jalr	-1194(ra) # 80004070 <initlog>
}
    80003522:	70a2                	ld	ra,40(sp)
    80003524:	7402                	ld	s0,32(sp)
    80003526:	64e2                	ld	s1,24(sp)
    80003528:	6942                	ld	s2,16(sp)
    8000352a:	69a2                	ld	s3,8(sp)
    8000352c:	6145                	addi	sp,sp,48
    8000352e:	8082                	ret
    panic("invalid file system");
    80003530:	00005517          	auipc	a0,0x5
    80003534:	0e050513          	addi	a0,a0,224 # 80008610 <syscalls+0x148>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	002080e7          	jalr	2(ra) # 8000053a <panic>

0000000080003540 <iinit>:
{
    80003540:	7179                	addi	sp,sp,-48
    80003542:	f406                	sd	ra,40(sp)
    80003544:	f022                	sd	s0,32(sp)
    80003546:	ec26                	sd	s1,24(sp)
    80003548:	e84a                	sd	s2,16(sp)
    8000354a:	e44e                	sd	s3,8(sp)
    8000354c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000354e:	00005597          	auipc	a1,0x5
    80003552:	0da58593          	addi	a1,a1,218 # 80008628 <syscalls+0x160>
    80003556:	0001c517          	auipc	a0,0x1c
    8000355a:	27250513          	addi	a0,a0,626 # 8001f7c8 <itable>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	5e2080e7          	jalr	1506(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003566:	0001c497          	auipc	s1,0x1c
    8000356a:	28a48493          	addi	s1,s1,650 # 8001f7f0 <itable+0x28>
    8000356e:	0001e997          	auipc	s3,0x1e
    80003572:	d1298993          	addi	s3,s3,-750 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003576:	00005917          	auipc	s2,0x5
    8000357a:	0ba90913          	addi	s2,s2,186 # 80008630 <syscalls+0x168>
    8000357e:	85ca                	mv	a1,s2
    80003580:	8526                	mv	a0,s1
    80003582:	00001097          	auipc	ra,0x1
    80003586:	e4e080e7          	jalr	-434(ra) # 800043d0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000358a:	08848493          	addi	s1,s1,136
    8000358e:	ff3498e3          	bne	s1,s3,8000357e <iinit+0x3e>
}
    80003592:	70a2                	ld	ra,40(sp)
    80003594:	7402                	ld	s0,32(sp)
    80003596:	64e2                	ld	s1,24(sp)
    80003598:	6942                	ld	s2,16(sp)
    8000359a:	69a2                	ld	s3,8(sp)
    8000359c:	6145                	addi	sp,sp,48
    8000359e:	8082                	ret

00000000800035a0 <ialloc>:
{
    800035a0:	715d                	addi	sp,sp,-80
    800035a2:	e486                	sd	ra,72(sp)
    800035a4:	e0a2                	sd	s0,64(sp)
    800035a6:	fc26                	sd	s1,56(sp)
    800035a8:	f84a                	sd	s2,48(sp)
    800035aa:	f44e                	sd	s3,40(sp)
    800035ac:	f052                	sd	s4,32(sp)
    800035ae:	ec56                	sd	s5,24(sp)
    800035b0:	e85a                	sd	s6,16(sp)
    800035b2:	e45e                	sd	s7,8(sp)
    800035b4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035b6:	0001c717          	auipc	a4,0x1c
    800035ba:	1fe72703          	lw	a4,510(a4) # 8001f7b4 <sb+0xc>
    800035be:	4785                	li	a5,1
    800035c0:	04e7fa63          	bgeu	a5,a4,80003614 <ialloc+0x74>
    800035c4:	8aaa                	mv	s5,a0
    800035c6:	8bae                	mv	s7,a1
    800035c8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035ca:	0001ca17          	auipc	s4,0x1c
    800035ce:	1dea0a13          	addi	s4,s4,478 # 8001f7a8 <sb>
    800035d2:	00048b1b          	sext.w	s6,s1
    800035d6:	0044d593          	srli	a1,s1,0x4
    800035da:	018a2783          	lw	a5,24(s4)
    800035de:	9dbd                	addw	a1,a1,a5
    800035e0:	8556                	mv	a0,s5
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	956080e7          	jalr	-1706(ra) # 80002f38 <bread>
    800035ea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035ec:	05850993          	addi	s3,a0,88
    800035f0:	00f4f793          	andi	a5,s1,15
    800035f4:	079a                	slli	a5,a5,0x6
    800035f6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035f8:	00099783          	lh	a5,0(s3)
    800035fc:	c785                	beqz	a5,80003624 <ialloc+0x84>
    brelse(bp);
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	a6a080e7          	jalr	-1430(ra) # 80003068 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003606:	0485                	addi	s1,s1,1
    80003608:	00ca2703          	lw	a4,12(s4)
    8000360c:	0004879b          	sext.w	a5,s1
    80003610:	fce7e1e3          	bltu	a5,a4,800035d2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003614:	00005517          	auipc	a0,0x5
    80003618:	02450513          	addi	a0,a0,36 # 80008638 <syscalls+0x170>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	f1e080e7          	jalr	-226(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003624:	04000613          	li	a2,64
    80003628:	4581                	li	a1,0
    8000362a:	854e                	mv	a0,s3
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	6a0080e7          	jalr	1696(ra) # 80000ccc <memset>
      dip->type = type;
    80003634:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003638:	854a                	mv	a0,s2
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	cb2080e7          	jalr	-846(ra) # 800042ec <log_write>
      brelse(bp);
    80003642:	854a                	mv	a0,s2
    80003644:	00000097          	auipc	ra,0x0
    80003648:	a24080e7          	jalr	-1500(ra) # 80003068 <brelse>
      return iget(dev, inum);
    8000364c:	85da                	mv	a1,s6
    8000364e:	8556                	mv	a0,s5
    80003650:	00000097          	auipc	ra,0x0
    80003654:	db4080e7          	jalr	-588(ra) # 80003404 <iget>
}
    80003658:	60a6                	ld	ra,72(sp)
    8000365a:	6406                	ld	s0,64(sp)
    8000365c:	74e2                	ld	s1,56(sp)
    8000365e:	7942                	ld	s2,48(sp)
    80003660:	79a2                	ld	s3,40(sp)
    80003662:	7a02                	ld	s4,32(sp)
    80003664:	6ae2                	ld	s5,24(sp)
    80003666:	6b42                	ld	s6,16(sp)
    80003668:	6ba2                	ld	s7,8(sp)
    8000366a:	6161                	addi	sp,sp,80
    8000366c:	8082                	ret

000000008000366e <iupdate>:
{
    8000366e:	1101                	addi	sp,sp,-32
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e822                	sd	s0,16(sp)
    80003674:	e426                	sd	s1,8(sp)
    80003676:	e04a                	sd	s2,0(sp)
    80003678:	1000                	addi	s0,sp,32
    8000367a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000367c:	415c                	lw	a5,4(a0)
    8000367e:	0047d79b          	srliw	a5,a5,0x4
    80003682:	0001c597          	auipc	a1,0x1c
    80003686:	13e5a583          	lw	a1,318(a1) # 8001f7c0 <sb+0x18>
    8000368a:	9dbd                	addw	a1,a1,a5
    8000368c:	4108                	lw	a0,0(a0)
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	8aa080e7          	jalr	-1878(ra) # 80002f38 <bread>
    80003696:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003698:	05850793          	addi	a5,a0,88
    8000369c:	40d8                	lw	a4,4(s1)
    8000369e:	8b3d                	andi	a4,a4,15
    800036a0:	071a                	slli	a4,a4,0x6
    800036a2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036a4:	04449703          	lh	a4,68(s1)
    800036a8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036ac:	04649703          	lh	a4,70(s1)
    800036b0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036b4:	04849703          	lh	a4,72(s1)
    800036b8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036bc:	04a49703          	lh	a4,74(s1)
    800036c0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036c4:	44f8                	lw	a4,76(s1)
    800036c6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036c8:	03400613          	li	a2,52
    800036cc:	05048593          	addi	a1,s1,80
    800036d0:	00c78513          	addi	a0,a5,12
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	654080e7          	jalr	1620(ra) # 80000d28 <memmove>
  log_write(bp);
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	c0e080e7          	jalr	-1010(ra) # 800042ec <log_write>
  brelse(bp);
    800036e6:	854a                	mv	a0,s2
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	980080e7          	jalr	-1664(ra) # 80003068 <brelse>
}
    800036f0:	60e2                	ld	ra,24(sp)
    800036f2:	6442                	ld	s0,16(sp)
    800036f4:	64a2                	ld	s1,8(sp)
    800036f6:	6902                	ld	s2,0(sp)
    800036f8:	6105                	addi	sp,sp,32
    800036fa:	8082                	ret

00000000800036fc <idup>:
{
    800036fc:	1101                	addi	sp,sp,-32
    800036fe:	ec06                	sd	ra,24(sp)
    80003700:	e822                	sd	s0,16(sp)
    80003702:	e426                	sd	s1,8(sp)
    80003704:	1000                	addi	s0,sp,32
    80003706:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003708:	0001c517          	auipc	a0,0x1c
    8000370c:	0c050513          	addi	a0,a0,192 # 8001f7c8 <itable>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	4c0080e7          	jalr	1216(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003718:	449c                	lw	a5,8(s1)
    8000371a:	2785                	addiw	a5,a5,1
    8000371c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000371e:	0001c517          	auipc	a0,0x1c
    80003722:	0aa50513          	addi	a0,a0,170 # 8001f7c8 <itable>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	55e080e7          	jalr	1374(ra) # 80000c84 <release>
}
    8000372e:	8526                	mv	a0,s1
    80003730:	60e2                	ld	ra,24(sp)
    80003732:	6442                	ld	s0,16(sp)
    80003734:	64a2                	ld	s1,8(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret

000000008000373a <ilock>:
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	e04a                	sd	s2,0(sp)
    80003744:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003746:	c115                	beqz	a0,8000376a <ilock+0x30>
    80003748:	84aa                	mv	s1,a0
    8000374a:	451c                	lw	a5,8(a0)
    8000374c:	00f05f63          	blez	a5,8000376a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003750:	0541                	addi	a0,a0,16
    80003752:	00001097          	auipc	ra,0x1
    80003756:	cb8080e7          	jalr	-840(ra) # 8000440a <acquiresleep>
  if(ip->valid == 0){
    8000375a:	40bc                	lw	a5,64(s1)
    8000375c:	cf99                	beqz	a5,8000377a <ilock+0x40>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6902                	ld	s2,0(sp)
    80003766:	6105                	addi	sp,sp,32
    80003768:	8082                	ret
    panic("ilock");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	ee650513          	addi	a0,a0,-282 # 80008650 <syscalls+0x188>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	dc8080e7          	jalr	-568(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377a:	40dc                	lw	a5,4(s1)
    8000377c:	0047d79b          	srliw	a5,a5,0x4
    80003780:	0001c597          	auipc	a1,0x1c
    80003784:	0405a583          	lw	a1,64(a1) # 8001f7c0 <sb+0x18>
    80003788:	9dbd                	addw	a1,a1,a5
    8000378a:	4088                	lw	a0,0(s1)
    8000378c:	fffff097          	auipc	ra,0xfffff
    80003790:	7ac080e7          	jalr	1964(ra) # 80002f38 <bread>
    80003794:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003796:	05850593          	addi	a1,a0,88
    8000379a:	40dc                	lw	a5,4(s1)
    8000379c:	8bbd                	andi	a5,a5,15
    8000379e:	079a                	slli	a5,a5,0x6
    800037a0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037a2:	00059783          	lh	a5,0(a1)
    800037a6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037aa:	00259783          	lh	a5,2(a1)
    800037ae:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037b2:	00459783          	lh	a5,4(a1)
    800037b6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ba:	00659783          	lh	a5,6(a1)
    800037be:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037c2:	459c                	lw	a5,8(a1)
    800037c4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037c6:	03400613          	li	a2,52
    800037ca:	05b1                	addi	a1,a1,12
    800037cc:	05048513          	addi	a0,s1,80
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	558080e7          	jalr	1368(ra) # 80000d28 <memmove>
    brelse(bp);
    800037d8:	854a                	mv	a0,s2
    800037da:	00000097          	auipc	ra,0x0
    800037de:	88e080e7          	jalr	-1906(ra) # 80003068 <brelse>
    ip->valid = 1;
    800037e2:	4785                	li	a5,1
    800037e4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037e6:	04449783          	lh	a5,68(s1)
    800037ea:	fbb5                	bnez	a5,8000375e <ilock+0x24>
      panic("ilock: no type");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	e6c50513          	addi	a0,a0,-404 # 80008658 <syscalls+0x190>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d46080e7          	jalr	-698(ra) # 8000053a <panic>

00000000800037fc <iunlock>:
{
    800037fc:	1101                	addi	sp,sp,-32
    800037fe:	ec06                	sd	ra,24(sp)
    80003800:	e822                	sd	s0,16(sp)
    80003802:	e426                	sd	s1,8(sp)
    80003804:	e04a                	sd	s2,0(sp)
    80003806:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003808:	c905                	beqz	a0,80003838 <iunlock+0x3c>
    8000380a:	84aa                	mv	s1,a0
    8000380c:	01050913          	addi	s2,a0,16
    80003810:	854a                	mv	a0,s2
    80003812:	00001097          	auipc	ra,0x1
    80003816:	c92080e7          	jalr	-878(ra) # 800044a4 <holdingsleep>
    8000381a:	cd19                	beqz	a0,80003838 <iunlock+0x3c>
    8000381c:	449c                	lw	a5,8(s1)
    8000381e:	00f05d63          	blez	a5,80003838 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	c3c080e7          	jalr	-964(ra) # 80004460 <releasesleep>
}
    8000382c:	60e2                	ld	ra,24(sp)
    8000382e:	6442                	ld	s0,16(sp)
    80003830:	64a2                	ld	s1,8(sp)
    80003832:	6902                	ld	s2,0(sp)
    80003834:	6105                	addi	sp,sp,32
    80003836:	8082                	ret
    panic("iunlock");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	e3050513          	addi	a0,a0,-464 # 80008668 <syscalls+0x1a0>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	cfa080e7          	jalr	-774(ra) # 8000053a <panic>

0000000080003848 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003848:	7179                	addi	sp,sp,-48
    8000384a:	f406                	sd	ra,40(sp)
    8000384c:	f022                	sd	s0,32(sp)
    8000384e:	ec26                	sd	s1,24(sp)
    80003850:	e84a                	sd	s2,16(sp)
    80003852:	e44e                	sd	s3,8(sp)
    80003854:	e052                	sd	s4,0(sp)
    80003856:	1800                	addi	s0,sp,48
    80003858:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000385a:	05050493          	addi	s1,a0,80
    8000385e:	08050913          	addi	s2,a0,128
    80003862:	a021                	j	8000386a <itrunc+0x22>
    80003864:	0491                	addi	s1,s1,4
    80003866:	01248d63          	beq	s1,s2,80003880 <itrunc+0x38>
    if(ip->addrs[i]){
    8000386a:	408c                	lw	a1,0(s1)
    8000386c:	dde5                	beqz	a1,80003864 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000386e:	0009a503          	lw	a0,0(s3)
    80003872:	00000097          	auipc	ra,0x0
    80003876:	90c080e7          	jalr	-1780(ra) # 8000317e <bfree>
      ip->addrs[i] = 0;
    8000387a:	0004a023          	sw	zero,0(s1)
    8000387e:	b7dd                	j	80003864 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003880:	0809a583          	lw	a1,128(s3)
    80003884:	e185                	bnez	a1,800038a4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003886:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000388a:	854e                	mv	a0,s3
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	de2080e7          	jalr	-542(ra) # 8000366e <iupdate>
}
    80003894:	70a2                	ld	ra,40(sp)
    80003896:	7402                	ld	s0,32(sp)
    80003898:	64e2                	ld	s1,24(sp)
    8000389a:	6942                	ld	s2,16(sp)
    8000389c:	69a2                	ld	s3,8(sp)
    8000389e:	6a02                	ld	s4,0(sp)
    800038a0:	6145                	addi	sp,sp,48
    800038a2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038a4:	0009a503          	lw	a0,0(s3)
    800038a8:	fffff097          	auipc	ra,0xfffff
    800038ac:	690080e7          	jalr	1680(ra) # 80002f38 <bread>
    800038b0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038b2:	05850493          	addi	s1,a0,88
    800038b6:	45850913          	addi	s2,a0,1112
    800038ba:	a021                	j	800038c2 <itrunc+0x7a>
    800038bc:	0491                	addi	s1,s1,4
    800038be:	01248b63          	beq	s1,s2,800038d4 <itrunc+0x8c>
      if(a[j])
    800038c2:	408c                	lw	a1,0(s1)
    800038c4:	dde5                	beqz	a1,800038bc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038c6:	0009a503          	lw	a0,0(s3)
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	8b4080e7          	jalr	-1868(ra) # 8000317e <bfree>
    800038d2:	b7ed                	j	800038bc <itrunc+0x74>
    brelse(bp);
    800038d4:	8552                	mv	a0,s4
    800038d6:	fffff097          	auipc	ra,0xfffff
    800038da:	792080e7          	jalr	1938(ra) # 80003068 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038de:	0809a583          	lw	a1,128(s3)
    800038e2:	0009a503          	lw	a0,0(s3)
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	898080e7          	jalr	-1896(ra) # 8000317e <bfree>
    ip->addrs[NDIRECT] = 0;
    800038ee:	0809a023          	sw	zero,128(s3)
    800038f2:	bf51                	j	80003886 <itrunc+0x3e>

00000000800038f4 <iput>:
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	e04a                	sd	s2,0(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003902:	0001c517          	auipc	a0,0x1c
    80003906:	ec650513          	addi	a0,a0,-314 # 8001f7c8 <itable>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	2c6080e7          	jalr	710(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003912:	4498                	lw	a4,8(s1)
    80003914:	4785                	li	a5,1
    80003916:	02f70363          	beq	a4,a5,8000393c <iput+0x48>
  ip->ref--;
    8000391a:	449c                	lw	a5,8(s1)
    8000391c:	37fd                	addiw	a5,a5,-1
    8000391e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003920:	0001c517          	auipc	a0,0x1c
    80003924:	ea850513          	addi	a0,a0,-344 # 8001f7c8 <itable>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	35c080e7          	jalr	860(ra) # 80000c84 <release>
}
    80003930:	60e2                	ld	ra,24(sp)
    80003932:	6442                	ld	s0,16(sp)
    80003934:	64a2                	ld	s1,8(sp)
    80003936:	6902                	ld	s2,0(sp)
    80003938:	6105                	addi	sp,sp,32
    8000393a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393c:	40bc                	lw	a5,64(s1)
    8000393e:	dff1                	beqz	a5,8000391a <iput+0x26>
    80003940:	04a49783          	lh	a5,74(s1)
    80003944:	fbf9                	bnez	a5,8000391a <iput+0x26>
    acquiresleep(&ip->lock);
    80003946:	01048913          	addi	s2,s1,16
    8000394a:	854a                	mv	a0,s2
    8000394c:	00001097          	auipc	ra,0x1
    80003950:	abe080e7          	jalr	-1346(ra) # 8000440a <acquiresleep>
    release(&itable.lock);
    80003954:	0001c517          	auipc	a0,0x1c
    80003958:	e7450513          	addi	a0,a0,-396 # 8001f7c8 <itable>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	328080e7          	jalr	808(ra) # 80000c84 <release>
    itrunc(ip);
    80003964:	8526                	mv	a0,s1
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	ee2080e7          	jalr	-286(ra) # 80003848 <itrunc>
    ip->type = 0;
    8000396e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003972:	8526                	mv	a0,s1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	cfa080e7          	jalr	-774(ra) # 8000366e <iupdate>
    ip->valid = 0;
    8000397c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003980:	854a                	mv	a0,s2
    80003982:	00001097          	auipc	ra,0x1
    80003986:	ade080e7          	jalr	-1314(ra) # 80004460 <releasesleep>
    acquire(&itable.lock);
    8000398a:	0001c517          	auipc	a0,0x1c
    8000398e:	e3e50513          	addi	a0,a0,-450 # 8001f7c8 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	23e080e7          	jalr	574(ra) # 80000bd0 <acquire>
    8000399a:	b741                	j	8000391a <iput+0x26>

000000008000399c <iunlockput>:
{
    8000399c:	1101                	addi	sp,sp,-32
    8000399e:	ec06                	sd	ra,24(sp)
    800039a0:	e822                	sd	s0,16(sp)
    800039a2:	e426                	sd	s1,8(sp)
    800039a4:	1000                	addi	s0,sp,32
    800039a6:	84aa                	mv	s1,a0
  iunlock(ip);
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	e54080e7          	jalr	-428(ra) # 800037fc <iunlock>
  iput(ip);
    800039b0:	8526                	mv	a0,s1
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	f42080e7          	jalr	-190(ra) # 800038f4 <iput>
}
    800039ba:	60e2                	ld	ra,24(sp)
    800039bc:	6442                	ld	s0,16(sp)
    800039be:	64a2                	ld	s1,8(sp)
    800039c0:	6105                	addi	sp,sp,32
    800039c2:	8082                	ret

00000000800039c4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039c4:	1141                	addi	sp,sp,-16
    800039c6:	e422                	sd	s0,8(sp)
    800039c8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039ca:	411c                	lw	a5,0(a0)
    800039cc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039ce:	415c                	lw	a5,4(a0)
    800039d0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039d2:	04451783          	lh	a5,68(a0)
    800039d6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039da:	04a51783          	lh	a5,74(a0)
    800039de:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039e2:	04c56783          	lwu	a5,76(a0)
    800039e6:	e99c                	sd	a5,16(a1)
}
    800039e8:	6422                	ld	s0,8(sp)
    800039ea:	0141                	addi	sp,sp,16
    800039ec:	8082                	ret

00000000800039ee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ee:	457c                	lw	a5,76(a0)
    800039f0:	0ed7e963          	bltu	a5,a3,80003ae2 <readi+0xf4>
{
    800039f4:	7159                	addi	sp,sp,-112
    800039f6:	f486                	sd	ra,104(sp)
    800039f8:	f0a2                	sd	s0,96(sp)
    800039fa:	eca6                	sd	s1,88(sp)
    800039fc:	e8ca                	sd	s2,80(sp)
    800039fe:	e4ce                	sd	s3,72(sp)
    80003a00:	e0d2                	sd	s4,64(sp)
    80003a02:	fc56                	sd	s5,56(sp)
    80003a04:	f85a                	sd	s6,48(sp)
    80003a06:	f45e                	sd	s7,40(sp)
    80003a08:	f062                	sd	s8,32(sp)
    80003a0a:	ec66                	sd	s9,24(sp)
    80003a0c:	e86a                	sd	s10,16(sp)
    80003a0e:	e46e                	sd	s11,8(sp)
    80003a10:	1880                	addi	s0,sp,112
    80003a12:	8baa                	mv	s7,a0
    80003a14:	8c2e                	mv	s8,a1
    80003a16:	8ab2                	mv	s5,a2
    80003a18:	84b6                	mv	s1,a3
    80003a1a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a1c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a1e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a20:	0ad76063          	bltu	a4,a3,80003ac0 <readi+0xd2>
  if(off + n > ip->size)
    80003a24:	00e7f463          	bgeu	a5,a4,80003a2c <readi+0x3e>
    n = ip->size - off;
    80003a28:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2c:	0a0b0963          	beqz	s6,80003ade <readi+0xf0>
    80003a30:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a32:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a36:	5cfd                	li	s9,-1
    80003a38:	a82d                	j	80003a72 <readi+0x84>
    80003a3a:	020a1d93          	slli	s11,s4,0x20
    80003a3e:	020ddd93          	srli	s11,s11,0x20
    80003a42:	05890613          	addi	a2,s2,88
    80003a46:	86ee                	mv	a3,s11
    80003a48:	963a                	add	a2,a2,a4
    80003a4a:	85d6                	mv	a1,s5
    80003a4c:	8562                	mv	a0,s8
    80003a4e:	fffff097          	auipc	ra,0xfffff
    80003a52:	9b0080e7          	jalr	-1616(ra) # 800023fe <either_copyout>
    80003a56:	05950d63          	beq	a0,s9,80003ab0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	fffff097          	auipc	ra,0xfffff
    80003a60:	60c080e7          	jalr	1548(ra) # 80003068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a64:	013a09bb          	addw	s3,s4,s3
    80003a68:	009a04bb          	addw	s1,s4,s1
    80003a6c:	9aee                	add	s5,s5,s11
    80003a6e:	0569f763          	bgeu	s3,s6,80003abc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a72:	000ba903          	lw	s2,0(s7)
    80003a76:	00a4d59b          	srliw	a1,s1,0xa
    80003a7a:	855e                	mv	a0,s7
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	8ac080e7          	jalr	-1876(ra) # 80003328 <bmap>
    80003a84:	0005059b          	sext.w	a1,a0
    80003a88:	854a                	mv	a0,s2
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	4ae080e7          	jalr	1198(ra) # 80002f38 <bread>
    80003a92:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a94:	3ff4f713          	andi	a4,s1,1023
    80003a98:	40ed07bb          	subw	a5,s10,a4
    80003a9c:	413b06bb          	subw	a3,s6,s3
    80003aa0:	8a3e                	mv	s4,a5
    80003aa2:	2781                	sext.w	a5,a5
    80003aa4:	0006861b          	sext.w	a2,a3
    80003aa8:	f8f679e3          	bgeu	a2,a5,80003a3a <readi+0x4c>
    80003aac:	8a36                	mv	s4,a3
    80003aae:	b771                	j	80003a3a <readi+0x4c>
      brelse(bp);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	fffff097          	auipc	ra,0xfffff
    80003ab6:	5b6080e7          	jalr	1462(ra) # 80003068 <brelse>
      tot = -1;
    80003aba:	59fd                	li	s3,-1
  }
  return tot;
    80003abc:	0009851b          	sext.w	a0,s3
}
    80003ac0:	70a6                	ld	ra,104(sp)
    80003ac2:	7406                	ld	s0,96(sp)
    80003ac4:	64e6                	ld	s1,88(sp)
    80003ac6:	6946                	ld	s2,80(sp)
    80003ac8:	69a6                	ld	s3,72(sp)
    80003aca:	6a06                	ld	s4,64(sp)
    80003acc:	7ae2                	ld	s5,56(sp)
    80003ace:	7b42                	ld	s6,48(sp)
    80003ad0:	7ba2                	ld	s7,40(sp)
    80003ad2:	7c02                	ld	s8,32(sp)
    80003ad4:	6ce2                	ld	s9,24(sp)
    80003ad6:	6d42                	ld	s10,16(sp)
    80003ad8:	6da2                	ld	s11,8(sp)
    80003ada:	6165                	addi	sp,sp,112
    80003adc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ade:	89da                	mv	s3,s6
    80003ae0:	bff1                	j	80003abc <readi+0xce>
    return 0;
    80003ae2:	4501                	li	a0,0
}
    80003ae4:	8082                	ret

0000000080003ae6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae6:	457c                	lw	a5,76(a0)
    80003ae8:	10d7e863          	bltu	a5,a3,80003bf8 <writei+0x112>
{
    80003aec:	7159                	addi	sp,sp,-112
    80003aee:	f486                	sd	ra,104(sp)
    80003af0:	f0a2                	sd	s0,96(sp)
    80003af2:	eca6                	sd	s1,88(sp)
    80003af4:	e8ca                	sd	s2,80(sp)
    80003af6:	e4ce                	sd	s3,72(sp)
    80003af8:	e0d2                	sd	s4,64(sp)
    80003afa:	fc56                	sd	s5,56(sp)
    80003afc:	f85a                	sd	s6,48(sp)
    80003afe:	f45e                	sd	s7,40(sp)
    80003b00:	f062                	sd	s8,32(sp)
    80003b02:	ec66                	sd	s9,24(sp)
    80003b04:	e86a                	sd	s10,16(sp)
    80003b06:	e46e                	sd	s11,8(sp)
    80003b08:	1880                	addi	s0,sp,112
    80003b0a:	8b2a                	mv	s6,a0
    80003b0c:	8c2e                	mv	s8,a1
    80003b0e:	8ab2                	mv	s5,a2
    80003b10:	8936                	mv	s2,a3
    80003b12:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b14:	00e687bb          	addw	a5,a3,a4
    80003b18:	0ed7e263          	bltu	a5,a3,80003bfc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b1c:	00043737          	lui	a4,0x43
    80003b20:	0ef76063          	bltu	a4,a5,80003c00 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b24:	0c0b8863          	beqz	s7,80003bf4 <writei+0x10e>
    80003b28:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b2a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b2e:	5cfd                	li	s9,-1
    80003b30:	a091                	j	80003b74 <writei+0x8e>
    80003b32:	02099d93          	slli	s11,s3,0x20
    80003b36:	020ddd93          	srli	s11,s11,0x20
    80003b3a:	05848513          	addi	a0,s1,88
    80003b3e:	86ee                	mv	a3,s11
    80003b40:	8656                	mv	a2,s5
    80003b42:	85e2                	mv	a1,s8
    80003b44:	953a                	add	a0,a0,a4
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	90e080e7          	jalr	-1778(ra) # 80002454 <either_copyin>
    80003b4e:	07950263          	beq	a0,s9,80003bb2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b52:	8526                	mv	a0,s1
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	798080e7          	jalr	1944(ra) # 800042ec <log_write>
    brelse(bp);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	fffff097          	auipc	ra,0xfffff
    80003b62:	50a080e7          	jalr	1290(ra) # 80003068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b66:	01498a3b          	addw	s4,s3,s4
    80003b6a:	0129893b          	addw	s2,s3,s2
    80003b6e:	9aee                	add	s5,s5,s11
    80003b70:	057a7663          	bgeu	s4,s7,80003bbc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b74:	000b2483          	lw	s1,0(s6)
    80003b78:	00a9559b          	srliw	a1,s2,0xa
    80003b7c:	855a                	mv	a0,s6
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	7aa080e7          	jalr	1962(ra) # 80003328 <bmap>
    80003b86:	0005059b          	sext.w	a1,a0
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	3ac080e7          	jalr	940(ra) # 80002f38 <bread>
    80003b94:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b96:	3ff97713          	andi	a4,s2,1023
    80003b9a:	40ed07bb          	subw	a5,s10,a4
    80003b9e:	414b86bb          	subw	a3,s7,s4
    80003ba2:	89be                	mv	s3,a5
    80003ba4:	2781                	sext.w	a5,a5
    80003ba6:	0006861b          	sext.w	a2,a3
    80003baa:	f8f674e3          	bgeu	a2,a5,80003b32 <writei+0x4c>
    80003bae:	89b6                	mv	s3,a3
    80003bb0:	b749                	j	80003b32 <writei+0x4c>
      brelse(bp);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	4b4080e7          	jalr	1204(ra) # 80003068 <brelse>
  }

  if(off > ip->size)
    80003bbc:	04cb2783          	lw	a5,76(s6)
    80003bc0:	0127f463          	bgeu	a5,s2,80003bc8 <writei+0xe2>
    ip->size = off;
    80003bc4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bc8:	855a                	mv	a0,s6
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	aa4080e7          	jalr	-1372(ra) # 8000366e <iupdate>

  return tot;
    80003bd2:	000a051b          	sext.w	a0,s4
}
    80003bd6:	70a6                	ld	ra,104(sp)
    80003bd8:	7406                	ld	s0,96(sp)
    80003bda:	64e6                	ld	s1,88(sp)
    80003bdc:	6946                	ld	s2,80(sp)
    80003bde:	69a6                	ld	s3,72(sp)
    80003be0:	6a06                	ld	s4,64(sp)
    80003be2:	7ae2                	ld	s5,56(sp)
    80003be4:	7b42                	ld	s6,48(sp)
    80003be6:	7ba2                	ld	s7,40(sp)
    80003be8:	7c02                	ld	s8,32(sp)
    80003bea:	6ce2                	ld	s9,24(sp)
    80003bec:	6d42                	ld	s10,16(sp)
    80003bee:	6da2                	ld	s11,8(sp)
    80003bf0:	6165                	addi	sp,sp,112
    80003bf2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf4:	8a5e                	mv	s4,s7
    80003bf6:	bfc9                	j	80003bc8 <writei+0xe2>
    return -1;
    80003bf8:	557d                	li	a0,-1
}
    80003bfa:	8082                	ret
    return -1;
    80003bfc:	557d                	li	a0,-1
    80003bfe:	bfe1                	j	80003bd6 <writei+0xf0>
    return -1;
    80003c00:	557d                	li	a0,-1
    80003c02:	bfd1                	j	80003bd6 <writei+0xf0>

0000000080003c04 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c04:	1141                	addi	sp,sp,-16
    80003c06:	e406                	sd	ra,8(sp)
    80003c08:	e022                	sd	s0,0(sp)
    80003c0a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c0c:	4639                	li	a2,14
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	18e080e7          	jalr	398(ra) # 80000d9c <strncmp>
}
    80003c16:	60a2                	ld	ra,8(sp)
    80003c18:	6402                	ld	s0,0(sp)
    80003c1a:	0141                	addi	sp,sp,16
    80003c1c:	8082                	ret

0000000080003c1e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c1e:	7139                	addi	sp,sp,-64
    80003c20:	fc06                	sd	ra,56(sp)
    80003c22:	f822                	sd	s0,48(sp)
    80003c24:	f426                	sd	s1,40(sp)
    80003c26:	f04a                	sd	s2,32(sp)
    80003c28:	ec4e                	sd	s3,24(sp)
    80003c2a:	e852                	sd	s4,16(sp)
    80003c2c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c2e:	04451703          	lh	a4,68(a0)
    80003c32:	4785                	li	a5,1
    80003c34:	00f71a63          	bne	a4,a5,80003c48 <dirlookup+0x2a>
    80003c38:	892a                	mv	s2,a0
    80003c3a:	89ae                	mv	s3,a1
    80003c3c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3e:	457c                	lw	a5,76(a0)
    80003c40:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c42:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c44:	e79d                	bnez	a5,80003c72 <dirlookup+0x54>
    80003c46:	a8a5                	j	80003cbe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c48:	00005517          	auipc	a0,0x5
    80003c4c:	a2850513          	addi	a0,a0,-1496 # 80008670 <syscalls+0x1a8>
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	8ea080e7          	jalr	-1814(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003c58:	00005517          	auipc	a0,0x5
    80003c5c:	a3050513          	addi	a0,a0,-1488 # 80008688 <syscalls+0x1c0>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	8da080e7          	jalr	-1830(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c68:	24c1                	addiw	s1,s1,16
    80003c6a:	04c92783          	lw	a5,76(s2)
    80003c6e:	04f4f763          	bgeu	s1,a5,80003cbc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c72:	4741                	li	a4,16
    80003c74:	86a6                	mv	a3,s1
    80003c76:	fc040613          	addi	a2,s0,-64
    80003c7a:	4581                	li	a1,0
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	d70080e7          	jalr	-656(ra) # 800039ee <readi>
    80003c86:	47c1                	li	a5,16
    80003c88:	fcf518e3          	bne	a0,a5,80003c58 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c8c:	fc045783          	lhu	a5,-64(s0)
    80003c90:	dfe1                	beqz	a5,80003c68 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c92:	fc240593          	addi	a1,s0,-62
    80003c96:	854e                	mv	a0,s3
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	f6c080e7          	jalr	-148(ra) # 80003c04 <namecmp>
    80003ca0:	f561                	bnez	a0,80003c68 <dirlookup+0x4a>
      if(poff)
    80003ca2:	000a0463          	beqz	s4,80003caa <dirlookup+0x8c>
        *poff = off;
    80003ca6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003caa:	fc045583          	lhu	a1,-64(s0)
    80003cae:	00092503          	lw	a0,0(s2)
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	752080e7          	jalr	1874(ra) # 80003404 <iget>
    80003cba:	a011                	j	80003cbe <dirlookup+0xa0>
  return 0;
    80003cbc:	4501                	li	a0,0
}
    80003cbe:	70e2                	ld	ra,56(sp)
    80003cc0:	7442                	ld	s0,48(sp)
    80003cc2:	74a2                	ld	s1,40(sp)
    80003cc4:	7902                	ld	s2,32(sp)
    80003cc6:	69e2                	ld	s3,24(sp)
    80003cc8:	6a42                	ld	s4,16(sp)
    80003cca:	6121                	addi	sp,sp,64
    80003ccc:	8082                	ret

0000000080003cce <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cce:	711d                	addi	sp,sp,-96
    80003cd0:	ec86                	sd	ra,88(sp)
    80003cd2:	e8a2                	sd	s0,80(sp)
    80003cd4:	e4a6                	sd	s1,72(sp)
    80003cd6:	e0ca                	sd	s2,64(sp)
    80003cd8:	fc4e                	sd	s3,56(sp)
    80003cda:	f852                	sd	s4,48(sp)
    80003cdc:	f456                	sd	s5,40(sp)
    80003cde:	f05a                	sd	s6,32(sp)
    80003ce0:	ec5e                	sd	s7,24(sp)
    80003ce2:	e862                	sd	s8,16(sp)
    80003ce4:	e466                	sd	s9,8(sp)
    80003ce6:	e06a                	sd	s10,0(sp)
    80003ce8:	1080                	addi	s0,sp,96
    80003cea:	84aa                	mv	s1,a0
    80003cec:	8b2e                	mv	s6,a1
    80003cee:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cf0:	00054703          	lbu	a4,0(a0)
    80003cf4:	02f00793          	li	a5,47
    80003cf8:	02f70363          	beq	a4,a5,80003d1e <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cfc:	ffffe097          	auipc	ra,0xffffe
    80003d00:	c9a080e7          	jalr	-870(ra) # 80001996 <myproc>
    80003d04:	15053503          	ld	a0,336(a0)
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	9f4080e7          	jalr	-1548(ra) # 800036fc <idup>
    80003d10:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d12:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d16:	4cb5                	li	s9,13
  len = path - s;
    80003d18:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d1a:	4c05                	li	s8,1
    80003d1c:	a87d                	j	80003dda <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d1e:	4585                	li	a1,1
    80003d20:	4505                	li	a0,1
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	6e2080e7          	jalr	1762(ra) # 80003404 <iget>
    80003d2a:	8a2a                	mv	s4,a0
    80003d2c:	b7dd                	j	80003d12 <namex+0x44>
      iunlockput(ip);
    80003d2e:	8552                	mv	a0,s4
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	c6c080e7          	jalr	-916(ra) # 8000399c <iunlockput>
      return 0;
    80003d38:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d3a:	8552                	mv	a0,s4
    80003d3c:	60e6                	ld	ra,88(sp)
    80003d3e:	6446                	ld	s0,80(sp)
    80003d40:	64a6                	ld	s1,72(sp)
    80003d42:	6906                	ld	s2,64(sp)
    80003d44:	79e2                	ld	s3,56(sp)
    80003d46:	7a42                	ld	s4,48(sp)
    80003d48:	7aa2                	ld	s5,40(sp)
    80003d4a:	7b02                	ld	s6,32(sp)
    80003d4c:	6be2                	ld	s7,24(sp)
    80003d4e:	6c42                	ld	s8,16(sp)
    80003d50:	6ca2                	ld	s9,8(sp)
    80003d52:	6d02                	ld	s10,0(sp)
    80003d54:	6125                	addi	sp,sp,96
    80003d56:	8082                	ret
      iunlock(ip);
    80003d58:	8552                	mv	a0,s4
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	aa2080e7          	jalr	-1374(ra) # 800037fc <iunlock>
      return ip;
    80003d62:	bfe1                	j	80003d3a <namex+0x6c>
      iunlockput(ip);
    80003d64:	8552                	mv	a0,s4
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	c36080e7          	jalr	-970(ra) # 8000399c <iunlockput>
      return 0;
    80003d6e:	8a4e                	mv	s4,s3
    80003d70:	b7e9                	j	80003d3a <namex+0x6c>
  len = path - s;
    80003d72:	40998633          	sub	a2,s3,s1
    80003d76:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d7a:	09acd863          	bge	s9,s10,80003e0a <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d7e:	4639                	li	a2,14
    80003d80:	85a6                	mv	a1,s1
    80003d82:	8556                	mv	a0,s5
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	fa4080e7          	jalr	-92(ra) # 80000d28 <memmove>
    80003d8c:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d8e:	0004c783          	lbu	a5,0(s1)
    80003d92:	01279763          	bne	a5,s2,80003da0 <namex+0xd2>
    path++;
    80003d96:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d98:	0004c783          	lbu	a5,0(s1)
    80003d9c:	ff278de3          	beq	a5,s2,80003d96 <namex+0xc8>
    ilock(ip);
    80003da0:	8552                	mv	a0,s4
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	998080e7          	jalr	-1640(ra) # 8000373a <ilock>
    if(ip->type != T_DIR){
    80003daa:	044a1783          	lh	a5,68(s4)
    80003dae:	f98790e3          	bne	a5,s8,80003d2e <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003db2:	000b0563          	beqz	s6,80003dbc <namex+0xee>
    80003db6:	0004c783          	lbu	a5,0(s1)
    80003dba:	dfd9                	beqz	a5,80003d58 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dbc:	865e                	mv	a2,s7
    80003dbe:	85d6                	mv	a1,s5
    80003dc0:	8552                	mv	a0,s4
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	e5c080e7          	jalr	-420(ra) # 80003c1e <dirlookup>
    80003dca:	89aa                	mv	s3,a0
    80003dcc:	dd41                	beqz	a0,80003d64 <namex+0x96>
    iunlockput(ip);
    80003dce:	8552                	mv	a0,s4
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	bcc080e7          	jalr	-1076(ra) # 8000399c <iunlockput>
    ip = next;
    80003dd8:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dda:	0004c783          	lbu	a5,0(s1)
    80003dde:	01279763          	bne	a5,s2,80003dec <namex+0x11e>
    path++;
    80003de2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003de4:	0004c783          	lbu	a5,0(s1)
    80003de8:	ff278de3          	beq	a5,s2,80003de2 <namex+0x114>
  if(*path == 0)
    80003dec:	cb9d                	beqz	a5,80003e22 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003dee:	0004c783          	lbu	a5,0(s1)
    80003df2:	89a6                	mv	s3,s1
  len = path - s;
    80003df4:	8d5e                	mv	s10,s7
    80003df6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003df8:	01278963          	beq	a5,s2,80003e0a <namex+0x13c>
    80003dfc:	dbbd                	beqz	a5,80003d72 <namex+0xa4>
    path++;
    80003dfe:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e00:	0009c783          	lbu	a5,0(s3)
    80003e04:	ff279ce3          	bne	a5,s2,80003dfc <namex+0x12e>
    80003e08:	b7ad                	j	80003d72 <namex+0xa4>
    memmove(name, s, len);
    80003e0a:	2601                	sext.w	a2,a2
    80003e0c:	85a6                	mv	a1,s1
    80003e0e:	8556                	mv	a0,s5
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	f18080e7          	jalr	-232(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003e18:	9d56                	add	s10,s10,s5
    80003e1a:	000d0023          	sb	zero,0(s10)
    80003e1e:	84ce                	mv	s1,s3
    80003e20:	b7bd                	j	80003d8e <namex+0xc0>
  if(nameiparent){
    80003e22:	f00b0ce3          	beqz	s6,80003d3a <namex+0x6c>
    iput(ip);
    80003e26:	8552                	mv	a0,s4
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	acc080e7          	jalr	-1332(ra) # 800038f4 <iput>
    return 0;
    80003e30:	4a01                	li	s4,0
    80003e32:	b721                	j	80003d3a <namex+0x6c>

0000000080003e34 <dirlink>:
{
    80003e34:	7139                	addi	sp,sp,-64
    80003e36:	fc06                	sd	ra,56(sp)
    80003e38:	f822                	sd	s0,48(sp)
    80003e3a:	f426                	sd	s1,40(sp)
    80003e3c:	f04a                	sd	s2,32(sp)
    80003e3e:	ec4e                	sd	s3,24(sp)
    80003e40:	e852                	sd	s4,16(sp)
    80003e42:	0080                	addi	s0,sp,64
    80003e44:	892a                	mv	s2,a0
    80003e46:	8a2e                	mv	s4,a1
    80003e48:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e4a:	4601                	li	a2,0
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	dd2080e7          	jalr	-558(ra) # 80003c1e <dirlookup>
    80003e54:	e93d                	bnez	a0,80003eca <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e56:	04c92483          	lw	s1,76(s2)
    80003e5a:	c49d                	beqz	s1,80003e88 <dirlink+0x54>
    80003e5c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5e:	4741                	li	a4,16
    80003e60:	86a6                	mv	a3,s1
    80003e62:	fc040613          	addi	a2,s0,-64
    80003e66:	4581                	li	a1,0
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	b84080e7          	jalr	-1148(ra) # 800039ee <readi>
    80003e72:	47c1                	li	a5,16
    80003e74:	06f51163          	bne	a0,a5,80003ed6 <dirlink+0xa2>
    if(de.inum == 0)
    80003e78:	fc045783          	lhu	a5,-64(s0)
    80003e7c:	c791                	beqz	a5,80003e88 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7e:	24c1                	addiw	s1,s1,16
    80003e80:	04c92783          	lw	a5,76(s2)
    80003e84:	fcf4ede3          	bltu	s1,a5,80003e5e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e88:	4639                	li	a2,14
    80003e8a:	85d2                	mv	a1,s4
    80003e8c:	fc240513          	addi	a0,s0,-62
    80003e90:	ffffd097          	auipc	ra,0xffffd
    80003e94:	f48080e7          	jalr	-184(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003e98:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e9c:	4741                	li	a4,16
    80003e9e:	86a6                	mv	a3,s1
    80003ea0:	fc040613          	addi	a2,s0,-64
    80003ea4:	4581                	li	a1,0
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	c3e080e7          	jalr	-962(ra) # 80003ae6 <writei>
    80003eb0:	872a                	mv	a4,a0
    80003eb2:	47c1                	li	a5,16
  return 0;
    80003eb4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb6:	02f71863          	bne	a4,a5,80003ee6 <dirlink+0xb2>
}
    80003eba:	70e2                	ld	ra,56(sp)
    80003ebc:	7442                	ld	s0,48(sp)
    80003ebe:	74a2                	ld	s1,40(sp)
    80003ec0:	7902                	ld	s2,32(sp)
    80003ec2:	69e2                	ld	s3,24(sp)
    80003ec4:	6a42                	ld	s4,16(sp)
    80003ec6:	6121                	addi	sp,sp,64
    80003ec8:	8082                	ret
    iput(ip);
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	a2a080e7          	jalr	-1494(ra) # 800038f4 <iput>
    return -1;
    80003ed2:	557d                	li	a0,-1
    80003ed4:	b7dd                	j	80003eba <dirlink+0x86>
      panic("dirlink read");
    80003ed6:	00004517          	auipc	a0,0x4
    80003eda:	7c250513          	addi	a0,a0,1986 # 80008698 <syscalls+0x1d0>
    80003ede:	ffffc097          	auipc	ra,0xffffc
    80003ee2:	65c080e7          	jalr	1628(ra) # 8000053a <panic>
    panic("dirlink");
    80003ee6:	00005517          	auipc	a0,0x5
    80003eea:	8c250513          	addi	a0,a0,-1854 # 800087a8 <syscalls+0x2e0>
    80003eee:	ffffc097          	auipc	ra,0xffffc
    80003ef2:	64c080e7          	jalr	1612(ra) # 8000053a <panic>

0000000080003ef6 <namei>:

struct inode*
namei(char *path)
{
    80003ef6:	1101                	addi	sp,sp,-32
    80003ef8:	ec06                	sd	ra,24(sp)
    80003efa:	e822                	sd	s0,16(sp)
    80003efc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003efe:	fe040613          	addi	a2,s0,-32
    80003f02:	4581                	li	a1,0
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	dca080e7          	jalr	-566(ra) # 80003cce <namex>
}
    80003f0c:	60e2                	ld	ra,24(sp)
    80003f0e:	6442                	ld	s0,16(sp)
    80003f10:	6105                	addi	sp,sp,32
    80003f12:	8082                	ret

0000000080003f14 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f14:	1141                	addi	sp,sp,-16
    80003f16:	e406                	sd	ra,8(sp)
    80003f18:	e022                	sd	s0,0(sp)
    80003f1a:	0800                	addi	s0,sp,16
    80003f1c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f1e:	4585                	li	a1,1
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	dae080e7          	jalr	-594(ra) # 80003cce <namex>
}
    80003f28:	60a2                	ld	ra,8(sp)
    80003f2a:	6402                	ld	s0,0(sp)
    80003f2c:	0141                	addi	sp,sp,16
    80003f2e:	8082                	ret

0000000080003f30 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f30:	1101                	addi	sp,sp,-32
    80003f32:	ec06                	sd	ra,24(sp)
    80003f34:	e822                	sd	s0,16(sp)
    80003f36:	e426                	sd	s1,8(sp)
    80003f38:	e04a                	sd	s2,0(sp)
    80003f3a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f3c:	0001d917          	auipc	s2,0x1d
    80003f40:	33490913          	addi	s2,s2,820 # 80021270 <log>
    80003f44:	01892583          	lw	a1,24(s2)
    80003f48:	02892503          	lw	a0,40(s2)
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	fec080e7          	jalr	-20(ra) # 80002f38 <bread>
    80003f54:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f56:	02c92683          	lw	a3,44(s2)
    80003f5a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f5c:	02d05863          	blez	a3,80003f8c <write_head+0x5c>
    80003f60:	0001d797          	auipc	a5,0x1d
    80003f64:	34078793          	addi	a5,a5,832 # 800212a0 <log+0x30>
    80003f68:	05c50713          	addi	a4,a0,92
    80003f6c:	36fd                	addiw	a3,a3,-1
    80003f6e:	02069613          	slli	a2,a3,0x20
    80003f72:	01e65693          	srli	a3,a2,0x1e
    80003f76:	0001d617          	auipc	a2,0x1d
    80003f7a:	32e60613          	addi	a2,a2,814 # 800212a4 <log+0x34>
    80003f7e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f80:	4390                	lw	a2,0(a5)
    80003f82:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f84:	0791                	addi	a5,a5,4
    80003f86:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f88:	fed79ce3          	bne	a5,a3,80003f80 <write_head+0x50>
  }
  bwrite(buf);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	09c080e7          	jalr	156(ra) # 8000302a <bwrite>
  brelse(buf);
    80003f96:	8526                	mv	a0,s1
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	0d0080e7          	jalr	208(ra) # 80003068 <brelse>
}
    80003fa0:	60e2                	ld	ra,24(sp)
    80003fa2:	6442                	ld	s0,16(sp)
    80003fa4:	64a2                	ld	s1,8(sp)
    80003fa6:	6902                	ld	s2,0(sp)
    80003fa8:	6105                	addi	sp,sp,32
    80003faa:	8082                	ret

0000000080003fac <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fac:	0001d797          	auipc	a5,0x1d
    80003fb0:	2f07a783          	lw	a5,752(a5) # 8002129c <log+0x2c>
    80003fb4:	0af05d63          	blez	a5,8000406e <install_trans+0xc2>
{
    80003fb8:	7139                	addi	sp,sp,-64
    80003fba:	fc06                	sd	ra,56(sp)
    80003fbc:	f822                	sd	s0,48(sp)
    80003fbe:	f426                	sd	s1,40(sp)
    80003fc0:	f04a                	sd	s2,32(sp)
    80003fc2:	ec4e                	sd	s3,24(sp)
    80003fc4:	e852                	sd	s4,16(sp)
    80003fc6:	e456                	sd	s5,8(sp)
    80003fc8:	e05a                	sd	s6,0(sp)
    80003fca:	0080                	addi	s0,sp,64
    80003fcc:	8b2a                	mv	s6,a0
    80003fce:	0001da97          	auipc	s5,0x1d
    80003fd2:	2d2a8a93          	addi	s5,s5,722 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd8:	0001d997          	auipc	s3,0x1d
    80003fdc:	29898993          	addi	s3,s3,664 # 80021270 <log>
    80003fe0:	a00d                	j	80004002 <install_trans+0x56>
    brelse(lbuf);
    80003fe2:	854a                	mv	a0,s2
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	084080e7          	jalr	132(ra) # 80003068 <brelse>
    brelse(dbuf);
    80003fec:	8526                	mv	a0,s1
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	07a080e7          	jalr	122(ra) # 80003068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff6:	2a05                	addiw	s4,s4,1
    80003ff8:	0a91                	addi	s5,s5,4
    80003ffa:	02c9a783          	lw	a5,44(s3)
    80003ffe:	04fa5e63          	bge	s4,a5,8000405a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004002:	0189a583          	lw	a1,24(s3)
    80004006:	014585bb          	addw	a1,a1,s4
    8000400a:	2585                	addiw	a1,a1,1
    8000400c:	0289a503          	lw	a0,40(s3)
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	f28080e7          	jalr	-216(ra) # 80002f38 <bread>
    80004018:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000401a:	000aa583          	lw	a1,0(s5)
    8000401e:	0289a503          	lw	a0,40(s3)
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	f16080e7          	jalr	-234(ra) # 80002f38 <bread>
    8000402a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000402c:	40000613          	li	a2,1024
    80004030:	05890593          	addi	a1,s2,88
    80004034:	05850513          	addi	a0,a0,88
    80004038:	ffffd097          	auipc	ra,0xffffd
    8000403c:	cf0080e7          	jalr	-784(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004040:	8526                	mv	a0,s1
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	fe8080e7          	jalr	-24(ra) # 8000302a <bwrite>
    if(recovering == 0)
    8000404a:	f80b1ce3          	bnez	s6,80003fe2 <install_trans+0x36>
      bunpin(dbuf);
    8000404e:	8526                	mv	a0,s1
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	0f2080e7          	jalr	242(ra) # 80003142 <bunpin>
    80004058:	b769                	j	80003fe2 <install_trans+0x36>
}
    8000405a:	70e2                	ld	ra,56(sp)
    8000405c:	7442                	ld	s0,48(sp)
    8000405e:	74a2                	ld	s1,40(sp)
    80004060:	7902                	ld	s2,32(sp)
    80004062:	69e2                	ld	s3,24(sp)
    80004064:	6a42                	ld	s4,16(sp)
    80004066:	6aa2                	ld	s5,8(sp)
    80004068:	6b02                	ld	s6,0(sp)
    8000406a:	6121                	addi	sp,sp,64
    8000406c:	8082                	ret
    8000406e:	8082                	ret

0000000080004070 <initlog>:
{
    80004070:	7179                	addi	sp,sp,-48
    80004072:	f406                	sd	ra,40(sp)
    80004074:	f022                	sd	s0,32(sp)
    80004076:	ec26                	sd	s1,24(sp)
    80004078:	e84a                	sd	s2,16(sp)
    8000407a:	e44e                	sd	s3,8(sp)
    8000407c:	1800                	addi	s0,sp,48
    8000407e:	892a                	mv	s2,a0
    80004080:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004082:	0001d497          	auipc	s1,0x1d
    80004086:	1ee48493          	addi	s1,s1,494 # 80021270 <log>
    8000408a:	00004597          	auipc	a1,0x4
    8000408e:	61e58593          	addi	a1,a1,1566 # 800086a8 <syscalls+0x1e0>
    80004092:	8526                	mv	a0,s1
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	aac080e7          	jalr	-1364(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    8000409c:	0149a583          	lw	a1,20(s3)
    800040a0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040a2:	0109a783          	lw	a5,16(s3)
    800040a6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040ac:	854a                	mv	a0,s2
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	e8a080e7          	jalr	-374(ra) # 80002f38 <bread>
  log.lh.n = lh->n;
    800040b6:	4d34                	lw	a3,88(a0)
    800040b8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040ba:	02d05663          	blez	a3,800040e6 <initlog+0x76>
    800040be:	05c50793          	addi	a5,a0,92
    800040c2:	0001d717          	auipc	a4,0x1d
    800040c6:	1de70713          	addi	a4,a4,478 # 800212a0 <log+0x30>
    800040ca:	36fd                	addiw	a3,a3,-1
    800040cc:	02069613          	slli	a2,a3,0x20
    800040d0:	01e65693          	srli	a3,a2,0x1e
    800040d4:	06050613          	addi	a2,a0,96
    800040d8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040da:	4390                	lw	a2,0(a5)
    800040dc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040de:	0791                	addi	a5,a5,4
    800040e0:	0711                	addi	a4,a4,4
    800040e2:	fed79ce3          	bne	a5,a3,800040da <initlog+0x6a>
  brelse(buf);
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	f82080e7          	jalr	-126(ra) # 80003068 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040ee:	4505                	li	a0,1
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	ebc080e7          	jalr	-324(ra) # 80003fac <install_trans>
  log.lh.n = 0;
    800040f8:	0001d797          	auipc	a5,0x1d
    800040fc:	1a07a223          	sw	zero,420(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004100:	00000097          	auipc	ra,0x0
    80004104:	e30080e7          	jalr	-464(ra) # 80003f30 <write_head>
}
    80004108:	70a2                	ld	ra,40(sp)
    8000410a:	7402                	ld	s0,32(sp)
    8000410c:	64e2                	ld	s1,24(sp)
    8000410e:	6942                	ld	s2,16(sp)
    80004110:	69a2                	ld	s3,8(sp)
    80004112:	6145                	addi	sp,sp,48
    80004114:	8082                	ret

0000000080004116 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004116:	1101                	addi	sp,sp,-32
    80004118:	ec06                	sd	ra,24(sp)
    8000411a:	e822                	sd	s0,16(sp)
    8000411c:	e426                	sd	s1,8(sp)
    8000411e:	e04a                	sd	s2,0(sp)
    80004120:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004122:	0001d517          	auipc	a0,0x1d
    80004126:	14e50513          	addi	a0,a0,334 # 80021270 <log>
    8000412a:	ffffd097          	auipc	ra,0xffffd
    8000412e:	aa6080e7          	jalr	-1370(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004132:	0001d497          	auipc	s1,0x1d
    80004136:	13e48493          	addi	s1,s1,318 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000413a:	4979                	li	s2,30
    8000413c:	a039                	j	8000414a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000413e:	85a6                	mv	a1,s1
    80004140:	8526                	mv	a0,s1
    80004142:	ffffe097          	auipc	ra,0xffffe
    80004146:	f18080e7          	jalr	-232(ra) # 8000205a <sleep>
    if(log.committing){
    8000414a:	50dc                	lw	a5,36(s1)
    8000414c:	fbed                	bnez	a5,8000413e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000414e:	5098                	lw	a4,32(s1)
    80004150:	2705                	addiw	a4,a4,1
    80004152:	0007069b          	sext.w	a3,a4
    80004156:	0027179b          	slliw	a5,a4,0x2
    8000415a:	9fb9                	addw	a5,a5,a4
    8000415c:	0017979b          	slliw	a5,a5,0x1
    80004160:	54d8                	lw	a4,44(s1)
    80004162:	9fb9                	addw	a5,a5,a4
    80004164:	00f95963          	bge	s2,a5,80004176 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004168:	85a6                	mv	a1,s1
    8000416a:	8526                	mv	a0,s1
    8000416c:	ffffe097          	auipc	ra,0xffffe
    80004170:	eee080e7          	jalr	-274(ra) # 8000205a <sleep>
    80004174:	bfd9                	j	8000414a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004176:	0001d517          	auipc	a0,0x1d
    8000417a:	0fa50513          	addi	a0,a0,250 # 80021270 <log>
    8000417e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	b04080e7          	jalr	-1276(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004188:	60e2                	ld	ra,24(sp)
    8000418a:	6442                	ld	s0,16(sp)
    8000418c:	64a2                	ld	s1,8(sp)
    8000418e:	6902                	ld	s2,0(sp)
    80004190:	6105                	addi	sp,sp,32
    80004192:	8082                	ret

0000000080004194 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004194:	7139                	addi	sp,sp,-64
    80004196:	fc06                	sd	ra,56(sp)
    80004198:	f822                	sd	s0,48(sp)
    8000419a:	f426                	sd	s1,40(sp)
    8000419c:	f04a                	sd	s2,32(sp)
    8000419e:	ec4e                	sd	s3,24(sp)
    800041a0:	e852                	sd	s4,16(sp)
    800041a2:	e456                	sd	s5,8(sp)
    800041a4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041a6:	0001d497          	auipc	s1,0x1d
    800041aa:	0ca48493          	addi	s1,s1,202 # 80021270 <log>
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	a20080e7          	jalr	-1504(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800041b8:	509c                	lw	a5,32(s1)
    800041ba:	37fd                	addiw	a5,a5,-1
    800041bc:	0007891b          	sext.w	s2,a5
    800041c0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041c2:	50dc                	lw	a5,36(s1)
    800041c4:	e7b9                	bnez	a5,80004212 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041c6:	04091e63          	bnez	s2,80004222 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041ca:	0001d497          	auipc	s1,0x1d
    800041ce:	0a648493          	addi	s1,s1,166 # 80021270 <log>
    800041d2:	4785                	li	a5,1
    800041d4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041d6:	8526                	mv	a0,s1
    800041d8:	ffffd097          	auipc	ra,0xffffd
    800041dc:	aac080e7          	jalr	-1364(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041e0:	54dc                	lw	a5,44(s1)
    800041e2:	06f04763          	bgtz	a5,80004250 <end_op+0xbc>
    acquire(&log.lock);
    800041e6:	0001d497          	auipc	s1,0x1d
    800041ea:	08a48493          	addi	s1,s1,138 # 80021270 <log>
    800041ee:	8526                	mv	a0,s1
    800041f0:	ffffd097          	auipc	ra,0xffffd
    800041f4:	9e0080e7          	jalr	-1568(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800041f8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041fc:	8526                	mv	a0,s1
    800041fe:	ffffe097          	auipc	ra,0xffffe
    80004202:	fe8080e7          	jalr	-24(ra) # 800021e6 <wakeup>
    release(&log.lock);
    80004206:	8526                	mv	a0,s1
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	a7c080e7          	jalr	-1412(ra) # 80000c84 <release>
}
    80004210:	a03d                	j	8000423e <end_op+0xaa>
    panic("log.committing");
    80004212:	00004517          	auipc	a0,0x4
    80004216:	49e50513          	addi	a0,a0,1182 # 800086b0 <syscalls+0x1e8>
    8000421a:	ffffc097          	auipc	ra,0xffffc
    8000421e:	320080e7          	jalr	800(ra) # 8000053a <panic>
    wakeup(&log);
    80004222:	0001d497          	auipc	s1,0x1d
    80004226:	04e48493          	addi	s1,s1,78 # 80021270 <log>
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffe097          	auipc	ra,0xffffe
    80004230:	fba080e7          	jalr	-70(ra) # 800021e6 <wakeup>
  release(&log.lock);
    80004234:	8526                	mv	a0,s1
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	a4e080e7          	jalr	-1458(ra) # 80000c84 <release>
}
    8000423e:	70e2                	ld	ra,56(sp)
    80004240:	7442                	ld	s0,48(sp)
    80004242:	74a2                	ld	s1,40(sp)
    80004244:	7902                	ld	s2,32(sp)
    80004246:	69e2                	ld	s3,24(sp)
    80004248:	6a42                	ld	s4,16(sp)
    8000424a:	6aa2                	ld	s5,8(sp)
    8000424c:	6121                	addi	sp,sp,64
    8000424e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004250:	0001da97          	auipc	s5,0x1d
    80004254:	050a8a93          	addi	s5,s5,80 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004258:	0001da17          	auipc	s4,0x1d
    8000425c:	018a0a13          	addi	s4,s4,24 # 80021270 <log>
    80004260:	018a2583          	lw	a1,24(s4)
    80004264:	012585bb          	addw	a1,a1,s2
    80004268:	2585                	addiw	a1,a1,1
    8000426a:	028a2503          	lw	a0,40(s4)
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	cca080e7          	jalr	-822(ra) # 80002f38 <bread>
    80004276:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004278:	000aa583          	lw	a1,0(s5)
    8000427c:	028a2503          	lw	a0,40(s4)
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	cb8080e7          	jalr	-840(ra) # 80002f38 <bread>
    80004288:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000428a:	40000613          	li	a2,1024
    8000428e:	05850593          	addi	a1,a0,88
    80004292:	05848513          	addi	a0,s1,88
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	a92080e7          	jalr	-1390(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000429e:	8526                	mv	a0,s1
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	d8a080e7          	jalr	-630(ra) # 8000302a <bwrite>
    brelse(from);
    800042a8:	854e                	mv	a0,s3
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	dbe080e7          	jalr	-578(ra) # 80003068 <brelse>
    brelse(to);
    800042b2:	8526                	mv	a0,s1
    800042b4:	fffff097          	auipc	ra,0xfffff
    800042b8:	db4080e7          	jalr	-588(ra) # 80003068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042bc:	2905                	addiw	s2,s2,1
    800042be:	0a91                	addi	s5,s5,4
    800042c0:	02ca2783          	lw	a5,44(s4)
    800042c4:	f8f94ee3          	blt	s2,a5,80004260 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	c68080e7          	jalr	-920(ra) # 80003f30 <write_head>
    install_trans(0); // Now install writes to home locations
    800042d0:	4501                	li	a0,0
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	cda080e7          	jalr	-806(ra) # 80003fac <install_trans>
    log.lh.n = 0;
    800042da:	0001d797          	auipc	a5,0x1d
    800042de:	fc07a123          	sw	zero,-62(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	c4e080e7          	jalr	-946(ra) # 80003f30 <write_head>
    800042ea:	bdf5                	j	800041e6 <end_op+0x52>

00000000800042ec <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042ec:	1101                	addi	sp,sp,-32
    800042ee:	ec06                	sd	ra,24(sp)
    800042f0:	e822                	sd	s0,16(sp)
    800042f2:	e426                	sd	s1,8(sp)
    800042f4:	e04a                	sd	s2,0(sp)
    800042f6:	1000                	addi	s0,sp,32
    800042f8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042fa:	0001d917          	auipc	s2,0x1d
    800042fe:	f7690913          	addi	s2,s2,-138 # 80021270 <log>
    80004302:	854a                	mv	a0,s2
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	8cc080e7          	jalr	-1844(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000430c:	02c92603          	lw	a2,44(s2)
    80004310:	47f5                	li	a5,29
    80004312:	06c7c563          	blt	a5,a2,8000437c <log_write+0x90>
    80004316:	0001d797          	auipc	a5,0x1d
    8000431a:	f767a783          	lw	a5,-138(a5) # 8002128c <log+0x1c>
    8000431e:	37fd                	addiw	a5,a5,-1
    80004320:	04f65e63          	bge	a2,a5,8000437c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004324:	0001d797          	auipc	a5,0x1d
    80004328:	f6c7a783          	lw	a5,-148(a5) # 80021290 <log+0x20>
    8000432c:	06f05063          	blez	a5,8000438c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004330:	4781                	li	a5,0
    80004332:	06c05563          	blez	a2,8000439c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004336:	44cc                	lw	a1,12(s1)
    80004338:	0001d717          	auipc	a4,0x1d
    8000433c:	f6870713          	addi	a4,a4,-152 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004340:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004342:	4314                	lw	a3,0(a4)
    80004344:	04b68c63          	beq	a3,a1,8000439c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004348:	2785                	addiw	a5,a5,1
    8000434a:	0711                	addi	a4,a4,4
    8000434c:	fef61be3          	bne	a2,a5,80004342 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004350:	0621                	addi	a2,a2,8
    80004352:	060a                	slli	a2,a2,0x2
    80004354:	0001d797          	auipc	a5,0x1d
    80004358:	f1c78793          	addi	a5,a5,-228 # 80021270 <log>
    8000435c:	97b2                	add	a5,a5,a2
    8000435e:	44d8                	lw	a4,12(s1)
    80004360:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004362:	8526                	mv	a0,s1
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	da2080e7          	jalr	-606(ra) # 80003106 <bpin>
    log.lh.n++;
    8000436c:	0001d717          	auipc	a4,0x1d
    80004370:	f0470713          	addi	a4,a4,-252 # 80021270 <log>
    80004374:	575c                	lw	a5,44(a4)
    80004376:	2785                	addiw	a5,a5,1
    80004378:	d75c                	sw	a5,44(a4)
    8000437a:	a82d                	j	800043b4 <log_write+0xc8>
    panic("too big a transaction");
    8000437c:	00004517          	auipc	a0,0x4
    80004380:	34450513          	addi	a0,a0,836 # 800086c0 <syscalls+0x1f8>
    80004384:	ffffc097          	auipc	ra,0xffffc
    80004388:	1b6080e7          	jalr	438(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000438c:	00004517          	auipc	a0,0x4
    80004390:	34c50513          	addi	a0,a0,844 # 800086d8 <syscalls+0x210>
    80004394:	ffffc097          	auipc	ra,0xffffc
    80004398:	1a6080e7          	jalr	422(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    8000439c:	00878693          	addi	a3,a5,8
    800043a0:	068a                	slli	a3,a3,0x2
    800043a2:	0001d717          	auipc	a4,0x1d
    800043a6:	ece70713          	addi	a4,a4,-306 # 80021270 <log>
    800043aa:	9736                	add	a4,a4,a3
    800043ac:	44d4                	lw	a3,12(s1)
    800043ae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043b0:	faf609e3          	beq	a2,a5,80004362 <log_write+0x76>
  }
  release(&log.lock);
    800043b4:	0001d517          	auipc	a0,0x1d
    800043b8:	ebc50513          	addi	a0,a0,-324 # 80021270 <log>
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	8c8080e7          	jalr	-1848(ra) # 80000c84 <release>
}
    800043c4:	60e2                	ld	ra,24(sp)
    800043c6:	6442                	ld	s0,16(sp)
    800043c8:	64a2                	ld	s1,8(sp)
    800043ca:	6902                	ld	s2,0(sp)
    800043cc:	6105                	addi	sp,sp,32
    800043ce:	8082                	ret

00000000800043d0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	e04a                	sd	s2,0(sp)
    800043da:	1000                	addi	s0,sp,32
    800043dc:	84aa                	mv	s1,a0
    800043de:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043e0:	00004597          	auipc	a1,0x4
    800043e4:	31858593          	addi	a1,a1,792 # 800086f8 <syscalls+0x230>
    800043e8:	0521                	addi	a0,a0,8
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	756080e7          	jalr	1878(ra) # 80000b40 <initlock>
  lk->name = name;
    800043f2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043fa:	0204a423          	sw	zero,40(s1)
}
    800043fe:	60e2                	ld	ra,24(sp)
    80004400:	6442                	ld	s0,16(sp)
    80004402:	64a2                	ld	s1,8(sp)
    80004404:	6902                	ld	s2,0(sp)
    80004406:	6105                	addi	sp,sp,32
    80004408:	8082                	ret

000000008000440a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000440a:	1101                	addi	sp,sp,-32
    8000440c:	ec06                	sd	ra,24(sp)
    8000440e:	e822                	sd	s0,16(sp)
    80004410:	e426                	sd	s1,8(sp)
    80004412:	e04a                	sd	s2,0(sp)
    80004414:	1000                	addi	s0,sp,32
    80004416:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004418:	00850913          	addi	s2,a0,8
    8000441c:	854a                	mv	a0,s2
    8000441e:	ffffc097          	auipc	ra,0xffffc
    80004422:	7b2080e7          	jalr	1970(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    80004426:	409c                	lw	a5,0(s1)
    80004428:	cb89                	beqz	a5,8000443a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000442a:	85ca                	mv	a1,s2
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffe097          	auipc	ra,0xffffe
    80004432:	c2c080e7          	jalr	-980(ra) # 8000205a <sleep>
  while (lk->locked) {
    80004436:	409c                	lw	a5,0(s1)
    80004438:	fbed                	bnez	a5,8000442a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000443a:	4785                	li	a5,1
    8000443c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	558080e7          	jalr	1368(ra) # 80001996 <myproc>
    80004446:	591c                	lw	a5,48(a0)
    80004448:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000444a:	854a                	mv	a0,s2
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	838080e7          	jalr	-1992(ra) # 80000c84 <release>
}
    80004454:	60e2                	ld	ra,24(sp)
    80004456:	6442                	ld	s0,16(sp)
    80004458:	64a2                	ld	s1,8(sp)
    8000445a:	6902                	ld	s2,0(sp)
    8000445c:	6105                	addi	sp,sp,32
    8000445e:	8082                	ret

0000000080004460 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004460:	1101                	addi	sp,sp,-32
    80004462:	ec06                	sd	ra,24(sp)
    80004464:	e822                	sd	s0,16(sp)
    80004466:	e426                	sd	s1,8(sp)
    80004468:	e04a                	sd	s2,0(sp)
    8000446a:	1000                	addi	s0,sp,32
    8000446c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000446e:	00850913          	addi	s2,a0,8
    80004472:	854a                	mv	a0,s2
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	75c080e7          	jalr	1884(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    8000447c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004480:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004484:	8526                	mv	a0,s1
    80004486:	ffffe097          	auipc	ra,0xffffe
    8000448a:	d60080e7          	jalr	-672(ra) # 800021e6 <wakeup>
  release(&lk->lk);
    8000448e:	854a                	mv	a0,s2
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	7f4080e7          	jalr	2036(ra) # 80000c84 <release>
}
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	64a2                	ld	s1,8(sp)
    8000449e:	6902                	ld	s2,0(sp)
    800044a0:	6105                	addi	sp,sp,32
    800044a2:	8082                	ret

00000000800044a4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044a4:	7179                	addi	sp,sp,-48
    800044a6:	f406                	sd	ra,40(sp)
    800044a8:	f022                	sd	s0,32(sp)
    800044aa:	ec26                	sd	s1,24(sp)
    800044ac:	e84a                	sd	s2,16(sp)
    800044ae:	e44e                	sd	s3,8(sp)
    800044b0:	1800                	addi	s0,sp,48
    800044b2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044b4:	00850913          	addi	s2,a0,8
    800044b8:	854a                	mv	a0,s2
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	716080e7          	jalr	1814(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c2:	409c                	lw	a5,0(s1)
    800044c4:	ef99                	bnez	a5,800044e2 <holdingsleep+0x3e>
    800044c6:	4481                	li	s1,0
  release(&lk->lk);
    800044c8:	854a                	mv	a0,s2
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	7ba080e7          	jalr	1978(ra) # 80000c84 <release>
  return r;
}
    800044d2:	8526                	mv	a0,s1
    800044d4:	70a2                	ld	ra,40(sp)
    800044d6:	7402                	ld	s0,32(sp)
    800044d8:	64e2                	ld	s1,24(sp)
    800044da:	6942                	ld	s2,16(sp)
    800044dc:	69a2                	ld	s3,8(sp)
    800044de:	6145                	addi	sp,sp,48
    800044e0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044e2:	0284a983          	lw	s3,40(s1)
    800044e6:	ffffd097          	auipc	ra,0xffffd
    800044ea:	4b0080e7          	jalr	1200(ra) # 80001996 <myproc>
    800044ee:	5904                	lw	s1,48(a0)
    800044f0:	413484b3          	sub	s1,s1,s3
    800044f4:	0014b493          	seqz	s1,s1
    800044f8:	bfc1                	j	800044c8 <holdingsleep+0x24>

00000000800044fa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044fa:	1141                	addi	sp,sp,-16
    800044fc:	e406                	sd	ra,8(sp)
    800044fe:	e022                	sd	s0,0(sp)
    80004500:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004502:	00004597          	auipc	a1,0x4
    80004506:	20658593          	addi	a1,a1,518 # 80008708 <syscalls+0x240>
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	eae50513          	addi	a0,a0,-338 # 800213b8 <ftable>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	62e080e7          	jalr	1582(ra) # 80000b40 <initlock>
}
    8000451a:	60a2                	ld	ra,8(sp)
    8000451c:	6402                	ld	s0,0(sp)
    8000451e:	0141                	addi	sp,sp,16
    80004520:	8082                	ret

0000000080004522 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000452c:	0001d517          	auipc	a0,0x1d
    80004530:	e8c50513          	addi	a0,a0,-372 # 800213b8 <ftable>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	69c080e7          	jalr	1692(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453c:	0001d497          	auipc	s1,0x1d
    80004540:	e9448493          	addi	s1,s1,-364 # 800213d0 <ftable+0x18>
    80004544:	0001e717          	auipc	a4,0x1e
    80004548:	e2c70713          	addi	a4,a4,-468 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000454c:	40dc                	lw	a5,4(s1)
    8000454e:	cf99                	beqz	a5,8000456c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004550:	02848493          	addi	s1,s1,40
    80004554:	fee49ce3          	bne	s1,a4,8000454c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004558:	0001d517          	auipc	a0,0x1d
    8000455c:	e6050513          	addi	a0,a0,-416 # 800213b8 <ftable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	724080e7          	jalr	1828(ra) # 80000c84 <release>
  return 0;
    80004568:	4481                	li	s1,0
    8000456a:	a819                	j	80004580 <filealloc+0x5e>
      f->ref = 1;
    8000456c:	4785                	li	a5,1
    8000456e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	e4850513          	addi	a0,a0,-440 # 800213b8 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	70c080e7          	jalr	1804(ra) # 80000c84 <release>
}
    80004580:	8526                	mv	a0,s1
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6105                	addi	sp,sp,32
    8000458a:	8082                	ret

000000008000458c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000458c:	1101                	addi	sp,sp,-32
    8000458e:	ec06                	sd	ra,24(sp)
    80004590:	e822                	sd	s0,16(sp)
    80004592:	e426                	sd	s1,8(sp)
    80004594:	1000                	addi	s0,sp,32
    80004596:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	e2050513          	addi	a0,a0,-480 # 800213b8 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	630080e7          	jalr	1584(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800045a8:	40dc                	lw	a5,4(s1)
    800045aa:	02f05263          	blez	a5,800045ce <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045ae:	2785                	addiw	a5,a5,1
    800045b0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045b2:	0001d517          	auipc	a0,0x1d
    800045b6:	e0650513          	addi	a0,a0,-506 # 800213b8 <ftable>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	6ca080e7          	jalr	1738(ra) # 80000c84 <release>
  return f;
}
    800045c2:	8526                	mv	a0,s1
    800045c4:	60e2                	ld	ra,24(sp)
    800045c6:	6442                	ld	s0,16(sp)
    800045c8:	64a2                	ld	s1,8(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret
    panic("filedup");
    800045ce:	00004517          	auipc	a0,0x4
    800045d2:	14250513          	addi	a0,a0,322 # 80008710 <syscalls+0x248>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	f64080e7          	jalr	-156(ra) # 8000053a <panic>

00000000800045de <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045de:	7139                	addi	sp,sp,-64
    800045e0:	fc06                	sd	ra,56(sp)
    800045e2:	f822                	sd	s0,48(sp)
    800045e4:	f426                	sd	s1,40(sp)
    800045e6:	f04a                	sd	s2,32(sp)
    800045e8:	ec4e                	sd	s3,24(sp)
    800045ea:	e852                	sd	s4,16(sp)
    800045ec:	e456                	sd	s5,8(sp)
    800045ee:	0080                	addi	s0,sp,64
    800045f0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045f2:	0001d517          	auipc	a0,0x1d
    800045f6:	dc650513          	addi	a0,a0,-570 # 800213b8 <ftable>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	5d6080e7          	jalr	1494(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004602:	40dc                	lw	a5,4(s1)
    80004604:	06f05163          	blez	a5,80004666 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004608:	37fd                	addiw	a5,a5,-1
    8000460a:	0007871b          	sext.w	a4,a5
    8000460e:	c0dc                	sw	a5,4(s1)
    80004610:	06e04363          	bgtz	a4,80004676 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004614:	0004a903          	lw	s2,0(s1)
    80004618:	0094ca83          	lbu	s5,9(s1)
    8000461c:	0104ba03          	ld	s4,16(s1)
    80004620:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004624:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004628:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000462c:	0001d517          	auipc	a0,0x1d
    80004630:	d8c50513          	addi	a0,a0,-628 # 800213b8 <ftable>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	650080e7          	jalr	1616(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    8000463c:	4785                	li	a5,1
    8000463e:	04f90d63          	beq	s2,a5,80004698 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004642:	3979                	addiw	s2,s2,-2
    80004644:	4785                	li	a5,1
    80004646:	0527e063          	bltu	a5,s2,80004686 <fileclose+0xa8>
    begin_op();
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	acc080e7          	jalr	-1332(ra) # 80004116 <begin_op>
    iput(ff.ip);
    80004652:	854e                	mv	a0,s3
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	2a0080e7          	jalr	672(ra) # 800038f4 <iput>
    end_op();
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	b38080e7          	jalr	-1224(ra) # 80004194 <end_op>
    80004664:	a00d                	j	80004686 <fileclose+0xa8>
    panic("fileclose");
    80004666:	00004517          	auipc	a0,0x4
    8000466a:	0b250513          	addi	a0,a0,178 # 80008718 <syscalls+0x250>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	ecc080e7          	jalr	-308(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004676:	0001d517          	auipc	a0,0x1d
    8000467a:	d4250513          	addi	a0,a0,-702 # 800213b8 <ftable>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	606080e7          	jalr	1542(ra) # 80000c84 <release>
  }
}
    80004686:	70e2                	ld	ra,56(sp)
    80004688:	7442                	ld	s0,48(sp)
    8000468a:	74a2                	ld	s1,40(sp)
    8000468c:	7902                	ld	s2,32(sp)
    8000468e:	69e2                	ld	s3,24(sp)
    80004690:	6a42                	ld	s4,16(sp)
    80004692:	6aa2                	ld	s5,8(sp)
    80004694:	6121                	addi	sp,sp,64
    80004696:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004698:	85d6                	mv	a1,s5
    8000469a:	8552                	mv	a0,s4
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	34c080e7          	jalr	844(ra) # 800049e8 <pipeclose>
    800046a4:	b7cd                	j	80004686 <fileclose+0xa8>

00000000800046a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a6:	715d                	addi	sp,sp,-80
    800046a8:	e486                	sd	ra,72(sp)
    800046aa:	e0a2                	sd	s0,64(sp)
    800046ac:	fc26                	sd	s1,56(sp)
    800046ae:	f84a                	sd	s2,48(sp)
    800046b0:	f44e                	sd	s3,40(sp)
    800046b2:	0880                	addi	s0,sp,80
    800046b4:	84aa                	mv	s1,a0
    800046b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046b8:	ffffd097          	auipc	ra,0xffffd
    800046bc:	2de080e7          	jalr	734(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046c0:	409c                	lw	a5,0(s1)
    800046c2:	37f9                	addiw	a5,a5,-2
    800046c4:	4705                	li	a4,1
    800046c6:	04f76763          	bltu	a4,a5,80004714 <filestat+0x6e>
    800046ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800046cc:	6c88                	ld	a0,24(s1)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	06c080e7          	jalr	108(ra) # 8000373a <ilock>
    stati(f->ip, &st);
    800046d6:	fb840593          	addi	a1,s0,-72
    800046da:	6c88                	ld	a0,24(s1)
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	2e8080e7          	jalr	744(ra) # 800039c4 <stati>
    iunlock(f->ip);
    800046e4:	6c88                	ld	a0,24(s1)
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	116080e7          	jalr	278(ra) # 800037fc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046ee:	46e1                	li	a3,24
    800046f0:	fb840613          	addi	a2,s0,-72
    800046f4:	85ce                	mv	a1,s3
    800046f6:	05093503          	ld	a0,80(s2)
    800046fa:	ffffd097          	auipc	ra,0xffffd
    800046fe:	f60080e7          	jalr	-160(ra) # 8000165a <copyout>
    80004702:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004706:	60a6                	ld	ra,72(sp)
    80004708:	6406                	ld	s0,64(sp)
    8000470a:	74e2                	ld	s1,56(sp)
    8000470c:	7942                	ld	s2,48(sp)
    8000470e:	79a2                	ld	s3,40(sp)
    80004710:	6161                	addi	sp,sp,80
    80004712:	8082                	ret
  return -1;
    80004714:	557d                	li	a0,-1
    80004716:	bfc5                	j	80004706 <filestat+0x60>

0000000080004718 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004718:	7179                	addi	sp,sp,-48
    8000471a:	f406                	sd	ra,40(sp)
    8000471c:	f022                	sd	s0,32(sp)
    8000471e:	ec26                	sd	s1,24(sp)
    80004720:	e84a                	sd	s2,16(sp)
    80004722:	e44e                	sd	s3,8(sp)
    80004724:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004726:	00854783          	lbu	a5,8(a0)
    8000472a:	c3d5                	beqz	a5,800047ce <fileread+0xb6>
    8000472c:	84aa                	mv	s1,a0
    8000472e:	89ae                	mv	s3,a1
    80004730:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004732:	411c                	lw	a5,0(a0)
    80004734:	4705                	li	a4,1
    80004736:	04e78963          	beq	a5,a4,80004788 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000473a:	470d                	li	a4,3
    8000473c:	04e78d63          	beq	a5,a4,80004796 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004740:	4709                	li	a4,2
    80004742:	06e79e63          	bne	a5,a4,800047be <fileread+0xa6>
    ilock(f->ip);
    80004746:	6d08                	ld	a0,24(a0)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	ff2080e7          	jalr	-14(ra) # 8000373a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004750:	874a                	mv	a4,s2
    80004752:	5094                	lw	a3,32(s1)
    80004754:	864e                	mv	a2,s3
    80004756:	4585                	li	a1,1
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	294080e7          	jalr	660(ra) # 800039ee <readi>
    80004762:	892a                	mv	s2,a0
    80004764:	00a05563          	blez	a0,8000476e <fileread+0x56>
      f->off += r;
    80004768:	509c                	lw	a5,32(s1)
    8000476a:	9fa9                	addw	a5,a5,a0
    8000476c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000476e:	6c88                	ld	a0,24(s1)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	08c080e7          	jalr	140(ra) # 800037fc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004778:	854a                	mv	a0,s2
    8000477a:	70a2                	ld	ra,40(sp)
    8000477c:	7402                	ld	s0,32(sp)
    8000477e:	64e2                	ld	s1,24(sp)
    80004780:	6942                	ld	s2,16(sp)
    80004782:	69a2                	ld	s3,8(sp)
    80004784:	6145                	addi	sp,sp,48
    80004786:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004788:	6908                	ld	a0,16(a0)
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	3c0080e7          	jalr	960(ra) # 80004b4a <piperead>
    80004792:	892a                	mv	s2,a0
    80004794:	b7d5                	j	80004778 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004796:	02451783          	lh	a5,36(a0)
    8000479a:	03079693          	slli	a3,a5,0x30
    8000479e:	92c1                	srli	a3,a3,0x30
    800047a0:	4725                	li	a4,9
    800047a2:	02d76863          	bltu	a4,a3,800047d2 <fileread+0xba>
    800047a6:	0792                	slli	a5,a5,0x4
    800047a8:	0001d717          	auipc	a4,0x1d
    800047ac:	b7070713          	addi	a4,a4,-1168 # 80021318 <devsw>
    800047b0:	97ba                	add	a5,a5,a4
    800047b2:	639c                	ld	a5,0(a5)
    800047b4:	c38d                	beqz	a5,800047d6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b6:	4505                	li	a0,1
    800047b8:	9782                	jalr	a5
    800047ba:	892a                	mv	s2,a0
    800047bc:	bf75                	j	80004778 <fileread+0x60>
    panic("fileread");
    800047be:	00004517          	auipc	a0,0x4
    800047c2:	f6a50513          	addi	a0,a0,-150 # 80008728 <syscalls+0x260>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	d74080e7          	jalr	-652(ra) # 8000053a <panic>
    return -1;
    800047ce:	597d                	li	s2,-1
    800047d0:	b765                	j	80004778 <fileread+0x60>
      return -1;
    800047d2:	597d                	li	s2,-1
    800047d4:	b755                	j	80004778 <fileread+0x60>
    800047d6:	597d                	li	s2,-1
    800047d8:	b745                	j	80004778 <fileread+0x60>

00000000800047da <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047da:	715d                	addi	sp,sp,-80
    800047dc:	e486                	sd	ra,72(sp)
    800047de:	e0a2                	sd	s0,64(sp)
    800047e0:	fc26                	sd	s1,56(sp)
    800047e2:	f84a                	sd	s2,48(sp)
    800047e4:	f44e                	sd	s3,40(sp)
    800047e6:	f052                	sd	s4,32(sp)
    800047e8:	ec56                	sd	s5,24(sp)
    800047ea:	e85a                	sd	s6,16(sp)
    800047ec:	e45e                	sd	s7,8(sp)
    800047ee:	e062                	sd	s8,0(sp)
    800047f0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047f2:	00954783          	lbu	a5,9(a0)
    800047f6:	10078663          	beqz	a5,80004902 <filewrite+0x128>
    800047fa:	892a                	mv	s2,a0
    800047fc:	8b2e                	mv	s6,a1
    800047fe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004800:	411c                	lw	a5,0(a0)
    80004802:	4705                	li	a4,1
    80004804:	02e78263          	beq	a5,a4,80004828 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004808:	470d                	li	a4,3
    8000480a:	02e78663          	beq	a5,a4,80004836 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000480e:	4709                	li	a4,2
    80004810:	0ee79163          	bne	a5,a4,800048f2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004814:	0ac05d63          	blez	a2,800048ce <filewrite+0xf4>
    int i = 0;
    80004818:	4981                	li	s3,0
    8000481a:	6b85                	lui	s7,0x1
    8000481c:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004820:	6c05                	lui	s8,0x1
    80004822:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004826:	a861                	j	800048be <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004828:	6908                	ld	a0,16(a0)
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	22e080e7          	jalr	558(ra) # 80004a58 <pipewrite>
    80004832:	8a2a                	mv	s4,a0
    80004834:	a045                	j	800048d4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004836:	02451783          	lh	a5,36(a0)
    8000483a:	03079693          	slli	a3,a5,0x30
    8000483e:	92c1                	srli	a3,a3,0x30
    80004840:	4725                	li	a4,9
    80004842:	0cd76263          	bltu	a4,a3,80004906 <filewrite+0x12c>
    80004846:	0792                	slli	a5,a5,0x4
    80004848:	0001d717          	auipc	a4,0x1d
    8000484c:	ad070713          	addi	a4,a4,-1328 # 80021318 <devsw>
    80004850:	97ba                	add	a5,a5,a4
    80004852:	679c                	ld	a5,8(a5)
    80004854:	cbdd                	beqz	a5,8000490a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004856:	4505                	li	a0,1
    80004858:	9782                	jalr	a5
    8000485a:	8a2a                	mv	s4,a0
    8000485c:	a8a5                	j	800048d4 <filewrite+0xfa>
    8000485e:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004862:	00000097          	auipc	ra,0x0
    80004866:	8b4080e7          	jalr	-1868(ra) # 80004116 <begin_op>
      ilock(f->ip);
    8000486a:	01893503          	ld	a0,24(s2)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	ecc080e7          	jalr	-308(ra) # 8000373a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004876:	8756                	mv	a4,s5
    80004878:	02092683          	lw	a3,32(s2)
    8000487c:	01698633          	add	a2,s3,s6
    80004880:	4585                	li	a1,1
    80004882:	01893503          	ld	a0,24(s2)
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	260080e7          	jalr	608(ra) # 80003ae6 <writei>
    8000488e:	84aa                	mv	s1,a0
    80004890:	00a05763          	blez	a0,8000489e <filewrite+0xc4>
        f->off += r;
    80004894:	02092783          	lw	a5,32(s2)
    80004898:	9fa9                	addw	a5,a5,a0
    8000489a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000489e:	01893503          	ld	a0,24(s2)
    800048a2:	fffff097          	auipc	ra,0xfffff
    800048a6:	f5a080e7          	jalr	-166(ra) # 800037fc <iunlock>
      end_op();
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	8ea080e7          	jalr	-1814(ra) # 80004194 <end_op>

      if(r != n1){
    800048b2:	009a9f63          	bne	s5,s1,800048d0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048b6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048ba:	0149db63          	bge	s3,s4,800048d0 <filewrite+0xf6>
      int n1 = n - i;
    800048be:	413a04bb          	subw	s1,s4,s3
    800048c2:	0004879b          	sext.w	a5,s1
    800048c6:	f8fbdce3          	bge	s7,a5,8000485e <filewrite+0x84>
    800048ca:	84e2                	mv	s1,s8
    800048cc:	bf49                	j	8000485e <filewrite+0x84>
    int i = 0;
    800048ce:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048d0:	013a1f63          	bne	s4,s3,800048ee <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048d4:	8552                	mv	a0,s4
    800048d6:	60a6                	ld	ra,72(sp)
    800048d8:	6406                	ld	s0,64(sp)
    800048da:	74e2                	ld	s1,56(sp)
    800048dc:	7942                	ld	s2,48(sp)
    800048de:	79a2                	ld	s3,40(sp)
    800048e0:	7a02                	ld	s4,32(sp)
    800048e2:	6ae2                	ld	s5,24(sp)
    800048e4:	6b42                	ld	s6,16(sp)
    800048e6:	6ba2                	ld	s7,8(sp)
    800048e8:	6c02                	ld	s8,0(sp)
    800048ea:	6161                	addi	sp,sp,80
    800048ec:	8082                	ret
    ret = (i == n ? n : -1);
    800048ee:	5a7d                	li	s4,-1
    800048f0:	b7d5                	j	800048d4 <filewrite+0xfa>
    panic("filewrite");
    800048f2:	00004517          	auipc	a0,0x4
    800048f6:	e4650513          	addi	a0,a0,-442 # 80008738 <syscalls+0x270>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	c40080e7          	jalr	-960(ra) # 8000053a <panic>
    return -1;
    80004902:	5a7d                	li	s4,-1
    80004904:	bfc1                	j	800048d4 <filewrite+0xfa>
      return -1;
    80004906:	5a7d                	li	s4,-1
    80004908:	b7f1                	j	800048d4 <filewrite+0xfa>
    8000490a:	5a7d                	li	s4,-1
    8000490c:	b7e1                	j	800048d4 <filewrite+0xfa>

000000008000490e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000490e:	7179                	addi	sp,sp,-48
    80004910:	f406                	sd	ra,40(sp)
    80004912:	f022                	sd	s0,32(sp)
    80004914:	ec26                	sd	s1,24(sp)
    80004916:	e84a                	sd	s2,16(sp)
    80004918:	e44e                	sd	s3,8(sp)
    8000491a:	e052                	sd	s4,0(sp)
    8000491c:	1800                	addi	s0,sp,48
    8000491e:	84aa                	mv	s1,a0
    80004920:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004922:	0005b023          	sd	zero,0(a1)
    80004926:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	bf8080e7          	jalr	-1032(ra) # 80004522 <filealloc>
    80004932:	e088                	sd	a0,0(s1)
    80004934:	c551                	beqz	a0,800049c0 <pipealloc+0xb2>
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	bec080e7          	jalr	-1044(ra) # 80004522 <filealloc>
    8000493e:	00aa3023          	sd	a0,0(s4)
    80004942:	c92d                	beqz	a0,800049b4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	19c080e7          	jalr	412(ra) # 80000ae0 <kalloc>
    8000494c:	892a                	mv	s2,a0
    8000494e:	c125                	beqz	a0,800049ae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004950:	4985                	li	s3,1
    80004952:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004956:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000495a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000495e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004962:	00004597          	auipc	a1,0x4
    80004966:	de658593          	addi	a1,a1,-538 # 80008748 <syscalls+0x280>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	1d6080e7          	jalr	470(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004972:	609c                	ld	a5,0(s1)
    80004974:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004978:	609c                	ld	a5,0(s1)
    8000497a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000497e:	609c                	ld	a5,0(s1)
    80004980:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004984:	609c                	ld	a5,0(s1)
    80004986:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000498a:	000a3783          	ld	a5,0(s4)
    8000498e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004992:	000a3783          	ld	a5,0(s4)
    80004996:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000499a:	000a3783          	ld	a5,0(s4)
    8000499e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049a2:	000a3783          	ld	a5,0(s4)
    800049a6:	0127b823          	sd	s2,16(a5)
  return 0;
    800049aa:	4501                	li	a0,0
    800049ac:	a025                	j	800049d4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049ae:	6088                	ld	a0,0(s1)
    800049b0:	e501                	bnez	a0,800049b8 <pipealloc+0xaa>
    800049b2:	a039                	j	800049c0 <pipealloc+0xb2>
    800049b4:	6088                	ld	a0,0(s1)
    800049b6:	c51d                	beqz	a0,800049e4 <pipealloc+0xd6>
    fileclose(*f0);
    800049b8:	00000097          	auipc	ra,0x0
    800049bc:	c26080e7          	jalr	-986(ra) # 800045de <fileclose>
  if(*f1)
    800049c0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049c4:	557d                	li	a0,-1
  if(*f1)
    800049c6:	c799                	beqz	a5,800049d4 <pipealloc+0xc6>
    fileclose(*f1);
    800049c8:	853e                	mv	a0,a5
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	c14080e7          	jalr	-1004(ra) # 800045de <fileclose>
  return -1;
    800049d2:	557d                	li	a0,-1
}
    800049d4:	70a2                	ld	ra,40(sp)
    800049d6:	7402                	ld	s0,32(sp)
    800049d8:	64e2                	ld	s1,24(sp)
    800049da:	6942                	ld	s2,16(sp)
    800049dc:	69a2                	ld	s3,8(sp)
    800049de:	6a02                	ld	s4,0(sp)
    800049e0:	6145                	addi	sp,sp,48
    800049e2:	8082                	ret
  return -1;
    800049e4:	557d                	li	a0,-1
    800049e6:	b7fd                	j	800049d4 <pipealloc+0xc6>

00000000800049e8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049e8:	1101                	addi	sp,sp,-32
    800049ea:	ec06                	sd	ra,24(sp)
    800049ec:	e822                	sd	s0,16(sp)
    800049ee:	e426                	sd	s1,8(sp)
    800049f0:	e04a                	sd	s2,0(sp)
    800049f2:	1000                	addi	s0,sp,32
    800049f4:	84aa                	mv	s1,a0
    800049f6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	1d8080e7          	jalr	472(ra) # 80000bd0 <acquire>
  if(writable){
    80004a00:	02090d63          	beqz	s2,80004a3a <pipeclose+0x52>
    pi->writeopen = 0;
    80004a04:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a08:	21848513          	addi	a0,s1,536
    80004a0c:	ffffd097          	auipc	ra,0xffffd
    80004a10:	7da080e7          	jalr	2010(ra) # 800021e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a14:	2204b783          	ld	a5,544(s1)
    80004a18:	eb95                	bnez	a5,80004a4c <pipeclose+0x64>
    release(&pi->lock);
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	268080e7          	jalr	616(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004a24:	8526                	mv	a0,s1
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	fbc080e7          	jalr	-68(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004a2e:	60e2                	ld	ra,24(sp)
    80004a30:	6442                	ld	s0,16(sp)
    80004a32:	64a2                	ld	s1,8(sp)
    80004a34:	6902                	ld	s2,0(sp)
    80004a36:	6105                	addi	sp,sp,32
    80004a38:	8082                	ret
    pi->readopen = 0;
    80004a3a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a3e:	21c48513          	addi	a0,s1,540
    80004a42:	ffffd097          	auipc	ra,0xffffd
    80004a46:	7a4080e7          	jalr	1956(ra) # 800021e6 <wakeup>
    80004a4a:	b7e9                	j	80004a14 <pipeclose+0x2c>
    release(&pi->lock);
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	236080e7          	jalr	566(ra) # 80000c84 <release>
}
    80004a56:	bfe1                	j	80004a2e <pipeclose+0x46>

0000000080004a58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a58:	711d                	addi	sp,sp,-96
    80004a5a:	ec86                	sd	ra,88(sp)
    80004a5c:	e8a2                	sd	s0,80(sp)
    80004a5e:	e4a6                	sd	s1,72(sp)
    80004a60:	e0ca                	sd	s2,64(sp)
    80004a62:	fc4e                	sd	s3,56(sp)
    80004a64:	f852                	sd	s4,48(sp)
    80004a66:	f456                	sd	s5,40(sp)
    80004a68:	f05a                	sd	s6,32(sp)
    80004a6a:	ec5e                	sd	s7,24(sp)
    80004a6c:	e862                	sd	s8,16(sp)
    80004a6e:	1080                	addi	s0,sp,96
    80004a70:	84aa                	mv	s1,a0
    80004a72:	8aae                	mv	s5,a1
    80004a74:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a76:	ffffd097          	auipc	ra,0xffffd
    80004a7a:	f20080e7          	jalr	-224(ra) # 80001996 <myproc>
    80004a7e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	14e080e7          	jalr	334(ra) # 80000bd0 <acquire>
  while(i < n){
    80004a8a:	0b405363          	blez	s4,80004b30 <pipewrite+0xd8>
  int i = 0;
    80004a8e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a90:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a92:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a96:	21c48b93          	addi	s7,s1,540
    80004a9a:	a089                	j	80004adc <pipewrite+0x84>
      release(&pi->lock);
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	1e6080e7          	jalr	486(ra) # 80000c84 <release>
      return -1;
    80004aa6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004aa8:	854a                	mv	a0,s2
    80004aaa:	60e6                	ld	ra,88(sp)
    80004aac:	6446                	ld	s0,80(sp)
    80004aae:	64a6                	ld	s1,72(sp)
    80004ab0:	6906                	ld	s2,64(sp)
    80004ab2:	79e2                	ld	s3,56(sp)
    80004ab4:	7a42                	ld	s4,48(sp)
    80004ab6:	7aa2                	ld	s5,40(sp)
    80004ab8:	7b02                	ld	s6,32(sp)
    80004aba:	6be2                	ld	s7,24(sp)
    80004abc:	6c42                	ld	s8,16(sp)
    80004abe:	6125                	addi	sp,sp,96
    80004ac0:	8082                	ret
      wakeup(&pi->nread);
    80004ac2:	8562                	mv	a0,s8
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	722080e7          	jalr	1826(ra) # 800021e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	85a6                	mv	a1,s1
    80004ace:	855e                	mv	a0,s7
    80004ad0:	ffffd097          	auipc	ra,0xffffd
    80004ad4:	58a080e7          	jalr	1418(ra) # 8000205a <sleep>
  while(i < n){
    80004ad8:	05495d63          	bge	s2,s4,80004b32 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004adc:	2204a783          	lw	a5,544(s1)
    80004ae0:	dfd5                	beqz	a5,80004a9c <pipewrite+0x44>
    80004ae2:	0289a783          	lw	a5,40(s3)
    80004ae6:	fbdd                	bnez	a5,80004a9c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ae8:	2184a783          	lw	a5,536(s1)
    80004aec:	21c4a703          	lw	a4,540(s1)
    80004af0:	2007879b          	addiw	a5,a5,512
    80004af4:	fcf707e3          	beq	a4,a5,80004ac2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af8:	4685                	li	a3,1
    80004afa:	01590633          	add	a2,s2,s5
    80004afe:	faf40593          	addi	a1,s0,-81
    80004b02:	0509b503          	ld	a0,80(s3)
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	be0080e7          	jalr	-1056(ra) # 800016e6 <copyin>
    80004b0e:	03650263          	beq	a0,s6,80004b32 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b12:	21c4a783          	lw	a5,540(s1)
    80004b16:	0017871b          	addiw	a4,a5,1
    80004b1a:	20e4ae23          	sw	a4,540(s1)
    80004b1e:	1ff7f793          	andi	a5,a5,511
    80004b22:	97a6                	add	a5,a5,s1
    80004b24:	faf44703          	lbu	a4,-81(s0)
    80004b28:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b2c:	2905                	addiw	s2,s2,1
    80004b2e:	b76d                	j	80004ad8 <pipewrite+0x80>
  int i = 0;
    80004b30:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b32:	21848513          	addi	a0,s1,536
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	6b0080e7          	jalr	1712(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004b3e:	8526                	mv	a0,s1
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	144080e7          	jalr	324(ra) # 80000c84 <release>
  return i;
    80004b48:	b785                	j	80004aa8 <pipewrite+0x50>

0000000080004b4a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b4a:	715d                	addi	sp,sp,-80
    80004b4c:	e486                	sd	ra,72(sp)
    80004b4e:	e0a2                	sd	s0,64(sp)
    80004b50:	fc26                	sd	s1,56(sp)
    80004b52:	f84a                	sd	s2,48(sp)
    80004b54:	f44e                	sd	s3,40(sp)
    80004b56:	f052                	sd	s4,32(sp)
    80004b58:	ec56                	sd	s5,24(sp)
    80004b5a:	e85a                	sd	s6,16(sp)
    80004b5c:	0880                	addi	s0,sp,80
    80004b5e:	84aa                	mv	s1,a0
    80004b60:	892e                	mv	s2,a1
    80004b62:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	e32080e7          	jalr	-462(ra) # 80001996 <myproc>
    80004b6c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	060080e7          	jalr	96(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b78:	2184a703          	lw	a4,536(s1)
    80004b7c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b80:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b84:	02f71463          	bne	a4,a5,80004bac <piperead+0x62>
    80004b88:	2244a783          	lw	a5,548(s1)
    80004b8c:	c385                	beqz	a5,80004bac <piperead+0x62>
    if(pr->killed){
    80004b8e:	028a2783          	lw	a5,40(s4)
    80004b92:	ebc9                	bnez	a5,80004c24 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b94:	85a6                	mv	a1,s1
    80004b96:	854e                	mv	a0,s3
    80004b98:	ffffd097          	auipc	ra,0xffffd
    80004b9c:	4c2080e7          	jalr	1218(ra) # 8000205a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba0:	2184a703          	lw	a4,536(s1)
    80004ba4:	21c4a783          	lw	a5,540(s1)
    80004ba8:	fef700e3          	beq	a4,a5,80004b88 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bac:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bae:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb0:	05505463          	blez	s5,80004bf8 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004bb4:	2184a783          	lw	a5,536(s1)
    80004bb8:	21c4a703          	lw	a4,540(s1)
    80004bbc:	02f70e63          	beq	a4,a5,80004bf8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bc0:	0017871b          	addiw	a4,a5,1
    80004bc4:	20e4ac23          	sw	a4,536(s1)
    80004bc8:	1ff7f793          	andi	a5,a5,511
    80004bcc:	97a6                	add	a5,a5,s1
    80004bce:	0187c783          	lbu	a5,24(a5)
    80004bd2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bd6:	4685                	li	a3,1
    80004bd8:	fbf40613          	addi	a2,s0,-65
    80004bdc:	85ca                	mv	a1,s2
    80004bde:	050a3503          	ld	a0,80(s4)
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	a78080e7          	jalr	-1416(ra) # 8000165a <copyout>
    80004bea:	01650763          	beq	a0,s6,80004bf8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bee:	2985                	addiw	s3,s3,1
    80004bf0:	0905                	addi	s2,s2,1
    80004bf2:	fd3a91e3          	bne	s5,s3,80004bb4 <piperead+0x6a>
    80004bf6:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bf8:	21c48513          	addi	a0,s1,540
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	5ea080e7          	jalr	1514(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	07e080e7          	jalr	126(ra) # 80000c84 <release>
  return i;
}
    80004c0e:	854e                	mv	a0,s3
    80004c10:	60a6                	ld	ra,72(sp)
    80004c12:	6406                	ld	s0,64(sp)
    80004c14:	74e2                	ld	s1,56(sp)
    80004c16:	7942                	ld	s2,48(sp)
    80004c18:	79a2                	ld	s3,40(sp)
    80004c1a:	7a02                	ld	s4,32(sp)
    80004c1c:	6ae2                	ld	s5,24(sp)
    80004c1e:	6b42                	ld	s6,16(sp)
    80004c20:	6161                	addi	sp,sp,80
    80004c22:	8082                	ret
      release(&pi->lock);
    80004c24:	8526                	mv	a0,s1
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	05e080e7          	jalr	94(ra) # 80000c84 <release>
      return -1;
    80004c2e:	59fd                	li	s3,-1
    80004c30:	bff9                	j	80004c0e <piperead+0xc4>

0000000080004c32 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c32:	de010113          	addi	sp,sp,-544
    80004c36:	20113c23          	sd	ra,536(sp)
    80004c3a:	20813823          	sd	s0,528(sp)
    80004c3e:	20913423          	sd	s1,520(sp)
    80004c42:	21213023          	sd	s2,512(sp)
    80004c46:	ffce                	sd	s3,504(sp)
    80004c48:	fbd2                	sd	s4,496(sp)
    80004c4a:	f7d6                	sd	s5,488(sp)
    80004c4c:	f3da                	sd	s6,480(sp)
    80004c4e:	efde                	sd	s7,472(sp)
    80004c50:	ebe2                	sd	s8,464(sp)
    80004c52:	e7e6                	sd	s9,456(sp)
    80004c54:	e3ea                	sd	s10,448(sp)
    80004c56:	ff6e                	sd	s11,440(sp)
    80004c58:	1400                	addi	s0,sp,544
    80004c5a:	892a                	mv	s2,a0
    80004c5c:	dea43423          	sd	a0,-536(s0)
    80004c60:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	d32080e7          	jalr	-718(ra) # 80001996 <myproc>
    80004c6c:	84aa                	mv	s1,a0

  begin_op();
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	4a8080e7          	jalr	1192(ra) # 80004116 <begin_op>

  if((ip = namei(path)) == 0){
    80004c76:	854a                	mv	a0,s2
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	27e080e7          	jalr	638(ra) # 80003ef6 <namei>
    80004c80:	c93d                	beqz	a0,80004cf6 <exec+0xc4>
    80004c82:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	ab6080e7          	jalr	-1354(ra) # 8000373a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c8c:	04000713          	li	a4,64
    80004c90:	4681                	li	a3,0
    80004c92:	e5040613          	addi	a2,s0,-432
    80004c96:	4581                	li	a1,0
    80004c98:	8556                	mv	a0,s5
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	d54080e7          	jalr	-684(ra) # 800039ee <readi>
    80004ca2:	04000793          	li	a5,64
    80004ca6:	00f51a63          	bne	a0,a5,80004cba <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004caa:	e5042703          	lw	a4,-432(s0)
    80004cae:	464c47b7          	lui	a5,0x464c4
    80004cb2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cb6:	04f70663          	beq	a4,a5,80004d02 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cba:	8556                	mv	a0,s5
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	ce0080e7          	jalr	-800(ra) # 8000399c <iunlockput>
    end_op();
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	4d0080e7          	jalr	1232(ra) # 80004194 <end_op>
  }
  return -1;
    80004ccc:	557d                	li	a0,-1
}
    80004cce:	21813083          	ld	ra,536(sp)
    80004cd2:	21013403          	ld	s0,528(sp)
    80004cd6:	20813483          	ld	s1,520(sp)
    80004cda:	20013903          	ld	s2,512(sp)
    80004cde:	79fe                	ld	s3,504(sp)
    80004ce0:	7a5e                	ld	s4,496(sp)
    80004ce2:	7abe                	ld	s5,488(sp)
    80004ce4:	7b1e                	ld	s6,480(sp)
    80004ce6:	6bfe                	ld	s7,472(sp)
    80004ce8:	6c5e                	ld	s8,464(sp)
    80004cea:	6cbe                	ld	s9,456(sp)
    80004cec:	6d1e                	ld	s10,448(sp)
    80004cee:	7dfa                	ld	s11,440(sp)
    80004cf0:	22010113          	addi	sp,sp,544
    80004cf4:	8082                	ret
    end_op();
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	49e080e7          	jalr	1182(ra) # 80004194 <end_op>
    return -1;
    80004cfe:	557d                	li	a0,-1
    80004d00:	b7f9                	j	80004cce <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	d56080e7          	jalr	-682(ra) # 80001a5a <proc_pagetable>
    80004d0c:	8b2a                	mv	s6,a0
    80004d0e:	d555                	beqz	a0,80004cba <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d10:	e7042783          	lw	a5,-400(s0)
    80004d14:	e8845703          	lhu	a4,-376(s0)
    80004d18:	c735                	beqz	a4,80004d84 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d1a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1c:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004d20:	6a05                	lui	s4,0x1
    80004d22:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d26:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d2a:	6d85                	lui	s11,0x1
    80004d2c:	7d7d                	lui	s10,0xfffff
    80004d2e:	ac1d                	j	80004f64 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d30:	00004517          	auipc	a0,0x4
    80004d34:	a2050513          	addi	a0,a0,-1504 # 80008750 <syscalls+0x288>
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	802080e7          	jalr	-2046(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d40:	874a                	mv	a4,s2
    80004d42:	009c86bb          	addw	a3,s9,s1
    80004d46:	4581                	li	a1,0
    80004d48:	8556                	mv	a0,s5
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	ca4080e7          	jalr	-860(ra) # 800039ee <readi>
    80004d52:	2501                	sext.w	a0,a0
    80004d54:	1aa91863          	bne	s2,a0,80004f04 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d58:	009d84bb          	addw	s1,s11,s1
    80004d5c:	013d09bb          	addw	s3,s10,s3
    80004d60:	1f74f263          	bgeu	s1,s7,80004f44 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d64:	02049593          	slli	a1,s1,0x20
    80004d68:	9181                	srli	a1,a1,0x20
    80004d6a:	95e2                	add	a1,a1,s8
    80004d6c:	855a                	mv	a0,s6
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	2e4080e7          	jalr	740(ra) # 80001052 <walkaddr>
    80004d76:	862a                	mv	a2,a0
    if(pa == 0)
    80004d78:	dd45                	beqz	a0,80004d30 <exec+0xfe>
      n = PGSIZE;
    80004d7a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d7c:	fd49f2e3          	bgeu	s3,s4,80004d40 <exec+0x10e>
      n = sz - i;
    80004d80:	894e                	mv	s2,s3
    80004d82:	bf7d                	j	80004d40 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d84:	4481                	li	s1,0
  iunlockput(ip);
    80004d86:	8556                	mv	a0,s5
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	c14080e7          	jalr	-1004(ra) # 8000399c <iunlockput>
  end_op();
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	404080e7          	jalr	1028(ra) # 80004194 <end_op>
  p = myproc();
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	bfe080e7          	jalr	-1026(ra) # 80001996 <myproc>
    80004da0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004da2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004da6:	6785                	lui	a5,0x1
    80004da8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004daa:	97a6                	add	a5,a5,s1
    80004dac:	777d                	lui	a4,0xfffff
    80004dae:	8ff9                	and	a5,a5,a4
    80004db0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004db4:	6609                	lui	a2,0x2
    80004db6:	963e                	add	a2,a2,a5
    80004db8:	85be                	mv	a1,a5
    80004dba:	855a                	mv	a0,s6
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	64a080e7          	jalr	1610(ra) # 80001406 <uvmalloc>
    80004dc4:	8c2a                	mv	s8,a0
  ip = 0;
    80004dc6:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dc8:	12050e63          	beqz	a0,80004f04 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dcc:	75f9                	lui	a1,0xffffe
    80004dce:	95aa                	add	a1,a1,a0
    80004dd0:	855a                	mv	a0,s6
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	856080e7          	jalr	-1962(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004dda:	7afd                	lui	s5,0xfffff
    80004ddc:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dde:	df043783          	ld	a5,-528(s0)
    80004de2:	6388                	ld	a0,0(a5)
    80004de4:	c925                	beqz	a0,80004e54 <exec+0x222>
    80004de6:	e9040993          	addi	s3,s0,-368
    80004dea:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dee:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004df0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004df2:	ffffc097          	auipc	ra,0xffffc
    80004df6:	056080e7          	jalr	86(ra) # 80000e48 <strlen>
    80004dfa:	0015079b          	addiw	a5,a0,1
    80004dfe:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e02:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e06:	13596363          	bltu	s2,s5,80004f2c <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e0a:	df043d83          	ld	s11,-528(s0)
    80004e0e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e12:	8552                	mv	a0,s4
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	034080e7          	jalr	52(ra) # 80000e48 <strlen>
    80004e1c:	0015069b          	addiw	a3,a0,1
    80004e20:	8652                	mv	a2,s4
    80004e22:	85ca                	mv	a1,s2
    80004e24:	855a                	mv	a0,s6
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	834080e7          	jalr	-1996(ra) # 8000165a <copyout>
    80004e2e:	10054363          	bltz	a0,80004f34 <exec+0x302>
    ustack[argc] = sp;
    80004e32:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e36:	0485                	addi	s1,s1,1
    80004e38:	008d8793          	addi	a5,s11,8
    80004e3c:	def43823          	sd	a5,-528(s0)
    80004e40:	008db503          	ld	a0,8(s11)
    80004e44:	c911                	beqz	a0,80004e58 <exec+0x226>
    if(argc >= MAXARG)
    80004e46:	09a1                	addi	s3,s3,8
    80004e48:	fb3c95e3          	bne	s9,s3,80004df2 <exec+0x1c0>
  sz = sz1;
    80004e4c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e50:	4a81                	li	s5,0
    80004e52:	a84d                	j	80004f04 <exec+0x2d2>
  sp = sz;
    80004e54:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e56:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e58:	00349793          	slli	a5,s1,0x3
    80004e5c:	f9078793          	addi	a5,a5,-112
    80004e60:	97a2                	add	a5,a5,s0
    80004e62:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e66:	00148693          	addi	a3,s1,1
    80004e6a:	068e                	slli	a3,a3,0x3
    80004e6c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e70:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e74:	01597663          	bgeu	s2,s5,80004e80 <exec+0x24e>
  sz = sz1;
    80004e78:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e7c:	4a81                	li	s5,0
    80004e7e:	a059                	j	80004f04 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e80:	e9040613          	addi	a2,s0,-368
    80004e84:	85ca                	mv	a1,s2
    80004e86:	855a                	mv	a0,s6
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	7d2080e7          	jalr	2002(ra) # 8000165a <copyout>
    80004e90:	0a054663          	bltz	a0,80004f3c <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e94:	058bb783          	ld	a5,88(s7)
    80004e98:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e9c:	de843783          	ld	a5,-536(s0)
    80004ea0:	0007c703          	lbu	a4,0(a5)
    80004ea4:	cf11                	beqz	a4,80004ec0 <exec+0x28e>
    80004ea6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ea8:	02f00693          	li	a3,47
    80004eac:	a039                	j	80004eba <exec+0x288>
      last = s+1;
    80004eae:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004eb2:	0785                	addi	a5,a5,1
    80004eb4:	fff7c703          	lbu	a4,-1(a5)
    80004eb8:	c701                	beqz	a4,80004ec0 <exec+0x28e>
    if(*s == '/')
    80004eba:	fed71ce3          	bne	a4,a3,80004eb2 <exec+0x280>
    80004ebe:	bfc5                	j	80004eae <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ec0:	4641                	li	a2,16
    80004ec2:	de843583          	ld	a1,-536(s0)
    80004ec6:	158b8513          	addi	a0,s7,344
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	f4c080e7          	jalr	-180(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ed2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ed6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004eda:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ede:	058bb783          	ld	a5,88(s7)
    80004ee2:	e6843703          	ld	a4,-408(s0)
    80004ee6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ee8:	058bb783          	ld	a5,88(s7)
    80004eec:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ef0:	85ea                	mv	a1,s10
    80004ef2:	ffffd097          	auipc	ra,0xffffd
    80004ef6:	c04080e7          	jalr	-1020(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004efa:	0004851b          	sext.w	a0,s1
    80004efe:	bbc1                	j	80004cce <exec+0x9c>
    80004f00:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f04:	df843583          	ld	a1,-520(s0)
    80004f08:	855a                	mv	a0,s6
    80004f0a:	ffffd097          	auipc	ra,0xffffd
    80004f0e:	bec080e7          	jalr	-1044(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80004f12:	da0a94e3          	bnez	s5,80004cba <exec+0x88>
  return -1;
    80004f16:	557d                	li	a0,-1
    80004f18:	bb5d                	j	80004cce <exec+0x9c>
    80004f1a:	de943c23          	sd	s1,-520(s0)
    80004f1e:	b7dd                	j	80004f04 <exec+0x2d2>
    80004f20:	de943c23          	sd	s1,-520(s0)
    80004f24:	b7c5                	j	80004f04 <exec+0x2d2>
    80004f26:	de943c23          	sd	s1,-520(s0)
    80004f2a:	bfe9                	j	80004f04 <exec+0x2d2>
  sz = sz1;
    80004f2c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f30:	4a81                	li	s5,0
    80004f32:	bfc9                	j	80004f04 <exec+0x2d2>
  sz = sz1;
    80004f34:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f38:	4a81                	li	s5,0
    80004f3a:	b7e9                	j	80004f04 <exec+0x2d2>
  sz = sz1;
    80004f3c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f40:	4a81                	li	s5,0
    80004f42:	b7c9                	j	80004f04 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f44:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f48:	e0843783          	ld	a5,-504(s0)
    80004f4c:	0017869b          	addiw	a3,a5,1
    80004f50:	e0d43423          	sd	a3,-504(s0)
    80004f54:	e0043783          	ld	a5,-512(s0)
    80004f58:	0387879b          	addiw	a5,a5,56
    80004f5c:	e8845703          	lhu	a4,-376(s0)
    80004f60:	e2e6d3e3          	bge	a3,a4,80004d86 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f64:	2781                	sext.w	a5,a5
    80004f66:	e0f43023          	sd	a5,-512(s0)
    80004f6a:	03800713          	li	a4,56
    80004f6e:	86be                	mv	a3,a5
    80004f70:	e1840613          	addi	a2,s0,-488
    80004f74:	4581                	li	a1,0
    80004f76:	8556                	mv	a0,s5
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	a76080e7          	jalr	-1418(ra) # 800039ee <readi>
    80004f80:	03800793          	li	a5,56
    80004f84:	f6f51ee3          	bne	a0,a5,80004f00 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f88:	e1842783          	lw	a5,-488(s0)
    80004f8c:	4705                	li	a4,1
    80004f8e:	fae79de3          	bne	a5,a4,80004f48 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f92:	e4043603          	ld	a2,-448(s0)
    80004f96:	e3843783          	ld	a5,-456(s0)
    80004f9a:	f8f660e3          	bltu	a2,a5,80004f1a <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f9e:	e2843783          	ld	a5,-472(s0)
    80004fa2:	963e                	add	a2,a2,a5
    80004fa4:	f6f66ee3          	bltu	a2,a5,80004f20 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fa8:	85a6                	mv	a1,s1
    80004faa:	855a                	mv	a0,s6
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	45a080e7          	jalr	1114(ra) # 80001406 <uvmalloc>
    80004fb4:	dea43c23          	sd	a0,-520(s0)
    80004fb8:	d53d                	beqz	a0,80004f26 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004fba:	e2843c03          	ld	s8,-472(s0)
    80004fbe:	de043783          	ld	a5,-544(s0)
    80004fc2:	00fc77b3          	and	a5,s8,a5
    80004fc6:	ff9d                	bnez	a5,80004f04 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fc8:	e2042c83          	lw	s9,-480(s0)
    80004fcc:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fd0:	f60b8ae3          	beqz	s7,80004f44 <exec+0x312>
    80004fd4:	89de                	mv	s3,s7
    80004fd6:	4481                	li	s1,0
    80004fd8:	b371                	j	80004d64 <exec+0x132>

0000000080004fda <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fda:	7179                	addi	sp,sp,-48
    80004fdc:	f406                	sd	ra,40(sp)
    80004fde:	f022                	sd	s0,32(sp)
    80004fe0:	ec26                	sd	s1,24(sp)
    80004fe2:	e84a                	sd	s2,16(sp)
    80004fe4:	1800                	addi	s0,sp,48
    80004fe6:	892e                	mv	s2,a1
    80004fe8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fea:	fdc40593          	addi	a1,s0,-36
    80004fee:	ffffe097          	auipc	ra,0xffffe
    80004ff2:	bc2080e7          	jalr	-1086(ra) # 80002bb0 <argint>
    80004ff6:	04054063          	bltz	a0,80005036 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ffa:	fdc42703          	lw	a4,-36(s0)
    80004ffe:	47bd                	li	a5,15
    80005000:	02e7ed63          	bltu	a5,a4,8000503a <argfd+0x60>
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	992080e7          	jalr	-1646(ra) # 80001996 <myproc>
    8000500c:	fdc42703          	lw	a4,-36(s0)
    80005010:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80005014:	078e                	slli	a5,a5,0x3
    80005016:	953e                	add	a0,a0,a5
    80005018:	611c                	ld	a5,0(a0)
    8000501a:	c395                	beqz	a5,8000503e <argfd+0x64>
    return -1;
  if(pfd)
    8000501c:	00090463          	beqz	s2,80005024 <argfd+0x4a>
    *pfd = fd;
    80005020:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005024:	4501                	li	a0,0
  if(pf)
    80005026:	c091                	beqz	s1,8000502a <argfd+0x50>
    *pf = f;
    80005028:	e09c                	sd	a5,0(s1)
}
    8000502a:	70a2                	ld	ra,40(sp)
    8000502c:	7402                	ld	s0,32(sp)
    8000502e:	64e2                	ld	s1,24(sp)
    80005030:	6942                	ld	s2,16(sp)
    80005032:	6145                	addi	sp,sp,48
    80005034:	8082                	ret
    return -1;
    80005036:	557d                	li	a0,-1
    80005038:	bfcd                	j	8000502a <argfd+0x50>
    return -1;
    8000503a:	557d                	li	a0,-1
    8000503c:	b7fd                	j	8000502a <argfd+0x50>
    8000503e:	557d                	li	a0,-1
    80005040:	b7ed                	j	8000502a <argfd+0x50>

0000000080005042 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005042:	1101                	addi	sp,sp,-32
    80005044:	ec06                	sd	ra,24(sp)
    80005046:	e822                	sd	s0,16(sp)
    80005048:	e426                	sd	s1,8(sp)
    8000504a:	1000                	addi	s0,sp,32
    8000504c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	948080e7          	jalr	-1720(ra) # 80001996 <myproc>
    80005056:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005058:	0d050793          	addi	a5,a0,208
    8000505c:	4501                	li	a0,0
    8000505e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005060:	6398                	ld	a4,0(a5)
    80005062:	cb19                	beqz	a4,80005078 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005064:	2505                	addiw	a0,a0,1
    80005066:	07a1                	addi	a5,a5,8
    80005068:	fed51ce3          	bne	a0,a3,80005060 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000506c:	557d                	li	a0,-1
}
    8000506e:	60e2                	ld	ra,24(sp)
    80005070:	6442                	ld	s0,16(sp)
    80005072:	64a2                	ld	s1,8(sp)
    80005074:	6105                	addi	sp,sp,32
    80005076:	8082                	ret
      p->ofile[fd] = f;
    80005078:	01a50793          	addi	a5,a0,26
    8000507c:	078e                	slli	a5,a5,0x3
    8000507e:	963e                	add	a2,a2,a5
    80005080:	e204                	sd	s1,0(a2)
      return fd;
    80005082:	b7f5                	j	8000506e <fdalloc+0x2c>

0000000080005084 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005084:	715d                	addi	sp,sp,-80
    80005086:	e486                	sd	ra,72(sp)
    80005088:	e0a2                	sd	s0,64(sp)
    8000508a:	fc26                	sd	s1,56(sp)
    8000508c:	f84a                	sd	s2,48(sp)
    8000508e:	f44e                	sd	s3,40(sp)
    80005090:	f052                	sd	s4,32(sp)
    80005092:	ec56                	sd	s5,24(sp)
    80005094:	0880                	addi	s0,sp,80
    80005096:	89ae                	mv	s3,a1
    80005098:	8ab2                	mv	s5,a2
    8000509a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000509c:	fb040593          	addi	a1,s0,-80
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	e74080e7          	jalr	-396(ra) # 80003f14 <nameiparent>
    800050a8:	892a                	mv	s2,a0
    800050aa:	12050e63          	beqz	a0,800051e6 <create+0x162>
    return 0;

  ilock(dp);
    800050ae:	ffffe097          	auipc	ra,0xffffe
    800050b2:	68c080e7          	jalr	1676(ra) # 8000373a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050b6:	4601                	li	a2,0
    800050b8:	fb040593          	addi	a1,s0,-80
    800050bc:	854a                	mv	a0,s2
    800050be:	fffff097          	auipc	ra,0xfffff
    800050c2:	b60080e7          	jalr	-1184(ra) # 80003c1e <dirlookup>
    800050c6:	84aa                	mv	s1,a0
    800050c8:	c921                	beqz	a0,80005118 <create+0x94>
    iunlockput(dp);
    800050ca:	854a                	mv	a0,s2
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	8d0080e7          	jalr	-1840(ra) # 8000399c <iunlockput>
    ilock(ip);
    800050d4:	8526                	mv	a0,s1
    800050d6:	ffffe097          	auipc	ra,0xffffe
    800050da:	664080e7          	jalr	1636(ra) # 8000373a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050de:	2981                	sext.w	s3,s3
    800050e0:	4789                	li	a5,2
    800050e2:	02f99463          	bne	s3,a5,8000510a <create+0x86>
    800050e6:	0444d783          	lhu	a5,68(s1)
    800050ea:	37f9                	addiw	a5,a5,-2
    800050ec:	17c2                	slli	a5,a5,0x30
    800050ee:	93c1                	srli	a5,a5,0x30
    800050f0:	4705                	li	a4,1
    800050f2:	00f76c63          	bltu	a4,a5,8000510a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050f6:	8526                	mv	a0,s1
    800050f8:	60a6                	ld	ra,72(sp)
    800050fa:	6406                	ld	s0,64(sp)
    800050fc:	74e2                	ld	s1,56(sp)
    800050fe:	7942                	ld	s2,48(sp)
    80005100:	79a2                	ld	s3,40(sp)
    80005102:	7a02                	ld	s4,32(sp)
    80005104:	6ae2                	ld	s5,24(sp)
    80005106:	6161                	addi	sp,sp,80
    80005108:	8082                	ret
    iunlockput(ip);
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	890080e7          	jalr	-1904(ra) # 8000399c <iunlockput>
    return 0;
    80005114:	4481                	li	s1,0
    80005116:	b7c5                	j	800050f6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005118:	85ce                	mv	a1,s3
    8000511a:	00092503          	lw	a0,0(s2)
    8000511e:	ffffe097          	auipc	ra,0xffffe
    80005122:	482080e7          	jalr	1154(ra) # 800035a0 <ialloc>
    80005126:	84aa                	mv	s1,a0
    80005128:	c521                	beqz	a0,80005170 <create+0xec>
  ilock(ip);
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	610080e7          	jalr	1552(ra) # 8000373a <ilock>
  ip->major = major;
    80005132:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005136:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000513a:	4a05                	li	s4,1
    8000513c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005140:	8526                	mv	a0,s1
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	52c080e7          	jalr	1324(ra) # 8000366e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000514a:	2981                	sext.w	s3,s3
    8000514c:	03498a63          	beq	s3,s4,80005180 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005150:	40d0                	lw	a2,4(s1)
    80005152:	fb040593          	addi	a1,s0,-80
    80005156:	854a                	mv	a0,s2
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	cdc080e7          	jalr	-804(ra) # 80003e34 <dirlink>
    80005160:	06054b63          	bltz	a0,800051d6 <create+0x152>
  iunlockput(dp);
    80005164:	854a                	mv	a0,s2
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	836080e7          	jalr	-1994(ra) # 8000399c <iunlockput>
  return ip;
    8000516e:	b761                	j	800050f6 <create+0x72>
    panic("create: ialloc");
    80005170:	00003517          	auipc	a0,0x3
    80005174:	60050513          	addi	a0,a0,1536 # 80008770 <syscalls+0x2a8>
    80005178:	ffffb097          	auipc	ra,0xffffb
    8000517c:	3c2080e7          	jalr	962(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005180:	04a95783          	lhu	a5,74(s2)
    80005184:	2785                	addiw	a5,a5,1
    80005186:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000518a:	854a                	mv	a0,s2
    8000518c:	ffffe097          	auipc	ra,0xffffe
    80005190:	4e2080e7          	jalr	1250(ra) # 8000366e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005194:	40d0                	lw	a2,4(s1)
    80005196:	00003597          	auipc	a1,0x3
    8000519a:	5ea58593          	addi	a1,a1,1514 # 80008780 <syscalls+0x2b8>
    8000519e:	8526                	mv	a0,s1
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	c94080e7          	jalr	-876(ra) # 80003e34 <dirlink>
    800051a8:	00054f63          	bltz	a0,800051c6 <create+0x142>
    800051ac:	00492603          	lw	a2,4(s2)
    800051b0:	00003597          	auipc	a1,0x3
    800051b4:	5d858593          	addi	a1,a1,1496 # 80008788 <syscalls+0x2c0>
    800051b8:	8526                	mv	a0,s1
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	c7a080e7          	jalr	-902(ra) # 80003e34 <dirlink>
    800051c2:	f80557e3          	bgez	a0,80005150 <create+0xcc>
      panic("create dots");
    800051c6:	00003517          	auipc	a0,0x3
    800051ca:	5ca50513          	addi	a0,a0,1482 # 80008790 <syscalls+0x2c8>
    800051ce:	ffffb097          	auipc	ra,0xffffb
    800051d2:	36c080e7          	jalr	876(ra) # 8000053a <panic>
    panic("create: dirlink");
    800051d6:	00003517          	auipc	a0,0x3
    800051da:	5ca50513          	addi	a0,a0,1482 # 800087a0 <syscalls+0x2d8>
    800051de:	ffffb097          	auipc	ra,0xffffb
    800051e2:	35c080e7          	jalr	860(ra) # 8000053a <panic>
    return 0;
    800051e6:	84aa                	mv	s1,a0
    800051e8:	b739                	j	800050f6 <create+0x72>

00000000800051ea <sys_dup>:
{
    800051ea:	7179                	addi	sp,sp,-48
    800051ec:	f406                	sd	ra,40(sp)
    800051ee:	f022                	sd	s0,32(sp)
    800051f0:	ec26                	sd	s1,24(sp)
    800051f2:	e84a                	sd	s2,16(sp)
    800051f4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051f6:	fd840613          	addi	a2,s0,-40
    800051fa:	4581                	li	a1,0
    800051fc:	4501                	li	a0,0
    800051fe:	00000097          	auipc	ra,0x0
    80005202:	ddc080e7          	jalr	-548(ra) # 80004fda <argfd>
    return -1;
    80005206:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005208:	02054363          	bltz	a0,8000522e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000520c:	fd843903          	ld	s2,-40(s0)
    80005210:	854a                	mv	a0,s2
    80005212:	00000097          	auipc	ra,0x0
    80005216:	e30080e7          	jalr	-464(ra) # 80005042 <fdalloc>
    8000521a:	84aa                	mv	s1,a0
    return -1;
    8000521c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000521e:	00054863          	bltz	a0,8000522e <sys_dup+0x44>
  filedup(f);
    80005222:	854a                	mv	a0,s2
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	368080e7          	jalr	872(ra) # 8000458c <filedup>
  return fd;
    8000522c:	87a6                	mv	a5,s1
}
    8000522e:	853e                	mv	a0,a5
    80005230:	70a2                	ld	ra,40(sp)
    80005232:	7402                	ld	s0,32(sp)
    80005234:	64e2                	ld	s1,24(sp)
    80005236:	6942                	ld	s2,16(sp)
    80005238:	6145                	addi	sp,sp,48
    8000523a:	8082                	ret

000000008000523c <sys_read>:
{
    8000523c:	7179                	addi	sp,sp,-48
    8000523e:	f406                	sd	ra,40(sp)
    80005240:	f022                	sd	s0,32(sp)
    80005242:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005244:	fe840613          	addi	a2,s0,-24
    80005248:	4581                	li	a1,0
    8000524a:	4501                	li	a0,0
    8000524c:	00000097          	auipc	ra,0x0
    80005250:	d8e080e7          	jalr	-626(ra) # 80004fda <argfd>
    return -1;
    80005254:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005256:	04054163          	bltz	a0,80005298 <sys_read+0x5c>
    8000525a:	fe440593          	addi	a1,s0,-28
    8000525e:	4509                	li	a0,2
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	950080e7          	jalr	-1712(ra) # 80002bb0 <argint>
    return -1;
    80005268:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526a:	02054763          	bltz	a0,80005298 <sys_read+0x5c>
    8000526e:	fd840593          	addi	a1,s0,-40
    80005272:	4505                	li	a0,1
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	95e080e7          	jalr	-1698(ra) # 80002bd2 <argaddr>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527e:	00054d63          	bltz	a0,80005298 <sys_read+0x5c>
  return fileread(f, p, n);
    80005282:	fe442603          	lw	a2,-28(s0)
    80005286:	fd843583          	ld	a1,-40(s0)
    8000528a:	fe843503          	ld	a0,-24(s0)
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	48a080e7          	jalr	1162(ra) # 80004718 <fileread>
    80005296:	87aa                	mv	a5,a0
}
    80005298:	853e                	mv	a0,a5
    8000529a:	70a2                	ld	ra,40(sp)
    8000529c:	7402                	ld	s0,32(sp)
    8000529e:	6145                	addi	sp,sp,48
    800052a0:	8082                	ret

00000000800052a2 <sys_write>:
{
    800052a2:	7179                	addi	sp,sp,-48
    800052a4:	f406                	sd	ra,40(sp)
    800052a6:	f022                	sd	s0,32(sp)
    800052a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052aa:	fe840613          	addi	a2,s0,-24
    800052ae:	4581                	li	a1,0
    800052b0:	4501                	li	a0,0
    800052b2:	00000097          	auipc	ra,0x0
    800052b6:	d28080e7          	jalr	-728(ra) # 80004fda <argfd>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	04054163          	bltz	a0,800052fe <sys_write+0x5c>
    800052c0:	fe440593          	addi	a1,s0,-28
    800052c4:	4509                	li	a0,2
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	8ea080e7          	jalr	-1814(ra) # 80002bb0 <argint>
    return -1;
    800052ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d0:	02054763          	bltz	a0,800052fe <sys_write+0x5c>
    800052d4:	fd840593          	addi	a1,s0,-40
    800052d8:	4505                	li	a0,1
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	8f8080e7          	jalr	-1800(ra) # 80002bd2 <argaddr>
    return -1;
    800052e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e4:	00054d63          	bltz	a0,800052fe <sys_write+0x5c>
  return filewrite(f, p, n);
    800052e8:	fe442603          	lw	a2,-28(s0)
    800052ec:	fd843583          	ld	a1,-40(s0)
    800052f0:	fe843503          	ld	a0,-24(s0)
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	4e6080e7          	jalr	1254(ra) # 800047da <filewrite>
    800052fc:	87aa                	mv	a5,a0
}
    800052fe:	853e                	mv	a0,a5
    80005300:	70a2                	ld	ra,40(sp)
    80005302:	7402                	ld	s0,32(sp)
    80005304:	6145                	addi	sp,sp,48
    80005306:	8082                	ret

0000000080005308 <sys_close>:
{
    80005308:	1101                	addi	sp,sp,-32
    8000530a:	ec06                	sd	ra,24(sp)
    8000530c:	e822                	sd	s0,16(sp)
    8000530e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005310:	fe040613          	addi	a2,s0,-32
    80005314:	fec40593          	addi	a1,s0,-20
    80005318:	4501                	li	a0,0
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	cc0080e7          	jalr	-832(ra) # 80004fda <argfd>
    return -1;
    80005322:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005324:	02054463          	bltz	a0,8000534c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	66e080e7          	jalr	1646(ra) # 80001996 <myproc>
    80005330:	fec42783          	lw	a5,-20(s0)
    80005334:	07e9                	addi	a5,a5,26
    80005336:	078e                	slli	a5,a5,0x3
    80005338:	953e                	add	a0,a0,a5
    8000533a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000533e:	fe043503          	ld	a0,-32(s0)
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	29c080e7          	jalr	668(ra) # 800045de <fileclose>
  return 0;
    8000534a:	4781                	li	a5,0
}
    8000534c:	853e                	mv	a0,a5
    8000534e:	60e2                	ld	ra,24(sp)
    80005350:	6442                	ld	s0,16(sp)
    80005352:	6105                	addi	sp,sp,32
    80005354:	8082                	ret

0000000080005356 <sys_fstat>:
{
    80005356:	1101                	addi	sp,sp,-32
    80005358:	ec06                	sd	ra,24(sp)
    8000535a:	e822                	sd	s0,16(sp)
    8000535c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000535e:	fe840613          	addi	a2,s0,-24
    80005362:	4581                	li	a1,0
    80005364:	4501                	li	a0,0
    80005366:	00000097          	auipc	ra,0x0
    8000536a:	c74080e7          	jalr	-908(ra) # 80004fda <argfd>
    return -1;
    8000536e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005370:	02054563          	bltz	a0,8000539a <sys_fstat+0x44>
    80005374:	fe040593          	addi	a1,s0,-32
    80005378:	4505                	li	a0,1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	858080e7          	jalr	-1960(ra) # 80002bd2 <argaddr>
    return -1;
    80005382:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005384:	00054b63          	bltz	a0,8000539a <sys_fstat+0x44>
  return filestat(f, st);
    80005388:	fe043583          	ld	a1,-32(s0)
    8000538c:	fe843503          	ld	a0,-24(s0)
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	316080e7          	jalr	790(ra) # 800046a6 <filestat>
    80005398:	87aa                	mv	a5,a0
}
    8000539a:	853e                	mv	a0,a5
    8000539c:	60e2                	ld	ra,24(sp)
    8000539e:	6442                	ld	s0,16(sp)
    800053a0:	6105                	addi	sp,sp,32
    800053a2:	8082                	ret

00000000800053a4 <sys_link>:
{
    800053a4:	7169                	addi	sp,sp,-304
    800053a6:	f606                	sd	ra,296(sp)
    800053a8:	f222                	sd	s0,288(sp)
    800053aa:	ee26                	sd	s1,280(sp)
    800053ac:	ea4a                	sd	s2,272(sp)
    800053ae:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b0:	08000613          	li	a2,128
    800053b4:	ed040593          	addi	a1,s0,-304
    800053b8:	4501                	li	a0,0
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	83a080e7          	jalr	-1990(ra) # 80002bf4 <argstr>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c4:	10054e63          	bltz	a0,800054e0 <sys_link+0x13c>
    800053c8:	08000613          	li	a2,128
    800053cc:	f5040593          	addi	a1,s0,-176
    800053d0:	4505                	li	a0,1
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	822080e7          	jalr	-2014(ra) # 80002bf4 <argstr>
    return -1;
    800053da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053dc:	10054263          	bltz	a0,800054e0 <sys_link+0x13c>
  begin_op();
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	d36080e7          	jalr	-714(ra) # 80004116 <begin_op>
  if((ip = namei(old)) == 0){
    800053e8:	ed040513          	addi	a0,s0,-304
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	b0a080e7          	jalr	-1270(ra) # 80003ef6 <namei>
    800053f4:	84aa                	mv	s1,a0
    800053f6:	c551                	beqz	a0,80005482 <sys_link+0xde>
  ilock(ip);
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	342080e7          	jalr	834(ra) # 8000373a <ilock>
  if(ip->type == T_DIR){
    80005400:	04449703          	lh	a4,68(s1)
    80005404:	4785                	li	a5,1
    80005406:	08f70463          	beq	a4,a5,8000548e <sys_link+0xea>
  ip->nlink++;
    8000540a:	04a4d783          	lhu	a5,74(s1)
    8000540e:	2785                	addiw	a5,a5,1
    80005410:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005414:	8526                	mv	a0,s1
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	258080e7          	jalr	600(ra) # 8000366e <iupdate>
  iunlock(ip);
    8000541e:	8526                	mv	a0,s1
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	3dc080e7          	jalr	988(ra) # 800037fc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005428:	fd040593          	addi	a1,s0,-48
    8000542c:	f5040513          	addi	a0,s0,-176
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	ae4080e7          	jalr	-1308(ra) # 80003f14 <nameiparent>
    80005438:	892a                	mv	s2,a0
    8000543a:	c935                	beqz	a0,800054ae <sys_link+0x10a>
  ilock(dp);
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	2fe080e7          	jalr	766(ra) # 8000373a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005444:	00092703          	lw	a4,0(s2)
    80005448:	409c                	lw	a5,0(s1)
    8000544a:	04f71d63          	bne	a4,a5,800054a4 <sys_link+0x100>
    8000544e:	40d0                	lw	a2,4(s1)
    80005450:	fd040593          	addi	a1,s0,-48
    80005454:	854a                	mv	a0,s2
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	9de080e7          	jalr	-1570(ra) # 80003e34 <dirlink>
    8000545e:	04054363          	bltz	a0,800054a4 <sys_link+0x100>
  iunlockput(dp);
    80005462:	854a                	mv	a0,s2
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	538080e7          	jalr	1336(ra) # 8000399c <iunlockput>
  iput(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	486080e7          	jalr	1158(ra) # 800038f4 <iput>
  end_op();
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	d1e080e7          	jalr	-738(ra) # 80004194 <end_op>
  return 0;
    8000547e:	4781                	li	a5,0
    80005480:	a085                	j	800054e0 <sys_link+0x13c>
    end_op();
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	d12080e7          	jalr	-750(ra) # 80004194 <end_op>
    return -1;
    8000548a:	57fd                	li	a5,-1
    8000548c:	a891                	j	800054e0 <sys_link+0x13c>
    iunlockput(ip);
    8000548e:	8526                	mv	a0,s1
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	50c080e7          	jalr	1292(ra) # 8000399c <iunlockput>
    end_op();
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	cfc080e7          	jalr	-772(ra) # 80004194 <end_op>
    return -1;
    800054a0:	57fd                	li	a5,-1
    800054a2:	a83d                	j	800054e0 <sys_link+0x13c>
    iunlockput(dp);
    800054a4:	854a                	mv	a0,s2
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	4f6080e7          	jalr	1270(ra) # 8000399c <iunlockput>
  ilock(ip);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	28a080e7          	jalr	650(ra) # 8000373a <ilock>
  ip->nlink--;
    800054b8:	04a4d783          	lhu	a5,74(s1)
    800054bc:	37fd                	addiw	a5,a5,-1
    800054be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	1aa080e7          	jalr	426(ra) # 8000366e <iupdate>
  iunlockput(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	4ce080e7          	jalr	1230(ra) # 8000399c <iunlockput>
  end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	cbe080e7          	jalr	-834(ra) # 80004194 <end_op>
  return -1;
    800054de:	57fd                	li	a5,-1
}
    800054e0:	853e                	mv	a0,a5
    800054e2:	70b2                	ld	ra,296(sp)
    800054e4:	7412                	ld	s0,288(sp)
    800054e6:	64f2                	ld	s1,280(sp)
    800054e8:	6952                	ld	s2,272(sp)
    800054ea:	6155                	addi	sp,sp,304
    800054ec:	8082                	ret

00000000800054ee <sys_unlink>:
{
    800054ee:	7151                	addi	sp,sp,-240
    800054f0:	f586                	sd	ra,232(sp)
    800054f2:	f1a2                	sd	s0,224(sp)
    800054f4:	eda6                	sd	s1,216(sp)
    800054f6:	e9ca                	sd	s2,208(sp)
    800054f8:	e5ce                	sd	s3,200(sp)
    800054fa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054fc:	08000613          	li	a2,128
    80005500:	f3040593          	addi	a1,s0,-208
    80005504:	4501                	li	a0,0
    80005506:	ffffd097          	auipc	ra,0xffffd
    8000550a:	6ee080e7          	jalr	1774(ra) # 80002bf4 <argstr>
    8000550e:	18054163          	bltz	a0,80005690 <sys_unlink+0x1a2>
  begin_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	c04080e7          	jalr	-1020(ra) # 80004116 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000551a:	fb040593          	addi	a1,s0,-80
    8000551e:	f3040513          	addi	a0,s0,-208
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	9f2080e7          	jalr	-1550(ra) # 80003f14 <nameiparent>
    8000552a:	84aa                	mv	s1,a0
    8000552c:	c979                	beqz	a0,80005602 <sys_unlink+0x114>
  ilock(dp);
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	20c080e7          	jalr	524(ra) # 8000373a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005536:	00003597          	auipc	a1,0x3
    8000553a:	24a58593          	addi	a1,a1,586 # 80008780 <syscalls+0x2b8>
    8000553e:	fb040513          	addi	a0,s0,-80
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	6c2080e7          	jalr	1730(ra) # 80003c04 <namecmp>
    8000554a:	14050a63          	beqz	a0,8000569e <sys_unlink+0x1b0>
    8000554e:	00003597          	auipc	a1,0x3
    80005552:	23a58593          	addi	a1,a1,570 # 80008788 <syscalls+0x2c0>
    80005556:	fb040513          	addi	a0,s0,-80
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	6aa080e7          	jalr	1706(ra) # 80003c04 <namecmp>
    80005562:	12050e63          	beqz	a0,8000569e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005566:	f2c40613          	addi	a2,s0,-212
    8000556a:	fb040593          	addi	a1,s0,-80
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	6ae080e7          	jalr	1710(ra) # 80003c1e <dirlookup>
    80005578:	892a                	mv	s2,a0
    8000557a:	12050263          	beqz	a0,8000569e <sys_unlink+0x1b0>
  ilock(ip);
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	1bc080e7          	jalr	444(ra) # 8000373a <ilock>
  if(ip->nlink < 1)
    80005586:	04a91783          	lh	a5,74(s2)
    8000558a:	08f05263          	blez	a5,8000560e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000558e:	04491703          	lh	a4,68(s2)
    80005592:	4785                	li	a5,1
    80005594:	08f70563          	beq	a4,a5,8000561e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005598:	4641                	li	a2,16
    8000559a:	4581                	li	a1,0
    8000559c:	fc040513          	addi	a0,s0,-64
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	72c080e7          	jalr	1836(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055a8:	4741                	li	a4,16
    800055aa:	f2c42683          	lw	a3,-212(s0)
    800055ae:	fc040613          	addi	a2,s0,-64
    800055b2:	4581                	li	a1,0
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	530080e7          	jalr	1328(ra) # 80003ae6 <writei>
    800055be:	47c1                	li	a5,16
    800055c0:	0af51563          	bne	a0,a5,8000566a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055c4:	04491703          	lh	a4,68(s2)
    800055c8:	4785                	li	a5,1
    800055ca:	0af70863          	beq	a4,a5,8000567a <sys_unlink+0x18c>
  iunlockput(dp);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	3cc080e7          	jalr	972(ra) # 8000399c <iunlockput>
  ip->nlink--;
    800055d8:	04a95783          	lhu	a5,74(s2)
    800055dc:	37fd                	addiw	a5,a5,-1
    800055de:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055e2:	854a                	mv	a0,s2
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	08a080e7          	jalr	138(ra) # 8000366e <iupdate>
  iunlockput(ip);
    800055ec:	854a                	mv	a0,s2
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	3ae080e7          	jalr	942(ra) # 8000399c <iunlockput>
  end_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	b9e080e7          	jalr	-1122(ra) # 80004194 <end_op>
  return 0;
    800055fe:	4501                	li	a0,0
    80005600:	a84d                	j	800056b2 <sys_unlink+0x1c4>
    end_op();
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	b92080e7          	jalr	-1134(ra) # 80004194 <end_op>
    return -1;
    8000560a:	557d                	li	a0,-1
    8000560c:	a05d                	j	800056b2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000560e:	00003517          	auipc	a0,0x3
    80005612:	1a250513          	addi	a0,a0,418 # 800087b0 <syscalls+0x2e8>
    80005616:	ffffb097          	auipc	ra,0xffffb
    8000561a:	f24080e7          	jalr	-220(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000561e:	04c92703          	lw	a4,76(s2)
    80005622:	02000793          	li	a5,32
    80005626:	f6e7f9e3          	bgeu	a5,a4,80005598 <sys_unlink+0xaa>
    8000562a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000562e:	4741                	li	a4,16
    80005630:	86ce                	mv	a3,s3
    80005632:	f1840613          	addi	a2,s0,-232
    80005636:	4581                	li	a1,0
    80005638:	854a                	mv	a0,s2
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	3b4080e7          	jalr	948(ra) # 800039ee <readi>
    80005642:	47c1                	li	a5,16
    80005644:	00f51b63          	bne	a0,a5,8000565a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005648:	f1845783          	lhu	a5,-232(s0)
    8000564c:	e7a1                	bnez	a5,80005694 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000564e:	29c1                	addiw	s3,s3,16
    80005650:	04c92783          	lw	a5,76(s2)
    80005654:	fcf9ede3          	bltu	s3,a5,8000562e <sys_unlink+0x140>
    80005658:	b781                	j	80005598 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000565a:	00003517          	auipc	a0,0x3
    8000565e:	16e50513          	addi	a0,a0,366 # 800087c8 <syscalls+0x300>
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	ed8080e7          	jalr	-296(ra) # 8000053a <panic>
    panic("unlink: writei");
    8000566a:	00003517          	auipc	a0,0x3
    8000566e:	17650513          	addi	a0,a0,374 # 800087e0 <syscalls+0x318>
    80005672:	ffffb097          	auipc	ra,0xffffb
    80005676:	ec8080e7          	jalr	-312(ra) # 8000053a <panic>
    dp->nlink--;
    8000567a:	04a4d783          	lhu	a5,74(s1)
    8000567e:	37fd                	addiw	a5,a5,-1
    80005680:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	fe8080e7          	jalr	-24(ra) # 8000366e <iupdate>
    8000568e:	b781                	j	800055ce <sys_unlink+0xe0>
    return -1;
    80005690:	557d                	li	a0,-1
    80005692:	a005                	j	800056b2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005694:	854a                	mv	a0,s2
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	306080e7          	jalr	774(ra) # 8000399c <iunlockput>
  iunlockput(dp);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	2fc080e7          	jalr	764(ra) # 8000399c <iunlockput>
  end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	aec080e7          	jalr	-1300(ra) # 80004194 <end_op>
  return -1;
    800056b0:	557d                	li	a0,-1
}
    800056b2:	70ae                	ld	ra,232(sp)
    800056b4:	740e                	ld	s0,224(sp)
    800056b6:	64ee                	ld	s1,216(sp)
    800056b8:	694e                	ld	s2,208(sp)
    800056ba:	69ae                	ld	s3,200(sp)
    800056bc:	616d                	addi	sp,sp,240
    800056be:	8082                	ret

00000000800056c0 <sys_open>:

uint64
sys_open(void)
{
    800056c0:	7131                	addi	sp,sp,-192
    800056c2:	fd06                	sd	ra,184(sp)
    800056c4:	f922                	sd	s0,176(sp)
    800056c6:	f526                	sd	s1,168(sp)
    800056c8:	f14a                	sd	s2,160(sp)
    800056ca:	ed4e                	sd	s3,152(sp)
    800056cc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ce:	08000613          	li	a2,128
    800056d2:	f5040593          	addi	a1,s0,-176
    800056d6:	4501                	li	a0,0
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	51c080e7          	jalr	1308(ra) # 80002bf4 <argstr>
    return -1;
    800056e0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056e2:	0c054163          	bltz	a0,800057a4 <sys_open+0xe4>
    800056e6:	f4c40593          	addi	a1,s0,-180
    800056ea:	4505                	li	a0,1
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	4c4080e7          	jalr	1220(ra) # 80002bb0 <argint>
    800056f4:	0a054863          	bltz	a0,800057a4 <sys_open+0xe4>

  begin_op();
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	a1e080e7          	jalr	-1506(ra) # 80004116 <begin_op>

  if(omode & O_CREATE){
    80005700:	f4c42783          	lw	a5,-180(s0)
    80005704:	2007f793          	andi	a5,a5,512
    80005708:	cbdd                	beqz	a5,800057be <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000570a:	4681                	li	a3,0
    8000570c:	4601                	li	a2,0
    8000570e:	4589                	li	a1,2
    80005710:	f5040513          	addi	a0,s0,-176
    80005714:	00000097          	auipc	ra,0x0
    80005718:	970080e7          	jalr	-1680(ra) # 80005084 <create>
    8000571c:	892a                	mv	s2,a0
    if(ip == 0){
    8000571e:	c959                	beqz	a0,800057b4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005720:	04491703          	lh	a4,68(s2)
    80005724:	478d                	li	a5,3
    80005726:	00f71763          	bne	a4,a5,80005734 <sys_open+0x74>
    8000572a:	04695703          	lhu	a4,70(s2)
    8000572e:	47a5                	li	a5,9
    80005730:	0ce7ec63          	bltu	a5,a4,80005808 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	dee080e7          	jalr	-530(ra) # 80004522 <filealloc>
    8000573c:	89aa                	mv	s3,a0
    8000573e:	10050263          	beqz	a0,80005842 <sys_open+0x182>
    80005742:	00000097          	auipc	ra,0x0
    80005746:	900080e7          	jalr	-1792(ra) # 80005042 <fdalloc>
    8000574a:	84aa                	mv	s1,a0
    8000574c:	0e054663          	bltz	a0,80005838 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005750:	04491703          	lh	a4,68(s2)
    80005754:	478d                	li	a5,3
    80005756:	0cf70463          	beq	a4,a5,8000581e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000575a:	4789                	li	a5,2
    8000575c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005760:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005764:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005768:	f4c42783          	lw	a5,-180(s0)
    8000576c:	0017c713          	xori	a4,a5,1
    80005770:	8b05                	andi	a4,a4,1
    80005772:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005776:	0037f713          	andi	a4,a5,3
    8000577a:	00e03733          	snez	a4,a4
    8000577e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005782:	4007f793          	andi	a5,a5,1024
    80005786:	c791                	beqz	a5,80005792 <sys_open+0xd2>
    80005788:	04491703          	lh	a4,68(s2)
    8000578c:	4789                	li	a5,2
    8000578e:	08f70f63          	beq	a4,a5,8000582c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	068080e7          	jalr	104(ra) # 800037fc <iunlock>
  end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	9f8080e7          	jalr	-1544(ra) # 80004194 <end_op>

  return fd;
}
    800057a4:	8526                	mv	a0,s1
    800057a6:	70ea                	ld	ra,184(sp)
    800057a8:	744a                	ld	s0,176(sp)
    800057aa:	74aa                	ld	s1,168(sp)
    800057ac:	790a                	ld	s2,160(sp)
    800057ae:	69ea                	ld	s3,152(sp)
    800057b0:	6129                	addi	sp,sp,192
    800057b2:	8082                	ret
      end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	9e0080e7          	jalr	-1568(ra) # 80004194 <end_op>
      return -1;
    800057bc:	b7e5                	j	800057a4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057be:	f5040513          	addi	a0,s0,-176
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	734080e7          	jalr	1844(ra) # 80003ef6 <namei>
    800057ca:	892a                	mv	s2,a0
    800057cc:	c905                	beqz	a0,800057fc <sys_open+0x13c>
    ilock(ip);
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	f6c080e7          	jalr	-148(ra) # 8000373a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057d6:	04491703          	lh	a4,68(s2)
    800057da:	4785                	li	a5,1
    800057dc:	f4f712e3          	bne	a4,a5,80005720 <sys_open+0x60>
    800057e0:	f4c42783          	lw	a5,-180(s0)
    800057e4:	dba1                	beqz	a5,80005734 <sys_open+0x74>
      iunlockput(ip);
    800057e6:	854a                	mv	a0,s2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	1b4080e7          	jalr	436(ra) # 8000399c <iunlockput>
      end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	9a4080e7          	jalr	-1628(ra) # 80004194 <end_op>
      return -1;
    800057f8:	54fd                	li	s1,-1
    800057fa:	b76d                	j	800057a4 <sys_open+0xe4>
      end_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	998080e7          	jalr	-1640(ra) # 80004194 <end_op>
      return -1;
    80005804:	54fd                	li	s1,-1
    80005806:	bf79                	j	800057a4 <sys_open+0xe4>
    iunlockput(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	192080e7          	jalr	402(ra) # 8000399c <iunlockput>
    end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	982080e7          	jalr	-1662(ra) # 80004194 <end_op>
    return -1;
    8000581a:	54fd                	li	s1,-1
    8000581c:	b761                	j	800057a4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000581e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005822:	04691783          	lh	a5,70(s2)
    80005826:	02f99223          	sh	a5,36(s3)
    8000582a:	bf2d                	j	80005764 <sys_open+0xa4>
    itrunc(ip);
    8000582c:	854a                	mv	a0,s2
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	01a080e7          	jalr	26(ra) # 80003848 <itrunc>
    80005836:	bfb1                	j	80005792 <sys_open+0xd2>
      fileclose(f);
    80005838:	854e                	mv	a0,s3
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	da4080e7          	jalr	-604(ra) # 800045de <fileclose>
    iunlockput(ip);
    80005842:	854a                	mv	a0,s2
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	158080e7          	jalr	344(ra) # 8000399c <iunlockput>
    end_op();
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	948080e7          	jalr	-1720(ra) # 80004194 <end_op>
    return -1;
    80005854:	54fd                	li	s1,-1
    80005856:	b7b9                	j	800057a4 <sys_open+0xe4>

0000000080005858 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005858:	7175                	addi	sp,sp,-144
    8000585a:	e506                	sd	ra,136(sp)
    8000585c:	e122                	sd	s0,128(sp)
    8000585e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	8b6080e7          	jalr	-1866(ra) # 80004116 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005868:	08000613          	li	a2,128
    8000586c:	f7040593          	addi	a1,s0,-144
    80005870:	4501                	li	a0,0
    80005872:	ffffd097          	auipc	ra,0xffffd
    80005876:	382080e7          	jalr	898(ra) # 80002bf4 <argstr>
    8000587a:	02054963          	bltz	a0,800058ac <sys_mkdir+0x54>
    8000587e:	4681                	li	a3,0
    80005880:	4601                	li	a2,0
    80005882:	4585                	li	a1,1
    80005884:	f7040513          	addi	a0,s0,-144
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	7fc080e7          	jalr	2044(ra) # 80005084 <create>
    80005890:	cd11                	beqz	a0,800058ac <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	10a080e7          	jalr	266(ra) # 8000399c <iunlockput>
  end_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	8fa080e7          	jalr	-1798(ra) # 80004194 <end_op>
  return 0;
    800058a2:	4501                	li	a0,0
}
    800058a4:	60aa                	ld	ra,136(sp)
    800058a6:	640a                	ld	s0,128(sp)
    800058a8:	6149                	addi	sp,sp,144
    800058aa:	8082                	ret
    end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	8e8080e7          	jalr	-1816(ra) # 80004194 <end_op>
    return -1;
    800058b4:	557d                	li	a0,-1
    800058b6:	b7fd                	j	800058a4 <sys_mkdir+0x4c>

00000000800058b8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058b8:	7135                	addi	sp,sp,-160
    800058ba:	ed06                	sd	ra,152(sp)
    800058bc:	e922                	sd	s0,144(sp)
    800058be:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	856080e7          	jalr	-1962(ra) # 80004116 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058c8:	08000613          	li	a2,128
    800058cc:	f7040593          	addi	a1,s0,-144
    800058d0:	4501                	li	a0,0
    800058d2:	ffffd097          	auipc	ra,0xffffd
    800058d6:	322080e7          	jalr	802(ra) # 80002bf4 <argstr>
    800058da:	04054a63          	bltz	a0,8000592e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058de:	f6c40593          	addi	a1,s0,-148
    800058e2:	4505                	li	a0,1
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	2cc080e7          	jalr	716(ra) # 80002bb0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ec:	04054163          	bltz	a0,8000592e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058f0:	f6840593          	addi	a1,s0,-152
    800058f4:	4509                	li	a0,2
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	2ba080e7          	jalr	698(ra) # 80002bb0 <argint>
     argint(1, &major) < 0 ||
    800058fe:	02054863          	bltz	a0,8000592e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005902:	f6841683          	lh	a3,-152(s0)
    80005906:	f6c41603          	lh	a2,-148(s0)
    8000590a:	458d                	li	a1,3
    8000590c:	f7040513          	addi	a0,s0,-144
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	774080e7          	jalr	1908(ra) # 80005084 <create>
     argint(2, &minor) < 0 ||
    80005918:	c919                	beqz	a0,8000592e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	082080e7          	jalr	130(ra) # 8000399c <iunlockput>
  end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	872080e7          	jalr	-1934(ra) # 80004194 <end_op>
  return 0;
    8000592a:	4501                	li	a0,0
    8000592c:	a031                	j	80005938 <sys_mknod+0x80>
    end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	866080e7          	jalr	-1946(ra) # 80004194 <end_op>
    return -1;
    80005936:	557d                	li	a0,-1
}
    80005938:	60ea                	ld	ra,152(sp)
    8000593a:	644a                	ld	s0,144(sp)
    8000593c:	610d                	addi	sp,sp,160
    8000593e:	8082                	ret

0000000080005940 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005940:	7135                	addi	sp,sp,-160
    80005942:	ed06                	sd	ra,152(sp)
    80005944:	e922                	sd	s0,144(sp)
    80005946:	e526                	sd	s1,136(sp)
    80005948:	e14a                	sd	s2,128(sp)
    8000594a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000594c:	ffffc097          	auipc	ra,0xffffc
    80005950:	04a080e7          	jalr	74(ra) # 80001996 <myproc>
    80005954:	892a                	mv	s2,a0
  
  begin_op();
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	7c0080e7          	jalr	1984(ra) # 80004116 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000595e:	08000613          	li	a2,128
    80005962:	f6040593          	addi	a1,s0,-160
    80005966:	4501                	li	a0,0
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	28c080e7          	jalr	652(ra) # 80002bf4 <argstr>
    80005970:	04054b63          	bltz	a0,800059c6 <sys_chdir+0x86>
    80005974:	f6040513          	addi	a0,s0,-160
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	57e080e7          	jalr	1406(ra) # 80003ef6 <namei>
    80005980:	84aa                	mv	s1,a0
    80005982:	c131                	beqz	a0,800059c6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	db6080e7          	jalr	-586(ra) # 8000373a <ilock>
  if(ip->type != T_DIR){
    8000598c:	04449703          	lh	a4,68(s1)
    80005990:	4785                	li	a5,1
    80005992:	04f71063          	bne	a4,a5,800059d2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	e64080e7          	jalr	-412(ra) # 800037fc <iunlock>
  iput(p->cwd);
    800059a0:	15093503          	ld	a0,336(s2)
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	f50080e7          	jalr	-176(ra) # 800038f4 <iput>
  end_op();
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	7e8080e7          	jalr	2024(ra) # 80004194 <end_op>
  p->cwd = ip;
    800059b4:	14993823          	sd	s1,336(s2)
  return 0;
    800059b8:	4501                	li	a0,0
}
    800059ba:	60ea                	ld	ra,152(sp)
    800059bc:	644a                	ld	s0,144(sp)
    800059be:	64aa                	ld	s1,136(sp)
    800059c0:	690a                	ld	s2,128(sp)
    800059c2:	610d                	addi	sp,sp,160
    800059c4:	8082                	ret
    end_op();
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	7ce080e7          	jalr	1998(ra) # 80004194 <end_op>
    return -1;
    800059ce:	557d                	li	a0,-1
    800059d0:	b7ed                	j	800059ba <sys_chdir+0x7a>
    iunlockput(ip);
    800059d2:	8526                	mv	a0,s1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	fc8080e7          	jalr	-56(ra) # 8000399c <iunlockput>
    end_op();
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	7b8080e7          	jalr	1976(ra) # 80004194 <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	bfd1                	j	800059ba <sys_chdir+0x7a>

00000000800059e8 <sys_exec>:

uint64
sys_exec(void)
{
    800059e8:	7145                	addi	sp,sp,-464
    800059ea:	e786                	sd	ra,456(sp)
    800059ec:	e3a2                	sd	s0,448(sp)
    800059ee:	ff26                	sd	s1,440(sp)
    800059f0:	fb4a                	sd	s2,432(sp)
    800059f2:	f74e                	sd	s3,424(sp)
    800059f4:	f352                	sd	s4,416(sp)
    800059f6:	ef56                	sd	s5,408(sp)
    800059f8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059fa:	08000613          	li	a2,128
    800059fe:	f4040593          	addi	a1,s0,-192
    80005a02:	4501                	li	a0,0
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	1f0080e7          	jalr	496(ra) # 80002bf4 <argstr>
    return -1;
    80005a0c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a0e:	0c054b63          	bltz	a0,80005ae4 <sys_exec+0xfc>
    80005a12:	e3840593          	addi	a1,s0,-456
    80005a16:	4505                	li	a0,1
    80005a18:	ffffd097          	auipc	ra,0xffffd
    80005a1c:	1ba080e7          	jalr	442(ra) # 80002bd2 <argaddr>
    80005a20:	0c054263          	bltz	a0,80005ae4 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a24:	10000613          	li	a2,256
    80005a28:	4581                	li	a1,0
    80005a2a:	e4040513          	addi	a0,s0,-448
    80005a2e:	ffffb097          	auipc	ra,0xffffb
    80005a32:	29e080e7          	jalr	670(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a36:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a3a:	89a6                	mv	s3,s1
    80005a3c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a3e:	02000a13          	li	s4,32
    80005a42:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a46:	00391513          	slli	a0,s2,0x3
    80005a4a:	e3040593          	addi	a1,s0,-464
    80005a4e:	e3843783          	ld	a5,-456(s0)
    80005a52:	953e                	add	a0,a0,a5
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	0c2080e7          	jalr	194(ra) # 80002b16 <fetchaddr>
    80005a5c:	02054a63          	bltz	a0,80005a90 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a60:	e3043783          	ld	a5,-464(s0)
    80005a64:	c3b9                	beqz	a5,80005aaa <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	07a080e7          	jalr	122(ra) # 80000ae0 <kalloc>
    80005a6e:	85aa                	mv	a1,a0
    80005a70:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a74:	cd11                	beqz	a0,80005a90 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a76:	6605                	lui	a2,0x1
    80005a78:	e3043503          	ld	a0,-464(s0)
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	0ec080e7          	jalr	236(ra) # 80002b68 <fetchstr>
    80005a84:	00054663          	bltz	a0,80005a90 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a88:	0905                	addi	s2,s2,1
    80005a8a:	09a1                	addi	s3,s3,8
    80005a8c:	fb491be3          	bne	s2,s4,80005a42 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a90:	f4040913          	addi	s2,s0,-192
    80005a94:	6088                	ld	a0,0(s1)
    80005a96:	c531                	beqz	a0,80005ae2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	f4a080e7          	jalr	-182(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa0:	04a1                	addi	s1,s1,8
    80005aa2:	ff2499e3          	bne	s1,s2,80005a94 <sys_exec+0xac>
  return -1;
    80005aa6:	597d                	li	s2,-1
    80005aa8:	a835                	j	80005ae4 <sys_exec+0xfc>
      argv[i] = 0;
    80005aaa:	0a8e                	slli	s5,s5,0x3
    80005aac:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005ab0:	00878ab3          	add	s5,a5,s0
    80005ab4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ab8:	e4040593          	addi	a1,s0,-448
    80005abc:	f4040513          	addi	a0,s0,-192
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	172080e7          	jalr	370(ra) # 80004c32 <exec>
    80005ac8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aca:	f4040993          	addi	s3,s0,-192
    80005ace:	6088                	ld	a0,0(s1)
    80005ad0:	c911                	beqz	a0,80005ae4 <sys_exec+0xfc>
    kfree(argv[i]);
    80005ad2:	ffffb097          	auipc	ra,0xffffb
    80005ad6:	f10080e7          	jalr	-240(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ada:	04a1                	addi	s1,s1,8
    80005adc:	ff3499e3          	bne	s1,s3,80005ace <sys_exec+0xe6>
    80005ae0:	a011                	j	80005ae4 <sys_exec+0xfc>
  return -1;
    80005ae2:	597d                	li	s2,-1
}
    80005ae4:	854a                	mv	a0,s2
    80005ae6:	60be                	ld	ra,456(sp)
    80005ae8:	641e                	ld	s0,448(sp)
    80005aea:	74fa                	ld	s1,440(sp)
    80005aec:	795a                	ld	s2,432(sp)
    80005aee:	79ba                	ld	s3,424(sp)
    80005af0:	7a1a                	ld	s4,416(sp)
    80005af2:	6afa                	ld	s5,408(sp)
    80005af4:	6179                	addi	sp,sp,464
    80005af6:	8082                	ret

0000000080005af8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005af8:	7139                	addi	sp,sp,-64
    80005afa:	fc06                	sd	ra,56(sp)
    80005afc:	f822                	sd	s0,48(sp)
    80005afe:	f426                	sd	s1,40(sp)
    80005b00:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b02:	ffffc097          	auipc	ra,0xffffc
    80005b06:	e94080e7          	jalr	-364(ra) # 80001996 <myproc>
    80005b0a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b0c:	fd840593          	addi	a1,s0,-40
    80005b10:	4501                	li	a0,0
    80005b12:	ffffd097          	auipc	ra,0xffffd
    80005b16:	0c0080e7          	jalr	192(ra) # 80002bd2 <argaddr>
    return -1;
    80005b1a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b1c:	0e054063          	bltz	a0,80005bfc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b20:	fc840593          	addi	a1,s0,-56
    80005b24:	fd040513          	addi	a0,s0,-48
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	de6080e7          	jalr	-538(ra) # 8000490e <pipealloc>
    return -1;
    80005b30:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b32:	0c054563          	bltz	a0,80005bfc <sys_pipe+0x104>
  fd0 = -1;
    80005b36:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b3a:	fd043503          	ld	a0,-48(s0)
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	504080e7          	jalr	1284(ra) # 80005042 <fdalloc>
    80005b46:	fca42223          	sw	a0,-60(s0)
    80005b4a:	08054c63          	bltz	a0,80005be2 <sys_pipe+0xea>
    80005b4e:	fc843503          	ld	a0,-56(s0)
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	4f0080e7          	jalr	1264(ra) # 80005042 <fdalloc>
    80005b5a:	fca42023          	sw	a0,-64(s0)
    80005b5e:	06054963          	bltz	a0,80005bd0 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b62:	4691                	li	a3,4
    80005b64:	fc440613          	addi	a2,s0,-60
    80005b68:	fd843583          	ld	a1,-40(s0)
    80005b6c:	68a8                	ld	a0,80(s1)
    80005b6e:	ffffc097          	auipc	ra,0xffffc
    80005b72:	aec080e7          	jalr	-1300(ra) # 8000165a <copyout>
    80005b76:	02054063          	bltz	a0,80005b96 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b7a:	4691                	li	a3,4
    80005b7c:	fc040613          	addi	a2,s0,-64
    80005b80:	fd843583          	ld	a1,-40(s0)
    80005b84:	0591                	addi	a1,a1,4
    80005b86:	68a8                	ld	a0,80(s1)
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	ad2080e7          	jalr	-1326(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b90:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b92:	06055563          	bgez	a0,80005bfc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b96:	fc442783          	lw	a5,-60(s0)
    80005b9a:	07e9                	addi	a5,a5,26
    80005b9c:	078e                	slli	a5,a5,0x3
    80005b9e:	97a6                	add	a5,a5,s1
    80005ba0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ba4:	fc042783          	lw	a5,-64(s0)
    80005ba8:	07e9                	addi	a5,a5,26
    80005baa:	078e                	slli	a5,a5,0x3
    80005bac:	00f48533          	add	a0,s1,a5
    80005bb0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bb4:	fd043503          	ld	a0,-48(s0)
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	a26080e7          	jalr	-1498(ra) # 800045de <fileclose>
    fileclose(wf);
    80005bc0:	fc843503          	ld	a0,-56(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	a1a080e7          	jalr	-1510(ra) # 800045de <fileclose>
    return -1;
    80005bcc:	57fd                	li	a5,-1
    80005bce:	a03d                	j	80005bfc <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bd0:	fc442783          	lw	a5,-60(s0)
    80005bd4:	0007c763          	bltz	a5,80005be2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bd8:	07e9                	addi	a5,a5,26
    80005bda:	078e                	slli	a5,a5,0x3
    80005bdc:	97a6                	add	a5,a5,s1
    80005bde:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005be2:	fd043503          	ld	a0,-48(s0)
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	9f8080e7          	jalr	-1544(ra) # 800045de <fileclose>
    fileclose(wf);
    80005bee:	fc843503          	ld	a0,-56(s0)
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	9ec080e7          	jalr	-1556(ra) # 800045de <fileclose>
    return -1;
    80005bfa:	57fd                	li	a5,-1
}
    80005bfc:	853e                	mv	a0,a5
    80005bfe:	70e2                	ld	ra,56(sp)
    80005c00:	7442                	ld	s0,48(sp)
    80005c02:	74a2                	ld	s1,40(sp)
    80005c04:	6121                	addi	sp,sp,64
    80005c06:	8082                	ret
	...

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	d93fc0ef          	jal	ra,800029e2 <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	6d0c                	ld	a1,24(a0)
    80005cac:	7110                	ld	a2,32(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	c82080e7          	jalr	-894(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	97aa                	add	a5,a5,a0
    80005d0c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	c4a080e7          	jalr	-950(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5151b          	slliw	a0,a0,0xd
    80005d2c:	0c2017b7          	lui	a5,0xc201
    80005d30:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d32:	43c8                	lw	a0,4(a5)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c22080e7          	jalr	-990(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	06a7c863          	blt	a5,a0,80005de0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005d74:	0001d717          	auipc	a4,0x1d
    80005d78:	28c70713          	addi	a4,a4,652 # 80023000 <disk>
    80005d7c:	972a                	add	a4,a4,a0
    80005d7e:	6789                	lui	a5,0x2
    80005d80:	97ba                	add	a5,a5,a4
    80005d82:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d86:	e7ad                	bnez	a5,80005df0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d88:	00451793          	slli	a5,a0,0x4
    80005d8c:	0001f717          	auipc	a4,0x1f
    80005d90:	27470713          	addi	a4,a4,628 # 80025000 <disk+0x2000>
    80005d94:	6314                	ld	a3,0(a4)
    80005d96:	96be                	add	a3,a3,a5
    80005d98:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d9c:	6314                	ld	a3,0(a4)
    80005d9e:	96be                	add	a3,a3,a5
    80005da0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005da4:	6314                	ld	a3,0(a4)
    80005da6:	96be                	add	a3,a3,a5
    80005da8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dac:	6318                	ld	a4,0(a4)
    80005dae:	97ba                	add	a5,a5,a4
    80005db0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005db4:	0001d717          	auipc	a4,0x1d
    80005db8:	24c70713          	addi	a4,a4,588 # 80023000 <disk>
    80005dbc:	972a                	add	a4,a4,a0
    80005dbe:	6789                	lui	a5,0x2
    80005dc0:	97ba                	add	a5,a5,a4
    80005dc2:	4705                	li	a4,1
    80005dc4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dc8:	0001f517          	auipc	a0,0x1f
    80005dcc:	25050513          	addi	a0,a0,592 # 80025018 <disk+0x2018>
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	416080e7          	jalr	1046(ra) # 800021e6 <wakeup>
}
    80005dd8:	60a2                	ld	ra,8(sp)
    80005dda:	6402                	ld	s0,0(sp)
    80005ddc:	0141                	addi	sp,sp,16
    80005dde:	8082                	ret
    panic("free_desc 1");
    80005de0:	00003517          	auipc	a0,0x3
    80005de4:	a1050513          	addi	a0,a0,-1520 # 800087f0 <syscalls+0x328>
    80005de8:	ffffa097          	auipc	ra,0xffffa
    80005dec:	752080e7          	jalr	1874(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005df0:	00003517          	auipc	a0,0x3
    80005df4:	a1050513          	addi	a0,a0,-1520 # 80008800 <syscalls+0x338>
    80005df8:	ffffa097          	auipc	ra,0xffffa
    80005dfc:	742080e7          	jalr	1858(ra) # 8000053a <panic>

0000000080005e00 <virtio_disk_init>:
{
    80005e00:	1101                	addi	sp,sp,-32
    80005e02:	ec06                	sd	ra,24(sp)
    80005e04:	e822                	sd	s0,16(sp)
    80005e06:	e426                	sd	s1,8(sp)
    80005e08:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e0a:	00003597          	auipc	a1,0x3
    80005e0e:	a0658593          	addi	a1,a1,-1530 # 80008810 <syscalls+0x348>
    80005e12:	0001f517          	auipc	a0,0x1f
    80005e16:	31650513          	addi	a0,a0,790 # 80025128 <disk+0x2128>
    80005e1a:	ffffb097          	auipc	ra,0xffffb
    80005e1e:	d26080e7          	jalr	-730(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e22:	100017b7          	lui	a5,0x10001
    80005e26:	4398                	lw	a4,0(a5)
    80005e28:	2701                	sext.w	a4,a4
    80005e2a:	747277b7          	lui	a5,0x74727
    80005e2e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e32:	0ef71063          	bne	a4,a5,80005f12 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e36:	100017b7          	lui	a5,0x10001
    80005e3a:	43dc                	lw	a5,4(a5)
    80005e3c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e3e:	4705                	li	a4,1
    80005e40:	0ce79963          	bne	a5,a4,80005f12 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e44:	100017b7          	lui	a5,0x10001
    80005e48:	479c                	lw	a5,8(a5)
    80005e4a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e4c:	4709                	li	a4,2
    80005e4e:	0ce79263          	bne	a5,a4,80005f12 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e52:	100017b7          	lui	a5,0x10001
    80005e56:	47d8                	lw	a4,12(a5)
    80005e58:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e5a:	554d47b7          	lui	a5,0x554d4
    80005e5e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e62:	0af71863          	bne	a4,a5,80005f12 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e66:	100017b7          	lui	a5,0x10001
    80005e6a:	4705                	li	a4,1
    80005e6c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	470d                	li	a4,3
    80005e70:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e72:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e74:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e78:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e7c:	8f75                	and	a4,a4,a3
    80005e7e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e80:	472d                	li	a4,11
    80005e82:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e84:	473d                	li	a4,15
    80005e86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e88:	6705                	lui	a4,0x1
    80005e8a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e8c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e90:	5bdc                	lw	a5,52(a5)
    80005e92:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e94:	c7d9                	beqz	a5,80005f22 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e96:	471d                	li	a4,7
    80005e98:	08f77d63          	bgeu	a4,a5,80005f32 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e9c:	100014b7          	lui	s1,0x10001
    80005ea0:	47a1                	li	a5,8
    80005ea2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ea4:	6609                	lui	a2,0x2
    80005ea6:	4581                	li	a1,0
    80005ea8:	0001d517          	auipc	a0,0x1d
    80005eac:	15850513          	addi	a0,a0,344 # 80023000 <disk>
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	e1c080e7          	jalr	-484(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005eb8:	0001d717          	auipc	a4,0x1d
    80005ebc:	14870713          	addi	a4,a4,328 # 80023000 <disk>
    80005ec0:	00c75793          	srli	a5,a4,0xc
    80005ec4:	2781                	sext.w	a5,a5
    80005ec6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005ec8:	0001f797          	auipc	a5,0x1f
    80005ecc:	13878793          	addi	a5,a5,312 # 80025000 <disk+0x2000>
    80005ed0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ed2:	0001d717          	auipc	a4,0x1d
    80005ed6:	1ae70713          	addi	a4,a4,430 # 80023080 <disk+0x80>
    80005eda:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005edc:	0001e717          	auipc	a4,0x1e
    80005ee0:	12470713          	addi	a4,a4,292 # 80024000 <disk+0x1000>
    80005ee4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ee6:	4705                	li	a4,1
    80005ee8:	00e78c23          	sb	a4,24(a5)
    80005eec:	00e78ca3          	sb	a4,25(a5)
    80005ef0:	00e78d23          	sb	a4,26(a5)
    80005ef4:	00e78da3          	sb	a4,27(a5)
    80005ef8:	00e78e23          	sb	a4,28(a5)
    80005efc:	00e78ea3          	sb	a4,29(a5)
    80005f00:	00e78f23          	sb	a4,30(a5)
    80005f04:	00e78fa3          	sb	a4,31(a5)
}
    80005f08:	60e2                	ld	ra,24(sp)
    80005f0a:	6442                	ld	s0,16(sp)
    80005f0c:	64a2                	ld	s1,8(sp)
    80005f0e:	6105                	addi	sp,sp,32
    80005f10:	8082                	ret
    panic("could not find virtio disk");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	90e50513          	addi	a0,a0,-1778 # 80008820 <syscalls+0x358>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	620080e7          	jalr	1568(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	91e50513          	addi	a0,a0,-1762 # 80008840 <syscalls+0x378>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	610080e7          	jalr	1552(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	92e50513          	addi	a0,a0,-1746 # 80008860 <syscalls+0x398>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	600080e7          	jalr	1536(ra) # 8000053a <panic>

0000000080005f42 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f42:	7119                	addi	sp,sp,-128
    80005f44:	fc86                	sd	ra,120(sp)
    80005f46:	f8a2                	sd	s0,112(sp)
    80005f48:	f4a6                	sd	s1,104(sp)
    80005f4a:	f0ca                	sd	s2,96(sp)
    80005f4c:	ecce                	sd	s3,88(sp)
    80005f4e:	e8d2                	sd	s4,80(sp)
    80005f50:	e4d6                	sd	s5,72(sp)
    80005f52:	e0da                	sd	s6,64(sp)
    80005f54:	fc5e                	sd	s7,56(sp)
    80005f56:	f862                	sd	s8,48(sp)
    80005f58:	f466                	sd	s9,40(sp)
    80005f5a:	f06a                	sd	s10,32(sp)
    80005f5c:	ec6e                	sd	s11,24(sp)
    80005f5e:	0100                	addi	s0,sp,128
    80005f60:	8aaa                	mv	s5,a0
    80005f62:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f64:	00c52c83          	lw	s9,12(a0)
    80005f68:	001c9c9b          	slliw	s9,s9,0x1
    80005f6c:	1c82                	slli	s9,s9,0x20
    80005f6e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f72:	0001f517          	auipc	a0,0x1f
    80005f76:	1b650513          	addi	a0,a0,438 # 80025128 <disk+0x2128>
    80005f7a:	ffffb097          	auipc	ra,0xffffb
    80005f7e:	c56080e7          	jalr	-938(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005f82:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f84:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f86:	0001dc17          	auipc	s8,0x1d
    80005f8a:	07ac0c13          	addi	s8,s8,122 # 80023000 <disk>
    80005f8e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f90:	4b0d                	li	s6,3
    80005f92:	a0ad                	j	80005ffc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f94:	00fc0733          	add	a4,s8,a5
    80005f98:	975e                	add	a4,a4,s7
    80005f9a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f9e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fa0:	0207c563          	bltz	a5,80005fca <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fa4:	2905                	addiw	s2,s2,1
    80005fa6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005fa8:	19690c63          	beq	s2,s6,80006140 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005fac:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005fae:	0001f717          	auipc	a4,0x1f
    80005fb2:	06a70713          	addi	a4,a4,106 # 80025018 <disk+0x2018>
    80005fb6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005fb8:	00074683          	lbu	a3,0(a4)
    80005fbc:	fee1                	bnez	a3,80005f94 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fbe:	2785                	addiw	a5,a5,1
    80005fc0:	0705                	addi	a4,a4,1
    80005fc2:	fe979be3          	bne	a5,s1,80005fb8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fc6:	57fd                	li	a5,-1
    80005fc8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fca:	01205d63          	blez	s2,80005fe4 <virtio_disk_rw+0xa2>
    80005fce:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fd0:	000a2503          	lw	a0,0(s4)
    80005fd4:	00000097          	auipc	ra,0x0
    80005fd8:	d92080e7          	jalr	-622(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80005fdc:	2d85                	addiw	s11,s11,1
    80005fde:	0a11                	addi	s4,s4,4
    80005fe0:	ff2d98e3          	bne	s11,s2,80005fd0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fe4:	0001f597          	auipc	a1,0x1f
    80005fe8:	14458593          	addi	a1,a1,324 # 80025128 <disk+0x2128>
    80005fec:	0001f517          	auipc	a0,0x1f
    80005ff0:	02c50513          	addi	a0,a0,44 # 80025018 <disk+0x2018>
    80005ff4:	ffffc097          	auipc	ra,0xffffc
    80005ff8:	066080e7          	jalr	102(ra) # 8000205a <sleep>
  for(int i = 0; i < 3; i++){
    80005ffc:	f8040a13          	addi	s4,s0,-128
{
    80006000:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006002:	894e                	mv	s2,s3
    80006004:	b765                	j	80005fac <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006006:	0001f697          	auipc	a3,0x1f
    8000600a:	ffa6b683          	ld	a3,-6(a3) # 80025000 <disk+0x2000>
    8000600e:	96ba                	add	a3,a3,a4
    80006010:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006014:	0001d817          	auipc	a6,0x1d
    80006018:	fec80813          	addi	a6,a6,-20 # 80023000 <disk>
    8000601c:	0001f697          	auipc	a3,0x1f
    80006020:	fe468693          	addi	a3,a3,-28 # 80025000 <disk+0x2000>
    80006024:	6290                	ld	a2,0(a3)
    80006026:	963a                	add	a2,a2,a4
    80006028:	00c65583          	lhu	a1,12(a2)
    8000602c:	0015e593          	ori	a1,a1,1
    80006030:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006034:	f8842603          	lw	a2,-120(s0)
    80006038:	628c                	ld	a1,0(a3)
    8000603a:	972e                	add	a4,a4,a1
    8000603c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006040:	20050593          	addi	a1,a0,512
    80006044:	0592                	slli	a1,a1,0x4
    80006046:	95c2                	add	a1,a1,a6
    80006048:	577d                	li	a4,-1
    8000604a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000604e:	00461713          	slli	a4,a2,0x4
    80006052:	6290                	ld	a2,0(a3)
    80006054:	963a                	add	a2,a2,a4
    80006056:	03078793          	addi	a5,a5,48
    8000605a:	97c2                	add	a5,a5,a6
    8000605c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000605e:	629c                	ld	a5,0(a3)
    80006060:	97ba                	add	a5,a5,a4
    80006062:	4605                	li	a2,1
    80006064:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006066:	629c                	ld	a5,0(a3)
    80006068:	97ba                	add	a5,a5,a4
    8000606a:	4809                	li	a6,2
    8000606c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006070:	629c                	ld	a5,0(a3)
    80006072:	97ba                	add	a5,a5,a4
    80006074:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006078:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000607c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006080:	6698                	ld	a4,8(a3)
    80006082:	00275783          	lhu	a5,2(a4)
    80006086:	8b9d                	andi	a5,a5,7
    80006088:	0786                	slli	a5,a5,0x1
    8000608a:	973e                	add	a4,a4,a5
    8000608c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006090:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006094:	6698                	ld	a4,8(a3)
    80006096:	00275783          	lhu	a5,2(a4)
    8000609a:	2785                	addiw	a5,a5,1
    8000609c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060a0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060a4:	100017b7          	lui	a5,0x10001
    800060a8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060ac:	004aa783          	lw	a5,4(s5)
    800060b0:	02c79163          	bne	a5,a2,800060d2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800060b4:	0001f917          	auipc	s2,0x1f
    800060b8:	07490913          	addi	s2,s2,116 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800060bc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060be:	85ca                	mv	a1,s2
    800060c0:	8556                	mv	a0,s5
    800060c2:	ffffc097          	auipc	ra,0xffffc
    800060c6:	f98080e7          	jalr	-104(ra) # 8000205a <sleep>
  while(b->disk == 1) {
    800060ca:	004aa783          	lw	a5,4(s5)
    800060ce:	fe9788e3          	beq	a5,s1,800060be <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060d2:	f8042903          	lw	s2,-128(s0)
    800060d6:	20090713          	addi	a4,s2,512
    800060da:	0712                	slli	a4,a4,0x4
    800060dc:	0001d797          	auipc	a5,0x1d
    800060e0:	f2478793          	addi	a5,a5,-220 # 80023000 <disk>
    800060e4:	97ba                	add	a5,a5,a4
    800060e6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060ea:	0001f997          	auipc	s3,0x1f
    800060ee:	f1698993          	addi	s3,s3,-234 # 80025000 <disk+0x2000>
    800060f2:	00491713          	slli	a4,s2,0x4
    800060f6:	0009b783          	ld	a5,0(s3)
    800060fa:	97ba                	add	a5,a5,a4
    800060fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006100:	854a                	mv	a0,s2
    80006102:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006106:	00000097          	auipc	ra,0x0
    8000610a:	c60080e7          	jalr	-928(ra) # 80005d66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000610e:	8885                	andi	s1,s1,1
    80006110:	f0ed                	bnez	s1,800060f2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006112:	0001f517          	auipc	a0,0x1f
    80006116:	01650513          	addi	a0,a0,22 # 80025128 <disk+0x2128>
    8000611a:	ffffb097          	auipc	ra,0xffffb
    8000611e:	b6a080e7          	jalr	-1174(ra) # 80000c84 <release>
}
    80006122:	70e6                	ld	ra,120(sp)
    80006124:	7446                	ld	s0,112(sp)
    80006126:	74a6                	ld	s1,104(sp)
    80006128:	7906                	ld	s2,96(sp)
    8000612a:	69e6                	ld	s3,88(sp)
    8000612c:	6a46                	ld	s4,80(sp)
    8000612e:	6aa6                	ld	s5,72(sp)
    80006130:	6b06                	ld	s6,64(sp)
    80006132:	7be2                	ld	s7,56(sp)
    80006134:	7c42                	ld	s8,48(sp)
    80006136:	7ca2                	ld	s9,40(sp)
    80006138:	7d02                	ld	s10,32(sp)
    8000613a:	6de2                	ld	s11,24(sp)
    8000613c:	6109                	addi	sp,sp,128
    8000613e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006140:	f8042503          	lw	a0,-128(s0)
    80006144:	20050793          	addi	a5,a0,512
    80006148:	0792                	slli	a5,a5,0x4
  if(write)
    8000614a:	0001d817          	auipc	a6,0x1d
    8000614e:	eb680813          	addi	a6,a6,-330 # 80023000 <disk>
    80006152:	00f80733          	add	a4,a6,a5
    80006156:	01a036b3          	snez	a3,s10
    8000615a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000615e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006162:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006166:	7679                	lui	a2,0xffffe
    80006168:	963e                	add	a2,a2,a5
    8000616a:	0001f697          	auipc	a3,0x1f
    8000616e:	e9668693          	addi	a3,a3,-362 # 80025000 <disk+0x2000>
    80006172:	6298                	ld	a4,0(a3)
    80006174:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006176:	0a878593          	addi	a1,a5,168
    8000617a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000617c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000617e:	6298                	ld	a4,0(a3)
    80006180:	9732                	add	a4,a4,a2
    80006182:	45c1                	li	a1,16
    80006184:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006186:	6298                	ld	a4,0(a3)
    80006188:	9732                	add	a4,a4,a2
    8000618a:	4585                	li	a1,1
    8000618c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006190:	f8442703          	lw	a4,-124(s0)
    80006194:	628c                	ld	a1,0(a3)
    80006196:	962e                	add	a2,a2,a1
    80006198:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000619c:	0712                	slli	a4,a4,0x4
    8000619e:	6290                	ld	a2,0(a3)
    800061a0:	963a                	add	a2,a2,a4
    800061a2:	058a8593          	addi	a1,s5,88
    800061a6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061a8:	6294                	ld	a3,0(a3)
    800061aa:	96ba                	add	a3,a3,a4
    800061ac:	40000613          	li	a2,1024
    800061b0:	c690                	sw	a2,8(a3)
  if(write)
    800061b2:	e40d1ae3          	bnez	s10,80006006 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061b6:	0001f697          	auipc	a3,0x1f
    800061ba:	e4a6b683          	ld	a3,-438(a3) # 80025000 <disk+0x2000>
    800061be:	96ba                	add	a3,a3,a4
    800061c0:	4609                	li	a2,2
    800061c2:	00c69623          	sh	a2,12(a3)
    800061c6:	b5b9                	j	80006014 <virtio_disk_rw+0xd2>

00000000800061c8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061c8:	1101                	addi	sp,sp,-32
    800061ca:	ec06                	sd	ra,24(sp)
    800061cc:	e822                	sd	s0,16(sp)
    800061ce:	e426                	sd	s1,8(sp)
    800061d0:	e04a                	sd	s2,0(sp)
    800061d2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061d4:	0001f517          	auipc	a0,0x1f
    800061d8:	f5450513          	addi	a0,a0,-172 # 80025128 <disk+0x2128>
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	9f4080e7          	jalr	-1548(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061e4:	10001737          	lui	a4,0x10001
    800061e8:	533c                	lw	a5,96(a4)
    800061ea:	8b8d                	andi	a5,a5,3
    800061ec:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061ee:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061f2:	0001f797          	auipc	a5,0x1f
    800061f6:	e0e78793          	addi	a5,a5,-498 # 80025000 <disk+0x2000>
    800061fa:	6b94                	ld	a3,16(a5)
    800061fc:	0207d703          	lhu	a4,32(a5)
    80006200:	0026d783          	lhu	a5,2(a3)
    80006204:	06f70163          	beq	a4,a5,80006266 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006208:	0001d917          	auipc	s2,0x1d
    8000620c:	df890913          	addi	s2,s2,-520 # 80023000 <disk>
    80006210:	0001f497          	auipc	s1,0x1f
    80006214:	df048493          	addi	s1,s1,-528 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006218:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000621c:	6898                	ld	a4,16(s1)
    8000621e:	0204d783          	lhu	a5,32(s1)
    80006222:	8b9d                	andi	a5,a5,7
    80006224:	078e                	slli	a5,a5,0x3
    80006226:	97ba                	add	a5,a5,a4
    80006228:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000622a:	20078713          	addi	a4,a5,512
    8000622e:	0712                	slli	a4,a4,0x4
    80006230:	974a                	add	a4,a4,s2
    80006232:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006236:	e731                	bnez	a4,80006282 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006238:	20078793          	addi	a5,a5,512
    8000623c:	0792                	slli	a5,a5,0x4
    8000623e:	97ca                	add	a5,a5,s2
    80006240:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006242:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006246:	ffffc097          	auipc	ra,0xffffc
    8000624a:	fa0080e7          	jalr	-96(ra) # 800021e6 <wakeup>

    disk.used_idx += 1;
    8000624e:	0204d783          	lhu	a5,32(s1)
    80006252:	2785                	addiw	a5,a5,1
    80006254:	17c2                	slli	a5,a5,0x30
    80006256:	93c1                	srli	a5,a5,0x30
    80006258:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000625c:	6898                	ld	a4,16(s1)
    8000625e:	00275703          	lhu	a4,2(a4)
    80006262:	faf71be3          	bne	a4,a5,80006218 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006266:	0001f517          	auipc	a0,0x1f
    8000626a:	ec250513          	addi	a0,a0,-318 # 80025128 <disk+0x2128>
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	a16080e7          	jalr	-1514(ra) # 80000c84 <release>
}
    80006276:	60e2                	ld	ra,24(sp)
    80006278:	6442                	ld	s0,16(sp)
    8000627a:	64a2                	ld	s1,8(sp)
    8000627c:	6902                	ld	s2,0(sp)
    8000627e:	6105                	addi	sp,sp,32
    80006280:	8082                	ret
      panic("virtio_disk_intr status");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	5fe50513          	addi	a0,a0,1534 # 80008880 <syscalls+0x3b8>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b0080e7          	jalr	688(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
