"""Interfaz del TIF. Ejecutar con: python -m streamlit run app.py"""
from pathlib import Path
from datetime import timedelta
import tomllib
import pandas as pd
import psycopg
import streamlit as st
import altair as alt

st.set_page_config(page_title="TIF | Seguimiento de pacientes", page_icon="📊", layout="wide")


def consultar(sql, parametros=()):
    """Ejecuta SELECT parametrizados y libera la conexión al terminar."""
    with psycopg.connect(**configuracion, connect_timeout=5) as conexion:
        conexion.read_only = True
        with conexion.cursor() as cursor:
            cursor.execute(sql, parametros)
            return pd.DataFrame(cursor.fetchall(), columns=[c.name for c in cursor.description])


def tabla_y_csv(datos, nombre):
    st.dataframe(datos, hide_index=True)
    st.download_button("Descargar resultados en CSV", datos.to_csv(index=False).encode("utf-8-sig"),
                       file_name=f"{nombre}.csv", mime="text/csv", key=f"csv_{nombre}")


def fechas(minima, maxima, clave):
    columnas = st.columns(2)
    inicio = columnas[0].date_input("Desde", value=minima, key=f"desde_{clave}")
    fin = columnas[1].date_input("Hasta (inclusive)", value=maxima, key=f"hasta_{clave}")
    if inicio > fin:
        st.warning("La fecha inicial debe ser anterior o igual a la final.")
        return None
    # El límite exclusivo del día siguiente incluye todas las horas del último día.
    return inicio, fin + timedelta(days=1)


def pacientes():
    st.subheader("Directorio de pacientes")
    texto = st.text_input("Buscar por nombre o apellido", placeholder="Escribí un nombre")
    patron = f"%{texto.strip()}%"
    datos = consultar("""SELECT id_paciente AS "ID", nombre AS "Nombre", apellido AS "Apellido",
                        fecha_nacimiento AS "Fecha de nacimiento" FROM paciente
                        WHERE nombre ILIKE %s OR apellido ILIKE %s ORDER BY apellido, nombre""",
                      (patron, patron))
    st.caption(f"{len(datos)} pacientes encontrados")
    if datos.empty:
        st.info("No hay coincidencias con esta búsqueda.")
    else:
        tabla_y_csv(datos, "pacientes")


def mediciones():
    st.subheader("Evolución de las mediciones")
    opciones = consultar("""SELECT DISTINCT p.id_paciente, p.apellido, p.nombre FROM paciente p
        JOIN asignacion_dispositivo ad ON ad.id_paciente=p.id_paciente
        JOIN registro_medicion rm ON rm.id_asignacion=ad.id_asignacion ORDER BY p.apellido,p.nombre""")
    if opciones.empty:
        st.info("No hay mediciones registradas.")
        return
    etiquetas = {r.id_paciente: f"{r.apellido}, {r.nombre} (ID {r.id_paciente})" for r in opciones.itertuples()}
    paciente = st.selectbox("Paciente", list(etiquetas), format_func=etiquetas.get)
    tipos = consultar("""SELECT DISTINCT tm.* FROM tipo_medicion tm
        JOIN registro_medicion rm ON rm.id_tipo_medicion=tm.id_tipo_medicion
        JOIN asignacion_dispositivo ad ON ad.id_asignacion=rm.id_asignacion
        WHERE ad.id_paciente=%s ORDER BY tm.nombre_medicion""", (paciente,))
    if tipos.empty:
        st.info("No hay tipos de medición disponibles.")
        return
    nombres = dict(zip(tipos.id_tipo_medicion, tipos.nombre_medicion))
    tipo = st.selectbox("Tipo de medición", list(nombres), format_func=nombres.get, key=f"tipo_{paciente}")
    detalle = tipos.loc[tipos.id_tipo_medicion == tipo].iloc[0]
    limites = consultar("""SELECT MIN(rm.fecha_hora)::date AS inicio, MAX(rm.fecha_hora)::date AS fin
        FROM registro_medicion rm JOIN asignacion_dispositivo ad ON ad.id_asignacion=rm.id_asignacion
        WHERE ad.id_paciente=%s AND rm.id_tipo_medicion=%s""", (paciente, tipo)).iloc[0]
    if limites.inicio is None:
        st.info("No hay registros disponibles.")
        return
    periodo = fechas(limites.inicio, limites.fin, f"med_{paciente}_{tipo}")
    if periodo is None:
        return
    datos = consultar("""SELECT rm.fecha_hora AS fecha, rm.valor_medido AS valor,
        d.numero_serie AS dispositivo FROM registro_medicion rm
        JOIN asignacion_dispositivo ad ON ad.id_asignacion=rm.id_asignacion
        JOIN dispositivo d ON d.id_dispositivo=ad.id_dispositivo
        WHERE ad.id_paciente=%s AND rm.id_tipo_medicion=%s
          AND rm.fecha_hora >= %s AND rm.fecha_hora < %s
        ORDER BY rm.fecha_hora,rm.id_registro_medicion""", (paciente, tipo, *periodo))
    if datos.empty:
        st.info("No hay mediciones dentro del período seleccionado.")
        return
    datos["valor"] = pd.to_numeric(datos.valor)
    datos["fecha"] = pd.to_datetime(datos.fecha)
    fuera = pd.Series(False, index=datos.index)
    umbrales = []
    for campo, etiqueta in [("umbral_minimo", "Mínimo"), ("umbral_maximo", "Máximo")]:
        valor = detalle[campo]
        if pd.notna(valor):
            valor = float(valor)
            umbrales.append({"limite": etiqueta, "valor": valor})
            fuera |= datos.valor.lt(valor) if campo == "umbral_minimo" else datos.valor.gt(valor)
    datos["comparacion"] = fuera.map({True: "Fuera de umbral", False: "Dentro de límites disponibles"})
    if not umbrales:
        datos["comparacion"] = "Sin umbrales definidos"
    a, b, c = st.columns(3)
    a.metric("Mediciones en el período", len(datos))
    b.metric(f"Promedio ({detalle.unidad_medida})", f"{datos.valor.mean():.2f}")
    c.metric("Fuera de umbral", int(fuera.sum()) if umbrales else "Sin definir")
    titulo_y = f"{detalle.nombre_medicion} ({detalle.unidad_medida})"
    base = alt.Chart(datos).encode(x=alt.X("fecha:T", title="Fecha y hora"),
        y=alt.Y("valor:Q", title=titulo_y, scale=alt.Scale(zero=False)),
        tooltip=["fecha:T", "valor:Q", "dispositivo:N", "comparacion:N"])
    lineas = base.mark_line(point=True).encode(color=alt.Color("dispositivo:N", title="Dispositivo"))
    capas = [lineas]
    if fuera.any():
        capas.append(alt.Chart(datos.loc[fuera]).mark_point(color="#dc2626", size=110, filled=True).encode(
            x="fecha:T", y="valor:Q", tooltip=["fecha:T", "valor:Q", "dispositivo:N"]))
    if umbrales:
        capas.append(alt.Chart(pd.DataFrame(umbrales)).mark_rule(color="#b45309", strokeDash=[6,4]).encode(
            y="valor:Q", tooltip=["limite:N", "valor:Q"]))
    st.altair_chart(alt.layer(*capas).properties(height=350).interactive(), width="stretch")
    st.caption("Líneas discontinuas: umbrales del catálogo. Puntos rojos: valores estrictamente fuera de esos límites. "
               "Esta comparación no crea ni reemplaza las alertas registradas.")
    if len(datos) == 1:
        st.info("Hay una sola medición: se muestra un punto, sin una tendencia temporal.")
    tabla_y_csv(datos.rename(columns={"fecha":"Fecha y hora", "valor":f"Valor ({detalle.unidad_medida})",
                                    "dispositivo":"Dispositivo", "comparacion":"Comparación"}), "mediciones")


def alertas():
    st.subheader("Alertas clínicas registradas")
    limites = consultar("SELECT MIN(fecha_alerta)::date AS inicio, MAX(fecha_alerta)::date AS fin FROM alerta_clinica").iloc[0]
    if limites.inicio is None:
        st.info("No hay alertas registradas.")
        return
    periodo = fechas(limites.inicio, limites.fin, "alertas")
    if periodo is None:
        return
    a, b = st.columns(2)
    gravedad = a.multiselect("Gravedad", ["leve", "moderada", "grave"], default=["leve", "moderada", "grave"])
    estado = b.selectbox("Estado de revisión", ["Todas", "Pendientes", "Revisadas"])
    if not gravedad:
        st.info("Seleccioná al menos una gravedad.")
        return
    revisada = None if estado == "Todas" else estado == "Revisadas"
    datos = consultar("""SELECT ac.id_alerta AS "ID", ac.fecha_alerta AS "Fecha de alerta",
        p.apellido || ', ' || p.nombre AS "Paciente", m.apellido || ', ' || m.nombre AS "Médico asociado",
        tm.nombre_medicion AS "Medición", rm.valor_medido AS "Valor", tm.unidad_medida AS "Unidad",
        ac.nivel_gravedad AS "Gravedad", CASE WHEN ac.revisada THEN 'Revisada' ELSE 'Pendiente' END AS "Estado"
        FROM alerta_clinica ac
        JOIN registro_medicion rm ON rm.id_registro_medicion=ac.id_registro_medicion
        JOIN asignacion_dispositivo ad ON ad.id_asignacion=rm.id_asignacion
        JOIN paciente p ON p.id_paciente=ad.id_paciente
        JOIN medico m ON m.id_medico=ac.id_medico
        JOIN tipo_medicion tm ON tm.id_tipo_medicion=rm.id_tipo_medicion
        WHERE ac.fecha_alerta >= %s AND ac.fecha_alerta < %s
          AND ac.nivel_gravedad = ANY(%s)
          AND (%s::boolean IS NULL OR ac.revisada = %s)
        ORDER BY ac.fecha_alerta DESC,ac.id_alerta DESC""", (*periodo, gravedad, revisada, revisada))
    st.caption("El período se aplica a la fecha de la alerta. Los indicadores reflejan los filtros seleccionados.")
    a,b,c = st.columns(3)
    a.metric("Alertas encontradas", len(datos))
    b.metric("Pendientes", int((datos.Estado == "Pendiente").sum()))
    c.metric("Graves", int((datos.Gravedad == "grave").sum()))
    if datos.empty:
        st.info("No hay alertas que coincidan con los filtros.")
        return
    resumen = datos.groupby("Gravedad").size().reindex(["leve","moderada","grave"], fill_value=0).reset_index(name="Cantidad")
    grafico = alt.Chart(resumen).mark_bar(cornerRadiusTopLeft=5, cornerRadiusTopRight=5).encode(
        x=alt.X("Gravedad:N", sort=["leve","moderada","grave"]), y=alt.Y("Cantidad:Q", axis=alt.Axis(tickMinStep=1)),
        color=alt.Color("Gravedad:N", scale=alt.Scale(domain=["leve","moderada","grave"], range=["#0d9488","#d97706","#dc2626"]), legend=None),
        tooltip=["Gravedad:N","Cantidad:Q"]).properties(height=280)
    st.altair_chart(grafico, width="stretch")
    tabla_y_csv(datos, "alertas")


# Ruta relativa al archivo, independiente de la carpeta actual de la terminal.
try:
    with Path(__file__).with_name("conexion.toml").open("rb") as archivo:
        configuracion = tomllib.load(archivo)["postgres"]
except (OSError, tomllib.TOMLDecodeError, KeyError):
    st.error("Falta completar la configuración local. Seguí las instrucciones de LEEME.md para preparar conexion.toml.")
    st.stop()

st.title("Seguimiento de pacientes")
st.caption("Monitoreo de mediciones y consulta de alertas · Trabajo Integrador Final")
with st.sidebar:
    st.header("Panel de seguimiento")
    st.write("Explorá pacientes, mediciones y alertas con las pestañas de la pantalla principal.")
    st.button("Actualizar datos")
    st.caption("Los cambios de filtros actualizan los resultados automáticamente.")

try:
    resumen = consultar("""SELECT (SELECT COUNT(*) FROM paciente) AS pacientes,
        (SELECT COUNT(*) FROM dispositivo) AS dispositivos,
        (SELECT COUNT(*) FROM alerta_clinica WHERE NOT revisada) AS pendientes""").iloc[0]
    a,b,c = st.columns(3)
    a.metric("Pacientes registrados", int(resumen.pacientes))
    b.metric("Dispositivos registrados", int(resumen.dispositivos))
    c.metric("Alertas pendientes totales", int(resumen.pendientes))
    st.caption("Resumen general de toda la base; no depende de los filtros de las pestañas.")
    tabs = st.tabs(["Pacientes", "Mediciones", "Alertas"])
    for tab, funcion in zip(tabs, [pacientes, mediciones, alertas]):
        with tab:
            funcion()
except psycopg.OperationalError:
    st.error("No se pudo acceder a los datos. Verificá que PostgreSQL esté iniciado y que conexion.toml tenga los datos correctos.")
except psycopg.Error as error:
    st.error("No se pudo completar una consulta. Revisá que la base tenga las tablas del TIF en el esquema configurado.")
    st.caption(f"Código de diagnóstico PostgreSQL: {error.sqlstate or 'no disponible'}")
