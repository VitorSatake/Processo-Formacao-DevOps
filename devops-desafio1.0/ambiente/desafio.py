
from typing import  List, Union
from uuid import UUID, uuid4
import uuid
from fastapi import FastAPI, HTTPException, Response
from pydantic import BaseModel, Field, constr, model_serializer
from tinydb import TinyDB, Query
from typing import Optional
import json
#import psycopg2

app = FastAPI()

db = TinyDB('db.json')
tabela_pessoas = db.table('pessoas')


class Pessoa(BaseModel):
    id: UUID = None
    nome: Union[constr(max_length=100), str, int, float, bool] # type: ignore
    apelido: constr(max_length=32) # type: ignore
    nascimento: str
    stack: list[Union[str, int]] = constr(max_length=3)

    class Config:
        schema_extra = {
            "example": {
                "nome": "nome",
                "apelido": "apelido",
                "nascimento": "nascimento",
                "stack": "stack"
                }
                }
        
@app.post("/pessoas/", response_model=Pessoa)
def create_pessoa(pessoa: Pessoa, response: Response):
 
    if not isinstance(pessoa.nome, str):
        raise HTTPException(status_code=400, detail="Campo invalido")
    if tabela_pessoas.contains(Query().nome == pessoa.nome):
        raise HTTPException(status_code=400, detail="Essa pessoa já existe")
    if not pessoa.nome:
        raise HTTPException(status_code=422, detail="O campo nome é obrigatório")
       
   
    if tabela_pessoas.contains(Query().apelido == pessoa.apelido):
        raise HTTPException(status_code=400, detail="Esse apelido já existe")
    
    pessoa.id = str(uuid4())
    
    tabela_pessoas.insert(pessoa.dict())

    response.headers["Location"] = f"/pessoa/{pessoa.id}"

    return pessoa

@app.get("/pessoas/{id}", response_model=Pessoa)
def read_pessoa(id: str):
    pessoa = tabela_pessoas.get(Query().id == id)
    if not pessoa:
        raise HTTPException(status_code=404, detail="Pessoa não encontrada")
    return pessoa

@app.get("/pessoas", response_model=List[Pessoa])
def buscar(t: str):
    resultados = []
    for pessoa in tabela_pessoas:
        for chave, valor in pessoa.items():
            if chave in ["nome", "apelido", "stack"] and isinstance(valor, str) and t.lower() in valor.lower():
                resultados.append(Pessoa(**pessoa))
                break 
    if not resultados:
        raise HTTPException(status_code=404, detail="Nenhum resultado encontrado")
    return resultados

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)

