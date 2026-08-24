#------------------------------------------------------------------------
# LIBRERÍAS
#------------------------------------------------------------------------
import json

from fastapi import APIRouter
from fastapi.responses import JSONResponse


#------------------------------------------------------------------------
# IMPORTS
#------------------------------------------------------------------------
from .modeloMART import modeloMART
from .Schemas.request import MARTRequest


#------------------------------------------------------------------------
# ROUTER
#------------------------------------------------------------------------
router = APIRouter(
    prefix="/mart",
    tags=["MART"]
)


#------------------------------------------------------------------------
# EJECUCIÓN DEL MODELO MAM
#------------------------------------------------------------------------
@router.post("")
def ejecutar_mam(request: MARTRequest):
    resultado = modeloMART(request)

    return JSONResponse(
        content=json.loads(
            resultado.to_json(
                orient="records"
            )
        )
    )
