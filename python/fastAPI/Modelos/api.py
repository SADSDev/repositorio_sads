#------------------------------------------------------------------------
#LIBRERIAS
#------------------------------------------------------------------------
import json

from fastapi import FastAPI
from fastapi import Request
import traceback
from fastapi.responses import JSONResponse

#----------------------------------------------------------------------
#IMPORTS
#---------------------------------------------------------------------
from MAM.modeloMAM import modeloMAM
from MAM.Schemas.request import MAMRequest

#--------------------------------------------------------------------------
# APPS
#--------------------------------------------------------------------------
app=FastAPI()


#Error handler----------------------------------------------------
@app.exception_handler(Exception)
async def excepcion_global(request: Request, exc: Exception):

    traceback.print_exc()

    return JSONResponse(
        status_code=500,
        content={
            "error": "Error interno del servidor."
        }
    )


#health check---------------------------------------------
@app.get("/health")
def health():
    return {
        "status": "ok"
    }

#MAM-----------------------------------------------------
@app.post("/mam")
def ejecutar_mam(request: MAMRequest):
    resultado = modeloMAM(request)

    return JSONResponse(
        content=json.loads(resultado.to_json(orient="records"))
    )
