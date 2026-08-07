#------------------------------------------------------------------------
# LIBRERÍAS
#------------------------------------------------------------------------
import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


#-----------------------------------------------
# CONFIGURACIÓN DE LOGS
#-----------------------------------------------
logger = logging.getLogger("uvicorn.error")

#----------------------------------------------------------
# EXCEPCIONES PERSONALIZADAS
#----------------------------------------------------------

#CONEXION SQL
class ErrorConexionSQL(Exception):
    pass

#DATOS DE INSUFICIENTES EN DF´S
class ErrorDatosModelo(Exception):
    def __init__(self, dataframe: str):
        self.dataframe = dataframe

        super().__init__(
            f"El DataFrame '{dataframe}' no contiene datos."
        )

#--------------------------------------------------
# HANDLERS
#---------------------------------------------------

#error de conexion sql
async def error_conexion_sql(
    request: Request,
    exc: ErrorConexionSQL
):
    logger.exception(
        "Error de conexión SQL en %s %s",
        request.method,
        request.url.path,
        exc_info=exc
    )

    return JSONResponse(
        status_code=503,
        content={
            "error": "No fue posible conectar con la base de datos."
        }
    )


# HANDLER DE ERROR INTERNO
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

# DATOS INSUFICIENTES EN DF´S
async def error_datos_modelo(
    request: Request,
    exc: ErrorDatosModelo
):
    logger.warning(
        "MAM | datos insuficientes | dataframe=%s | ruta=%s",
        exc.dataframe,
        request.url.path
    )

    return JSONResponse(
        status_code=422,
        content={
            "error": "No hay datos suficientes para ejecutar el modelo.",
            "dataframe": exc.dataframe
        }
    )


#--------------------------------------------------
# REGISTRO DE MANEJADORES
#---------------------------------------------------
def registrar_manejadores(app: FastAPI):
    app.add_exception_handler(
        ErrorDatosModelo,
        error_datos_modelo
    )

    app.add_exception_handler(
        ErrorConexionSQL,
        error_conexion_sql
    )

    app.add_exception_handler(
        Exception,
        error_interno
    )