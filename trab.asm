.text

init:
	jal main
fim:
	move $a0, $v0
	li $v0, 17
	syscall

abrir_arquivo_para_leitura:
#prologo

#corpo
	move $a1, $zero
	move $a2, $zero
	li $v0, 13
	syscall

#epilogo
	jr $ra


ler_arquivo:
#prologo
#corpo
	li $a2, 4 #numero de bytes para ser lido do arquivo
	li $v0, 14
	syscall
#epilogo
	jr $ra
	
	
bin_to_hex:
	move $t0, $a0
	
	#imprimir o Ox
	la $a0, hex_char # a0 = endereço da string com caracteres hexadecimais
	li $v0, 4
	syscall
	
	li $t1, 0 #o procedimento irá de 0 a 7
	for_bin_to_hex:
	#codigo for
	la $a0, hex_char
	la $t3, mascara_4_primeiros_bits
	lw $t3, 0($t3)
	and $t2, $t0, $t3 #t2 = 4 bits mais significativos
	sll $t0, $t0, 4 #muda os 4 bits mais significativos
	srl $t2, $t2, 28 #ajeita os bits depois de usar a mascara
	sll $t2, $t2, 1 #multiplica t2 por 2
	add $t2, $t2, 3 #adiciona 4 para q a0 possa receber o endereço do numero correspondente
	add $a0, $a0, $t2 #a0 == endereço na string do caracter correspondente ao numero
	#printa o caracter
	li $v0, 4
	syscall
	#incrementa o for
	add $t1, $t1, 1
	#condição do for
	bne $t1, 8, for_bin_to_hex
	
	jr $ra
	
isola_opcode:
	la $t0, mascara_OP_R
	lw $t1, 0($t0) #carrega a mascara de opcode (6 primeiros bits)
	
	and $v0, $a0, $t1 #$v0 = codigo com opcode isolado
	srl $v0, $v0, 26 #$v0 = opcode apenas
	jr $ra
	
descobre_tipo_instrucao:
#prologo
#corpo
	move $t0, $a0
	#se opcode == 0 ou opcode == 28 -> instrução tipo R
	beqz $t0, return_R
	beq $t0, 28, return_R
	#se opcode == 1 ou opcode == 3 -> instrução tipo J
	beq $t0, 2, return_J
	beq $t0, 3, return_J
	#senão -> instrução tipo I
	return_I:
		li $v0, 2
		j epilogo_descobre_tipo_instrucao
	return_R:
		li $v0, 1
		j epilogo_descobre_tipo_instrucao
	return_J:
		li $v0, 3
	
#epilogo
	epilogo_descobre_tipo_instrucao:
		jr $ra


decodifica_instrucao:
#prologo
	addiu $sp, $sp, -16
	sw $ra, 0($sp)
	sw $a0, 4($sp)# identificador do tipo da instrução
	sw $a1, 8($sp)# código inteiro da instrução
	
#corpo
	move $t0, $a0
	lw $a0, 8($sp)
	beq $t0, 1, decodifica_R
	beq $t0, 2, decodifica_I
	beq $t0, 3, decodifica_J
	decodifica_R:
		jal func_decodifica_R
		j epilogo_decodifica_instrucao
	decodifica_I:
		jal func_decodifica_I
		j epilogo_decodifica_instrucao
	decodifica_J:
		jal func_decodifica_J
		j epilogo_decodifica_instrucao
			
#epilogo
	epilogo_decodifica_instrucao:
	lw $ra, 0($sp)
	addiu $sp, $sp, 16
	jr $ra
	
	
	
	
func_decodifica_R:
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	la $t0, mascara_OP_R
	lw $t1, 0($t0) # t1 = mascara_OP
	
	la $t0, mascara_RS_R 
	lw $t2, 0($t0) # t2 = mascara_Rs
	
	la $t0, mascara_RT_R 
	lw $t3, 0($t0)  # t3 = mascara_Rt
		
	la $t0, mascara_RD_R 
	lw $t4, 0($t0)  # t4 = mascara_Rd
	
	la $t0, mascara_SHAMT_R 
	lw $t5, 0($t0)  # t5 = mascara_Shamt
	
	la $t0, mascara_FUNCT_R 
	lw $t6, 0($t0)  # t6 = mascara_Funct
	
	and $t1, $t1, $a0 # t1 = op = 0
	
	and $t2, $t2, $a0 # t2 = rs
	srl $t2, $t2, 21
	
	and $t3, $t3, $a0 # t3 = rt
	srl $t3, $t3, 16
	
	and $t4, $t4, $a0 # t4 = rd
	srl $t4, $t4, 11
	
	and $t5, $t5, $a0 # t5 = shamt
	srl $t5, $t5, 6
	
	and $t6, $t6, $a0 # t6 = funct
	
	# armazena os valores dos registradores $tx nos seus respectivos locais da memória
	la $t0, ponteiro_R
	lw $t0, 0($t0)
	sw $t1, 0($t0)
	
	la $t0, ponteiro_R
	lw $t0, 4($t0)
	sw $t2, 0($t0)	
	
	la $t0, ponteiro_R
	lw $t0, 8($t0)
	sw $t3, 0($t0)
	
	la $t0, ponteiro_R
	lw $t0, 12($t0)
	sw $t4, 0($t0)	
	
	la $t0, ponteiro_R
	lw $t0, 16($t0)
	sw $t5, 0($t0)	
	
	la $t0, ponteiro_R
	lw $t0, 20($t0)
	sw $t6, 0($t0)	
	
	jal printa_R
	
#epilogo
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	
	
printa_R:
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	#analisa a funct
	la $t0, ponteiro_R
	lw $t0, 20($t0)
	lw $a0, 0($t0) #$a0 contem o funct da instrução R
	jal analisa_funct
	#depois de ter pegado a string da função
	#printa a função
	move $a0, $v0
	li $v0, 4
	syscall
	#agora analisa os registradores
	beq $v1, 2, fim_printa_R # se v1 == 2 instrução é syscall, não tem registradores
	beq $v1, 1, print_RS #se v1 == 1 instrução é jr, só printa o RS
	#RD
	la $t0, ponteiro_R
	lw $t0, 12($t0)
	lw $a0, 0($t0) #$a0 contem o rd da instrução R
	jal analisa_registrador
	#printa RD
	move $a0, $v0
	li $v0, 4
	syscall
	#RS
	print_RS:
	la $t0, ponteiro_R
	lw $t0, 4($t0)
	lw $a0, 0($t0) #$a0 contem o rs da instrução R
	jal analisa_registrador
	#printa RS
	move $a0, $v0
	li $v0, 4
	syscall
	beq $v1, 1, fim_printa_R #se v1 == 1 instrução é jr, só printa o RS
	#RT
	la $t0, ponteiro_R
	lw $t0, 8($t0)
	lw $a0, 0($t0) #$a0 contem o rt da instrução R
	jal analisa_registrador
	#printa RT
	move $a0, $v0
	li $v0, 4
	syscall
#epilogo
	fim_printa_R:
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra


analisa_funct:
#corpo
	#switch case com o campo funct
	beq $a0, 32, funct_add     # se funct == 10 0000 
	beq $a0, 33, funct_addu     # se funct == 10 0001 
	beq $a0, 8, funct_jr     # se funct == 00 1000 
	beq $a0, 12, funct_syscall     # se funct == 00 1100
	beq $a0, 2, funct_mul		#mul == 00 0010
	
	
	funct_add:
	la $v0, str_add
	li $v1, 0
	jr $ra
	funct_addu:
	la $v0, str_addu
	li $v1, 0
	jr $ra
	funct_jr:
	la $v0, str_jr
	li $v1, 1
	jr $ra
	funct_syscall:
	la $v0, str_syscall
	li $v1, 2
	jr $ra
	funct_mul:
	la $v0, str_mul
	la $v1, 0
	jr $ra	
	
analisa_registrador:
#prologo
#corpo
	#retorna o endereço da string relativo ao registrador usado
	la $v0, str_zero
	beq $a0, 0, epilogo_AR
	la $v0, str_at
	beq $a0, 1, epilogo_AR
	la $v0, str_v0
	beq $a0, 2, epilogo_AR
	la $v0, str_v1
	beq $a0, 3, epilogo_AR
	la $v0, str_a0
	beq $a0, 4, epilogo_AR
	la $v0, str_a1
	beq $a0, 5, epilogo_AR
	la $v0, str_a2
	beq $a0, 6, epilogo_AR
	la $v0, str_a3
	beq $a0, 7, epilogo_AR
	la $v0, str_t0
	beq $a0, 8, epilogo_AR
	la $v0, str_t1
	beq $a0, 9, epilogo_AR
	la $v0, str_t2
	beq $a0, 10, epilogo_AR
	la $v0, str_t3
	beq $a0, 11, epilogo_AR
	la $v0, str_t4
	beq $a0, 12, epilogo_AR
	la $v0, str_t5
	beq $a0, 13, epilogo_AR
	la $v0, str_t6
	beq $a0, 14, epilogo_AR
	la $v0, str_t7
	beq $a0, 15, epilogo_AR
	la $v0, str_s0
	beq $a0, 16, epilogo_AR
	la $v0, str_s1
	beq $a0, 17, epilogo_AR
	la $v0, str_s2
	beq $a0, 18, epilogo_AR
	la $v0, str_s3
	beq $a0, 19, epilogo_AR
	la $v0, str_s4
	beq $a0, 20, epilogo_AR
	la $v0, str_s5
	beq $a0, 21, epilogo_AR
	la $v0, str_s6
	beq $a0, 22, epilogo_AR
	la $v0, str_s7
	beq $a0, 23, epilogo_AR
	la $v0, str_t8
	beq $a0, 24, epilogo_AR
	la $v0, str_t9
	beq $a0, 25, epilogo_AR
	la $v0, str_k0
	beq $a0, 26, epilogo_AR
	la $v0, str_k1
	beq $a0, 27, epilogo_AR
	la $v0, str_gp
	beq $a0, 28, epilogo_AR
	la $v0, str_sp
	beq $a0, 29, epilogo_AR
	la $v0, str_fp
	beq $a0, 30, epilogo_AR
	la $v0, str_ra
	beq $a0, 31, epilogo_AR
	
	
#epilogo
	epilogo_AR:
	jr $ra
	

func_decodifica_I:
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	#mascara_OP_I: .word 0xFC000000
	#mascara_RS_I: .word 0x03e00000
	#mascara_RT_I: .word 0x001f0000
	#mascara_IMM_I: .word 0x0000ffff
	la $t0, mascara_OP_I
	lw $t1, 0($t0) #t1 = mascara_OP
	
	la $t0, mascara_RS_I
	lw $t2, 0($t0) #t2 = mascara_RS
	
	la $t0, mascara_RT_I
	lw $t3, 0($t0) #t3 = mascara_RT
	
	la $t0, mascara_IMM_I
	lw $t4, 0($t0) #t4 = mascara_IMM_I
	
	and $t1, $t1, $a0 #t1 = op
	srl $t1, $t1, 26
	
	and $t2, $t2, $a0 #t2 = rs
	srl $t2, $t2, 21
	
	and $t3, $t3, $a0 #t3 = rt
	srl $t3, $t3, 16
	
	and $t4, $t4, $a0 #t4 = imm
	
	# armazena os valores dos registradores $tx nos seus respectivos locais da memória
	la $t0 ponteiro_I
	lw $t0, 0($t0)
	sw $t1, 0($t0)
	
	la $t0 ponteiro_I
	lw $t0, 4($t0)
	sw $t2, 0($t0)	
	
	la $t0 ponteiro_I
	lw $t0, 8($t0)
	sw $t3, 0($t0)
	
	la $t0 ponteiro_I
	lw $t0, 12($t0)
	sw $t4, 0($t0)	
	
	jal printa_I
	 
	
#epilogo
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra

printa_I:
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	#analisa o opcode
	la $t0, ponteiro_I
	lw $t0, 0($t0)
	lw $a0, 0($t0) #$a0 contem o opcode da instrução I
	jal analisa_opcode_I
	#depois de ter pegado a string da função
	#printa a instrução
	move $a0, $v0 #carrega em a0 o endereço que contem a string da instrução
	li $v0, 4
	syscall
	
	#printa as informçaões baseado na instrução retornada
	beq $v1, 0, print0
	beq $v1, 1, print1
	beq $v1, 2, print2
	beq $v1, 3, print3
	beq $v1, -1, fim_print_I
	print0:
	jal print0_I
	j fim_print_I
	print1:
	jal print1_I
	j fim_print_I
	print2:
	jal print2_I
	j fim_print_I
	print3:
	jal print3_I
	j fim_print_I
	
	
#epilogo
	fim_print_I:
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	
print0_I:
#prologo
	addiu $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
#corpo
	la $s0, ponteiro_I #carrega em s0 o endereço de ponteiro_I
	#RT
	lw $t0, 8($s0) #carrega em t0 o endereço de Rt no ponteiro_I
	lw $a0, 0($t0) #carrega em a0 a informação de Rt
	jal analisa_registrador
	#printa Rt
	move $a0, $v0
	li $v0, 4
	syscall
	#IMM_I
	lw $t0, 12($s0)#carrega em t0 o endereço do IMM_I
	lw $a0, 0($t0)#carrega em a0 o IMM_I
	#printa IMM_I
	jal bin_to_hex
	
	# printa '('
	li $a0, '('
	li $v0, 11
	syscall
	
	#RS
	lw $t0, 4($s0)
	lw $a0, 0($t0)
	jal analisa_registrador
	#printa Rs
	move $a0, $v0,
	li $v0, 4
	syscall
	
	# printa ')'
	li $a0, ')'
	li $v0, 11
	syscall
	
#pilogo
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addiu $sp, $sp, 8
	
	jr $ra
	
print1_I:
#prologo
	addiu $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
#corpo
	la $s0, ponteiro_I #carrega em s0 o endereço de ponteiro_I
	#RT
	lw $t0, 8($s0) #carrega em t0 o endereço de Rt no ponteiro_I
	lw $a0, 0($t0) #carrega em a0 a informação de Rt
	jal analisa_registrador
	#printa Rt
	move $a0, $v0
	li $v0, 4
	syscall
	#RS
	lw $t0, 4($s0)
	lw $a0, 0($t0)
	jal analisa_registrador
	#printa Rs
	move $a0, $v0,
	li $v0, 4
	syscall
	#IMM_I
	lw $t0, 12($s0)#carrega em t0 o endereço do IMM_I
	lw $a0, 0($t0)#carrega em a0 o IMM_I
	#printa IMM_I
	jal bin_to_hex
	
#pilogo
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addiu $sp, $sp, 8
	
	jr $ra
	
print2_I:
#prologo
	addiu $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
#corpo
	la $s0, ponteiro_I #carrega em s0 o endereço de ponteiro_I
	#RT
	lw $t0, 8($s0) #carrega em t0 o endereço de Rt no ponteiro_I
	lw $a0, 0($t0) #carrega em a0 a informação de Rt
	jal analisa_registrador
	#printa Rt
	move $a0, $v0
	li $v0, 4
	syscall
	#IMM_I
	lw $t0, 12($s0)#carrega em t0 o endereço do IMM_I
	lw $a0, 0($t0)#carrega em a0 o IMM_I
	#printa IMM_I
	jal bin_to_hex
	
#pilogo
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addiu $sp, $sp, 8
	
	jr $ra
	
print3_I:
#prologo
	addiu $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
#corpo
	la $s0, ponteiro_I #carrega em s0 o endereço de ponteiro_I
	#RS
	lw $t0, 4($s0)
	lw $a0, 0($t0)
	jal analisa_registrador
	#printa Rs
	move $a0, $v0,
	li $v0, 4
	syscall
	#RT
	lw $t0, 8($s0) #carrega em t0 o endereço de Rt no ponteiro_I
	lw $a0, 0($t0) #carrega em a0 a informação de Rt
	jal analisa_registrador
	#printa Rt
	move $a0, $v0
	li $v0, 4
	syscall
	#IMM_I
	lw $t0, 12($s0)#carrega em t0 o endereço do IMM_I
	lw $a0, 0($t0)#carrega em a0 o IMM_I
	#printa IMM_I
	jal bin_to_hex
	
#pilogo
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addiu $sp, $sp, 8
	
	jr $ra
	
	
analisa_opcode_I:
#corpo
	#switch case com o opcode I 
	beq $a0, 9, op_addiu		#addiu == 0010 01
	beq $a0, 8, op_addi		#addi == 0010 00
	beq $a0, 43, op_sw		#sw == 1010 11
	beq $a0, 35, op_lw		#lw == 1000 11
				#la 
	beq $a0, 15, op_lui			#- lui == 0011 11
	beq $a0, 13, op_ori			#- ori == 0011 01
	
	beq $a0, 5, op_bne		#bne == 0001 01
	
	#se não for nenhum desses opcodes, significa que é uma instrução desconhecida
	j instrucao_desconhecida
	
	
	op_addiu:
	la $v0, str_addiu
	li $v1, 1
	jr $ra
	op_addi:
	la $v0, str_addi
	li $v1, 1
	jr $ra
	op_sw:
	la $v0, str_sw
	li $v1, 0
	jr $ra
	op_lw:
	la $v0, str_lw
	li $v1, 0
	jr $ra	
	op_lui:
	la $v0, str_lui
	li $v1, 2
	jr $ra	
	op_ori:
	la $v0, str_ori
	li $v1, 1
	jr $ra	
	op_bne:
	la $v0, str_bne
	li $v1, 3
	jr $ra
	instrucao_desconhecida:
	la $v0, str_erro
	li $v1, -1
	jr $ra

func_decodifica_J:
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	la $t0, mascara_OP_J
	lw $t1, 0($t0) # t1 = mascara_OP
	
	la $t0, mascara_IMM_J
	lw $t2, 0($t0) # t2 = mascara_IMM_J
	
	
	and $t1, $t1, $a0 # t1 = op
	srl $t1, $t1, 26
	
	and $t2, $t2, $a0 # t2 = IMM_J
	
	
	
	
	
	# armazena os valores dos registradores $tx nos seus respectivos locais da memória
	la $t0, ponteiro_J
	lw $t0, 0($t0)
	sw $t1, 0($t0)
	
	la $t0, ponteiro_J
	lw $t0, 4($t0)
	sw $t2, 0($t0)
	
	jal printa_J
	
#epilogo
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra

printa_J:
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	#analisa o opcode
	la $t0, ponteiro_J
	lw $t0, 0($t0)
	lw $a0, 0($t0) #$a0 contem o opcode da instrução J
	jal analisa_opcode_J
	#depois de ter pegado a string da isntrução
	#printa a instrução
	move $a0, $v0
	li $v0, 4
	syscall
	#IMM_J
	#Para o print da instrução J, é necessário realizar um procedimento com seu IMM e PC+4 para descobrir o loop
	la $t0, ponteiro_J
	lw $t0, 4($t0)#carrega em t0 o endereço do IMM_J
	lw $a0, 0($t0)#carrega em a0 o IMM_J
	jal descobre_loop
	
	#printa loop
	move $a0, $v0 #carrega o loop em a0
	jal bin_to_hex
	
#epilogo
	
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra

analisa_opcode_J:
#corpo
	#switch case com o opcode J
	beq $a0, 2, op_j	#j == 0000 01
	beq $a0, 3, op_jal	#jal == 0000 11
	
	
	op_j:
	la $v0, str_j
	jr $ra
	op_jal:
	la $v0, str_jal
	jr $ra
	
descobre_loop:
#corpo

	la $t0, PC #carrega endereço de PC
	lw $t0, 0($t0)#carrega conteúdo de PC
	addi $t0, $t0, 4 #PC + 4
	
	 move $t1, $a0 #passa para t1 o conteúdo de IMM_J
	 
	 sll $t1, $t1, 2 #2 shifts esquerdo no IMM_J
	 la $t2, mascara_26_bits 
	 lw $t2, 0($t2) #carrega em t2 a mascara para isolar os bits de IMM_J
	 and $t1, $t1, $t2 #'zera' os 4 bits mais significativos de IMM_J
	 
	 la $t2, mascara_4_primeiros_bits
	 lw $t2, 0($t2) #carrega em t2 a mascara para isolar os bits de PC+4
	 and $t0, $t0, $t2 #isola os 4 bits mais significativos de PC+4
	 
	 #v0 = loop
	 or $v0, $t0, $t1 # realiza um OR entre os resultados para unir os 4 primeiros bits do PC+4 com os outros 26 bits de IMM_J
#epilogo
	 jr $ra

	
main:
	addiu $sp, $sp, -20
	sw $zero, 16($sp)#valor reservado para guardar o código inteiro da instrução
	sw $zero, 12($sp)#valor reservado para processos com o opcode
	sw $zero, 8($sp)#valor de verificação de leitura do arquivo
	sw $ra, 4($sp) #valor de retorno para função chamadora
	sw $zero, 0($sp)#valor de retorno desta função
	la $a0, nome_arquivo
	jal abrir_arquivo_para_leitura
	la $t0, descritor_arquivo
	sw $v0, 0($t0) #armazenar o descritor do arquivo após abrir o arquivo
	bgtz $v0, main_if_abriu_arquivo
	
	
	main_if_nao_abriu_arquivo:
		la $a0, string_erro_ao_abrir_arquivo
		li $v0, 4
		syscall
		j fim_leitura_arquivo
	main_if_abriu_arquivo:
		la $a0, string_abriu_arquivo
		li $v0, 4
		syscall
	
#ler arquivo
	for_ler_arquivo:
	for_codigo:
	main_printa_PC:
		la $a0, PC #carrega em a0 o endereço de PC que indica o PC atual
		lw $a0, 0($a0) #carrega em a0 o valor de PC atual
		jal bin_to_hex
		#printa espaço
		li $a0, ' '
		li $v0, 11
		syscall
	main_ler_arquivo:
		la $t0, descritor_arquivo
		lw $a0, 0($t0)#armazena em a0 o descritor
	
		la $a1, buffer_leitura # armazena o endereço do buffer em a1
		
		jal ler_arquivo
		sw $v0, 8($sp) #armazena o numero de bits lidos
	main_printa_instrucao_hex:
		la $t1, buffer_leitura
		lw $a0, 0($t1) #carrega a0 a instrução lida
		sw $a0, 16($sp)# armazena a instrução
		jal bin_to_hex #printa a instrução
		#printa espaço
		li $a0, ' '
		li $v0, 11
		syscall
	main_isola_opcode:
		
		lw $a0, 16($sp)#carrega em a0 a instrução novamente
		jal isola_opcode
		sw $v0, 12($sp)# amrmazena opcode
		
	main_descobre_o_tipo_da_instrucao:
		lw $a0, 12($sp) # opcode como parâmetro
		jal descobre_tipo_instrucao
	main_decodifica_instrucao:
		move $a0, $v0 # passa o resultado como parâmetro
		lw $a1, 16($sp)# passa codigo da instrução como parâmetro
		jal decodifica_instrucao
	main_quebra_linha_para_proxima_instrucao:
		#printa '\n'
		li $a0, '\n'
		li $v0, 11
		syscall
	main_proximo_PC:
		# próximo PC == PC + 4
		la $t0, PC
		lw $t1 0($t0) #carrega em t1 o valor de PC
		addi $t1, $t1, 4 #PC + 4
		sw $t1, 0($t0) #guarda o próximo PC
		
	for_condicao:
		lw $t0, 8($sp)
		#se $t0 for menor que 4, $t1 = 1 e encerra o for
		slti $t1, $t0, 4
		# se $t1 == 0 continua o for
		beq $t1, $zero, for_codigo

fim_leitura_arquivo:
	lw $ra, 4($sp)
	lw $v0, 0($sp)
	addiu $sp, $sp, 20
	jr $ra
	
	
	
.data

nome_arquivo: .asciiz "dados_trabalho.bin"
descritor_arquivo: .word 0 #descritor do arquivo

buffer_leitura: .space 4  # buffer para a leitura do arquivo


string_erro_ao_abrir_arquivo: .asciiz "erro ao abrir arquivo\n"
string_abriu_arquivo: .asciiz "abriu arquivo\n"

PC: .word 0x00400000

mascaras:
	mascara_4_primeiros_bits: .word 0xf0000000
	mascara_26_bits: .word 0x0fffffff
# -------------------------------------
# | OP | RS | RT | RD | SHAMT | FUNCT |
#    6    5    5    5     5       6
# -------------------------------------

	mascara_OP_R: .word 0xFC000000
	mascara_RS_R: .word 0x03e00000
	mascara_RT_R: .word 0x001f0000
	mascara_RD_R: .word 0x0000f800
	mascara_SHAMT_R: .word 0x000007c0
	mascara_FUNCT_R: .word 0x0000003f

# -------------------------------------
# | OP | RS | RT  |       IMM         |
#    6    5    5          16
# -------------------------------------
	mascara_OP_I: .word 0xFC000000
	mascara_RS_I: .word 0x03e00000
	mascara_RT_I: .word 0x001f0000
	mascara_IMM_I: .word 0x0000ffff



# -------------------------------------
# | OP |            IMM               |
#    6              26  
# -------------------------------------
	mascara_OP_J: .word 0xFC000000
	mascara_IMM_J: .word 0x03ffffff

	
ponteiro_R: .word OP, RS, RT, RD, SHAMT, FUNCT	
ponteiro_I: .word OP, RS, RT, IMM_I
ponteiro_J: .word OP, IMM_J
	
opcode:
OP: .space 4
	
registradores:
RS: .space 4
RT: .space 4
RD: .space 4

tipo_R:
SHAMT: .space 4
FUNCT: .space 4

tipo_I:
IMM_I: .space 4

tipo_J:
IMM_J: .space 4

strings_R:
str_add: .asciiz "add "
str_addu: .asciiz "addu "
str_jr: .asciiz "jr "
str_syscall: .asciiz "syscall "

strings_I:
str_addiu: .asciiz "addiu "
str_addi: .asciiz "addi "
str_sw: .asciiz "sw "
str_lw: .asciiz "lw "
str_mul: .asciiz "mul "
str_lui: .asciiz "lui "
str_ori: .asciiz "ori "
str_bne: .asciiz "bne "

strings_J:
str_j: .asciiz "j "
str_jal: .asciiz "jal "


str_erro: .asciiz "instrucao desconhecida "

register_strings:
str_zero: .asciiz "$0 "
str_at: .asciiz "$1 "
str_v0: .asciiz "$2 "
str_v1: .asciiz "$3 "
str_a0: .asciiz "$4 "
str_a1: .asciiz "$5 "
str_a2: .asciiz "$6 "
str_a3: .asciiz "$7 "
str_t0: .asciiz "$8 "
str_t1: .asciiz "$9 "
str_t2: .asciiz "$10 "
str_t3: .asciiz "$11 "
str_t4: .asciiz "$12 "
str_t5: .asciiz "$13 "
str_t6: .asciiz "$14 "
str_t7: .asciiz "$15 "
str_s0: .asciiz "$16 "
str_s1: .asciiz "$17 "
str_s2: .asciiz "$18 "
str_s3: .asciiz "$19 "
str_s4: .asciiz "$20 "
str_s5: .asciiz "$21 "
str_s6: .asciiz "$22 "
str_s7: .asciiz "$23 "
str_t8: .asciiz "$24 "
str_t9: .asciiz "$25 "
str_k0: .asciiz "$26 "
str_k1: .asciiz "$27 "
str_gp: .asciiz "$28 "
str_sp: .asciiz "$29 "
str_fp: .asciiz "$30 "
str_ra: .asciiz "$31 "

hex_char: .asciiz "0x", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"

