--Mostrar nombre y apellido de los pacientes, cuyo seguimiento haya finalizado 

SELECT Nombre, Apellido
FROM Paciente p
WHERE EXISTS (
	SELECT *
	FROM Seguimiento s
	WHERE s.Id_Paciente = p.Id_Paciente
	AND s.Fecha_Fin IS NOT NULL
);
