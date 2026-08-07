#------------------------------------------------------------------------
# LIBRERÍAS
#------------------------------------------------------------------------
from fastapi import FastAPI


#------------------------------------------------------------------------
# IMPORTS
#------------------------------------------------------------------------

#excepciones
from Core.exceptions import registrar_manejadores

#modelos
from MAM.routes import router as mam_router
from MART.routes import router as mart_router

#------------------------------------------------------------------------
# APLICACIÓN
#------------------------------------------------------------------------
app = FastAPI(
    title="Modelos SODISA"
)


#------------------------------------------------------------------------
# CONFIGURACIÓN
#------------------------------------------------------------------------
registrar_manejadores(app)

app.include_router(mam_router)
app.include_router(mart_router) 


#------------------------------------------------------------------------
# HEALTH CHECK
#------------------------------------------------------------------------
@app.get("/health")
def health():
    return {
        "status": "ok"
    }
