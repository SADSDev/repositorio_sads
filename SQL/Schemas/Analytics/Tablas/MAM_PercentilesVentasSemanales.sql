CREATE TABLE PWST.ANALYTICS_PercentilesVentasSemanales
(
    Mes DATE NOT NULL,
    Agencia INT NOT NULL,
    NUR VARCHAR(50) NOT NULL,
    Semana_Mes INT NOT NULL,
    PMin DECIMAL(18,6) NULL,
    PMax DECIMAL(18,6) NULL

    CONSTRAINT PK_PercentilesVentasSemanales
        PRIMARY KEY CLUSTERED
        (Mes, Agencia, NUR, Semana_Mes)
);