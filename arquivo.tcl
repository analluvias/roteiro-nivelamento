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

# -----------------------------------------
# Atividade 2 - TCL
# -----------------------------------------

# RECEBE E LE O ARQUIVO

# $argc guarda o número de argumentos passados no terminal. 
# Se for 0, o usuário não digitou o nome do arquivo.
if {$argc == 0} {
    puts "Uso: tclsh extrair_hierarquia.tcl <arquivo_verilog>"
    exit 1 ;# Encerra o script com código de erro 1
}

# $argv e a lista de argumentos. lindex pega o primeiro item (índice 0), 
# que e o nome do arquivo digitado no terminal.
set filename [lindex $argv 0]

# O comando 'catch' tenta executar o 'open' (abrir o arquivo em modo leitura 'r').
if {[catch {set fp [open $filename r]} errmsg]} {
    puts "Erro ao abrir o arquivo: $errmsg"
    exit 1
}

# Le o arquivo e coloca na variavel content
set content [read $fp]

# Fecha o arquivo
close $fp

# Divide o texto em uma lista, cortando a cada quebra de linha
set lines [split $content "\n"]



# DESCOBRE QUAIS MODULOS EXISTEM NO ARQUIVO

# Cria uma lista vazia para guardar os nomes
set known_modules [list]

# Expressão Regular (regexp):
# ^\s* -> Começa a linha ignorando espaços em branco
# module\s+  -> Procura a palavra 'module' seguida de espaços
# ([a-zA-Z0-9_]+) -> Captura o nome do módulo e salva na variável 'mod_name'
foreach line $lines {
	if {[regexp {\s*module\s+([a-zA-Z0-9_]+)} $line -> mod_name]} {
		lappend known_modules $mod_name
	}
}




# PREPARANDO A MEMORIA

# Dicionarios em TCL funcionam iguais tabelas
# hierarchy: Vai guardar "NomeDoModulo -> {Submodulo1: qtd, Submodulo2: qtd}"
set hierarchy [dict create]

# has_primitives: Vai guardar "NomeDoModulo -> 1 (tem primitiva) ou 0 (não tem)"
set has_primitives [dict create]

# Varivavel para saber qual modulo esta sendo lido
set current_module ""

# Inicializa os dicionarios para cada modulo que foi encontrado
foreach mod $known_modules {
	dict set hierarchy $mod [dict create]
	dict set has_primitives $mod 0
}



# CONTAR AS INTASNCIA
foreach line $lines {
	# Verifica se entrou na declaração de um modulo
    	if {[regexp {^\s*module\s+([a-zA-Z0-9_]+)} $line -> mod_name]} {
        	set current_module $mod_name ;# Atualiza o nosso "rastreador"

    	# Verifica se saiu do modulo
    	} elseif {[regexp {^\s*endmodule} $line]} {
        	set current_module "" ;# Limpa o rastreador

    	# Se esta dentro de um modulo, procura instâncias
    	} elseif {$current_module ne ""} {

        	# Ignora linhas vazias ou comentarios
        	if {[regexp {^\s*//} $line] || [regexp {^\s*$} $line]} { continue }

        	# Procura o padrao de instancia: "TipoDaPorta NomeDaInstancia ("
        	# Captura o "TipoDaPorta" (ex: AND2, flipflop_D) na variavel 'inst_type'
        	if {[regexp {^\s*([a-zA-Z0-9_]+)\s+[a-zA-Z0-9_]+\s*\(} $line -> inst_type]} {

            		# Se o tipo instanciado e um dos modulos declarados no nosso arquivo...
            		if {$inst_type in $known_modules } {
				# Verifica se o submódulo já está no dicionário do módulo atual
                		if {[dict exists $hierarchy $current_module $inst_type]} {
                    			set count [dict get $hierarchy $current_module $inst_type]
                		} else {
                    			set count 0
                		}
                		incr count ;# Soma +1 na contagem

                		# Atualiza o dicionário aninhado de forma segura
                		dict set hierarchy $current_module $inst_type $count

            		# Se nao e um modulo nosso, pode ser uma celula primitiva (AND, XOR, etc)
            		} else {
                		# Lista de palavras reservadas do Verilog que nao sao instancias
                		set keywords {always if else assign module input output wire reg endmodule}

                		# 'ni' significa "Not In" (nao esta na lista).
                		# Se nao e palavra reservada, entao é uma celula primitiva!
                		if {$inst_type ni $keywords} {
                    			dict set has_primitives $current_module 1 ;# Marca a flag como 1 (Verdadeiro)
                		}
            		}
       		}
    	}
}



# IMPRIMIR A ARVORE FORMATADA NA TELA

puts "\n=== HIERARQUIA DO DESIGN ==="

foreach mod $known_modules {
	# Imprime o nome do modulo principal (A raiz da arvore)
	puts "\n$mod"

	# Busca os dados calculados no Passo 2	
	set submods [dict get $hierarchy $mod]
    	set num_submods [dict size $submods]
    	set prims [dict get $has_primitives $mod]

	# Cenario 1: Modulo comportamental puro
    	if {$num_submods == 0 && $prims == 0} {
        	puts "  └── (módulo primitivo - sem submódulos)"

    	# Cenario 2: Modulo que so usa portas logicas basicas (sem submodulos proprios)
    	} elseif {$num_submods == 0 && $prims == 1} {
        	puts "  └── (apenas células primitivas)"

    	# Cenario 3: Modulo misto ou estrutural (chama submodulos proprios)
    	} else {
        	set keys [dict keys $submods]
        	set total_submods [llength $keys]
        	set i 0

        	# Percorre cada submodulo instanciado e a quantidade de vezes que ele aparece
        	dict for {submod count} $submods {

			# Ajusta o plural da palavra 'instancia' usando um operador ternario
	            	set inst_str [expr {$count == 1 ? "1 instância" : "$count instâncias"}]

            		# Logica de desenho:
            		# Se nao tem primitivas e for o ultimo submodulo da lista, fecha a arvore com '└──'
            		if {$prims == 0 && $i == ($total_submods - 1)} {
                		puts "  └── $submod ($inst_str)"
            		# Caso contrario, continua a arvore com '├──'
            		} else {
                		puts "  ├── $submod ($inst_str)"
            		}
            		incr i
		}

        	# Se tambem tiver portas logicas basicas, elas sempre ficam no final da arvore
        	if {$prims == 1} {
            		puts "  └── (células primitivas)"
        	}
    	}
}
puts ""

# -----------------------
# Fim Atividade 2
# -----------------------

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