#!/bin/bash

#caminho_imagens=~/Downloads/imagens-livros

#for imagem in $@
#do
 #       convert $caminho_imagens/$imagem.jpg $caminho_imagens/$imagem.png
#done

#O símbolo $@ é utilizado para referenciar 
# odos os parâmetros passados por um 
#usuário para nosso script, sem precisar 
#ao certo quantos parâmetros são.

# melhorando o script

converte_imagem(){
cd ~/Downloads/imagens-livros

if [ ! -d png ] #verifica se existe o diretorio png
then
        mkdir png
fi

for imagem in *.jpg
do
        local imagem_sem_extensao=$(ls $imagem | awk -F. '{ print $1 }')
        #local=so pode ser acessada no escopo local, no caso, dentro da funcao
        convert $imagem_sem_extensao.jpg png/$imagem_sem_extensao.png
done
}

converte_imagem 2>erros_conversao.txt #2=mensagens de erro padrao
#redirecionando para um arquivo para armazenar essas mensagens

if [ $? -eq 0 ] #status0 = sucesso, 1-255= falha
then
        echo "Conversão realizada com sucesso"
else
        echo "Falha no processo"
fi

#A opção -F é usado quando queremos 
#especificar um campo delimitador do 
#parâmetro de texto passado. 
#Nesse nosso exemplo, estamos "cortando" 
#o parâmetro de texto passado onde 
#tivermos o .