--Mostrar el nombre y la unidad de medida de aquellos Tipos de Medicion (del catalogo)
--que nunca hayan generado una Alerta Clínica con un nivel de gravedad "grave"

SELECT tm.Nombre_Medicion, tm.Unidad_Medida
FROM Tipo_Medicion tm
WHERE NOT EXISTS (
	SELECT 1
	FROM Registro_Medicion rm
	JOIN Alerta_Clinica ac ON ac.Id_Registro_Medicion = rm.Id_Registro_Medicion
	WHERE rm.Id_Tipo_Medicion = tm.Id_Tipo_Medicion
	AND ac.Nivel_Gravedad = 'grave'
);
