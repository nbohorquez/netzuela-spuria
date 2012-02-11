SELECT 'Usuarios.sql';
USE `Spuria`;

/*
*************************************************************
*                      InsertarUsuario				              *
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarUsuario`;
SELECT 'InsertarUsuario';

DELIMITER $$

CREATE FUNCTION `InsertarUsuario` (a_Parroquia INT, a_CorreoElectronico VARCHAR(45), a_Contrasena VARCHAR(45))
RETURNS INT NOT DETERMINISTIC
BEGIN
    DECLARE AccesoID INT;

    DECLARE EXIT HANDLER FOR 1048
    BEGIN
        SET @MensajeDeError = 'Error de valor nulo en InsertarUsuario()';
        SET @CodigoDeError = 1048;
        RETURN -1048;
    END; 

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SET @MensajeDeError = 'Error de valor duplicado en InsertarUsuario()';
        SET @CodigoDeError = 1062;
        RETURN -1062;
    END;

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SET @MensajeDeError = 'Error de clave externa en InsertarUsuario()';
        SET @CodigoDeError = 1452;
        RETURN -1452;
    END;

    INSERT INTO Usuario VALUES (    
        NULL,
        a_Parroquia
    );

    SELECT LAST_INSERT_ID() INTO AccesoID; 

    INSERT INTO Acceso VALUES (
        AccesoID,
        FALSE,
        a_CorreoElectronico,
        a_Contrasena,
        NOW(),
        NULL,
        '00:00',
        0, '00:00', '00:00'
    );

    RETURN AccesoID;
END$$

/*
*************************************************************
*                    InsertarAdministrador			            *
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarAdministrador`;
SELECT 'InsertarAdministrador';

DELIMITER $$

CREATE FUNCTION `InsertarAdministrador` (a_Creador INT, a_Usuario_P INT, a_Estatus CHAR(9), a_Privilegios VARCHAR(45), 
							a_Nombre VARCHAR(45), a_Apellido VARCHAR(45))
RETURNS INT NOT DETERMINISTIC
BEGIN
    DECLARE Rastreable_P INT;
    
    DECLARE EXIT HANDLER FOR 1048
    BEGIN
        SET @MensajeDeError = 'Error de valor nulo en InsertarAdministrador()';
        SET @CodigoDeError = 1048;
        RETURN -1048;
    END; 

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SET @MensajeDeError = 'Error de clave externa en InsertarAdministrador()';
        SET @CodigoDeError = 1452;
        RETURN -1452;
    END;
    
    SELECT InsertarRastreable(a_Creador) INTO Rastreable_P;

    INSERT INTO Administrador VALUES (
        Rastreable_P,
        a_Usuario_P,
        NULL,
        a_Estatus,
        a_Privilegios,
        a_Nombre,
        a_Apellido
    );
	
    RETURN LAST_INSERT_ID();
END$$

/*
*************************************************************
*                      InsertarCliente				              *
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `InsertarCliente`;
SELECT 'InsertarCliente';

DELIMITER $$

CREATE FUNCTION `InsertarCliente` (a_Creador INT, a_Usuario_P INT, a_RIF CHAR(10), a_Categoria INT, a_Estatus CHAR(9), 
						a_NombreLegal VARCHAR(45), a_NombreComun VARCHAR(45), a_Telefono CHAR(12), 
						a_Edificio_CC CHAR(20), a_Piso CHAR(12), a_Apartamento CHAR(12), a_Local CHAR(12), 
						a_Casa CHAR(20), a_Calle CHAR(12), a_Sector_Urb_Barrio CHAR(20), a_PaginaWeb CHAR(40), 
						a_Facebook CHAR(80), a_Twitter CHAR(80))
RETURNS CHAR(10) NOT DETERMINISTIC
BEGIN
    DECLARE Rastreable_P, Describible_P INT;

    DECLARE EXIT HANDLER FOR 1048
    BEGIN
        SET @MensajeDeError = 'Error de valor nulo en InsertarCliente()';
        SET @CodigoDeError = 1048;
        RETURN -1048;
    END; 

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SET @MensajeDeError = 'Error de clave externa en InsertarCliente()';
        SET @CodigoDeError = 1452;
        RETURN -1452;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SET @MensajeDeError = 'Error de valor duplicado en InsertarCliente()';
        SET @CodigoDeError = 1062;
        RETURN -1062;
    END;

    SELECT InsertarRastreable(a_Creador) INTO Rastreable_P;
    SELECT InsertarDescribible() INTO Describible_P;
        
    INSERT INTO Cliente VALUES (
        Rastreable_P,
        Describible_P,
        a_Usuario_P,
        a_RIF,
        a_Categoria,
        a_Estatus,
        a_NombreLegal,
        a_NombreComun,
        a_Telefono,
        a_Edificio_CC,
        a_Piso,
        a_Apartamento,
        a_Local,
        a_Casa,
        a_Calle,
        a_Sector_Urb_Barrio,
        a_PaginaWeb,
        a_Facebook,
        a_Twitter
    );  
    
    RETURN a_RIF;
END$$

/***********************************************************/
DELIMITER ;
/***********************************************************/