--Se desea obtener un listado de los medicos que hayan generado al menos una alerta clinica, pero 
--que no hayan realizado ningun registro clinico asociado.
--Para cada medico se debera mostrar su identificador, nombre, apellido y especialidad.

SELECT m.Id_Medico, m.Nombre, m.Apellido, m.Especialidad
FROM Medico m
JOIN Alerta_Clinica ac ON ac.Id_Medico = m.Id_Medico

EXCEPT

SELECT m.Id_Medico, m.Nombre, m.Apellido, m.Especialidad
FROM Medico m
JOIN Registro_Clinico rc ON rc.Id_Medico = m.id_Medico



