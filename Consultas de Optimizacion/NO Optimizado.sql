--Se desea obtener el nombre y apellido de los pacientes, junto con el valor de las 
--mediciones que realizaron, considerando únicamente aquellos registros cuyo valor 
--medido sea inferior a 70 y que correspondan a asignaciones de dispositivos iniciadas a partir del 1 de enero de 2025.

SELECT P.Nombre, P.Apellido, RM.Valor_Medido
FROM Paciente P
JOIN Asignacion_Dispositivo AD ON AD.Id_Paciente = P.Id_Paciente
JOIN Registro_Medicion RM ON RM.Id_Asignacion = AD.Id_Asignacion
WHERE RM.Valor_Medido < 70
AND AD.Fecha_inicio >= '2025-01-01'

