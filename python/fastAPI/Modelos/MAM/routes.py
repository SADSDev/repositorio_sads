#------------------------------------------------------------------------
# LIBRERÍAS
#------------------------------------------------------------------------
import json

from fastapi import APIRouter
from fastapi.responses import JSONResponse


#------------------------------------------------------------------------
# IMPORTS
#------------------------------------------------------------------------
from MAM.modeloMAM import modeloMAM
from MAM.Schemas.request import MAMRequest


#------------------------------------------------------------------------
# ROUTER
#------------------------------------------------------------------------
router = APIRouter(
    prefix="/mam",
    tags=["MAM"]
)


#------------------------------------------------------------------------
# EJECUCIÓN DEL MODELO MAM
#------------------------------------------------------------------------
@router.post("")
def ejecutar_mam(request: MAMRequest):
    resultado = modeloMAM(request)

    return JSONResponse(
        content=json.loads(
            resultado.to_json(
                orient="records"
            )
        )
    )
