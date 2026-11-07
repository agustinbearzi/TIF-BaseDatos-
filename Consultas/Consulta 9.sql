--Obtener el nombre de cada tipo de medicion junto con el promedio de los valores registrados para ese tipo. 
--Mostrar unicamente aquellos tipos de medicion cuyo promedio sea superior a 50. Ordenar los resultados 
--de mayor a menor promedio.

SELECT tm.Id_Tipo_Medicion, tm.Nombre_Medicion, AVG(rm.Valor_Medido) AS Promedio
FROM Tipo_Medicion tm
JOIN Registro_Medicion rm ON tm.Id_Tipo_Medicion = rm.Id_Tipo_Medicion
GROUP BY tm.Id_Tipo_Medicion, tm.Nombre_Medicion
HAVING AVG(rm.Valor_Medido) > 50
ORDER BY Promedio DESC

