--Mostrar cuantas alertas fueron registradas dentro del mes de marzo 
--con un nivel de gravedad "grave" y moderado fueron revisadas

SELECT COUNT(a.Nivel_Gravedad) AS Alertas_Revisadas
FROM Alerta_Clinica a
WHERE a.Revisada = TRUE
AND a.Nivel_Gravedad IN ('moderada', 'grave')
AND EXISTS (
	SELECT 1
	FROM Registro_Medicion r
	WHERE r.Id_Registro_Medicion = a.Id_Registro_Medicion
	AND EXTRACT(MONTH FROM r.Fecha_Hora) = 04
);
