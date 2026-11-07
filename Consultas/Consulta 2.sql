--Mostrar la FECHA DE INICIO, junto al DNI de los pacientes y el ESTADO de 
--los dispositivos cuya asignación inicio en febrero. 

SELECT a.Fecha_Inicio, p.Dni, d.Estado
FROM Asignacion_Dispositivo a
JOIN Paciente p ON a.Id_Paciente = p.Id_Paciente
JOIN Dispositivo d ON a.Id_Dispositivo = d.Id_Dispositivo
WHERE EXTRACT(MONTH FROM a.Fecha_inicio) = 02;
