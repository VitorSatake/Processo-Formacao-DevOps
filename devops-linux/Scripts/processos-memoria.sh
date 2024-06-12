#!/bin/bash

if [ ! -d log ]
then
        mkdir log
fi

processos_memoria(){
processos=$(ps -e -o pid --sort -size | head -n 11 | grep [0-9])
for pid in $processos
do
        nome_processo=$(ps -p $pid -o comm=)
        echo -n $(date +%F,%H:%M:%S,) >> log/$nome_processo.log # > sobreescreve oque esta no arquivo, >> adiciona apenas ao que ja está la
        tamanho_processo=$(ps -p $pid -o size | grep [0-9])
        echo "$(bc <<< "scale=2;$tamanho_processo/1024") MB" >> log/$nome_processo.log
        # -n , nao faz quebra de linha
done
}

processos_memoria
if [ $? -eq 0 ]
then
        echo "Arquivos salvos com sucesso"
else
        echo "Houve um problema"
fi


# A opção scale é utilizada para especificar quantas casas decimais nós queremos considerar na divisão,