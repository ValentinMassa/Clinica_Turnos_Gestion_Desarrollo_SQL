/*
BASES DE DATOS APLICADAS



Se proveen maestros de Médicos, Pacientes, Prestadores y Sedes en formato CSV. También se dispone
de un archivo JSON que contiene la parametrización del mecanismo de autorización según estudio y
obra social, además de porcentaje cubierto, etc. Ver archivo “Datasets para importar” en Miel.

*/


use Clinica_Turnos
go

---Importar Archivos CSV
if not exists(select 1 from sys.schemas where name = 'ImportacionArchivoCSV')
		exec ('create schema ImportacionArchivoCSV')
else
	print'schema ya creado'
GO

--importar JSON
if not exists(select 1 from sys.schemas where name = 'ImportacionArchivoJSON')
		exec ('create schema ImportacionArchivoJSON')
else
	print'schema ya creado'

go
--GENERAR XML
if not exists(select 1 from sys.schemas where name = 'GenerarXML')
		exec ('create schema GenerarXML')
else
	print'schema ya creado'

go

-----------------------------------
--IMPORTAR MEDICO
----------------------------------

CREATE OR ALTER procedure ImportacionArchivoCSV.ImportarMedico_00
@path varchar(500),
@pathErr varchar(500)
AS BEGIN
	BEGIN TRY
	BEGIN TRANSACTION

		declare @Dinamico nvarchar(max)
		declare @idEstado bit

		CREATE TABLE #TempMedico 
		(Nombre VARCHAR(30) not null, Apellido varchar(30) not null, especialidad varchar(100) not null, ID_Matricula int primary key not null)

		set @Dinamico = 'BULK INSERT #TempMedico 
		FROM'''+ @path +'''WITH
		(
		FIELDTERMINATOR = '';'', 
		ROWTERMINATOR = ''\n'', 
		CODEPAGE = ''65001'', 
		ERRORFILE = '''+@pathErr+'\ERRORES_MEDICO.csv'', 
		MAXERRORS = 20,
		FIRSTROW = 2,
		KEEPNULLS 
		)';

		-- Cuando se usa ErrorFile? No se puede insertar null en matricula, nombre, apellido, si hay, genera el archivo con esos datos
		exec sp_executesql @Dinamico;
		set @idEstado = 1

		insert into Medico_info.Especialidad(Nombre_Especialidad) 
			Select distinct especialidad from #TempMedico as b
			where not exists (select 1 from Medico_info.Especialidad as a where a.Nombre_Especialidad = b.especialidad )

		insert into Medico_info.Medico(Nombre_Medico, Apellido_Medico, idEspecialidad, Nro_Matricula, Estado)
			select 
			upper(rtrim(SUBSTRING(c.Nombre, CHARINDEX('.', c.Nombre) + 1, LEN(c.Nombre) - CHARINDEX('.', c.Nombre)))), 
			upper(c.Apellido), d.id_Especialidad, c.ID_Matricula, @idEstado
				from #TempMedico as c inner join Medico_info.Especialidad as d on Nombre_Especialidad = especialidad
					where not exists (select 1 from Medico_info.Medico as a where a.Nro_Matricula = c.ID_Matricula)
		drop table #TempMedico
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		raiserror('HUBO UN ERROR EN LA IMPORTACION DE LOS DATOS MEDICO', 17, 1)
		DECLARE @ERR_MENSAJE varchar(50) = ERROR_MESSAGE();
		DECLARE @ERR_STATE INT = ERROR_STATE();
		DECLARE @ERR_SERV INT = ERROR_SEVERITY();
		PRINT @ERR_MENSAJE
			ROLLBACK TRANSACTION
		exec Log_Info.InsertarAlLog 'ERROR', @ERR_MENSAJE, '', @ERR_SERV, @ERR_STATE
		
	END CATCH
	
END;

go
--EXEC ImportacionArchivoCSV.ImportarMedico_00 archivoUbi, ErrorFileUbi
-----------------------------------
--IMPORTAR PRESTADOR
----------------------------------

CREATE OR ALTER procedure ImportacionArchivoCSV.ImportarPrestador_01
@path varchar(500),
@pathErr varchar(500)
AS BEGIN
	BEGIN TRY
	BEGIN TRANSACTION 
		declare @Dinamico nvarchar(max)

	CREATE TABLE #TempPrestador 
		(prestador VARCHAR(20) not null, planPres varchar(40) not null)

		set @Dinamico = 'BULK INSERT #TempPrestador 
		FROM'''+ @path +'''WITH
		(
		FIELDTERMINATOR = '';'', 
		ROWTERMINATOR = ''\n'', 
		CODEPAGE = ''65001'', 
		ERRORFILE = '''+@pathErr+'\ERRORES_Prestador.csv'',
		MAXERRORS = 20,
		FIRSTROW = 2,
		KEEPNULLS
		-- Cuando se usa ErrorFile? No se puede insertar null en nombre Prestador o
		--Plan_Prestador
		)';
		exec sp_executesql @Dinamico;
	
		insert into Prestador_info.Prestador(Nombre)
			Select DISTINCT RTRIM(UPPER(b.prestador))
			from #TempPrestador as b
			where not exists (select 1 from Prestador_info.Prestador as a 
				where a.Nombre = RTRIM(UPPER(b.prestador))
				)
				-- prestador planpres id_prestador nombre estado

		insert into Prestador_info.PrestadorCobertura(Plan_Prestador, idPrestador)
			Select upper(rtrim(LEFT(planPres, LEN(planPres) - 2))), H.id_Prestador
			from #TempPrestador as b inner join Prestador_info.Prestador as H
				on RTRIM(UPPER(b.prestador)) = RTRIM(UPPER(H.Nombre))	
					where NOT EXISTS (SELECT 1 FROM Prestador_info.PrestadorCobertura as N 
					where N.Plan_Prestador=  UPPER(RTRIM(LEFT(planPres, LEN(planPres) - 2)))
						and N.idPrestador = H.id_Prestador)
			
		drop table #TempPrestador
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		raiserror('HUBO UN ERROR EN LA IMPORTACION DE LOS DATOS PRESTADOR', 17, 1)
		DECLARE @ERR_MENSAJE varchar(50) = ERROR_MESSAGE();
		DECLARE @ERR_STATE INT = ERROR_STATE();
		DECLARE @ERR_SERV INT = ERROR_SEVERITY();
		PRINT @ERR_MENSAJE
			ROLLBACK TRANSACTION
		exec Log_Info.InsertarAlLog 'ERROR', @ERR_MENSAJE, '', @ERR_SERV, @ERR_STATE
	END CATCH
END;

go

--exec ImportacionArchivoCSV.ImportarPrestador_01 @PAthArch, @PathErr

-----------------------------------
--IMPORTAR SEDE
----------------------------------
CREATE OR ALTER procedure ImportacionArchivoCSV.ImportarSede_02
@path varchar(500),
@pathErr varchar(500)
AS BEGIN
	BEGIN TRY
	BEGIN TRANSACTION

		declare @Dinamico nvarchar(max)

		CREATE TABLE #TempSede 
			(Sede VARCHAR(20) not null, Direcccion varchar(40) not null, Localidad varchar(20) not null, provincia varchar(20) not null)
	
			set @Dinamico = 'BULK INSERT #TempSede 
			FROM'''+ @path +'''WITH
			(
			FIELDTERMINATOR = '';'', 
			ROWTERMINATOR = ''\n'', 
			CODEPAGE = ''65001'', 
			ERRORFILE = '''+@pathErr+'\ERRORES_Sede.csv'',
			MAXERRORS = 20,
			FIRSTROW = 2,
			KEEPNULLS
			)';
			-- Cuando se usa ErrorFile? cuando llegue algun dato que es null....
			exec sp_executesql @Dinamico;

			insert into Sede_info.SedeAtencion(Nombre_Sede, Direccion_Sede)
				select RTRIM(UPPER(a.Sede)), (CONCAT(Direcccion,' ',Localidad, ' ', provincia)) 
					from #TempSede as a where not exists(select 1 from Sede_info.SedeAtencion b 
						where RTRIM(UPPER(a.Sede)) = RTRIM(UPPER(b.Nombre_Sede)) )
			drop table #TempSede
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		raiserror('HUBO UN ERROR EN LA IMPORTACION DE LOS DATOS SEDE', 17, 1)
		DECLARE @ERR_MENSAJE varchar(50) = ERROR_MESSAGE();
		DECLARE @ERR_STATE INT = ERROR_STATE();
		DECLARE @ERR_SERV INT = ERROR_SEVERITY();
		PRINT @ERR_MENSAJE
			ROLLBACK TRANSACTION
		exec Log_Info.InsertarAlLog 'ERROR', @ERR_MENSAJE, '', @ERR_SERV, @ERR_STATE
	END CATCH
END;

go

-----------------------------------
--IMPORTAR Pacientes
----------------------------------
CREATE OR ALTER procedure ImportacionArchivoCSV.ImportarPaciente_03
@path varchar(500),
@pathErr varchar(500)
AS BEGIN
	BEGIN TRY
	BEGIN TRANSACTION

	declare @Dinamico nvarchar(max)

	CREATE TABLE #TempPaciente
		(Nombre VARCHAR(30) not null, Apellido varchar(30) not null,FecNac varchar(12) not null, tipDoc varchar(20) not null, 
			NroDoc int not null, Sexo_Bio char(10) not null, Genero varchar(20), Telefono_Cel varchar(20) not null, 
				Nacionalidad varchar(30) not null, mail varchar(50) not null, 
					calleynro varchar(100), localidad varchar(50), provincia varchar(25))
	
		set @Dinamico = 'BULK INSERT #TempPaciente 
		FROM'''+ @path +'''WITH
		(
		FIELDTERMINATOR = '';'', 
		ROWTERMINATOR = ''\n'', 
		CODEPAGE = ''65001'', 
		ERRORFILE = '''+@pathErr+'\ERRORES_Paciente.csv'',
		MAXERRORS = 20,
		FIRSTROW = 2,
		KEEPNULLS
		)';
		exec sp_executesql @Dinamico;

		IF EXISTS (SELECT 1 FROM #TempPaciente as a WHERE NOT (UPPER(RTRIM(a.Sexo_Bio)) like 'M%' OR UPPER(RTRIM(a.Sexo_Bio)) LIKE 'F%'))
			BEGIN
				SELECT * FROM #TempPaciente AS a WHERE NOT(UPPER(RTRIM(a.Sexo_Bio)) like 'M%' OR UPPER(RTRIM(a.Sexo_Bio)) LIKE 'F%')
					FOR XML RAW('ERROR_EN_ESTUDIOS'), ROOT ('XML');
				DELETE FROM #TempPaciente WHERE NOT (UPPER(RTRIM(Sexo_Bio)) like 'M%' OR UPPER(RTRIM(Sexo_Bio))  LIKE 'F%')
			END;
			--sacamos regitros que haya errores

			insert into Paciente_info.Paciente(Nombre,Apellido,FecNac, Tipo_Documento, DNI,
				Sexo_Biologico, Genero,	Telefono_Celular, Mail, Nacionalidad)
			select RTRIM(UPPER(a.Nombre)),
			RTRIM(UPPER(a.Apellido)),
				FORMAT(CONVERT(DATE, a.FecNac, 103), 'yyyy-M-d'), 
				RTRIM(UPPER(a.tipDoc)), 
				a.NroDoc,
				upper(left(rtrim(a.Sexo_Bio), 1)), 
				a.Genero, 
				a.Telefono_Cel, 
				a.mail, 
				upper(rtrim(a.Nacionalidad)) 
				from #TempPaciente a where 
					not exists(select 1 from Paciente_info.Paciente b where b.DNI = a.NroDoc)
		
			insert into Paciente_info.Domicilio(provincia, localidad, calleYnro, idHistoriaClinica)
				select 
				f.provincia, 
				f.localidad, 
				f.calleynro, 
				c.id_Historia_Clinica 
					from #TempPaciente as f
					inner join Paciente_info.Paciente as c on f.NroDoc =  c.DNI
						where not exists (select 1 from Paciente_info.Domicilio as pa 
							where pa.idHistoriaClinica = c.id_Historia_Clinica )


			insert into Paciente_info.Usuario(IdUsuario,contrasenia, fechaCreacion)
				select fa.NroDoc, fa.NroDoc, cast(getdate() as date) from #TempPaciente as fa
					where not exists(select 1 from Paciente_info.Usuario as ne 
						where ne.IdUsuario = fa.NroDoc)

		drop table #TempPaciente 
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		raiserror('HUBO UN ERROR EN LA IMPORTACION DE LOS DATOS Paciente', 17, 1)
		DECLARE @ERR_MENSAJE varchar(50) = ERROR_MESSAGE();
		DECLARE @ERR_STATE INT = ERROR_STATE();
		DECLARE @ERR_SERV INT = ERROR_SEVERITY();
		PRINT @ERR_MENSAJE
			ROLLBACK TRANSACTION
		exec Log_Info.InsertarAlLog 'ERROR', @ERR_MENSAJE, '', @ERR_SERV, @ERR_STATE
	END CATCH
END;

GO
----------------------------------
--ESTUDIOS IMPORTAR
----------------------------------

------------------
--FUNCION CORRECION COLLATE
-----------------
CREATE or alter FUNCTION ImportacionArchivoJSON.ConvertirDeANSIaUTF8_MAYUS(@palabra varchar(100))
returns varchar(100)
as begin
	set @palabra = REPLACE(@palabra, 'Ã¡', 'á')
	set @palabra = REPLACE(@palabra, 'Ã©', 'é')
	set @palabra = REPLACE(@palabra, 'Ã­', 'í')
	set @palabra = REPLACE(@palabra, 'Ã³', 'ó')
	set @palabra = REPLACE(@palabra, 'Ãº', 'ú')
	set @palabra = REPLACE(@palabra, 'Ã', 'Á')
	set @palabra = REPLACE(@palabra, 'Ã‰', 'É')
	set @palabra = REPLACE(@palabra, 'Ã', 'Í')
	set @palabra = REPLACE(@palabra, 'Ã“', 'Ó')
	set @palabra = REPLACE(@palabra, 'Ãš', 'Ú')
	set @palabra = REPLACE(@palabra,'Ã±', 'ñ')
	set @palabra = REPLACE(@palabra, 'Ã‘', 'Ñ')
	
	return UPPER(@palabra)
END;


go 

CREATE OR ALTER procedure ImportacionArchivoJSON.ImportarEstudios_04
@path varchar(500),
@pathErr varchar(500)
AS BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		declare @Dinamico nvarchar(max)	

		CREATE TABLE #TempJson 
			(area VARCHAR(40), estudio varchar(100),PRESTADOR VARCHAR(40), 
				plan_Pres varchar(40), porcentaje int , costo int , estado BIT )
		CREATE TABLE #TempJsonUTF8
			(area VARCHAR(40), estudio varchar(100), plan_Pres varchar(40), 
				porcentaje int, costo int, estado BIT)
	--creamos dos tablas, una donde guardamos la importacion, otra donde guardamos el archivo con collate utf8
		
		set @Dinamico = 
			'INSERT INTO #TempJson(area, estudio,PRESTADOR, plan_Pres, porcentaje, costo, estado) SELECT 
			B.AREA, B.ESTUDIO, B.PRESTADOR, B.PLAN_PRESTADOR, B.PORCENTAJE, B.COSTO, B.ESTADO 
			FROM OPENROWSET 
				(BULK'''+@path+''',CODEPAGE = 65001,
					ERRORFILE = '''+@pathErr+'\ERRORES_ESTUDIO.csv'',
						MAXERRORS = 20, SINGLE_CLOB) AS DATA
			CROSS APPLY OPENJSON(DATA.BulkColumn)
			WITH (
			AREA VARCHAR(40) ''$.Area'',
			ESTUDIO VARCHAR(100) ''$.Estudio'',
			PRESTADOR VARCHAR(40) ''$.Prestador'',
			PLAN_PRESTADOR VARCHAR(40) ''$.Plan'',
			PORCENTAJE INT ''$."Porcentaje Cobertura"'',
			COSTO INT ''$.Costo'',
			ESTADO BIT ''$."Requiere autorizacion"''
			)AS B';
	
		exec sp_executesql @Dinamico

		IF EXISTS (SELECT 1 FROM #TempJson AS A WHERE 
						A.area IS NULL OR
						A.costo IS NULL OR 
						A.estado IS NULL OR
						A.estudio IS NULL OR
						A.plan_Pres IS NULL OR
						A.porcentaje IS NULL OR
						A.PRESTADOR IS NULL)
			BEGIN
				SELECT * FROM #TempJson AS A WHERE 
						A.area IS NULL OR
						A.costo IS NULL OR 
						A.estado IS NULL OR
						A.estudio IS NULL OR
						A.plan_Pres IS NULL OR
						A.porcentaje IS NULL OR
						A.PRESTADOR IS NULL
						FOR XML RAW('ERROR_EN_ESTUDIOS_NULL'), ROOT ('XML')
				DELETE FROM #TempJson WHERE 
						area IS NULL OR
						costo IS NULL OR 
						estado IS NULL OR
						estudio IS NULL OR
						plan_Pres IS NULL OR
						porcentaje IS NULL OR
						PRESTADOR IS NULL
			END;


		--corregimos acentos e insertamos a nueva tabla
		INSERT INTO #TempJsonUTF8(area, estudio, plan_Pres, porcentaje, costo, estado) 
			select 
			RTRIM(ImportacionArchivoJSON.ConvertirDeANSIaUTF8_MAYUS(B.area)),
			RTRIM(ImportacionArchivoJSON.ConvertirDeANSIaUTF8_MAYUS(B.estudio)),
			RTRIM(ImportacionArchivoJSON.ConvertirDeANSIaUTF8_MAYUS(B.plan_Pres)),
			B.porcentaje,
			B.costo,
			B.estado
			from #TempJson as B

		drop table #TempJson

		--verificamos que todos los registros del archivo a insertar tengan relacion con un plan prestador existente

		IF EXISTS(SELECT 1 FROM #TempJsonUTF8 as b LEFT JOIN Prestador_info.PrestadorCobertura as a 
				on a.Plan_Prestador = b.plan_Pres WHERE a.Plan_Prestador IS NULL)
				-- 'HAY UN PRESTADOR/SERVICIO DE PRESTADOR NO REGISTRADO'
		BEGIN
			with FilasQueSonError as
			(
				SELECT 
					b.estudio as F_estudio, 
					b.area as F_area, 
					b.costo as F_costo, 
					b.estado as F_Estado, 
					b.porcentaje as F_procentaje, 
					b.plan_Pres as F_Plan_Pres 
					FROM #TempJsonUTF8 as b LEFT JOIN Prestador_info.PrestadorCobertura as a 
					on a.Plan_Prestador = b.plan_Pres WHERE a.Plan_Prestador IS NULL
			)
			select * from FilasQueSonError
				FOR XML RAW('ERROR_EN_ESTUDIOS'), ROOT ('XML');

			--GENERAMOS XML CON LOS REGISTROS QUE FALTA REGISTRAR

			with FilasQueSonError as
			(
				SELECT 
					b.estudio as F_estudio, 
					b.area as F_area, 
					b.costo as F_costo, 
					b.estado as F_Estado, 
					b.porcentaje as F_procentaje, 
					b.plan_Pres as F_Plan_Pres 
					FROM #TempJsonUTF8 as b LEFT JOIN Prestador_info.PrestadorCobertura as a 
					on a.Plan_Prestador = b.plan_Pres WHERE a.Plan_Prestador IS NULL
			)
			DELETE FROM #TempJsonUTF8 where exists
				(Select 1 from FilasQueSonError as f where
					f.F_area =	#TempJsonUTF8.area and
					f.F_costo = #TempJsonUTF8.costo and
					f.F_Estado = #TempJsonUTF8.estado and
					f.F_estudio = #TempJsonUTF8.estudio and
					f.F_Plan_Pres = #TempJsonUTF8.plan_Pres and
					f.F_procentaje = #TempJsonUTF8.porcentaje
					);
			--LOS ELIMINAMOS DE LA TABLA A INSERTAREN LA BASE DE DATOS
	
			END;

		--cte para ayuda visual, insertamos los datos en la tabla estudio y checkeamos repetidos
		with COBERTURAS as
		(
			select Plan_Prestador, id_PrestadorCobertura from Prestador_info.PrestadorCobertura
		)
		INSERT INTO Estudio_info.Estudio(Fecha, Area, Nombre_Estudio, 
			Autorizado, Porcentaje_Cobertura, costo, idPrestadorCobertura)
		select 
			cast(getdate() as date),
			N.area,
			N.estudio,
			estado,
			porcentaje,
			costo,
			(SELECT H.id_PrestadorCobertura from COBERTURAS as H where H.Plan_Prestador = N.plan_Pres)
			FROM #TempJsonUTF8 as N
			Where not exists(select 1 from Estudio_info.Estudio AS F
				where 
					F.Nombre_Estudio = N.estudio AND
					F.Area = N.area AND
					F.Autorizado = N.estado AND
					F.Porcentaje_Cobertura = N.porcentaje AND
					F.costo = N.costo AND
					F.idPrestadorCobertura = (SELECT a.id_PrestadorCobertura from COBERTURAS as a where a.Plan_Prestador = N.plan_Pres) AND
					F.Fecha = CAST(GETDATE() AS DATE)
				)

		DROP TABLE #TempJsonUTF8 
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		raiserror('HUBO UN ERROR EN LA IMPORTACION DE LOS DATOS ESTUDIO', 17, 1)
		DECLARE @ERR_MENSAJE varchar(50) = ERROR_MESSAGE();
		DECLARE @ERR_STATE INT = ERROR_STATE();
		DECLARE @ERR_SERV INT = ERROR_SEVERITY();
		PRINT @ERR_MENSAJE
			ROLLBACK TRANSACTION
		exec Log_Info.InsertarAlLog 'ERROR', @ERR_MENSAJE, '', @ERR_SERV, @ERR_STATE
	END CATCH
END;

GO

-----------------
--GENERAR XML
-----------------

CREATE OR ALTER PROCEDURE GenerarXML.TurnosAtendidosEnRangoPorObraSocial_05
	@OBRASOCIAL VARCHAR(20),
	@FECHA_DESDE DATE,
	@FECHA_HASTA DATE
AS BEGIN
	
	with PACIENTESCONDOBRASOC as
	(
		select
			N.id_Historia_Clinica AS PAC_HISTCLINIC, 
			N.Apellido PAC_APELL,
			N.Nombre AS PAC_NOMBRE,
			N.DNI AS PAC_DNI,
			L.id_Prestador AS PAC_ID_PREST,
			L.Nombre AS PAC_NOMBRE_PREST
				from Paciente_info.Paciente AS N 
					INNER JOIN Paciente_info.Cobertura  AS H ON N.id_Historia_Clinica = H.idHistoriaClinica
					INNER JOIN Prestador_info.PrestadorCobertura AS K ON H.idPrestadorCobertura = K.id_PrestadorCobertura
					INNER JOIN Prestador_info.Prestador AS L ON K.idPrestador = L.id_Prestador
	),
	MEDICOS as
		(
			SELECT 
					B.id_Medico AS ID_MEDICO,
					B.Nro_Matricula AS MATRICULA, 
					B.Nombre_Medico AS NOMBRE_MEDICO,
					T.id_Especialidad AS ID_ESP_MEDIC,
					T.Nombre_Especialidad AS NOMBRE_ESP_MEDIC
			FROM Medico_info.Medico AS B
					INNER JOIN Medico_info.Especialidad AS T ON B.idEspecialidad = T.id_Especialidad 
		),
		TURNOSCONESTADO AS
			(
				SELECT 
					J.id_Turno AS TURNO_ID,
					J.IdHistoriaClinica AS TURNO_ID_HISTCLINIC, 
					J.idEstado_Turno AS TURNO_ESTADO_ID, 
					J.Fecha_Turno AS FECHA_TURNO, 
					J.Hora_Turno_Inicio  AS TURNO_HORA_INICIO,
					J.idMedico AS TURNO_ID_MEDICO,
					J.idEspecialidad AS TURNO_ID_ESPECIALIDAD
				FROM Turnos_info.ReservaTurno AS J
					WHERE J.idEstado_Turno = (SELECT N.id_EstadoTurno FROM Turnos_info.EstadoTurno AS N
													WHERE N.nombreEstado = 'ATENDIDO')
			)
			SELECT
				U.PAC_APELL, 
				U.PAC_NOMBRE, 
				U.PAC_DNI, 
				U.PAC_NOMBRE_PREST,
				Y.NOMBRE_MEDICO,
				Y.MATRICULA, 
				Y.NOMBRE_ESP_MEDIC,
				T.FECHA_TURNO,
				T.TURNO_HORA_INICIO
					FROM TURNOSCONESTADO AS T
						INNER JOIN MEDICOS AS Y ON T.TURNO_ID_MEDICO = Y.ID_MEDICO
						INNER JOIN PACIENTESCONDOBRASOC U ON T.TURNO_ID_HISTCLINIC = U.PAC_HISTCLINIC
					WHERE 
						U.PAC_NOMBRE_PREST = @OBRASOCIAL AND
						DATEDIFF(DAY, @FECHA_DESDE, @FECHA_HASTA) >= 0
					FOR XML RAW('REGISTRO'), ROOT ('XML')
END;


