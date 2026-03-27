#!/bin/bash

# CAMINHO DO ARQUIVO QUE VOCÊ DESEJA ORGANIZAR
PASTA="$1"

# echo "$PASTA"

PASTAS_EXISTENTES=()

# for para percorrer pastas existentes
for pasta in "$PASTA"/*; do
    if [ -d "$pasta" ]; then
    	nome_pasta=${pasta##*/}
        PASTAS_EXISTENTES+=("$nome_pasta")
    fi
done

# printo as pastas encontradas
echo "${PASTAS_EXISTENTES[@]}"
echo ""

for arquivo in "$PASTA"/*; do
    if [ -f "$arquivo" ]; then
        echo "$arquivo"

        # pegando a extensao
        extensao="${arquivo##*.}"
        echo "$extensao"

		# testando se a extensao atual existe na lista de pastas criadas
        if [[ " ${PASTAS_EXISTENTES[*]} " == *" $extensao "* ]]; then
        	# se existir, entao nao crio a pasta
        	echo ""
            echo "Encontrado"
        else 
        	echo ""
        	echo "vou criar essa nova pasta $extensao"
        	mkdir "$1/$extensao"
        fi
    fi
done
