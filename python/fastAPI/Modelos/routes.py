#--------------------------------------------
# LIBRERIAS
#-------------------------------------------
from fastapi import APIRouter

#---------------------------------------------
# IMPORTS
#---------------------------------------------
from fastAPI.Modelos.MAM.modeloMAM import modeloMAM

from fastAPI.Modelos.MART.modeloMART import modeloMART

from fastAPI.Modelos.Procesos.PlanComercial_subir_a_SQL import subir_datos_sql_plancomercial
from fastAPI.Modelos.Schemas.request import PlanComercialRequest
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

    metas_agencia = {
        "VOLUMEN GTP": request.mam.meta_gtp,
        "VOLUMEN MM": request.mam.meta_mm
    }

    subir_datos_sql_plancomercial(
        df_mam=df_mam,
        df_mart=df_mart,
        indicadores_agencia=metas_agencia,
        marcas_estrategicas=marcas_estrategicas,
        anio=request.mart.anio,
        mes=request.mart.mes,
        agencia=request.mart.agencia,
        schema="PWST",
        tabla_metas_diarias_sql="SADS_SegOper_Metas",
        tabla_metas_agencia_sql="SADS_SegOper_MetasAgencia"
    )
    

    return {
        "mam": df_mam.to_dict(orient="records"),
        "mart": df_mart.to_dict(orient="records")
    }