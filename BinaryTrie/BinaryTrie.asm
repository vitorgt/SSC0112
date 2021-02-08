 ################################################################################################################################ 
 # 																# 
 # INTEGRANTES:															# 
 # 			Fabio Fogarin Destro 10284667			- Insercao e Leitura/Verificacao Strings		# 
 # 			Paulo Andre de Oliveira Carneiro 10295304	- Busca e Menu						# 
 # 			Renata Vinhaga dos Anjos 10295263		- Visualizacao						# 
 # 			Vitor Henrique Gratiere Torres 10284952		- Remocao						# 
 # 																# 
 ################################################################################################################################ 

			.data
			.align 2

strDigitada:		.space 16
strMenu:		.asciiz "\nMenu principal de opcoes\n1 - Insercao\n2 - Remocao\n3 - Busca\n4 - Visualizacao\n5 - Fim\n\nEscolha uma opcao (1 a 5): "
strDigiteIns:		.asciiz ">> Digite o binario para insercao: "
strDigiteRem:		.asciiz ">> Digite o binario para remocao: "
strDigiteBus:		.asciiz ">> Digite o binario para busca: "
strInseridaSuc:		.asciiz ">> Chave inserida com sucesso.\n"
strInsercaoRepetida:	.asciiz ">> Chave repetida. Insercao nao permitida.\n"
strInvalida:		.asciiz ">> Chave invalida. Insira somente numeros binarios(ou -1 retorna ao menu)\n"
strRemovidaSuc:		.asciiz ">> Chave removida com sucesso.\n"
strRetornaMenu:		.asciiz ">> Retornando ao menu.\n\n"
strBuscaEncontrada:	.asciiz ">> Chave encontrada na arvore: "
strBuscaNaoEncontrada:	.asciiz ">> Chave nao encontrada na arvore: -1\n"
strOpInvalidaMenu:	.asciiz "Opcao invalida.\n"
strDireita:		.asciiz "dir "
strEsq:			.asciiz "esq "
strRaiz:		.asciiz "raiz "
strRaizVisu:		.asciiz "RAIZ, "
strCaminho:		.asciiz ">> Caminho percorrido: "
quebraLinha:		.asciiz "\n"
strT:			.asciiz "T, "
strNT:			.asciiz "NT, "
virgula:		.asciiz ", "
strNivel:		.asciiz "\n>> N"
strAbreP:		.asciiz " ("
strFechaP:		.asciiz ")"
strNull:		.asciiz "NULL"
barraN:			.byte '\n'
digUm:			.byte '1'
digZero:		.byte '0'
digMenos:		.byte '-'

			.text
			.globl main


 #################################################################################################################################
 # 
 # 			INICIALIZA O PROGRAMA
 # 
 # 			ESTRUTURA DE CADA NO:
 # 			12 bytes cada no, indicando o ponteiro para a esquerda, ponteiro para a direita, e
 # 			uma informacao (0 ou 1) que caso seja 1, indica que eh um no terminal
 # 
 # 			As implementacoes utilizadas, foram iterativas e nao recursivas devido a uma decisao de projeto
 # 
 # 			O codigo foi desenvolvido e testado utilizando o sofware MARS 4.5
 #
			
main: 			jal	novoNo				 # ALOCANDO A RAIZ DA ARVORE $S0 = ponteiro para a raiz
			move	$s0, $v0			 # $s0 = ponteiro para a raiz

			lb	$s1, barraN			 # carrega o byte '\n'
			lb	$s2, digUm			 # carrega o byte '1'
			lb	$s3, digZero			 # carrega o byte '0'
			lb	$s4, digMenos			 # carrega o byte '-'


menu:			li	$v0, 4
			la	$a0, strMenu			 # imprime o menu
			syscall

			li	$v0, 5				 # le a opcao desejada (inteiro)
			syscall
			move	$t1, $v0			 # salvo inteiro em $t1

			li	$t2, 1				 # registrador auxiliar = 1
			beq	$t1, $t2, insere		 # se $t1 (opcao lida) == $t2 (1) vai para opcao insere

			li	$t2, 2				 # registrador auxiliar = 2
			beq	$t1, $t2, remove		 # se $t1 (opcao lida) == $t2 (2) vai para opcao remove

			li	$t2, 3				 # registrador auxiliar = 3
			beq	$t1, $t2, busca			 # se $t1 (opcao lida) == $t2 (3) vai para opcao busca

			li	$t2, 4				 # registrador auxiliar = 4
			beq	$t1, $t2, visualiza		 # se $t1 (opcao lida) == $t2 (4) vai para opcao vizualizar

			li	$t2, 5				 # registrador auxiliar = 5
			beq	$t1, $t2, encerraPrograma	 # se $t1 (opcao lida) == $t2 (5) vai para opcao encerrar programa

								 # Se nao e nenhuma das opcoes, eh invalido
			j	opcaoInvalida


opcaoInvalida:		li	$v0, 4				 # print String
			la	$a0, strOpInvalidaMenu		 # avisa que e uma opcao invalida ("Opcao invalida.\n")
			syscall
			j	menu				 # volta para o menu

 # 			FIM MENU
 # 
 #################################################################################################################################
 # 
 # 			ALGORITIMO DA INSERCAO
 # 
 # 			Le a chave binaria atraves de uma string, ate ser uma string valida (apenas zero e um)
 # 			Percorre a string, verificando cada byte da string, vendo se e um byte '0' ou um byte '1'
 # 			Percorre a arvore, a partir da raiz, de acordo com cada byte, (zero ou um), e caso o caminho ainda nao
 # 			exista vai alocando os nos necessarios para construir o caminho. Ao fim da insercao, se a info do no 
 # 			final for 1, quer dizer que a chave ja existia na arvore, e portanto a insercao eh repitida
 # 

insere:			li	$v0, 4				 # print String
			la	$a0, strDigiteIns		 # (">> Digite o binario para insercao: ")
			syscall

			jal	leString			 # quando volta da funcao, tem em $v0 ou 0 (string lida com sucesso) ou -1 (string invalida)
			li	$t1, -1
			beq	$v0, $t1, insere		 # se a funcao leString retornou -1, quer dizer que leu uma string invalida

			la	$t0, strDigitada		 # carrega a string digitada
			move	$t2, $s0			 # $t2 sera o ponteiro atual. aqui $t2 = $s0 ($s0 e o ponteiro para a raiz)


percorreInsere:							 # eh necessario percorrer a string ate o fim
			lb	$t1, 0($t0)
			addi	$t0, $t0, 1
			beq	$t1, $s1, fimStrInsercao	 # se char atual = '\n' -> fimStrInsercao

			beq	$t1, $s2, insereDireita		 # se char atual = '1' -> insereDireita
								 # byte atual eh '0'
			lw	$t3, 0($t2)			 # $t3 = ($t2)->esq
								 # eh necessario verificar se eh NULL ou nao
			bne	$t3, $zero, mudaAtualInsere	 # se $t3 != NULL -> continua percorrendo. muda atual pra atual->prox

			jal	novoNo				 # aloca o novo no
			sw	$v0, 0($t2)			 # aponta para o no alocado
			move	$t2, $v0			 # no atual recebe o proximo no
			j	percorreInsere

insereDireita:		lw	$t3, 4($t2)			 # $t3 = ($t2)->dir
								 # eh necessario verificar se eh NULL ou nao
			bne	$t3, $zero, mudaAtualInsere	 # se $t3 != NULL -> continua percorrendo. muda atual pra atual->prox

			jal	novoNo				 # aloca o novo no
			sw	$v0, 4($t2)			 # aponta para o no alocado
			move	$t2, $v0			 # no atual recebe o proximo no
			j	percorreInsere		

mudaAtualInsere:	move	$t2, $t3			 # at = at->prox
			j	percorreInsere

fimStrInsercao:		lw	$t4, 8($t2)			 # carrega a info do ultimo no
			bne	$t4, $zero, insercaoRepetida	 # se info != 0 -> chave repetida

			li	$t4, 1
			sw	$t4, 8($t2)			 # salva 1 na info do ultimo no atual

								 # inserido com sucesso			
			li	$v0, 4
			la	$a0, strInseridaSuc		 # Insercao ok (">> Chave inserida com sucesso.\n")
			syscall	

			j	insere

insercaoRepetida:						 # chave repetida
			li	$v0, 4
			la	$a0, strInsercaoRepetida	 # Insercao repetida (">> Chave repetida. Insercao nao permitida.\n")
			syscall

			j	insere				 # ja que falhou, tenta inserir de novo

 # 			FIM INSERE
 #
 #################################################################################################################################
 #
 # 			ALGORITIMO DA REMOCAO
 # 
 # 			Le a string como na insercao
 # 			Para cada byte da string verifica se existe o caminho digitado descendo a arvore
 # 			Enquanto desce, armazena o caminho percorrido na pilha (zeros e uns)
 # 			Em duas variaveis auxiliares:
 # 				Na primeira, o primeiro no a partir do qual pode ser removido
 # 				Na segunda, se deve remover para a direita ou para a esquerda a partir do no armazenado na primeira variavel auxiliar
 # 			Ao chegar ao no desejado para remocao eh verificado se eh um no terminal ou nao
 # 				Se nao for no terminal (informacao do no = 0)
 # 					Nao posso remover um no que nao foi inserido, portanto remocao falha
 # 				Se for no terminal (informacao do no = 1)
 # 					Se tiver filhos sua informao eh atualizada para zero e a remocao foi bem sucedida
 # 					Se nao tiver filhos, atualizo na primeira variavel auxiliar que contem o no em que apartir dele pode-se excluir
 #

remove:			li	$v0, 4
			la	$a0, strDigiteRem		 # Digite um binario para remocao (">> Digite o binario para remocao: ")
			syscall

			jal	leString			 # quando volta da funcao, tem em $v0 ou 0 (string lida com sucesso) ou -1 (string invalida)
			li	$t1, -1
			beq	$v0, $t1, remove		 # se a funcao leString retornou -1, quer dizer que leu uma string invalida

								 # $t0 -> no atual
								 # $t1 -> ultimo no que eu posso remover
								 # $t2 -> segue para a direita ou para a esquerda na hora de remover 

			la	$t3, strDigitada
			move	$t0, $s0			 # t0 = raiz
			move	$t1, $s0			 # t1 = raiz

								 # incialmente, posso apagar a partir da raiz, olhando para baixo, para a esquerda ou para a direita
			lb	$t4, 0($t3)
			slt	$t2, $t4, $s2			 # t2 = 1 se t4 = '0', t2 = 0 se t4 = '1'

			li	$t6, 1				 # inicializando o contador de movimentos com 1, pois ja coloquei a raiz
			addi	$sp, $sp, -4			 # descendo a pilha
			li	$t7, -1				 # salvar na pilha -1, que indica que estava na raiz
			sw	$t7, 0($sp)			 # armazenando raiz na pilha

								 # vou percorrer a arvore, pela string, marcando o ultimo no 
								 # que eu posso remover e verificar se tem a string p remover

percorreRemocao:	lb	$t4, 0($t3)			 # carrega byte da string
			addi	$t3, $t3, 1
			beq	$t4, $s2, perRemoDir		 # se o byte e '1'

								 # o valor do byte atual da string e zero
			lw	$t5, 0($t0)

			beq	$t5, $zero, falhaRemocao

			addi	$sp, $sp, -4			 # andando com a pilha
			addi	$t6, $t6, 1			 # contador de movimentos
			li	$t7, 0
			sw	$t7, 0($sp)			 # salvando na pilha que fiz um movimento para a esquerda

			j	proxRemo

perRemoDir:		lw	$t5, 4($t0)
			beq	$t5, $zero, falhaRemocao
			addi	$sp, $sp, -4			 # andando com a pilha
			addi	$t6, $t6, 1			 # contador de movimentos
			li	$t7, 1
			sw	$t7, 0($sp)			 # salvando na pilha que fiz um movimento para a direita

proxRemo:		move	$t0, $t5

								 # vou olhar se ele ja e o ultimo no, se tem filho, atualizo a info para 0 e a remocao foi bem sucessida
			lb	$t4, ($t3)			 # estou olhando um byte a frente, para ver se o proximo eh um '\n'
			bne	$t4, $s1, proxNaoUlt		 # se t4 != '\n'

								 # TRATA ULT NO: sei que e o ultimo no
			lw	$t5, 8($t0)
			beq	$t5, $zero, falhaRemocao	 # se e o ultimo no e nao tem um, nao pode remover

			lw	$t5, 0($t0)			 # pega o filho da esquerda
			bne	$t5, $zero, temFilhoMudaInfo
			lw	$t5, 4($t0)			 # pega o filho da direita
			bne	$t5, $zero, temFilhoMudaInfo

								 # nao tem filho, => EXECUTA A REMOCAO DE FATO AQUI

			beq	$t2, $zero, removeDir		 # se t2 for 0, remove	filho da direita
			sw	$zero, 0($t1)
			j	remocaoSucesso

removeDir:		sw	$zero, 4($t1)
			j	remocaoSucesso

temFilhoMudaInfo:	sw	$zero, 8($t0)
			j	remocaoSucesso

proxNaoUlt:							 # tenho que ver se esse no tem info 1 ou dois filhos, para salva-lo
			lw	$t5, 8($t0)			 # verifica info
			beq	$t5, $zero, verBifurcacao	 # se a info nao for 1, precisa verificar se tem 2 filhos

								 # ja que e 1, tenho que atualizar esse como o ultimo no que eu posso remover
			j	atualizaUltRemovivel

verBifurcacao:		lw	$t5, 0($t0)
			beq	$t5, $zero, percorreRemocao	 # ja sei que nao tem os dois filhos, continuo percorrendo

			lw	$t5, 4($t0)
			beq	$t5, $zero, percorreRemocao

								 # ja que e bifurcacao, atualiza o ultimo que pode ser removido

atualizaUltRemovivel:	move	$t1, $t0
								 # preciso saber para que lado vou remover a paritr de $t1
			lb	$t4, 0($t3)
								 # li $t2, 0
			slt	$t2, $t4, $s2			 # t2 = 1 se t4 = '0', t2 = 0 se t4 = '1'

			j	percorreRemocao			 # continua percorrendo

remocaoSucesso:							 # removido com sucesso, volta remocao
			li	$v0, 4				 # print String
			la	$a0, strRemovidaSuc		 # Remocao bem sucedida (">> Chave removida com sucesso.\n")
			syscall
			j	desempilhaRemocao

falhaRemocao:		li	$v0, 4
			la	$a0, strBuscaNaoEncontrada	 # remocao de algo nao encontrado (">> Chave nao encontrada na arvore: -1\n")
			syscall

desempilhaRemocao:	li	$t5, 4
			addi	$t6, $t6, -1			 # diminuindo um no contador de movimentos pois quero que o sp volte para o primeiro item e nao para a posicao anterior ao primeiro item
			mult	$t6, $t5			 # fazendo a conta para descobrir quantas posicoes o sp deve subir para ir para o primeiro item empilhado
			mflo	$s5
			add	$sp, $sp, $s5			 # movendo sp para o primeiro item
			addi	$t6, $t6, 1			 # voltando o contador de movimentos ao normal

			li	$v0, 4
			la	$a0, strCaminho			 # (">> Caminho percorrido: ")
			syscall

contDesempilhaRemo:	beq	$t6, $zero, voltaSpRemocao	 # ja imprimiu todos os movimentos realizados, vai para o rotulo que volta o sp para sua posicao inicial

			lw	$t7, 0($sp)			 # pego oq esta armazenado na pilha na posicao apontada por sp
			addi	$t6, $t6, -1			 # diminuo um nos movimentos a serem analisados
			add	$sp, $sp, -4			 # desco com o sp

			li	$t5, -1
			beq	$t7, $t5, imprimeRaizRemocao	 # se oq esta armazenado na pilha tiver o mesmo valor que -1, imprime raiz

			li	$t5, 0
			beq	$t7, $t5, imprimeEsqRemocao	 # se oq esta armazenado na pilha tiver o valor 0, imprime que foi realizado um movimento para a esquerda

								 # imprimindo movimento para a Direita
			li	$v0, 4
			la	$a0, strDireita			 # ("dir ")
			syscall
			j	contDesempilhaRemo

voltaSpRemocao:		add	$sp, $sp, $s5			 # voltando sp para a posicao inicial da pilha

			li	$v0, 4
			la	$a0, quebraLinha		 # ("\n")
			syscall
			j	remove

imprimeRaizRemocao:	li	$v0, 4
			la	$a0, strRaiz			 # ("raiz ")
			syscall
			j	contDesempilhaRemo

imprimeEsqRemocao:	li	$v0, 4
			la	$a0, strEsq			 # ("esq ")
			syscall
			j	contDesempilhaRemo

 # 			FIM REMOVE
 #
 #################################################################################################################################
 #
 # 			ALGORITIMO DA BUSCA
 # 
 # 			Le string e verifica se eh valida.
 # 			Comeca a descer pela arvore, analisando byte a byte da string. Caso '0' desco para a esquerda, caso '1' desco para a direita.
 # 			Enquanto isso salvo quantos movimentos foram realizados ate entao e armazeno na pilha o caminho percorrido.
 # 			Se tentar descer para um no nulo (isto eh que nao foi inserido e nao existe na arvore) vou para o rotulo de busca invalida.
 # 			Se cheguei ao no desejado, testo se a info dele eh 0 que indica que nao eh um no terminal,
 # 			logo a chave nao foi econtrada e portando foi uma busca invalida
 # 			Caso contrario imprimo que a chave foi encontrada.
 # 			Em ambos os casos imprimo o caminho na arvore realizado pela busca
 #

busca:			li	$v0, 4 
			la	$a0, strDigiteBus		 # (">> Digite o binario para a busca: ")
			syscall

			jal	leString			 # quando volta da funcao, tem em $v0 ou 0 (string lida com sucesso) ou -1 (string invalida)
			li	$t1, -1 
			beq	$v0, $t1, busca			 # se a funcao leString retornou -1, quer dizer que leu uma string invalida

			li	$t6, 1				 # inicializando o contador de movimentos com 1
			addi	$sp, $sp, -4			 # descendo a pilha
			li	$t7, -1				 # salvar na pilha -1, que indica que estava na raiz
			sw	$t7, 0($sp)			 # armazenando raiz na pilha

			la	$t0, strDigitada		 # carrega a string digitada
			move	$t2, $s0			 # $t2 sera o ponteiro atual. aqui $t2 = $s0 ($s0 e o ponteiro para a raiz)


percorreBusca:		lb	$t1, 0($t0)			 # pegando um byte da string
			addi	$t0, $t0, 1
			beq	$t1, $s1, fimBusca		 # se char atual = '\n' -> fimStrInserca

			beq	$t1, $s2, buscaDireita		 # se char atual = '1' , ando para a direita
								 # byte atual e '0' , move esquerda
			lw	$t3, 0($t2)			 # $t3 = ($t2)->esq
			beq	$t3, $zero, buscaError		 # se for nulo, nao achei o que estava sendo buscado

			addi	$sp, $sp, -4			 # andando com a pilha
			addi	$t6, $t6, 1			 # contador de movimentos
			li	$t7, 0
			sw	$t7, 0($sp)			 # salvando na pilha que fiz um movimento para a esquerda

			move	$t2, $t3

			j	percorreBusca


buscaDireita: 		lw	$t3, 4($t2)
			move	$t2, $t3
			beq	$t2, $zero, buscaError		 # se for nulo, nao achei o que estava sendo buscado
			addi	$sp, $sp, -4			 # andando com a pilha
			addi	$t6, $t6, 1			 # contador de movimentos
			li	$t7, 1
			sw	$t7, 0($sp)			 # salvando na pilha que fiz um movimento para a direita

			j	percorreBusca


fimBusca:		lw	$t3, 8($t2)
			beq	$t3, $zero, buscaError		 # vendo se info eh igual a 1
			li	$v0, 4
			la	$a0, strBuscaEncontrada		 # (">> Chave encontrada na arvore: ")
			syscall

			li	$v0, 4
			la	$a0, strDigitada		 # imprime o binario digitado
			syscall

			move	$v0, $t2
			j	desempilhaBusca

buscaError:		li	$v0, 4
			la	$a0, strBuscaNaoEncontrada	 # (">> Chave nao encontrada na arvore: -1\n")
			syscall

			li	$v0, -1

desempilhaBusca:	li	$t5, 4
			addi	$t6, $t6, -1			 # diminuindo um no contador de movimentos pois quero que o sp volte para o primeiro item e nao para a posicao anterior ao primeiro item
			mult	$t6, $t5			 # fazendo a conta para descobrir quantas posicoes o sp deve subir para ir para o primeiro item empilhado
			mflo	$s5
			add	$sp, $sp, $s5			 # movendo sp para o primeiro item
			addi	$t6, $t6, 1			 # voltando o contador de movimentos ao normal

			move	$t5, $v0			 # salvando o valor de retorno da funcao
			li	$v0, 4
			la	$a0, strCaminho			 # (">> Caminho percorrido:")
			syscall
			move	$v0, $t5

contDesempilhaBusca:	beq	$t6, $zero, voltaSpBusca	 # ja imprimiu todos os movimentos realizados, vai para o rotulo que volta o sp para sua posicao inicial

			lw	$t7, 0($sp)			 # pego oq esta armazenado na pilha na posicao apontada por sp
			addi	$t6, $t6, -1			 # diminuo um nos movimentos a serem analisados
			add	$sp, $sp, -4			 # desco com o sp

			li	$t5, -1
			beq	$t7, $t5, imprimeRaiz		 # se oq esta armazenado na pilha tiver o mesmo valor que -1, imprime raiz

			li	$t5, 0
			beq	$t7, $t5, imprimeEsq		 # se oq esta armazenado na pilha tiver o valor 0, imprime que foi realizado um movimento para a esquerda

								 # imprimindo Direita
			move	$t5, $v0			 # salvando o conteudo do retorno da funcao, para nao perder
			li	$v0, 4
			la	$a0, strDireita			 # ("dir ")
			syscall
			move	$v0, $t5
			j	contDesempilhaBusca

voltaSpBusca:		add	$sp, $sp, $s5			 # voltando sp para a posicao inicial

								 # imprimindo um \n
			move	$t5, $v0
			li	$v0, 4
			la	$a0, quebraLinha		 # ("\n")
			syscall
			move	$v0, $t5
			j	busca

imprimeRaiz:		move	$t5, $v0			 # salvando o conteudo do retorno da funcao, para nao perder
			li	$v0, 4
			la	$a0, strRaiz			 # ("raiz ")
			syscall
			move	$v0, $t5
			j	contDesempilhaBusca

imprimeEsq:		move	$t5, $v0			 # salvando o conteudo do retorno da funcao, para nao perder
			li	$v0, 4
			la	$a0, strEsq			 # ("esq ")
			syscall
			move	$v0, $t5
			j	contDesempilhaBusca

 # 			FIM BUSCA
 #
 #################################################################################################################################
 #
 # 			ALGORITIMO DA VISUALIZACAO
 # 
 # 			Recebe a raiz e por meio de uma BFS (busca em largura) adaptada imprime os niveis da arvore.
 # 			Comeca inserindo a raiz no inicio da fila (inicio -> $t5, fim -> $sp) e enquanto os nos do nivel seguinte nao 
 # 			forem todos nulos(ou seja enquanto a arvore nao acabou), insere no fim da fila os filhos (nao nulos) 
 # 			do no que esta no topo dessa, imprime esse no e retira ele da fila(incrementando o auxiliar $t2, 
 # 			que armazena o numero de nos do nivel seguinte).
 # 			Para saber em que nivel estamos, temos o auxiliar $t1 que sempre e atualizado pelo numero de nos do nivel 
 # 			seguinte e vai sendo decrementado, pois assim que chegar a 0 significa que um nivel acabou.
 #

visualiza:		li	$t0, 0				 # para guardar o numero do nivel a ser impresso
			li	$t1, 1				 # para guardar o numero de nos do nivel atual, comeca com 1 por conta da raiz
			li	$t2, 0				 # para guardar o numero de nos do nivel seguinte
			move	$t3, $s0			 # t3 recebe ponteiro da raiz
			addi	$sp, $sp, -8			 # sp sera o ponteiro para o final da fila
			move	$t5, $sp			 # t5 sera o ponteiro para o inicio da fila
								 # insere raiz na fila
			sw	$t3, 0($sp)			 # recebe o ponteiro da raiz
			li	$t4, -1				 # valor de representacao da raiz
			sw	$t4, 4($sp)			 # recebe o valor de representacao, pode ser -1 para raiz, 0 para esq e 1 para dir
								 # imprime ">> N(t0)"
			jal	imprimeStrNivel

enfilera:		jal	imprimeNo			 # imprimeNo inicio da fila
			jal	pushfilhos			 # insere_esq() t2 ++; insere_dir() t2++
			addi	$t5, $t5, -8			 # pop.fila
			addi	$t1, $t1, -1			 # numero de nos do nivel atual - 1
			bne	$t1, $zero, enfilera		 # while( t1 > 0 ), enquanto o numero de nos do nivel atual retirados da fila nao for 0 
			addi	$t0, $t0, 1			 # numero do nivel++
			beq	$t2, $zero, fimVisualiza			 # while( t2 > 0 ) , enquanto o numero de nos do nivel seguinte for maior que 0
			jal	imprimeStrNivel
			move	$t1, $t2			 # t1 = t2
			li	$t2, 0				 # t2 = 0
			j	enfilera

imprimeStrNivel:	li	$v0, 4
			la	$a0, strNivel			 # ("\n >> N")
			syscall
			li	$v0, 1
			move	$a0, $t0			 # imprime o numero do nivel atual
			syscall
			jr	$ra

imprimeNo:							 # imprime --->   (0, NT, &esq, &dir)
			li	$v0, 4
			la	$a0, strAbreP			 # string: (" (")
			syscall
			lw	$t4, 4($t5)			 # tem valor -1 se raiz, 0 se filho esq, 1 se filho dir
			li	$t6, -1
			bne	$t4, $t6, imprimeNum		 # se nao for raiz
			li	$v0, 4
			la	$a0, strRaizVisu		 # ("RAIZ, ")
			syscall
			li	$v0, 4
			la	$a0, strNT			 # sempre imprime NO NAO terminal para raiz  ("NT, ")
			syscall
			j	imprEsq

imprimeNum:		li	$v0, 1
			move	$a0, $t4			 # 0 para esq ou 1 para dir
			syscall

			li	$v0, 4
			la	$a0, virgula			 # (", ")
			syscall

								 # imprime se eh no terminal ou nao
			lw	$t6, 0($t5)
			lw	$t4, 8($t6)			 # t4 pega o valor de info ( terminal ou nao )
			beq	$t4, $zero, imprimeNT
			li	$v0, 4
			la	$a0, strT			 # imprime string para terminal : ("T, ")
			syscall
			j	imprEsq

imprimeNT:		li	$v0, 4
			la	$a0, strNT			 # imprime string para NAO terminal ("NT, ")
			syscall

imprEsq:		lw	$t6, 0($t5)
			lw	$t4, 0($t6)			 # t4 = t5-> esq
			beq	$t4, $zero, nullEsq		 # se o filho esquerdo nao existir
			li	$v0, 34				 # imprime hexadecimal
			move	$a0, $t4
			syscall
			j	imprDir

nullEsq:		li	$v0, 4
			la	$a0, strNull			 # ("NULL")
			syscall

imprDir:		li	$v0, 4				 # imprime virgula dps de exibir a info do no da esquerda
			la	$a0, virgula			 # (", ")
			syscall

			lw	$t6, 0($t5)
			lw	$t4, 4($t6)			 # t4 = t5-> dir
			beq	$t4, $zero, nullDir		 # se o filho direito nao existir
			li	$v0, 34				 # imprime hexadecimal
			move	$a0, $t4
			syscall
			j	fimImprimeNo

nullDir:		li	$v0, 4
			la	$a0, strNull			 # ("NULL")
			syscall

fimImprimeNo:		li	$v0, 4
			la	$a0, strFechaP			 # (")")
			syscall
			jr	$ra				 # volta para o enfilera

pushfilhos:							 # push esquerda (se tiver filho a esquerda do no atual, enfilera o filho)
			lw	$t6, 0($t5)
			lw	$t4, 0($t6)			 # t4 = t5->esq
			beq	$t4, $zero, pushDir		 # se o filho esquerdo do no atual nao existir nao coloca na fila
			addi	$t2, $t2, 1			 # numero de nos nivel seguinte++
			addi	$sp, $sp, -8			 # adiciona na pilha
			sw	$t4, 0($sp)			 # 0($sp)  =  t5->esq
			li	$t4, 0				 # valor de esq = 0
			sw	$t4, 4($sp)

pushDir:		lw	$t6, 0($t5)			 # (se tiver filho a direita do no atual, enfilera o filho)
			lw	$t4, 4($t6)			 # t4 = t5->dir
			beq	$t4, $zero, retornaEnfilera	 # se o filho esquerdo do no atual nao existir nao coloca na fila
			addi	$t2, $t2, 1			 # numero de nos nivel seguinte++
			addi	$sp, $sp, -8			 # adiciona na pilha
			sw	$t4, 0($sp)			 # 0($sp)  =  t5->dir
			li	$t4, 1				 # valor de dir = 1
			sw	$t4, 4($sp)

retornaEnfilera:	jr	$ra

fimVisualiza:		li	$v0, 4
			la	$a0, quebraLinha		 # ("\n")
			syscall

			j	menu

 # 			FIM VISUALIZA
 #
 #################################################################################################################################
 #
 # 			ALGORITIMO DA LEITURA DE STRINGS
 # 	
 # 			Le string e verifica se eh valida ou nao
 # 			Recebe em strDigitada a string digitada, e a partir disso, verifica char por char, olhando se foi digitado '-1' ou senao, se todos os chars
 # 			sao '0' ou '1' e caso contrario, retorna que eh uma string invalida
 # 			Ao final dessa funcao, $v0 tem -1 caso seja uma string invalida ou 1 se eh uma string valida
 #

leString: 		li	$v0, 8
			la	$a0, strDigitada
			li	$a1, 16
			syscall

			la	$t0, strDigitada

			lb	$t1, 0($t0) 
			beq	$t1, $s1, leString		 # se true, quer dizer que a string e vazia (apenas um enter), continua solicitando que digite uma string

								 # verifica se foi digitado -1
			lb	$t1, 0($t0)
			bne	$t1, $s4, verStrByteCarregado	 # se primeiro byte != '-', verifica a string, ja tendo carregado o 1º byte
			addi	$t0, $t0, 1			 # se primeiro byte == '-', pula para o proximo char e ve se e '1'
			lb	$t1, 0($t0)
			bne	$t1, $s2 printStrInvalida	 # se segundo byte != '1', string invalida
			li	$v0, 4
			la	$a0, strRetornaMenu		 # (">> Retornando ao menu\n\n")
			syscall
			j	menu				 # se o primeiro byte e '-' e o segundo '1', vai para o menu

verificaStringValida:	addi	$t0,$t0,1			 # na 1a iteracao, o byte ja esta carregado e n cai nessa linha (cai em "verStrByteCarregado")
			lb	$t1,0($t0)
verStrByteCarregado:	beq	$t1, $s1, fimVerificaString	 # compara com o \n -> faria com $zero, para achar o \0, mas, tem o \n antes!!
			beq	$t1, $s2, verificaStringValida	 # compara com '1' -> se e 1, e valido com certeza 
			bne	$t1, $s3, printStrInvalida	 # ja que nao e '1', se for diferente de '0', e invalida
			j	verificaStringValida 

printStrInvalida:	li	$v0, 4
			la	$a0, strInvalida		 # ("Chave invalida. Insira somente numeros binarios (ou -1 retorna ao meunu)\n")
			syscall

			li	$v0, -1				 # retorno da funcao = -1, indica que a chave digitada e invalida
			jr	$ra

								 # QUER DIZER QUE A STRING E VALIDA
fimVerificaString:	li	$v0, 0				 # auxliar = 0, indica que a chava digitada e valida
			jr	$ra

 # 			FIM LE STRING
 #
 #################################################################################################################################
 # 
 # 			ALOCA NO
 # 
 # 			Aloca um novo no, de acordo com uma "struct" de 12 bytes, sendo eles, 4 para ponteiro para esquerda,
 # 			4 para ponteiro para a direita e 4 que indicam se eh um no terminal ou nao
 # 			ao fim dessa funcao, $v0 tem o endereco do no alocado
 # 

novoNo:			li	$v0, 9				 # avisei que quero alocar
			li	$a0, 12				 # avisei que quero 12 bytes
			syscall
			sw	$zero, 0($v0)			 # incializa o ponteiro esq com zero
			sw	$zero, 4($v0)			 # inicializa o ponteiro dir com zero
			sw	$zero, 8($v0)			 # inicializa a info com zero

			jr	$ra				 # volta para onde foi chamado

 # 			FIM ALOCA NO
 #
 #################################################################################################################################
 #
 # 			ENCERRA A EXECUCAO DO PROGRAMA
 #

encerraPrograma:	li	$v0, 10
			syscall

 # 			FIM ENCERRA
 #
 #################################################################################################################################

