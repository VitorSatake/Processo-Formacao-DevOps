# Use a imagem base do Python
FROM python:3.9-slim

# Define o diretório de trabalho na imagem
WORKDIR /app

# Copia o arquivo requirements.txt para a imagem
COPY requeriments.txt .

# Instala as dependências da aplicação
RUN pip install --no-cache-dir -r requeriments.txt

# Copia o código fonte da aplicação para a imagem
COPY . .

# Expõe a porta em que a aplicação estará em execução
EXPOSE 8000

# Comando para iniciar a aplicação quando o contêiner for executado
CMD ["uvicorn", "desafio.main:app", "--host", "0.0.0.0", "--port", "8000"]
