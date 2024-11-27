
USE Clinica_Turnos

GO
RAISERROR(N'ESTA PARTE DEL script no está pensado para que lo ejecutes "de una" con F5. Seleccioná y ejecutá de a poco.', 20, 1) WITH LOG;
GO
--LOTE PRUEBA

exec ImportacionArchivoCSV.ImportarMedico_00 '@INSERTALADIRDELARCHIVO','@INSERTALADIRDELARCHIVOERROR'
GO
exec ImportacionArchivoCSV.ImportarPrestador_01 '@INSERTALADIRDELARCHIVO','@INSERTALADIRDELARCHIVOERROR'
GO
exec ImportacionArchivoCSV.ImportarSede_02 '@INSERTALADIRDELARCHIVO','@INSERTALADIRDELARCHIVOERROR'
GO
exec  ImportacionArchivoCSV.ImportarPaciente_03 '@INSERTALADIRDELARCHIVO','@INSERTALADIRDELARCHIVOERROR'
GO
exec ImportacionArchivoJSON.ImportarEstudios_04 '@INSERTALADIRDELARCHIVO','@INSERTALADIRDELARCHIVOERROR'

/*
MIRAR RESULTADOS
select * from Medico_info.Medico
select * from Medico_info.Especialidad
SELECT * FROM Prestador_info.Prestador
SELECT * FROM Prestador_info.PrestadorCobertura
select * from Sede_info.SedeAtencion
select* from Paciente_info.Usuario
select* from Paciente_info.Paciente 
*/

/* INSERTAMOS VALORES A COBERTURA*/
INSERT INTO Paciente_info.Cobertura(idHistoriaClinica, idPrestadorCobertura) VALUES
(1,1),
(2,1),
(3,1),
(4,2),
(5,2),
(6,3),
(7,3),
(8,3),
(9,3),
(10,8),
(11,8),
(12,8),
(13,8),
(14,9),
(15,10),
(16,10),
(17,11),
(18,11)

/*
VER RESULTADO
select * from Paciente_info.Cobertura
*/

/* DAMOS DE ALTA TURNOS EN DIAS X SEDE*/
exec Sede_info.InsertarDiasxSede 119918, '10:00', '17:00', '2024-06-22', 1
exec Sede_info.InsertarDiasxSede 119919, '10:00', '14:00', '2024-06-22', 1
exec Sede_info.InsertarDiasxSede 119920, '17:00', '18:00', '2024-06-22', 1
exec Sede_info.InsertarDiasxSede 119921, '13:00', '19:00', '2024-06-22', 1
exec Sede_info.InsertarDiasxSede 119922, '09:00', '13:00', '2024-06-22', 1
exec Sede_info.InsertarDiasxSede 119918, '09:00', '13:00', '2024-07-22', 1
exec Sede_info.InsertarDiasxSede 119919, '09:00', '13:00', '2024-08-22', 1

/* RESERVAMOS ESOS TURNOS DADOS DE ALTA....*/

exec Turnos_info.InsertarReserva '2024-06-22', '10:00', 25111001, 119918, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '11:00', 25111001, 119919, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '17:00', 25111002, 119920, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '13:00', 25111002, 119921, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '09:00', 25111003, 119922, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '13:00', 25111003, 119918, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '13:30', 25111003, 119919, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '17:30', 25111004, 119920, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-06-22', '16:00', 25111004, 119921, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-07-22', '09:00', 25111001, 119918, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-08-22', '09:30', 25111002, 119919, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-07-22', '10:30', 25111004, 119918, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-08-22', '10:00', 25111004, 119919, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-07-22', '09:15', 25111010, 119918, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-08-22', '09:45', 25111011, 119919, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-07-22', '10:45', 25111012, 119918, 1, 'PRESENCIAL'
exec Turnos_info.InsertarReserva '2024-08-22', '10:15', 25111010, 119919, 1, 'PRESENCIAL'

/*
VER RESULTADO
select * from Sede_info.DiasxSede
select * from Turnos_info.ReservaTurno
*/


/*
MODIFICAMOS ALGUN TURNO PONIENDOLO EN ATENDIDO, ASI GENERAMOS EL XML
select * from Sede_info.DiasxSede
select * from Turnos_info.ReservaTurno
*/

exec Turnos_info.ModificarReserva 25111010, '2024-08-22', '10:15', 'ATENDIDO'
exec Turnos_info.ModificarReserva 25111012,'2024-07-22', '10:45', 'ATENDIDO'

/*GENERAMOS EL XML*/

EXEC GenerarXML.TurnosAtendidosEnRangoPorObraSocial_05 'OSDE', '2024-07-22', '2024-08-22'