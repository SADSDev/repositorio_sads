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

#completos
from routes import router as plan_comercial_router


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

#modelos individuales
app.include_router(mam_router)
app.include_router(mart_router) 

#modelos completos
app.include_router(plan_comercial_router)

#------------------------------------------------------------------------
# HEALTH CHECK
#------------------------------------------------------------------------
@app.get("/health")
def health():
    return {
        "status": "ok"
    }
