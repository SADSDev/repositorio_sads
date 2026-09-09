from fastapi import APIRouter

from MAM.modeloMAM import modeloMAM
from MART.modeloMART import modeloMART

from Schemas.request import PlanComercialRequest

router = APIRouter(
    prefix="/completos",
    tags=["completos"]
)


@router.post("/plan_comercial")
def ejecutar_plan(request: PlanComercialRequest):

    df_mam = modeloMAM(request.mam)

    df_mart = modeloMART(request.mart)

    return {
        "mam": df_mam.to_dict(orient="records"),
        "mart": df_mart.to_dict(orient="records")
    }