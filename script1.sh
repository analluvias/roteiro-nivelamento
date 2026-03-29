#!/bin/bash

PASTA="$1"

if [ -z "$PASTA" ]; then
    echo "Uso: $0 <diretorio>"
    exit 1
fi

# Função que decide o destino do arquivo
classificar_arquivo() {
    local arquivo="$1"
    local nome=$(basename "$arquivo")

    # regra: include (.vh)
    if [[ "$arquivo" == *.vh ]]; then
        echo "include"

    # regra: scripts (.tcl, .do, .sh)
    elif [[ "$arquivo" == *.tcl || "$arquivo" == *.do || "$arquivo" == *.sh ]]; then
        echo "scripts"

    # regra: testbench
    elif [[ "$nome" == *_tb.v || "$nome" == *test* ]]; then
        echo "tb"

    # regra: src (.v que não são testbench)
    elif [[ "$arquivo" == *.v ]]; then
        echo "src"

    # regra: docs (fallback)
    else
        echo "docs"
    fi
}

# Percorrendo arquivos
for arquivo in "$PASTA"/*; do
    if [ -f "$arquivo" ]; then

        destino=$(classificar_arquivo "$arquivo")

        echo "Arquivo: $arquivo -> Pasta: $destino"

        # cria a pasta se não existir
        mkdir -p "$PASTA/$destino"

        # move o arquivo
        mv "$arquivo" "$PASTA/$destino/"
    fi
done
