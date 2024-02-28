from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def hello_root():
    return {"message": "Hello World"}


#comando para executar a api no ambiente : uvicorn ambiente.main:app --reload