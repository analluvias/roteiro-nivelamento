puts "ola mundo - entre aspas";
# ESTE EH UM COMENTARIO NO INICIO DE UMA LINHA
puts {ola mundo - entre chaves}
# puts {exemplo de sintaxe de comentario invalida} # *erro* - nao ha ponto e virgula
# puts "esta eh a linha 1"; puts "esta eh a linha 2"
# puts "olá mundo; com um ponto e virgula entre aspas"
# palavras nao precisam ser colocas entre aspas a menos que contenham espacos
puts olaMundo

# -----------------------------------------
# atividade 1 - TCL
# -----------------------------------------

# criando variaveis
set arquivo "contador_netlist.tcl";
set palavras {"AND2" "XOR2" "flipflop_D"}
array set contadores {}
set soma_total 0

# inicializando contadores
foreach palavra $palavras {
	set contadores($palavra) 0
}

# abrindo arquivo no modo leitura e salvando
# file = arquivo lido
set file [open $arquivo r]

# leitura linha a linha, enquanto houver linhas
# gets lê linha do arq $file e guarda em line
while {[gets $file line] >= 0 } {

	# for para cada palavra
	foreach palavra $palavras {
		# inicio da linha
		set pos 0

		# [string first $t $line $pos] -> procura a primeira ocorrencia da palavra dentro de line
		# começando por pos, ficando -1 ou a posicao encontrada
		# depois armazena o valor da posição
		while {[set indice [string first $palavra $line $pos]] != -1} {
			# somo +1 sempre que a palavra for encontrada
			incr contadores($palavra);
			
			# [string length $t] -> retorna o tamanho da string procurada
			# expr -> expressão matematica: expr {$indice + [string length $palavra]}: posicao encontrada + tam da palavra
			#  setta pos para onde vai procurar da proxima vez dentro da mesma linha
			set pos [expr {$indice + [string length $palavra]}]
			
		}
	}
}

# fecho o arquivo
close $file

# printando o resultado
puts "=== RELATORIO DE CELULAS ===";
foreach palavra $palavras {
	puts "$palavra: $contadores($palavra)"
	# soma total = expressao matematica { soma_total + contadores[i] }
	set soma_total [expr {$soma_total + $contadores($palavra)}]
}

puts "TOTAL: $soma_total"

# ----------------
# FIM ATV 1
# ----------------
