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


# ------------
# atividade 3
# ------------

# conceito de fanout de um fio -> número de vezes que essa net (fio) alimenta entradas

# Este script calcula o fanout de cada net (fio) em uma netlist de circuito digital.
# Fanout = número de vezes que uma net é usada como entrada para células lógicas.
# Netlist é uma descrição de como os componentes de um circuito estão conectados.

# arquivo de entrada
set arquivo "contador_netlist.tcl"

# dicionário de fanout
# As chaves serão os nomes das nets, e os valores serão seus fanouts.
# Exemplo: fanout("clock") = 5 significa que a net clock alimenta 5 entradas.
array set fanout {}

# pinos considerados como saída -> sendo os elementos y Y e Q
# essas ocorrencias não serão contadas para fanout
set output_pins {y Y Q}

# abrir arquivo
set file [open $arquivo r]


 # Loop que lê cada linha do arquivo até o final.
 # gets $file line: lê uma linha do arquivo e armazena em 'line'.
 # Retorna o número de caracteres lidos, ou -1 quando atinge o final.
 # Enquanto o retorno for >= 0, continua o loop.
while {[gets $file line] >= 0} {

    # extrair conexões .pino(net)
    set matches [regexp -all -inline {\.([A-Za-z0-9_]+)\(([^)]+)\)} $line]


	# Se não encontrou nenhum padrão .pino(net) na linha, pula para próxima linha.
    # llength $matches retorna o número de elementos na lista 'matches'.
    if {[llength $matches] == 0} {
        continue
    }

    # transformar em pares {pino net}
    # Converte a lista plana 'matches' em uma lista de pares.
    # Exemplo: matches = {.Y(Q) Y Q .A(clock) A clock}
    # A cada iteração do foreach:
    # - full recebe .Y(Q), pino recebe Y, net recebe Q
    # - depois full recebe .A(clock), pino recebe A, net recebe clock
    # 
    # pares = {{Y Q} {A clock}}
    # Cada elemento é uma lista de dois elementos: [pino, net]
    set pares {}
    foreach {full pino net} $matches {
        lappend pares [list $pino $net]
    }

    # separar entradas e saídas
    # Cria duas listas vazias:
    # - entradas: armazena nets que estão conectadas a pinos de entrada
    # - saidas: armazena nets que estão conectadas a pinos de saída
    set entradas {}
    set saidas {}

    
	# Para cada par [pino, net], extrai o nome do pino e da net.
    # lindex $par 0: pega o primeiro elemento (pino)
    # lindex $par 1: pega o segundo elemento (net)
    foreach par $pares {
        set pino [lindex $par 0]
        set net  [lindex $par 1]

        # identificar saída
        # lsearch -exact $output_pins $pino: procura o nome do pino na lista de pinos de saída.
        # -exact: busca exata (não usa expressões regulares)
        # Se encontrar (retorno != -1), é um pino de saída, então adiciona a net
        # na lista 'saidas'.
        # Caso contrário, é um pino de entrada, adiciona a net na lista 'entradas'.
        if {[lsearch -exact $output_pins $pino] != -1} {
            lappend saidas $net
        } else {
            lappend entradas $net
        }
    }

    # garantir que saídas existam no fanout
    # Se não existir, inicializa com valor 0.
    # Isso garante que todas as nets que são saídas estarão no dicionário,
    # mesmo que tenham fanout zero (não conectadas a nenhuma entrada).
    foreach net $saidas {
        if {![info exists fanout($net)]} {
            set fanout($net) 0
        }
    }

    # contar fanout (somente entradas)
    # Para cada net que é entrada, incrementa seu fanout.
    # Mas primeiro verifica se é uma constante (ex: 1'b1, 1'b0, 32'hFFFFFFFF).
    # Expressão regular para identificar constantes:
    # ^[0-9]+'[bhd][0-9a-fA-F]+$
    # - ^[0-9]+  : começa com um ou mais dígitos (tamanho em bits)
    # - '[bhd]   : apóstrofo seguido de b (binário), h (hexadecimal) ou d (decimal)
    # - [0-9a-fA-F]+ : um ou mais dígitos/letras representando o valor
    # - $         : fim da string
    #
    # Se for constante, não conta fanout (continue pula para próxima iteração)
    foreach net $entradas {

        # ignorar constantes (ex: 1'b1, 1'b0)
        if {[regexp {^[0-9]+'[bhd][0-9a-fA-F]+$} $net]} {
            continue
        }

        # Se a net não existe no array, inicializa com 0
        if {![info exists fanout($net)]} {
            set fanout($net) 0
        }

		# incr incrementa o valor da net em 1 (fanout += 1)
        incr fanout($net)
    }
}

close $file

# =========================
# RELATÓRIOS
# =========================

puts "\n=== FANOUT POR NET ==="

# converter array → lista
# Converte o array fanout para uma lista de pares [net, fanout].
# array names fanout: retorna todas as chaves (nomes das nets) do array.
# Para cada net, cria uma lista [net, fanout($net)] e adiciona em 'lista'.
# Exemplo: fanout("clock")=5, fanout("reset")=2
# lista = {{clock 5} {reset 2}}
set lista {}
foreach net [array names fanout] {
    lappend lista [list $net $fanout($net)]
}

# ordenar por fanout (decrescente)
set ordenado [lsort -decreasing -integer -index 1 $lista]

# top 15
puts "\n=== TOP 15 FANOUT ==="
foreach item [lrange $ordenado 0 14] {
    puts "[lindex $item 0]: [lindex $item 1]"
}

# fanout zero
# São nets que foram identificadas como saídas de algum componente,
# mas não alimentam nenhuma entrada.
puts "\n=== FANOUT ZERO (analisar) ==="
foreach net [array names fanout] {
    if {$fanout($net) == 0} {
        puts $net
    }
}
