SELECT 'UsuariosDelSistema.sql';
USE `Spuria`;

/*
*******************************************************
*                       Valeria 				              *
*******************************************************
*/

DELIMITER ;

DROP PROCEDURE IF EXISTS `CrearUsuarioValeria`;
SELECT 'CrearUsuarioValeria';

DELIMITER $$

CREATE PROCEDURE CrearUsuarioValeria() 
BEGIN
    DECLARE ExisteValeria INT;

    SELECT COUNT(*) FROM mysql.user 
    WHERE user = 'Valeria' AND host = 'localhost' 
    INTO ExisteValeria;

    IF ExisteValeria > 0 THEN 
        DROP USER 'Valeria'@'localhost';
    END IF;

    CREATE USER 'Valeria'@'localhost' IDENTIFIED BY '#25pAz7_?Xx#OR9?';
    
    GRANT SELECT (TiendaID, Codigo, Descripcion, Precio, Cantidad) ON InventarioTienda TO 'Valeria'@'localhost';
    GRANT EXECUTE ON PROCEDURE Spuria.Actualizar TO 'Valeria'@'localhost';
    GRANT EXECUTE ON PROCEDURE Spuria.Insertar TO 'Valeria'@'localhost';
    GRANT EXECUTE ON PROCEDURE Spuria.Eliminar TO 'Valeria'@'localhost';
END$$

/*
*******************************************************
*                         Paris 				              *
*******************************************************
*/

DELIMITER ;

DROP PROCEDURE IF EXISTS `CrearUsuarioParis`;
SELECT 'CrearUsuarioParis';

DELIMITER $$

CREATE PROCEDURE CrearUsuarioParis() 
BEGIN
    DECLARE ExisteParis INT;

    SELECT COUNT(*) FROM mysql.user 
    WHERE user = 'Paris' AND host = 'localhost' 
    INTO ExisteParis;

    IF ExisteParis > 0 THEN 
        DROP USER 'Paris'@'localhost';
    END IF;

    CREATE USER 'Paris'@'localhost' IDENTIFIED BY '#37KhVFmG1_Lp@#j?R4';
END$$

/******************************************************/
DELIMITER ;
/******************************************************/