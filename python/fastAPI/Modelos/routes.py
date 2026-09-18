#--------------------------------------------
# LIBRERIAS
#-------------------------------------------
from fastapi import APIRouter

#---------------------------------------------
# IMPORTS
#---------------------------------------------
from MAM.modeloMAM import modeloMAM

from MART.modeloMART import modeloMART

from Procesos.PlanComercial_subir_a_SQL import subir_datos_sql
from Schemas.request import PlanComercialRequest
#--------------------------------------------------------
# CONFIG API PLAN COMERCIAL
#--------------------------------------------------------
router = APIRouter(
    prefix="/completos",
    tags=["completos"]
)


@router.post("/plan_comercial")
def ejecutar_plan(request: PlanComercialRequest):

    df_mam = modeloMAM(request.mam)

    df_mart = modeloMART(request.mart)

    marcas_estrategicas = [
        marca.marca
        for marca in request.mam.marcas_estrategicas
    ]

    subir_datos_sql(
        df_mam=df_mam,
        df_mart=df_mart,
        marcas_estrategicas=marcas_estrategicas,
        anio=request.mart.anio,
        mes=request.mart.mes,
        schema="PWST",
        tabla_sql="SADS_SegOper_Metas"
    )
    

    return {
        "mam": df_mam.to_dict(orient="records"),
        "mart": df_mart.to_dict(orient="records")
    }