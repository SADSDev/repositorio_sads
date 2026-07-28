# Obtiene el volumen esperado mensual por ruta.

#-----------------------------------
# LIBRERIAS
#-----------------------------------
import pandas as pd


#-----------------------------------
# PROCESO DE VOLUMEN ESPERADO
#-----------------------------------
def volumen_esperado(
    df_compradores_esperados: pd.DataFrame,
    df_ticket_esperado: pd.DataFrame,
    df_frecuencia_ponderada: pd.DataFrame
) -> pd.DataFrame:

    df_volumen_esperado = (
        df_compradores_esperados
        .merge(
            df_ticket_esperado,
            on="NUR",
            how="left"
        )
        .merge(
            df_frecuencia_ponderada,
            on="NUR",
            how="left"
        )
        .assign(
            volumen_esperado=lambda x:
            x["clientes_esperados"]
            * x["ticket_esperado"]
            * x["frecuencia_ponderada"]
        )
        [["NUR", "volumen_esperado"]]
    )

    return df_volumen_esperado