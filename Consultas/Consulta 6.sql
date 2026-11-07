--Mostrar el nombre, apellido y especialidad de los medicos que actualmente estan realizando un seguimiento activo
--(sin fecha de fin) a pacientes que poseen alertas clinicas generadas que aun no han sido revisadas por ningun profesional.

SELECT DISTINCT m.Nombre, m.Apellido, m.Especialidad
FROM Medico m
JOIN Seguimiento s ON m.Id_Medico = s.Id_Medico
WHERE s.fecha_fin IS NULL
AND s.Id_Paciente IN (
	SELECT ad.Id_Paciente
	FROM Asignacion_Dispositivo ad
	JOIN Registro_Medicion rm ON ad.Id_Asignacion = rm.Id_Asignacion
	JOIN Alerta_Clinica ac ON rm.Id_Registro_Medicion = ac.Id_Registro_Medicion
	WHERE ac.Revisada = FALSE
);

