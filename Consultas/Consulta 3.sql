--Mostrar los diagnosticos realizados por los medicos especializados en neurologia

SELECT r.Diagnostico
FROM Registro_Clinico r
WHERE r.Id_Medico IN (
	SELECT m.Id_Medico
	FROM Medico m
	WHERE m.Especialidad = 'Neurología'
);
