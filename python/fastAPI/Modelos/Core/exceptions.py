#------------------------------------------------------------------------
# LIBRERÍAS
#------------------------------------------------------------------------
import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


#------------------------------------------------------------------------
# CONFIGURACIÓN DE LOGS
#------------------------------------------------------------------------
logger = logging.getLogger("uvicorn.error")


#------------------------------------------------------------------------
# HANDLER DE ERROR INTERNO
#------------------------------------------------------------------------
async def error_interno(
    request: Request,
    exc: Exception
):
    logger.exception(
        "Error no controlado en %s %s",
        request.method,
        request.url.path,
        exc_info=exc
    )

    return JSONResponse(
        status_code=500,
        content={
            "error": "Error interno del servidor."
        }
    )


#------------------------------------------------------------------------
# REGISTRO DE MANEJADORES
#------------------------------------------------------------------------
def registrar_manejadores(app: FastAPI):
    app.add_exception_handler(
        Exception,
        error_interno
    )
