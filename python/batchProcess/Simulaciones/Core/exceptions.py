#------------------------------------------------------------------------
# LIBRERÍAS
#------------------------------------------------------------------------



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

#--------------------------------------------------
# REGISTRO DE MANEJADORES
#---------------------------------------------------
