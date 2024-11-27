

use Clinica_Turnos
-----------------------------------
--SETEAMOS roles, usuarios y logins
-----------------------------------
/*
• Paciente
	exec Paciente_info.ActualizarUsuario

• Medico
	exec Sede_info.InsertarDiasxSede
	exec Sede_info.VerificarFechaDelDia

• Personal Administrativo
	exec Paciente_info.ActualizarPaciente
	exec Paciente_info.DarAltaPAciente
	exec Paciente_info.DarBajaPaciente
	exec Paciente_info.EliminarCobertura
	exec Paciente_info.InsertarCobertura
	exec Paciente_info.InsertarDomicilio
	exec Paciente_info.ModificarDomicilio
	exec Turnos_info.InsertarReserva
	exec Turnos_info.ModificarReserva

• Personal Técnico clínico
	exec Estudio_info.AgregarEstudio

• Administrador General
	exec Prestador_info.AltaCoberturaPrestador
	exec Prestador_info.AltaPrestador
	exec Prestador_info.EliminarPrestador
	exec Medico_info.ActualizarMedico
	exec Medico_info.EliminarMedico
	exec Medico_info.InsertarEspecialidad
	exec Medico_info.InsertarMedico
	exec Sede_info.InsertarSede
*/

--Rol y permisos a Paciente
create role Paciente
go
grant execute on object ::Paciente_info.ActualizarUsuario to Paciente
go

--Rol y permisos a Medico
create role Medico
go
grant execute on object ::Sede_info.InsertarDiasxSede to Medico
go
grant execute on object ::Sede_info.VerificarFechaDelDia to Medico
go

--Rol y permisos a Personal Administrativo
create role Personal_Administrativo
go
grant execute on object ::Paciente_info.ActualizarPaciente to Personal_Administrativo
go
grant execute on object ::Paciente_info.DarAltaPAciente to Personal_Administrativo
go
grant execute on object ::Paciente_info.DarBajaPaciente to Personal_Administrativo
go
grant execute on object ::Paciente_info.EliminarCobertura to Personal_Administrativo
go
grant execute on object ::Paciente_info.InsertarCobertura to Personal_Administrativo
go
grant execute on object ::Paciente_info.InsertarDomicilio to Personal_Administrativo
go
grant execute on object ::Paciente_info.ModificarDomicilio to Personal_Administrativo
go
grant execute on object ::Turnos_info.InsertarReserva to Personal_Administrativo
go
grant execute on object ::Turnos_info.ModificarReserva to Personal_Administrativo
go

--Rol y permisos a Personal Tecnico Clinico
create role Personal_Tecnico_clínico
go
grant execute on object ::Estudio_info.AgregarEstudio to Personal_Tecnico_clínico
go

--Rol y permisos a Administrador General
create role Administrador_General
go
grant execute on object ::Prestador_info.AltaPrestador to Administrador_General
go
grant execute on object ::Prestador_info.AltaCoberturaPrestador to Administrador_General
go
grant execute on object ::Prestador_info.EliminarPrestador to Administrador_General
go
grant execute on object ::Medico_info.ActualizarMedico to Administrador_General
go
grant execute on object ::Medico_info.EliminarMedico to Administrador_General
go
grant execute on object ::Medico_info.InsertarEspecialidad to Administrador_General
go
grant execute on object ::Medico_info.InsertarMedico to Administrador_General
go
grant execute on object ::Sede_info.InsertarSede to Administrador_General
go


--- Creamos el login basico que podria hacer un paciente desde una app.

create login Api_Conexion_Bd with password = 'Usuario1234',
	CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;
GO
CREATE USER Api_Conexion_Bd_U FOR LOGIN Api_Conexion_Bd
GO
-- LE ASGINAMOS UN ROL AL USUARIO
ALTER ROLE Paciente ADD MEMBER Api_Conexion_Bd_U

---
/*
Para los demas roles, la idea es usar un grupo de windows, ya que segun el hospital informo, se trabajara 
con las computadoras que se tienen en las instalaciones  --> mas facil la organizacion ya que windows verifica las credenciales.

Solo el usuario tendra una conexion al servidor por medio de un login por la API DE LA APLICACION
*/

CREATE LOGIN [CURESA\MEDICOS] FROM WINDOWS
GO
CREATE USER MEDICO FOR LOGIN [CURESA\MEDICOS];
GO
ALTER ROLE Medico ADD MEMBER MEDICO
GO

CREATE LOGIN [CURESA\PER_TECNICO] FROM WINDOWS
GO
CREATE USER PER_TECNICO FOR LOGIN [CURESA\PER_TECNICO];
GO
ALTER ROLE Personal_Tecnico_clínico ADD MEMBER PER_TECNICO
GO

CREATE LOGIN [CURESA\ADM_GRAL] FROM WINDOWS;
GO
CREATE USER ADM_GRAL FOR LOGIN [CURESA\ADM_GRAL];
GO
ALTER ROLE Administrador_General ADD MEMBER ADM_GRAL
GO

CREATE LOGIN [CURESA\PER_ADMIN] FROM WINDOWS
GO
CREATE USER PER_ADM FOR LOGIN [CURESA\PER_ADMIN];
GO
ALTER ROLE Personal_Administrativo ADD MEMBER PER_ADM


/*
vamos a crear un rol para alguien que de soporte a la base de datos(que no es el dba)
*/

CREATE login Usuario_Soporte with password = 'UsuarioSoporte1234', 
	DEFAULT_DATABASE = ENTREGA_INTEGRADOR_GRUPO_6,
	CHECK_POLICY = ON, 
	CHECK_EXPIRATION = OFF;
GO
CREATE USER UsuarioSoporte FOR LOGIN Usuario_Soporte
GO
-- LE ASGINAMOS UN ROL AL ADMIN
GRANT CONTROL ON DATABASE::ENTREGA_INTEGRADOR_GRUPO_6 TO UsuarioSoporte
