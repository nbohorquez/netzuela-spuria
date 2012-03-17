SELECT 'consumidores.sql';
USE `spuria`;

/*
*************************************************************
*				               InsertarSeguidor			                *
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarSeguidor`;
SELECT 'InsertarSeguidor';

DELIMITER $$

CREATE FUNCTION `InsertarSeguidor` (a_Creador INT, a_CalificableSeguibleID INT, a_ConsumidorID INT, a_AvisarSi CHAR(40))
RETURNS INT NOT DETERMINISTIC
BEGIN
    DECLARE Rastreable_P INT;

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SET @MensajeDeError = 'Error de clave externa en InsertarSeguidor()';
        SET @CodigoDeError = 1452;
        RETURN -1452;
    END; 

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SET @MensajeDeError = 'Error de valor duplicado en InsertarSeguidor()';
        SET @CodigoDeError = 1062;
        RETURN -1062;
    END;

    DECLARE EXIT HANDLER FOR 1048
    BEGIN
        SET @MensajeDeError = 'Error de valor nulo en InsertarSeguidor()';
        SET @CodigoDeError = 1048;
        RETURN -1048;
    END; 

    SELECT InsertarRastreable(a_Creador) INTO Rastreable_P;

    INSERT INTO seguidor VALUES (
        Rastreable_P,
        a_ConsumidorID,
        a_CalificableSeguibleID,
        a_AvisarSi
    );

    RETURN TRUE;
END$$

/*
*************************************************************
*                    InsertarConsumidor				              *
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarConsumidor`;
SELECT 'InsertarConsumidor';

DELIMITER $$

CREATE FUNCTION `InsertarConsumidor` (a_Creador INT, a_Nombre VARCHAR(45), a_Apellido VARCHAR(45), 
                                      a_Estatus CHAR(9), a_Sexo CHAR(6), a_FechaDeNacimiento DATE, 
                                      a_GrupoDeEdad CHAR(15), a_GradoDeInstruccion CHAR(16), a_Parroquia INT, 
                                      a_CorreoElectronico VARCHAR(45), a_Contrasena VARCHAR(45))
RETURNS INT NOT DETERMINISTIC
BEGIN
    DECLARE Rastreable_P, Interlocutor_P, UsuarioID, ConsumidorID INT;
        
    DECLARE EXIT HANDLER FOR 1048
    BEGIN
        SET @MensajeDeError = 'Error de valor nulo en InsertarConsumidor()';
        SET @CodigoDeError = 1048;
        RETURN -1048;
    END; 

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SET @MensajeDeError = 'Error de clave externa en InsertarConsumidor()';
        SET @CodigoDeError = 1452;
        RETURN -1452;
    END;

    SELECT InsertarUsuario (
        a_Parroquia, 
        a_CorreoElectronico, a_Contrasena
    ) INTO UsuarioID;

    SELECT InsertarRastreable(a_Creador) INTO Rastreable_P;    
    SELECT InsertarInterlocutor() INTO Interlocutor_P;

    INSERT INTO consumidor VALUES (
        Rastreable_P,
        Interlocutor_P,
        UsuarioID,
        NULL,
        a_Nombre,
        a_Apellido,
        a_Estatus,
        a_Sexo,
        a_FechaDeNacimiento,
        a_GrupoDeEdad,
        a_GradoDeInstruccion
    );

    RETURN LAST_INSERT_ID();
END$$

/***********************************************************/
DELIMITER ;
/***********************************************************/