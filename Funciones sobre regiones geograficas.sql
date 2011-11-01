USE `Spuria`;

/*
*************************************************************
*			TiendasConsumidoresCrear			*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `TiendasConsumidoresCrear`;
DELIMITER $$

CREATE FUNCTION `TiendasConsumidoresCrear` (a_RegionGeograficaID INT, a_NumeroDeConsumidores INT, a_NumeroDeTiendas INT)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE C, P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en TiendasConsumidoresCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en TiendasConsumidoresCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;
*/
	SELECT COUNT(*) FROM TiendasConsumidores
	WHERE RegionGeograficaID = a_RegionGeograficaID
	INTO C;

    	IF C > 0 THEN /* Hay ya por lo menos un valor historico almacenado; hay que sustituirlo */
        	UPDATE TiendasConsumidores
        	SET FechaFin = NOW() 
        	WHERE RegionGeograficaID = a_RegionGeograficaID AND FechaFin IS NULL;
  	END IF;

	INSERT INTO TiendasConsumidores VALUES (
		a_RegionGeograficaID,
		NOW(),
		NULL,
		a_NumeroDeConsumidores,
		a_NumeroDeTiendas
	);

    	SELECT Poblacion FROM RegionGeografica 
	WHERE RegionGeograficaID = a_RegionGeograficaID INTO P;

	UPDATE RegionGeografica 
	SET Consumidores_Poblacion = a_NumeroDeConsumidores/P, Tiendas_Poblacion = a_NumeroDeTiendas/P, Tiendas_Consumidores = a_NumeroDeTiendas/a_NumeroDeConsumidores 
	WHERE RegionGeograficaID = a_RegionGeograficaID;

	RETURN TRUE;
END$$

/*
*************************************************************
*			RegionGeografiaCrear				*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `RegionGeograficaCrear`;
DELIMITER $$

CREATE FUNCTION `RegionGeograficaCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE RegionGeografica_P, Dibujable_P, Rastreable_P, bobo INT;
/*
	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en RegionGeograficaCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;
*/
	SELECT DibujableCrear() INTO Dibujable_P;
	SELECT RastreableCrear(a_Creador) INTO Rastreable_P;
	
	INSERT INTO RegionGeografica VALUES (
		Rastreable_P,
		Dibujable_P,
		NULL,
		a_Nombre,
		a_Poblacion,
		0, 0, NULL
	);

	SELECT LAST_INSERT_ID() INTO RegionGeografica_P;

	SELECT TiendasConsumidoresCrear(RegionGeografica_P, 0, 0) INTO bobo;
	RETURN RegionGeografica_P;
END$$

/*
*************************************************************
*				ContinenteCrear				*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `ContinenteCrear`;
DELIMITER $$

CREATE FUNCTION `ContinenteCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE C, RegionGeografica_P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en ContinenteCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 
*/
	/* Comprobamos que no haya otro continente en el mundo con el mismo nombre */
	SELECT COUNT(*) FROM Continente, RegionGeografica
	WHERE Nombre = a_Nombre AND RegionGeograficaID = Continente.RegionGeografica_P
	INTO C;

	IF C = 0 THEN
		SELECT RegionGeograficaCrear(a_Creador, a_Nombre, a_Poblacion) INTO RegionGeografica_P;
		INSERT INTO Continente VALUES(RegionGeografica_P, NULL);
		RETURN LAST_INSERT_ID();
	ELSE
		RETURN FALSE;
	END IF;
END$$

/*
*************************************************************
*			SubcontinenteCrear				*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `SubcontinenteCrear`;
DELIMITER $$

CREATE FUNCTION `SubcontinenteCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED, a_Continente INT)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE C, RegionGeografica_P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en SubcontinenteCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en SubcontinenteCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;
*/
	/* Comprobamos que no haya otro subcontinente en el continente con el mismo nombre */
	SELECT COUNT(*) FROM Subcontinente, RegionGeografica
	WHERE Nombre = a_Nombre AND Continente = a_Continente
	INTO C;

	IF C = 0 THEN
		SELECT RegionGeograficaCrear(a_Creador, a_Nombre, a_Poblacion) INTO RegionGeografica_P;
		INSERT INTO Subcontinente VALUES(RegionGeografica_P, NULL, a_Continente);
		RETURN LAST_INSERT_ID();
	ELSE
		RETURN FALSE;
	END IF;
END$$

/*
*************************************************************
*				PaisCrear					*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `PaisCrear`;
DELIMITER $$

CREATE FUNCTION `PaisCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED, a_Continente INT, a_Capital INT, 
					a_Idioma CHAR(10), a_MonedaLocal VARCHAR(45), a_MonedaLocal_Dolar DECIMAL(10,2),
					a_PIB DECIMAL(15,0))
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE C, RegionGeografica_P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en PaisCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en PaisCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;

	DECLARE EXIT HANDLER FOR 1062
	BEGIN
		SET @MensajeDeError = 'Error de valor duplicado en PaisCrear()';
		SET @CodigoDeError = 1062;
		RETURN -1062;
	END;
*/
	/* Comprobamos que no haya otro pais en el mundo con el mismo nombre */
	SELECT COUNT(*) FROM Pais, RegionGeografica
	WHERE Nombre = a_Nombre AND RegionGeograficaID = Pais.RegionGeografica_P
	INTO C;

	IF C = 0 THEN
		SELECT RegionGeograficaCrear(a_Creador, a_Nombre, a_Poblacion) INTO RegionGeografica_P;
	
		INSERT INTO Pais VALUES (
			RegionGeografica_P, 
			NULL,
			a_Continente,
			a_Capital,
			a_Idioma,
			a_MonedaLocal,
			a_MonedaLocal_Dolar,
			a_PIB
		);
		RETURN LAST_INSERT_ID();
	ELSE
		RETURN FALSE;
	END IF;
END$$

/*
*************************************************************
*			PaisSubcontinenteCrear				*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `PaisSubcontinenteCrear`;
DELIMITER $$

CREATE FUNCTION `PaisSubcontinenteCrear` (a_PaisID INT, a_SubcontinenteID INT)
RETURNS INT NOT DETERMINISTIC
BEGIN
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en PaisSubcontinenteCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en PaisSubcontinenteCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;

	DECLARE EXIT HANDLER FOR 1062
	BEGIN
		SET @MensajeDeError = 'Error de valor duplicado en PaisSubcontinenteCrear()';
		SET @CodigoDeError = 1062;
		RETURN -1062;
	END; 
*/
	INSERT INTO PaisSubcontinente VALUES (
		a_PaisID,
		a_SubcontinenteID
	);
	
	RETURN TRUE;
END$$

/*
*************************************************************
*				EstadoCrear					*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `EstadoCrear`;
DELIMITER $$

CREATE FUNCTION `EstadoCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED, a_Pais INT, a_HusoHorarioNormal TIME,
					a_HusoHorarioVerano TIME)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE C, RegionGeografica_P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en EstadoCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en EstadoCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;
*/
	/* Comprobamos que no haya otro estado hermano con el mismo nombre */
	SELECT COUNT(*) FROM Estado, RegionGeografica
	WHERE Nombre = a_Nombre AND Pais = a_Pais
	INTO C;

	IF C = 0 THEN
		SELECT RegionGeograficaCrear(a_Creador, a_Nombre, a_Poblacion) INTO RegionGeografica_P;
	
		INSERT INTO Estado VALUES (
			RegionGeografica_P, 
			NULL,
			a_Pais,
			a_HusoHorarioNormal,
			a_HusoHorarioVerano
		);
		RETURN LAST_INSERT_ID();
	ELSE
		RETURN FALSE;
	END IF;
END$$

/*
*************************************************************
*				CiudadCrear					*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `CiudadCrear`;
DELIMITER $$

CREATE FUNCTION `CiudadCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE RegionGeografica_P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en CiudadCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en CiudadCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;
*/
	SELECT RegionGeograficaCrear(a_Creador, a_Nombre, a_Poblacion) INTO RegionGeografica_P;

	INSERT INTO Ciudad VALUES (
		RegionGeografica_P, 
		NULL
	);
	RETURN LAST_INSERT_ID();
END$$

/*
*************************************************************
*				MunicipioCrear				*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `MunicipioCrear`;
DELIMITER $$

CREATE FUNCTION `MunicipioCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED, a_Estado INT, a_Ciudad INT)
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE C, RegionGeografica_P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en MunicipioCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en MunicipioCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;
*/
	/* Comprobamos que no haya otro municipio hermano con el mismo nombre */
	SELECT COUNT(*) FROM Municipio, RegionGeografica
	WHERE Nombre = a_Nombre AND Estado = a_Estado
	INTO C;

	IF C = 0 THEN
		SELECT RegionGeograficaCrear(a_Creador, a_Nombre, a_Poblacion) INTO RegionGeografica_P;

		INSERT INTO Municipio VALUES (
			RegionGeografica_P, 
			NULL,
			a_Estado,
			a_Ciudad
		);
		RETURN LAST_INSERT_ID();
	ELSE
		RETURN FALSE;
	END IF;
END$$

/*
*************************************************************
*				ParroquiaCrear				*
*************************************************************
*/

DELIMITER ;

DROP FUNCTION IF EXISTS `ParroquiaCrear`;
DELIMITER $$

CREATE FUNCTION `ParroquiaCrear` (a_Creador INT, a_Nombre VARCHAR(45), a_Poblacion INT UNSIGNED, a_Municipio INT, a_CodigoPostal CHAR(10))
RETURNS INT NOT DETERMINISTIC
BEGIN
	DECLARE C, RegionGeografica_P INT;
/*
	DECLARE EXIT HANDLER FOR 1452
	BEGIN
		SET @MensajeDeError = 'Error de clave externa en ParroquiaCrear()';
		SET @CodigoDeError = 1452;
		RETURN -1452;
	END; 

	DECLARE EXIT HANDLER FOR 1048
	BEGIN
		SET @MensajeDeError = 'Error de valor nulo en ParroquiaCrear()';
		SET @CodigoDeError = 1048;
		RETURN -1048;
	END;
*/
	/* Comprobamos que no haya otra parroquia hermana con el mismo nombre */
	SELECT COUNT(*) FROM Parroquia, RegionGeografica
	WHERE Nombre = a_Nombre AND Municipio = a_Municipio
	INTO C;

	IF C = 0 THEN
		SELECT RegionGeograficaCrear(a_Creador, a_Nombre, a_Poblacion) INTO RegionGeografica_P;

		INSERT INTO Parroquia VALUES (
			RegionGeografica_P, 
			NULL,
			a_CodigoPostal,
			a_Municipio
		);
		RETURN LAST_INSERT_ID();
	ELSE
		RETURN FALSE;
	END IF;	
END$$

/***********************************************************/
DELIMITER ;
/***********************************************************/