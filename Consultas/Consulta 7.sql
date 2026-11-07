--Obtener un listado de los pacientes que hayan registrado mediciones superiores a 80 durante el año 2025. 
--Para cada registro, mostrar el nombre y apellido del paciente, la marca y el modelo del dispositivo 
--utilizado, el tipo de medicion, el valor registrado y la fecha y hora en que se realizo. Los resultados 
--deberan presentarse ordenados de manera descendente segun el valor de la medicion.

SELECT p.Nombre, p.Apellido, d.Marca, d.Modelo, tm.Nombre_Medicion, rm.Fecha_Hora, rm.Valor_Medido
FROM Paciente p
JOIN (
	SELECT Id_Asignacion, Id_Dispositivo, Id_Paciente
	FROM Asignacion_Dispositivo 
) ad ON ad.Id_Paciente = p.Id_Paciente

JOIN (
	SELECT Id_Dispositivo, Marca, Modelo
	FROM Dispositivo
) d ON d.Id_Dispositivo = ad.Id_Dispositivo

JOIN (
	SELECT Id_Asignacion, Id_Tipo_Medicion, Fecha_Hora, Valor_Medido
	FROM Registro_Medicion
	WHERE Valor_Medido > 80
	AND Fecha_Hora >= '2025-01-01'
	AND Fecha_Hora < '2025-12-31'
) rm ON rm.Id_Asignacion = ad.Id_Asignacion

JOIN (
	SELECT Id_Tipo_Medicion, Nombre_Medicion
	FROM Tipo_Medicion
) tm ON tm.Id_Tipo_Medicion = rm.Id_Tipo_Medicion

ORDER BY Valor_Medido DESC



