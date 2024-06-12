
from typing import  List, Union
from uuid import UUID, uuid4
import uuid
#from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query, Response
from pydantic import BaseModel, Field, constr, model_serializer
import psycopg2  
from psycopg2.extras import DictCursor  
from datetime import date
import os


app = FastAPI()

#load_dotenv(".env")

DB_NAME = "Pessoa"
DB_USER = "postgres"
DB_PASSWORD = "root"
DB_HOST = "127.0.0.1"#"localhost"
DB_PORT = "5432"

conn = psycopg2.connect(
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT
)

print(os.getenv("postgres"))
print(os.getenv("postgres"))
print(os.getenv("root"))
print(os.getenv("localhost"))
print(os.getenv("5432"))

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
    
        if not pessoa.nome or not isinstance(pessoa.nome, str):
            raise HTTPException(status_code=422, detail="O campo 'nome' é obrigatório")
        
        if not pessoa.apelido or not isinstance(pessoa.apelido, str):
            raise HTTPException(status_code=422, detail="O campo 'apelido' é é obrigatório")
        
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM pessoas WHERE apelido = %s", (pessoa.apelido,))
            existing_person = cursor.fetchone()
            if existing_person:
                raise HTTPException(status_code=422, detail="Uma pessoa com esse apelido já existe")
            
        if not pessoa.nascimento or not isinstance(pessoa.nascimento, str):
            raise HTTPException(status_code=422, detail="O campo 'nascimento' é é obrigatório")

        if pessoa.stack:
            if not all(isinstance(item, str) for item in pessoa.stack):
                raise HTTPException(status_code=400, detail="Todos os elementos da lista 'stack' devem ser strings")

        pessoa.id = str(uuid4())
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO pessoas (id, nome, apelido, nascimento, stack)
            VALUES (%s, %s, %s, %s, %s)
        """, (str(pessoa.id), pessoa.nome, pessoa.apelido, pessoa.nascimento, pessoa.stack))
        conn.commit()
        cur.close()
        response.headers["Location"] = f"/pessoas/{pessoa.id}" 
        
        if pessoa:
         raise HTTPException(status_code=201, detail="Pessoa criada.")
     
        return pessoa

@app.get("/pessoas/{id}", response_model=Pessoa)
def read_pessoa(id: str):
    with conn, conn.cursor(cursor_factory=DictCursor) as cursor:
        try:

            cursor.execute("SELECT * FROM pessoas WHERE id = %s", (id,))
            pessoa_dict = cursor.fetchone()

            if not pessoa_dict:
                raise HTTPException(status_code=404, detail="Pessoa não encontrada")

            nascimento = pessoa_dict[3]
            nascimento_str = nascimento.isoformat()
            pessoa_dict[3] = nascimento_str

            pessoa = Pessoa(**pessoa_dict)

            return pessoa

        except Exception as e:

            print("Erro durante a consulta SQL:", e)
            raise HTTPException(status_code=500, detail="Erro interno do servidor")

@app.get("/pessoas", response_model=List[Pessoa])
def search_pessoa(t: str):
    
    if not t:
        raise HTTPException(status_code=400, detail="O parâmetro 't' é obrigatório.")
    
    with conn, conn.cursor(cursor_factory=DictCursor) as cursor:
        try:
            cursor.execute("""
                SELECT id, nome, apelido, to_char(nascimento, 'YYYY-MM-DD') as nascimento, stack 
                FROM pessoas 
                WHERE LOWER(nome) LIKE %s OR LOWER(apelido) LIKE %s OR EXISTS (
                    SELECT 1 FROM unnest(stack) AS s
                    WHERE LOWER(s) LIKE %s
                )
            """, (f"%{t.lower()}%", f"%{t.lower()}%", f"%{t.lower()}%"))
            pessoas_dicts = cursor.fetchall()

            pessoas = [Pessoa(**pessoa_dict) for pessoa_dict in pessoas_dicts]

            return pessoas

        except Exception as e:
            print("Erro durante a consulta SQL:", e)
            raise HTTPException(status_code=200, detail="[]")
        
@app.put("/pessoas/{id}", response_model=Pessoa)
def update_pessoa(id: str, pessoa: Pessoa):
    with conn, conn.cursor() as cursor:
        cursor.execute("SELECT * FROM pessoas WHERE id = %s", (id,))
        existing_person = cursor.fetchone()
        if not existing_person:
            raise HTTPException(status_code=404, detail="Pessoa não encontrada")

        cursor.execute("""
            UPDATE pessoas
            SET nome = %s, apelido = %s, nascimento = %s, stack = %s
            WHERE id = %s
        """, (pessoa.nome, pessoa.apelido, pessoa.nascimento, pessoa.stack, id))
        conn.commit()

    return pessoa

@app.delete("/pessoas/{id}", status_code=204)
def delete_pessoa(id: str):
    with conn, conn.cursor() as cursor:
        cursor.execute("SELECT * FROM pessoas WHERE id = %s", (id,))
        pessoa_dict = cursor.fetchone()
        if not pessoa_dict:
            raise HTTPException(status_code=404, detail="Pessoa não encontrada")

        cursor.execute("DELETE FROM pessoas WHERE id = %s", (id,))
        conn.commit()

    return Response(status_code=204)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8080)