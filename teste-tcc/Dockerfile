# Usar uma imagem base oficial do Python
FROM python:3.9-slim

# Instalar dependências de sistema necessárias
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Definir o diretório de trabalho no contêiner
WORKDIR /app

# Copiar o arquivo requirements.txt para o contêiner
COPY requirements.txt .

# Instalar as dependências do Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o restante do código da aplicação para o contêiner
COPY . .

# Expor a porta em que a aplicação irá rodar (por exemplo, 8000 para FastAPI)
EXPOSE 8080

# Definir o comando padrão para rodar a aplicação
CMD ["uvicorn", "ambiente.tcc:app", "--host", "0.0.0.0", "--port", "8080"]
