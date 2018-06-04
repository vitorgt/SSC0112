/********************************************************
 * Codigo por:											*
 *  Turma 2  Grupo 9									*
 *   10284667 Fabio Fogarin Destro 						*
 *   10295304 Paulo Andre de Oliveira Carneiro 			*
 *   10295263 Renata Vinhaga dos Anjos					*
 *   10284952 Vitor Henrique Gratiere Torres 			*
 *														*
 *	Todas as partes do trabalho foram desenvolvidas em	*
 * 	grupo, em que todos os integrantes desenvolviam e	*
 *	conferiam as funções e as funcionalidades.			*
 *	Todos participaram igualmente do projeto.			*
 ********************************************************/

#include<stdio.h>
#include<stdlib.h>
#include<pthread.h>
#include<semaphore.h>

#define RegDst0		((sinais & (1 << 0)) != 0)
#define RegDst1		((sinais & (1 << 1)) != 0)
#define EscReg		((sinais & (1 << 2)) != 0)
#define UALFonteA	((sinais & (1 << 3)) != 0)
#define UALFonteB0	((sinais & (1 << 4)) != 0)
#define UALFonteB1	((sinais & (1 << 5)) != 0)
#define UALOp0		((sinais & (1 << 6)) != 0)
#define UALOp1		((sinais & (1 << 7)) != 0)
#define FontePC0	((sinais & (1 << 8)) != 0)
#define FontePC1	((sinais & (1 << 9)) != 0)
#define PCEscCond	((sinais & (1 << 10)) != 0)
#define PCEsc		((sinais & (1 << 11)) != 0)
#define IouD		((sinais & (1 << 12)) != 0)
#define LerMem		((sinais & (1 << 13)) != 0)
#define EscMem		((sinais & (1 << 14)) != 0)
#define BNE			((sinais & (1 << 15)) != 0)
#define IREsc		((sinais & (1 << 16)) != 0)
#define MemParaReg0	((sinais & (1 << 17)) != 0)
#define MemParaReg1	((sinais & (1 << 18)) != 0)

#define INS_31_26	((IR & 0b11111100000000000000000000000000) >> 26)
#define INS_25_21	((IR & 0b00000011111000000000000000000000) >> 21)
#define INS_20_16	((IR & 0b00000000000111110000000000000000) >> 16)
#define INS_15_00	((IR & 0b00000000000000001111111111111111) >> 0)
#define INS_15_11	((IR & 0b00000000000000001111100000000000) >> 11)
#define INS_25_00	((IR & 0b00000011111111111111111111111111) >> 0)
#define INS_05_00	((IR & 0b00000000000000000000000000111111) >> 0)

#define PC_31_28	(PC & 0b11110000000000000000000000000000)

#define S0 ((S & (1 << 0)) != 0)
#define S1 ((S & (1 << 1)) != 0)
#define S2 ((S & (1 << 2)) != 0)
#define S3 ((S & (1 << 3)) != 0)

#define Est00 (!S3 & !S2 & !S1 & !S0)
#define Est01 (!S3 & !S2 & !S1 &  S0)
#define Est02 (!S3 & !S2 &  S1 & !S0)
#define Est03 (!S3 & !S2 &  S1 &  S0)
#define Est04 (!S3 &  S2 & !S1 & !S0)
#define Est05 (!S3 &  S2 & !S1 &  S0)
#define Est06 (!S3 &  S2 &  S1 & !S0)
#define Est07 (!S3 &  S2 &  S1 &  S0)
#define Est08 ( S3 & !S2 & !S1 & !S0)
#define Est09 ( S3 & !S2 & !S1 &  S0)
#define Est10 ( S3 & !S2 &  S1 & !S0)
#define Est11 ( S3 & !S2 &  S1 &  S0)
#define Est12 ( S3 &  S2 & !S1 & !S0)
#define Est13 ( S3 &  S2 & !S1 &  S0)
#define Est14 ( S3 &  S2 &  S1 & !S0)
#define Est15 ( S3 &  S2 &  S1 &  S0)

#define OpTipoR	(INS_31_26 == 0b000000)
#define OpJ		(INS_31_26 == 0b000010)
#define OpJAL	(INS_31_26 == 0b000011)
#define OpBEQ	(INS_31_26 == 0b000100)
#define OpBNE	(INS_31_26 == 0b000101)
#define OpADDI	(INS_31_26 == 0b001000)
#define OpANDI	(INS_31_26 == 0b001100)
#define OpJR	(INS_31_26 == 0b010100)
#define OpJALR	(INS_31_26 == 0b010101)
#define OpLW	(INS_31_26 == 0b100011)
#define OpSW	(INS_31_26 == 0b101011)

/* 
 * Serao utilizados os PREFIXOS:
 *   S para Semaforos
 *   T para Thread handlers
 *   F para Funcoes
 *   N para simular barramentos (proximo valor da variavel)
 */

//Semaforos para cada thread
sem_t S_main, S_UC, S_Memory, S_Registers, S_UAL,S_UAL_Operacao;
sem_t S_or_and_pc, S_mux_BNE, S_mux_ioud, S_mux_RegDst;
sem_t S_mux_MemParaReg, S_mux_UALFonteA, S_mux_UALFonteB, S_mux_FontePC;

/*
 * Representação de cada bit para o estado e o próximo estado
 *   0   0   0   0 |   0   0   0   0
 * NS3 NS2 NS1 NS0 |  S3  S2  S1  S0
 */
char S; // estado e novo estado
int N_PC, N_IR, N_MDR, N_A, N_B, N_AluOut;
int PC, IR, MDR, A, B, AluOut;
int PCfim, PCbne, zero, UALresultado;
int Address, WriteData, MemData, WriteRegister;
int UALFonteA_val, UALFonteB_val, UAL_Operacao;
int sinais; // Variavel para os sinais de controle da UC
int reg[32]; // Registradores
unsigned char RAM[128]; // Memória RAM
int KILLALL; // se o programa for acabar define KILLALL = 1 e acorda todos os processos
int ERRO = 0;//Classifica possiveis erros encontrados

//Recupera uma palavra da ram, isto eh concatena as 4 posicoes de Ram inicializando pelo endereco passado como argumento
unsigned int get_ram(int at){//'at' eh enderecado a byte
	if(at < 0 || at > 128){ // verifica se é uma posiçao valida na memoria
		ERRO = 2; // erro de acesso invalido na memoria
		return 0;
	}
	return (unsigned int)(((int)RAM[at])<<24 | ((int)RAM[at+1])<<16 | ((int)RAM[at+2])<<8 | ((int)RAM[at+3]));
}

//Funcao recebe uma word de 32 bits e a divide em bytes, cada byte ocupara uma posicao da ram 
void set_ram(int at, unsigned int input){//'at' eh enderecado a byte
	if(at < 0 || at > 128){ // verifia se é uma posição valida na memoria
		ERRO = 2;
		return;
	}
	RAM[at+0] = (unsigned char)((input & 0b11111111000000000000000000000000)>>24);
	RAM[at+1] = (unsigned char)((input & 0b00000000111111110000000000000000)>>16);
	RAM[at+2] = (unsigned char)((input & 0b00000000000000001111111100000000)>>8);
	RAM[at+3] = (unsigned char)((input & 0b00000000000000000000000011111111));
}

//Funcao zera todos os registradores e todas as posicoes de memoria
void zera(){
	S = 0;
	N_PC = N_IR = N_MDR = N_A = N_B = N_AluOut = 0;
	PC = IR = MDR = A = B = AluOut = 0;
	PCfim = PCbne = zero = UALresultado = 0;
	Address = WriteData = MemData = WriteRegister = 0;
	UALFonteA_val = UALFonteB_val = UAL_Operacao = 0;
	sinais = 0;
	for(int i = 0; i < 32; i++){
		reg[i] = 0;
		set_ram(i*4, 0);
	}
	KILLALL = 0;
	ERRO = 0;
}

/***************************** Print Functions *****************************/

void print_barramentos(){
	printf("PC=%-10u\tIR=%-10u\tMDR=%-10u\n", PC, IR, MDR);
	printf("A=%-10d\tB=%-10d\tAluOut=%-10d\n\n", A, B, AluOut);
	fflush(0);
}

void print_sinais(){
	printf("Controle=%u\n\n", sinais);
	fflush(0);
}

void print_regs(){
	printf("Banco de Registradores\n");
	char RegNames[32][3] = {{"r0\0"},{"at\0"},{"v0\0"},{"v1\0"},
		{"a0\0"},{"a1\0"},{"a2\0"},{"a3\0"},
		{"t0\0"},{"t1\0"},{"t2\0"},{"t3\0"},
		{"t4\0"},{"t5\0"},{"t6\0"},{"t7\0"},
		{"s0\0"},{"s1\0"},{"s2\0"},{"s3\0"},
		{"s4\0"},{"s5\0"},{"s6\0"},{"s7\0"},
		{"t8\0"},{"t9\0"},{"k0\0"},{"k1\0"},
		{"gp\0"},{"sp\0"},{"fp\0"},{"ra\0"}};
	for(int i = 0; i < 32; i+=8){
		printf("R%02d(%s)=%-5d\t", i, RegNames[i], reg[i]);
		if(i >= 24 && i != 31){
			printf("\n");
			i-=31;
		}
	}
	printf("\n\n");
	fflush(0);
}

void print_ram(){
	printf("Memória (endereços a byte)\n");
	for(int i = 0; i < 128; i+=32){
		printf("[%02d]=%-11u\t", i, get_ram(i));
		if(i >= 96 && i != 124){
			printf("\n");
			i-=124;
		}
	}
	printf("\n\n");
	fflush(0);
}

/***************************** Fim Print Functions *****************************/

void *F_mux_BNE(){
	while(1){
		sem_wait(&S_mux_BNE); //So espera a ula
		if(KILLALL) pthread_exit(0);

		if(BNE == 0) PCbne = zero;
		if(BNE == 1) PCbne = !zero;

		sem_post(&S_or_and_pc);
	}
}

//funcao que realiza as equacoes logicas de and e de or e seta PCFim para 0 ou 1, liberando ou nao a escrita em PC
void *F_or_and_pc(){
	while(1){
		sem_wait(&S_or_and_pc);//So espera o BNE
		if(KILLALL) pthread_exit(0);

		PCfim = (PCbne && PCEscCond) || PCEsc;

		sem_post(&S_main);
	}
}

//esse mux eh responsavel por definir de onde vira o conteudo que sera escrito em PC , salvando o conteudo em uma variavel temporaria que armazenara
//o conteudo do novo PC e espera para fazer a atribuicao no proximo tique de clock, quando os sinais permitirem essa escrita
void *F_mux_FontePC(void *p_arg){
	while(1){
		sem_wait(&S_mux_FontePC);//So espera a ula
		if(KILLALL) pthread_exit(0);

		if(FontePC1 == 0 && FontePC0 == 0){
			N_PC = UALresultado;
		}else if(FontePC1 == 0 && FontePC0 == 1){
			N_PC = AluOut;
		}else if(FontePC1 == 1 && FontePC0 == 0){
			N_PC = (INS_25_00 << 2) | PC_31_28;
		}else if(FontePC1 == 1 && FontePC0 == 1){
			N_PC = A;
		}

		sem_post(&S_main);
	}
}

//Essa funcao realiza as operacoes da ULA de acordo com a variavel UAL_Operacao que foi setada na ALU control
void *F_UAL(void *p_arg){
	while(1){
		for(int i = 0; i < 3; i++){ // aguarda o F_UAL_Operacao e os mux UALFonteA e UALFonteB
			sem_wait(&S_UAL);//Espera o ULAOperacao, FonteB e FonteA
		}
		if(KILLALL) pthread_exit(0);

		if(UAL_Operacao == 0){ // soma
			UALresultado = UALFonteA_val + UALFonteB_val;
		}else if(UAL_Operacao == 1){ // subtração
			UALresultado = UALFonteA_val - UALFonteB_val;
		}else if(UAL_Operacao == 2){ // slt
			if(UALFonteA_val <= UALFonteB_val){
				UALresultado = 0;
			}else{
				UALresultado = 1;
			}
		}else if(UAL_Operacao == 3){ // and
			UALresultado = UALFonteA_val & UALFonteB_val;
		}else if(UAL_Operacao == 4){ // or
			UALresultado = UALFonteA_val | UALFonteB_val;
		}else{
			ERRO = 3; // operação invalida
		}

		if(UALresultado == 0){
			zero = 1;
		}else{
			zero = 0;
		}

		N_AluOut = UALresultado;

		sem_post(&S_mux_FontePC);
		sem_post(&S_mux_BNE);
	}
}

//UAL Control, seta qual operacao a ula realizara de acordo com os sinais ULAOP1 e ULAOP0, e caso seja uma operacao do tipo R, com o campo de funcao
void *F_UAL_Operacao(void *p_arg){
	while(1){
		sem_wait(&S_UAL_Operacao);//So espera UC
		if(KILLALL) pthread_exit(0);

		int campo_funcao = INS_05_00;
		if(UALOp1 == 0 && UALOp0 == 0){ //lw e sw, addi
			UAL_Operacao = 0;//soma
		}else if(UALOp1 == 0 && UALOp0 == 1){ //beq e bne
			UAL_Operacao = 1; //subtracao
		}else if(UALOp1 == 1 && UALOp0 == 0){ //tipo R
			if(campo_funcao == 0b100000){
				UAL_Operacao = 0; //soma
			}else if(campo_funcao == 0b100010){
				UAL_Operacao = 1; //subtracao
			}else if(campo_funcao == 0b101010){
				UAL_Operacao = 2; //slt
			}else if(campo_funcao == 0b100100){
				UAL_Operacao = 3; //and
			}else if(campo_funcao == 0b100101){
				UAL_Operacao = 4; //or
			}
		}else if(UALOp1 == 1 && UALOp0 == 1){ //Operacao andi
			UAL_Operacao = 3; //and
		}else{
			ERRO = 3;
		}

		sem_post(&S_UAL);
	}
}

int extensao_sinal(int i){
	if(i & 0b1000000000000000)
		return (i | 0b11111111111111110000000000000000);
	return (i | 0b00000000000000000000000000000000);
}

//Esse funcao corresponde ao mux que define qual sera o segundo valor encaminhado para a ULA
void *F_mux_UALFonteB(void *p_arg){
	while(1){
		sem_wait(&S_mux_UALFonteB);//So espera a UC
		if(KILLALL) pthread_exit(0);

		if(UALFonteB1 == 0 && UALFonteB0 == 0) { // 0
			UALFonteB_val = B;
		}else if(UALFonteB1 == 0 && UALFonteB0 == 1){ // 1
			UALFonteB_val = 4;
		}else if(UALFonteB1 == 1 && UALFonteB0 == 0){ // 2
			UALFonteB_val = extensao_sinal(INS_15_00);
		}else if(UALFonteB1 == 1 && UALFonteB0 == 1){ // 3
			UALFonteB_val = (extensao_sinal(INS_15_00)) << 2;
		}

		sem_post(&S_UAL);
	}
}
//Esse funcao corresponde ao mux que define qual sera o primeiro valor encaminhado para a ULA
void *F_mux_UALFonteA(void *p_arg){
	while(1){
		sem_wait(&S_mux_UALFonteA);//So espera UC
		if(KILLALL) pthread_exit(0);

		if(UALFonteA == 0) {
			UALFonteA_val = PC;
		}else if(UALFonteA == 1){
			UALFonteA_val = A;
		}

		sem_post(&S_UAL);
	}
}


void *F_Registers(void *p_arg){
	while(1){
		for(int i = 0; i < 2; i++){ // aguarda o mux RegDst e MemParaReg finalizar
			sem_wait(&S_Registers);//Espera MemparaReg e RegDst
		}
		if(KILLALL) pthread_exit(0);

		if(INS_25_21 < 0 || INS_25_21 > 31) ERRO = 4;//Verifica se o registrador requisitado esta dentro do intervalo
		else N_A = reg[INS_25_21];

		if(INS_20_16 < 0 || INS_20_16 > 31) ERRO = 4;
		else N_B = reg[INS_20_16];

		if(EscReg == 1){
			// < 2 pq nao pode escrever no 0 ($zero) nem no 1 ($at)
			// nem no 26 (k0) nem 27 (k1)
			if(WriteRegister < 2 || WriteRegister > 31 || WriteRegister == 26 || WriteRegister == 27) ERRO = 4;
			else reg[WriteRegister] = WriteData;
		}

		sem_post(&S_main); // avisa a main que acabou essa parte
	}
}

//Funcoa que corresponde ao mux que define qual o conteudo que sera escrito no registrador destino
void *F_mux_MemParaReg(void *p_arg){
	while(1){
		sem_wait(&S_mux_MemParaReg);//So espera UC
		if(KILLALL) pthread_exit(0);

		if(MemParaReg1 == 0 && MemParaReg0 == 0){ // 0
			WriteData = AluOut;
		}else if(MemParaReg1 == 0 && MemParaReg0 == 1){ // 1
			WriteData = MDR;
		}else if(MemParaReg1 == 1 && MemParaReg0 == 0){ // 2
			WriteData = PC;
		}

		sem_post(&S_Registers); // avisa F_Registers que terminou a execução desse mux
	}
}

//Funcoa que corresponde ao mux que define qual o registrador destino
void *F_mux_RegDst(void *p_arg){
	while(1){
		sem_wait(&S_mux_RegDst);//Espera UC
		if(KILLALL) pthread_exit(0);

		if(RegDst1 == 0 && RegDst0 == 0){ // 0
			WriteRegister = INS_20_16;
		}else if(RegDst1 == 0 && RegDst0 == 1){ // 1
			WriteRegister = INS_15_11;
		}else if(RegDst1 == 1 && RegDst0 == 0){ // 2
			WriteRegister = 31; // registrador 31 ($ra)
		}

		sem_post(&S_Registers); // avisa F_Regiserts que terminou
	}
}

//funcao responsavel pelos acessos a memoria (leitura e escrita)
void *F_Memory(void *p_arg){
	while(1){
		sem_wait(&S_Memory);//Espera o Mux IorD
		if(KILLALL) pthread_exit(0);
		if(LerMem == 1) {
			MemData = get_ram(Address);//verificacao de erros dentro da funcao
			N_IR = MemData;
			N_MDR = MemData;
		}
		if(EscMem == 1){
			set_ram(Address, B);//verificacao de erros dentro da funcao
		}

		sem_post(&S_main); // avisa a main que acabou essa parte
	}
}

//Funcoa que corresponde ao mux que define onde deve ser feito o acesso a memoria (conteudo de pc ou o endereco armazenado no ALUout)
void *F_mux_ioud(void *p_arg){
	while(1){
		sem_wait(&S_mux_ioud);//Espera a UC
		if(KILLALL) pthread_exit(0);

		if(IouD == 0) {
			Address = PC;
		}else if(IouD == 1) {
			Address = AluOut;
		}

		sem_post(&S_Memory);
	}
}

//Funcao correspondente a Unidade de Controle principal, responsavel por setar todos os sinais necessarios para aquela informacao
void *F_UC(void *p_arg){
	while(1){
		sem_wait(&S_UC);//Espera a Main libera-la
		if(KILLALL) pthread_exit(0);

		sinais = 0; // define todos os bit com zero

		sinais |= ( (Est07) << 0 ); // RegDst0
		sinais |= ( (Est10) << 1 ); // RegDst1
		sinais |= ( ( (Est04) | (Est07) | (Est10) | (Est12) | (Est13) ) << 2 ); // RegWrite
		sinais |= ( ( (Est02) | (Est06) | (Est08) | (Est14) | (Est15) ) << 3 ); // UALFonteA
		sinais |= ( ( (Est00) | (Est01) ) << 4 ); //ALUSrcB0
		sinais |= ( ( (Est01) | (Est02) | (Est14) ) << 5 ); //ALUSrcB1
		sinais |= ( ( (Est08) | (Est14) | (Est15) ) << 6 ); //ALUOp0
		sinais |= ( ( (Est06) | (Est14) ) << 7 ); //ALUOp1
		sinais |= ( ( (Est08) | (Est11) | (Est12) | (Est15) ) << 8 ); //FontePC0
		sinais |= ( ( (Est09) | (Est10) | (Est11) | (Est12) ) << 9 ); //FontePC1
		sinais |= ( ( (Est08) | (Est15) ) << 10 ); //PCWriteCond
		sinais |= ( ( (Est00) | (Est09) | (Est10) | (Est11) | (Est12) ) << 11 ); //PCescreve
		sinais |= ( ( (Est03) | (Est05) ) << 12 ); // IouD
		sinais |= ( ( (Est00) | (Est03) ) << 13 ); // LerMem
		sinais |= ( (Est05) << 14 ); // EscMem
		sinais |= ( (Est15) << 15 ); // BNE
		sinais |= ( (Est00) << 16 ); // IREsc
		sinais |= ( (Est04) << 17 ); //MemParaReg0
		sinais |= ( ( (Est10) | (Est12) ) << 18 ); //MemParaReg1


		S &= 0b00001111; // zerando os Next States, que são apenas os quatro primeiros bits de S
		S |= (Est00 | (Est01 & (OpJ | OpJR | OpBNE)) | Est02 | Est06 | Est14)  << 4; //N_S0
		S |= ((Est01 & (OpLW | OpSW | OpADDI | OpTipoR | OpJAL | OpJR | OpANDI | OpBNE)) | (Est02 & OpLW) | Est06) << 5; // N_S1
		S |= ((Est01 & (OpTipoR | OpJALR | OpANDI | OpBNE)) | (Est02 & (OpSW | OpADDI)) | Est03 | Est06 | Est14) << 6; // N_S2
		S |= ((Est01 & (OpBEQ | OpJ | OpJAL | OpJR | OpJALR | OpANDI | OpBNE)) | (Est02 && OpADDI) | Est14) << 7; // N_S3


		sem_post(&S_mux_ioud);

		sem_post(&S_mux_RegDst);
		sem_post(&S_mux_MemParaReg);

		sem_post(&S_mux_UALFonteA);
		sem_post(&S_mux_UALFonteB);
		sem_post(&S_UAL_Operacao);
	}
}

void erroCriaThread(){
	printf("Erro ao criar thread\n");
	fflush(0);
	exit(1);
}

int main(int argc, char *argv[]){

	zera();
	FILE *f = fopen(argv[1], "rb+");
	int pos = 0;
	unsigned int aux;
	while(fscanf(f,"%u",&aux) != EOF){
		set_ram(pos,aux);
		pos += 4;
	}
	fclose(f);

	// inicializa semafaros e cria trheads
	pthread_t T_UC, T_Memory, T_Registers,T_UAL_Operacao, T_UAL;
	pthread_t T_mux_ioud, T_mux_RegDst,T_mux_MemParaReg, T_mux_UALFonteA;
	pthread_t T_mux_UALFonteB, T_mux_FontePC, T_or_and_pc, T_mux_BNE;

	int inicial = 0;
	void *void_arg = NULL;

	sem_init(&S_main, 0, inicial);

	sem_init(&S_UC,			0, inicial);
	sem_init(&S_mux_ioud,		0, inicial);
	sem_init(&S_or_and_pc,		0, inicial);
	sem_init(&S_mux_BNE,		0, inicial);
	sem_init(&S_Memory,		0, inicial);
	sem_init(&S_mux_RegDst,		0, inicial);
	sem_init(&S_mux_MemParaReg,	0, inicial);
	sem_init(&S_Registers,		0, inicial);
	sem_init(&S_mux_UALFonteA,	0, inicial);
	sem_init(&S_mux_UALFonteB,	0, inicial);
	sem_init(&S_UAL_Operacao,	0, inicial);
	sem_init(&S_UAL,		0, inicial);
	sem_init(&S_mux_FontePC,	0, inicial);

	//cria thread e para de executar se der erro
	if(pthread_create(&T_UC,		0, (void *)F_UC,		void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_mux_ioud,		0, (void *)F_mux_ioud,		void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_or_and_pc,		0, (void *)F_or_and_pc,		void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_mux_BNE,		0, (void *)F_mux_BNE,		void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_Memory,		0, (void *)F_Memory,		void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_mux_RegDst,	0, (void *)F_mux_RegDst,	void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_mux_MemParaReg,	0, (void *)F_mux_MemParaReg,	void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_Registers,		0, (void *)F_Registers,		void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_mux_UALFonteA,	0, (void *)F_mux_UALFonteA,	void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_mux_UALFonteB,	0, (void *)F_mux_UALFonteB,	void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_UAL_Operacao,	0, (void *)F_UAL_Operacao,	void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_UAL,		0, (void *)F_UAL,		void_arg) != 0) erroCriaThread();
	if(pthread_create(&T_mux_FontePC,	0, (void *)F_mux_FontePC,	void_arg) != 0) erroCriaThread();


	for(int contOp = 0; ERRO == 0; contOp++){ // cada iteração é um tique de clock
		sem_post(&S_UC);//Libera a Unidade de Controle

		for(int i=0;i<4;i++){ // espera cada uma das partes que rodam em paralelo terminar
			sem_wait(&S_main);// Memory, Registers, FontePC, or_and_pc
		}

		if(PCfim) PC = N_PC;
		if(IREsc) IR = N_IR;

		if(!(OpTipoR || OpJ || OpJAL || OpBEQ || OpBNE || OpADDI || OpANDI || OpJR || OpJALR || OpLW || OpSW)){
			ERRO = 1; //se nao for nenhuma dessas funcoes, eh instrucao invalida
		}
		MDR = N_MDR;
		A = N_A;
		B = N_B;
		AluOut = N_AluOut;

		S &= 0b11110000; // zera o estado atual
		S |= S>>4; // estado atual recebe proximo estado

	}

	if(ERRO != 0) printf("Status de Saída: ");
	if(ERRO == 1) printf("Término devido à tentativa de execução de instrução inválida.\n\n");
	else if(ERRO == 2) printf("Término devido à acesso inválido de memória.\n\n");
	else if(ERRO == 3) printf("Término devido à operação inválida da ULA.\n\n");
	else if(ERRO == 4) printf("Término devido à acesso inválido ao Banco de Registradores.\n\n");

	// impressões
	print_barramentos();
	print_sinais();
	print_regs();
	print_ram();

	KILLALL = 1;
	for(int i = 0; i < 5; i++){
		//Garante que acorda todas as thread, ja que algumas dependem de mais de um post
		sem_post(&S_UC);
		sem_post(&S_Memory);
		sem_post(&S_Registers);
		sem_post(&S_UAL);
		sem_post(&S_mux_ioud);
		sem_post(&S_mux_RegDst);
		sem_post(&S_mux_MemParaReg);
		sem_post(&S_mux_UALFonteA);
		sem_post(&S_mux_UALFonteB);
		sem_post(&S_mux_BNE);
		sem_post(&S_mux_FontePC);
		sem_post(&S_UAL_Operacao);
		sem_post(&S_or_and_pc);
	}

	return 0;
}
