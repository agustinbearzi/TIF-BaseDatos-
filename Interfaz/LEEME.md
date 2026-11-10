
## Preparación

1. Instalar los requerimentos con `python -m pip install -r requirements.txt`.
2. Pone la contraseña de tu postgre en `password` y el nombre que tenga asignado la base de datos en `dbname`, dentro del archivo `conexion.toml` (Si el user fuera otro tambien cambiarlo en `user`)
3. Ejecutá `python -m streamlit run app.py`.

## Funcionamiento

- Pacientes: búsqueda por nombre o apellido con ILIKE y parámetros.
- Mediciones: paciente, tipo y fechas; serie por dispositivo; umbrales del catálogo; contador de valores estrictamente fuera de los límites disponibles. Sin límites no se clasifica como normal. Un punto aislado no demuestra una tendencia.
- Alertas: filtros por fecha de alerta, gravedad y revisión. El médico mostrado es el asociado en alerta_clinica.
- Los intervalos incluyen el día final completo: inicio <= fecha < día siguiente al final.
- El resumen superior siempre corresponde a toda la base. Los indicadores interiores corresponden a la selección.
- Cada descarga CSV contiene los resultados visibles, con codificación UTF-8 con BOM.
- Los SELECT se ejecutan con parámetros y transacciones de solo lectura. Cada conexión se cierra al terminar. Los umbrales visuales no generan nuevas alertas.

