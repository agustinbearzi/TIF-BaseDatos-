--Se desea obtener el nombre y apellido de los pacientes, junto con el valor de las 
--mediciones que realizaron, considerando únicamente aquellos registros cuyo valor 
--medido sea inferior a 70 y que correspondan a asignaciones de dispositivos iniciadas a partir del 1 de enero de 2025.

SELECT P.Nombre, P.Apellido, RM.Valor_Medido
FROM Paciente P
JOIN (
	SELECT Id_Asignacion, Id_Paciente
	FROM Asignacion_Dispositivo
	WHERE Fecha_Inicio >= '2025-01-01'
) A ON A.Id_Paciente = P.Id_Paciente
JOIN (
	SELECT Id_Asignacion, Valor_Medido
	FROM Registro_Medicion
	WHERE Valor_Medido < 70
) RM ON RM.Id_Asignacion = A.Id_Asignacion

