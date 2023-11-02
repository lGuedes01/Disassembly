.text

init:
	jal main
fim:
	move $a0, $v0
	li $v0, 17
	syscall
	
	
	
abrir_arquivo_para_escrita:
#prologo

#corpo
	la $a0, nome_arquivo_de_escrita
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall

#epilogo
	jr $ra
	
	
escreve_arquivo:
#prologo
# tenho que passar por a0 a string que quero botar no arquivo e por a1 o numero de caracteres da string. Depois passas a1 -> a2 e a0 -> a1
#corpo
	move $a2, $a1
	move $a1, $a0
	
	la $t0, descritor_arquivo_de_escrita
	lw $a0, 0($t0)
	li $v0, 15
	syscall
#epilogo
	jr $ra

abrir_arquivo_para_leitura:
#prologo

#corpo
	la $a0, nome_arquivo_de_leitura
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall

#epilogo
	jr $ra


ler_arquivo:
#prologo
#corpo
	la $t0, descritor_arquivo_de_leitura
	lw $a0, 0($t0)#armazena em a0 o descritor
		
	la $a1, buffer_leitura # armazena o endereço do buffer em a1
	
	li $a2, 4 #numero de bytes para ser lido do arquivo
	li $v0, 14
	syscall
#epilogo
	jr $ra
	
	
bin_to_hex:
#prologo
	addiu $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $a0, 12($sp)#armazena o numero que foi passado para a função
#corpo
	
	#imprimir o Ox
	la $a0, hex_char # a0 = endereço da string com caracteres hexadecimais
	li $a1, 2
	jal escreve_arquivo
	
	
	li $s0, 0 #o procedimento irá de 0 a 7
	lw $s1, 12($sp)#carrega o numero passado para a função em s1
	for_bin_to_hex:
	#codigo for
	la $a0, hex_char
	la $t0, mascara_4_primeiros_bits
	lw $t0, 0($t0)
	and $t1, $s1, $t0 #t1 = 4 bits mais significativos
	sll $s1, $s1, 4 #muda os 4 bits mais significativos
	srl $t1, $t1, 28 #ajeita os bits depois de usar a mascara
	sll $t1, $t1, 1 #multiplica t1 por 2
	add $t1, $t1, 3 #adiciona 3 para q a0 possa receber o endereço do numero correspondente
	add $a0, $a0, $t1 #a0 == endereço na string do caracter correspondente ao numero
	#printa o caracter
	li $a1, 1
	jal escreve_arquivo
	#incrementa o for
	add $s0, $s0, 1
	#condição do for
	bne $s0, 8, for_bin_to_hex
#epilogo
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $a0, 12($sp)
	addiu $sp, $sp, 16
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
	addiu $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
#corpo
	#analisa a funct
	la $t0, ponteiro_R
	lw $t0, 20($t0)
	lw $a0, 0($t0) #$a0 contem o funct da instrução R
	jal analisa_funct
	move $s0, $v1
	#agora analisa os registradores
	beq $s0, 2, fim_printa_R # se s0 == 2 instrução é syscall, não tem registradores
	beq $s0, 1, print_RS #se s0 == 1 instrução é jr, só printa o RS
	#RD
	la $t0, ponteiro_R
	lw $t0, 12($t0)
	lw $a0, 0($t0) #$a0 contem o rd da instrução R
	jal analisa_registrador
	#RS
	print_RS:
	la $t0, ponteiro_R
	lw $t0, 4($t0)
	lw $a0, 0($t0) #$a0 contem o rs da instrução R
	jal analisa_registrador
	beq $s0, 1, fim_printa_R #se s0 == 1 instrução é jr, só printa o RS
	#RT
	la $t0, ponteiro_R
	lw $t0, 8($t0)
	lw $a0, 0($t0) #$a0 contem o rt da instrução R
	jal analisa_registrador
#epilogo
	fim_printa_R:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addiu $sp, $sp, 8
	jr $ra


analisa_funct:
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	#switch case com o campo funct
	beq $a0, 32, funct_add     # se funct == 10 0000 
	beq $a0, 33, funct_addu     # se funct == 10 0001 
	beq $a0, 8, funct_jr     # se funct == 00 1000 
	beq $a0, 12, funct_syscall     # se funct == 00 1100
	beq $a0, 2, funct_mul		#mul == 00 0010
	
	
	funct_add:
	la $a0, str_add
	li $a1, 4
	jal escreve_arquivo
	li $v1, 0
	j epilogo_AF
	funct_addu:
	la $a0, str_addu
	li $a1, 5
	jal escreve_arquivo
	li $v1, 0
	j epilogo_AF
	funct_jr:
	la $a0, str_jr
	li $a1, 3
	jal escreve_arquivo
	li $v1, 1
	j epilogo_AF
	funct_syscall:
	la $a0, str_syscall
	li $a1, 8
	jal escreve_arquivo
	li $v1, 2
	j epilogo_AF
	funct_mul:
	la $a0, str_mul
	li $a1, 4
	jal escreve_arquivo
	la $v1, 0
	j epilogo_AF
#epilogo
epilogo_AF:
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	
analisa_registrador:
#prologo
	addiu $sp, $sp, -4
	sw $ra 0($sp)
#corpo
	move $t0, $a0
	#retorna o endereço da string relativo ao registrador usado
	la $a0, str_zero
	li $a1, 3
	beq $t0, 0, print_AR
	la $a0, str_at
	li $a1, 3
	beq $t0, 1, print_AR
	la $a0, str_v0
	li $a1, 3
	beq $t0, 2, print_AR
	la $a0, str_v1
	li $a1, 3
	beq $t0, 3, print_AR
	la $a0, str_a0
	li $a1, 3
	beq $t0, 4, print_AR
	la $a0, str_a1
	li $a1, 3
	beq $t0, 5, print_AR
	la $a0, str_a2
	li $a1, 3
	beq $t0, 6, print_AR
	la $a0, str_a3
	li $a1, 3
	beq $t0, 7, print_AR
	la $a0, str_t0
	li $a1, 3
	beq $t0, 8, print_AR
	la $a0, str_t1
	li $a1, 3
	beq $t0, 9, print_AR
	la $a0, str_t2
	li $a1, 4
	beq $t0, 10, print_AR
	la $a0, str_t3
	li $a1, 4
	beq $t0, 11, print_AR
	la $a0, str_t4
	li $a1, 4
	beq $t0, 12, print_AR
	la $a0, str_t5
	li $a1, 4
	beq $t0, 13, print_AR
	la $a0, str_t6
	li $a1, 4
	beq $t0, 14, print_AR
	la $a0, str_t7
	li $a1, 4
	beq $t0, 15, print_AR
	la $a0, str_s0
	li $a1, 4
	beq $t0, 16, print_AR
	la $a0, str_s1
	li $a1, 4
	beq $t0, 17, print_AR
	la $a0, str_s2
	li $a1, 4
	beq $t0, 18, print_AR
	la $a0, str_s3
	li $a1, 4
	beq $t0, 19, print_AR
	la $a0, str_s4
	li $a1, 4
	beq $t0, 20, print_AR
	la $a0, str_s5
	li $a1, 4
	beq $t0, 21, print_AR
	la $a0, str_s6
	li $a1, 4
	beq $t0, 22, print_AR
	la $a0, str_s7
	li $a1, 4
	beq $t0, 23, print_AR
	la $a0, str_t8
	li $a1, 4
	beq $t0, 24, print_AR
	la $a0, str_t9
	li $a1, 4
	beq $t0, 25, print_AR
	la $a0, str_k0
	li $a1, 4
	beq $t0, 26, print_AR
	la $a0, str_k1
	li $a1, 4
	beq $t0, 27, print_AR
	la $a0, str_gp
	li $a1, 4
	beq $t0, 28, print_AR
	la $a0, str_sp
	li $a1, 4
	beq $t0, 29, print_AR
	la $a0, str_fp
	li $a1, 4
	beq $t0, 30, print_AR
	la $a0, str_ra
	li $a1, 4
	beq $t0, 31, print_AR
	
print_AR:
	jal escreve_arquivo
	
	
#epilogo
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
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
	move $t0, $v1
	
	#printa as informçaões baseado na instrução retornada
	beq $t0, 0, print0
	beq $t0, 1, print1
	beq $t0, 2, print2
	beq $t0, 3, print3
	beq $t0, -1, fim_print_I
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
	#IMM_I
	lw $t0, 12($s0)#carrega em t0 o endereço do IMM_I
	lw $a0, 0($t0)#carrega em a0 o IMM_I
	#printa IMM_I
	jal bin_to_hex
	
	# printa '('
	la $a0, str_abre_parenteses
	li $a1, 1
	jal escreve_arquivo
	
	#RS
	lw $t0, 4($s0)
	lw $a0, 0($t0)
	jal analisa_registrador
	
	# printa ')'
	la $a0, str_fecha_parenteses
	li $a1, 1
	jal escreve_arquivo
	
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

	#RS
	lw $t0, 4($s0)
	lw $a0, 0($t0)
	jal analisa_registrador

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

	#RT
	lw $t0, 8($s0) #carrega em t0 o endereço de Rt no ponteiro_I
	lw $a0, 0($t0) #carrega em a0 a informação de Rt
	jal analisa_registrador

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
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
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
	la $a0, str_addiu
	li $a1, 6
	jal escreve_arquivo
	li $v1, 1
	j epilogo_analisa_op_I
	op_addi:
	la $a0, str_addi
	li $a1, 5
	jal escreve_arquivo
	li $v1, 1
	j epilogo_analisa_op_I
	op_sw:
	la $a0, str_sw
	li $a1, 3
	jal escreve_arquivo
	li $v1, 0
	j epilogo_analisa_op_I
	op_lw:
	la $a0, str_lw
	li $a1, 3
	jal escreve_arquivo
	li $v1, 0
	j epilogo_analisa_op_I	
	op_lui:
	la $a0, str_lui
	li $a1, 4
	jal escreve_arquivo
	li $v1, 2
	j epilogo_analisa_op_I	
	op_ori:
	la $a0, str_ori
	li $a1, 4
	jal escreve_arquivo
	li $v1, 1
	j epilogo_analisa_op_I	
	op_bne:
	la $a0, str_bne
	li $a1, 4
	jal escreve_arquivo
	li $v1, 3
	j epilogo_analisa_op_I
	instrucao_desconhecida:
	la $a0, str_erro
	li $a1, 23
	jal escreve_arquivo
	li $v1, -1
	j epilogo_analisa_op_I
#epilogo
epilogo_analisa_op_I:
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
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
#prologo
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
#corpo
	#switch case com o opcode J
	beq $a0, 2, op_j	#j == 0000 01
	beq $a0, 3, op_jal	#jal == 0000 11
	
	
	op_j:
	la $a0, str_j
	li $a1, 2
	jal escreve_arquivo
	j epilogo_analisa_op_J
	op_jal:
	la $a0, str_jal
	li $a1, 4
	jal escreve_arquivo
	j epilogo_analisa_op_J
	
#epilogo
epilogo_analisa_op_J:
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
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
	jal abrir_arquivo_para_leitura
	la $t0, descritor_arquivo_de_leitura
	sw $v0, 0($t0) #armazenar o descritor do arquivo após abrir o arquivo
	bgtz $v0, main_if_abriu_arquivo_de_leitura
	main_if_nao_abriu_arquivo_de_leitura:
		la $a0, string_erro_ao_abrir_arquivo
		li $v0, 4
		syscall
		j fim_leitura_arquivo
	main_if_abriu_arquivo_de_leitura:
		la $a0, string_abriu_arquivo
		li $v0, 4
		syscall
		
	jal abrir_arquivo_para_escrita
	la $t0, descritor_arquivo_de_escrita
	sw $v0, 0($t0) #armazenar o descritor do arquivo após abrir o arquivo
	bgtz $v0, main_if_abriu_arquivo_de_escrita
	main_if_nao_abriu_arquivo_de_escrita:
		la $a0, string_erro_ao_abrir_arquivo
		li $v0, 4
		syscall
		j fim_leitura_arquivo
	main_if_abriu_arquivo_de_escrita:
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
		la $a0, space
		li $a1, 1
		jal escreve_arquivo
	main_ler_arquivo:
		
		
		jal ler_arquivo
		sw $v0, 8($sp) #armazena o numero de bits lidos
	main_printa_instrucao_hex:
		la $t1, buffer_leitura
		lw $a0, 0($t1) #carrega a0 a instrução lida
		sw $a0, 16($sp)# armazena a instrução
		jal bin_to_hex #printa a instrução
		#printa espaço
		la $a0, space
		li $a1, 1
		jal escreve_arquivo
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
		la $a0, enter
		li $a1, 1
		jal escreve_arquivo
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

nome_arquivo_de_leitura: .asciiz "arquivo_entrada.bin"
descritor_arquivo_de_leitura: .word 0 #descritor do arquivo de leitura
buffer_leitura: .space 4  # buffer para a leitura do arquivo

nome_arquivo_de_escrita: .asciiz "arquivo_saida.txt"
descritor_arquivo_de_escrita: .word 0 #descritor do arquivo de saida
buffer_escrita: .space 4 # buffer para escrita no arquivo

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

space: .asciiz " "
enter: .asciiz "\n"
str_fecha_parenteses: .asciiz ")"
str_abre_parenteses: .asciiz "("
