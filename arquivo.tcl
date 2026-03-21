puts "ola mundo - entre aspas";
# ESTE EH UM COMENTARIO NO INICIO DE UMA LINHA
puts {ola mundo - entre chaves}
# puts {exemplo de sintaxe de comentario invalida} # *erro* - nao ha ponto e virgula
# puts "esta eh a linha 1"; puts "esta eh a linha 2"
# puts "olá mundo; com um ponto e virgula entre aspas"
# palavras nao precisam ser colocas entre aspas a menos que contenham espacos
puts olaMundo

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
