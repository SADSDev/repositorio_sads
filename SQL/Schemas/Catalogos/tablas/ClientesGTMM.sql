  
CREATE TABLE PWST.CATALOGOS_ClientesGTMM
(
    Cliente VARCHAR(20) NOT NULL,
    Clasificacion VARCHAR(50),
    SD VARCHAR(100),
    MDZ VARCHAR(150),
    Agencia INT,

    CONSTRAINT PK_CATALOGOS_ClientesGTMM
        PRIMARY KEY (Cliente),

    CONSTRAINT FK_ClientesGTMM_Cliente
        FOREIGN KEY (Cliente)
        REFERENCES PWST.POWERSTREET_Universo_Clientes (Codigo_GLN),

    CONSTRAINT FK_ClientesGTMM_Agencia
        FOREIGN KEY (Agencia)
        REFERENCES PWST.CATALOGOS_Agencias (Agencia)
);
