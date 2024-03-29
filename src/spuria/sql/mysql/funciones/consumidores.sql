SELECT 'consumidores.sql';
USE `spuria`;

/*
*************************************************************
*						InsertarSeguidor					*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarSeguidor`;
SELECT 'InsertarSeguidor';

DELIMITER $$

CREATE FUNCTION `InsertarSeguidor` (a_CalificableSeguibleID INT, a_ConsumidorID INT, a_AvisarSi CHAR(40))
RETURNS INT NOT DETERMINISTIC
BEGIN
    DECLARE rastreable_p, creador INT;

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

	SELECT u.rastreable_p
	FROM usuario AS u
	JOIN consumidor AS c ON u.usuario_id = c.usuario_p
	WHERE c.consumidor_id = a_ConsumidorID
	INTO creador;

    SELECT InsertarRastreable(creador) INTO rastreable_p;

    INSERT INTO seguidor VALUES (
        rastreable_p,
        a_ConsumidorID,
        a_CalificableSeguibleID,
        a_AvisarSi
    );

    RETURN TRUE;
END$$

/*
*************************************************************
*                    InsertarConsumidor						*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarConsumidor`;
SELECT 'InsertarConsumidor';

DELIMITER $$

CREATE FUNCTION `InsertarConsumidor` (a_Creador INT, a_Nombre VARCHAR(45), a_Apellido VARCHAR(45), 
                                      a_Estatus CHAR(9), a_Sexo CHAR(6), a_FechaDeNacimiento DATE, 
                                      a_GrupoDeEdad CHAR(15), a_GradoDeInstruccion CHAR(16), a_Ubicacion CHAR(16), 
                                      a_CorreoElectronico VARCHAR(45), a_Contrasena VARBINARY(60))
RETURNS INT NOT DETERMINISTIC
BEGIN
    DECLARE Interlocutor_P, UsuarioID INT;
        
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
		a_Creador, 
		a_Nombre, 
		a_Apellido, 
		a_Estatus, 
		a_Ubicacion, 
		a_CorreoElectronico, 
		a_Contrasena
    ) INTO UsuarioID;
  
    SELECT InsertarInterlocutor() INTO Interlocutor_P;

    INSERT INTO consumidor VALUES (
        Interlocutor_P,
        UsuarioID,
        NULL,
        a_Sexo,
        a_FechaDeNacimiento,
        a_GrupoDeEdad,
        a_GradoDeInstruccion
    );

    RETURN LAST_INSERT_ID();
END$$

/*
*************************************************************
*                    InsertarConsumidor						*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarConsumidor2`;
SELECT 'InsertarConsumidor2';

DELIMITER $$

CREATE FUNCTION `InsertarConsumidor2` (a_UsuarioID INT, a_Sexo CHAR(6), a_FechaDeNacimiento DATE, 
                                       a_GrupoDeEdad CHAR(15), a_GradoDeInstruccion CHAR(16))
RETURNS INT NOT DETERMINISTIC
BEGIN
    DECLARE Interlocutor_P INT;
        
    DECLARE EXIT HANDLER FOR 1048
    BEGIN
        SET @MensajeDeError = 'Error de valor nulo en InsertarConsumidor2()';
        SET @CodigoDeError = 1048;
        RETURN -1048;
    END; 

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SET @MensajeDeError = 'Error de clave externa en InsertarConsumidor2()';
        SET @CodigoDeError = 1452;
        RETURN -1452;
    END;

    SELECT InsertarInterlocutor() INTO Interlocutor_P;

    INSERT INTO consumidor VALUES (
        Interlocutor_P,
        a_UsuarioID,
        NULL,
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
