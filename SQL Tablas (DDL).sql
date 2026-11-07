-- 1. Tabla Paciente
CREATE TABLE Paciente (
    id_paciente INT PRIMARY KEY,
    dni VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100)
);

-- 2. Tabla Medico
CREATE TABLE Medico (
    id_medico INT PRIMARY KEY,
    matricula VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    especialidad VARCHAR(50),
    telefono VARCHAR(20),
    email VARCHAR(100)
);

-- 3. Tabla Seguimiento
CREATE TABLE Seguimiento (
    id_seguimiento INT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_medico INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    CONSTRAINT chk_seguimiento_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente),
    FOREIGN KEY (id_medico) REFERENCES Medico(id_medico)
);

-- 4. Tabla Dispositivo
CREATE TABLE Dispositivo (
    id_dispositivo INT PRIMARY KEY,
    numero_serie VARCHAR(50) UNIQUE NOT NULL,
    marca VARCHAR(50),
    modelo VARCHAR(50),
    fecha_adquisicion DATE,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT chk_dispositivo_estado CHECK (estado IN ('activo', 'en mantenimiento', 'disponible'))
);

-- 5. Tabla Tipo_Medicion
CREATE TABLE Tipo_Medicion (
    id_tipo_medicion INT PRIMARY KEY,
    nombre_medicion VARCHAR(50) NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL,
    umbral_minimo DECIMAL(10,2),
    umbral_maximo DECIMAL(10,2)
);

-- 6. Tabla Dispositivo_Tipo_Medicion
CREATE TABLE Dispositivo_Tipo_Medicion (
    id_dispositivo INT NOT NULL,
    id_tipo_medicion INT NOT NULL,
    PRIMARY KEY (id_dispositivo, id_tipo_medicion),
    FOREIGN KEY (id_dispositivo) REFERENCES Dispositivo(id_dispositivo),
    FOREIGN KEY (id_tipo_medicion) REFERENCES Tipo_Medicion(id_tipo_medicion)
);

-- 7. Tabla Asignacion_Dispositivo
CREATE TABLE Asignacion_Dispositivo (
    id_asignacion INT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_dispositivo INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    CONSTRAINT chk_asignacion_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente),
    FOREIGN KEY (id_dispositivo) REFERENCES Dispositivo(id_dispositivo)
);

-- 8. Tabla Registro_Medicion
CREATE TABLE Registro_Medicion (
    id_registro_medicion INT PRIMARY KEY,
    id_asignacion INT NOT NULL,
    id_tipo_medicion INT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL,
    valor_medido DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_asignacion) REFERENCES Asignacion_Dispositivo(id_asignacion),
    FOREIGN KEY (id_tipo_medicion) REFERENCES Tipo_Medicion(id_tipo_medicion)
);

-- 9. Tabla Alerta_Clinica
CREATE TABLE Alerta_Clinica (
    id_alerta INT PRIMARY KEY,
    id_registro_medicion INT UNIQUE NOT NULL,
    id_medico INT NOT NULL,
    nivel_gravedad VARCHAR(20) NOT NULL,
    fecha_alerta TIMESTAMP NOT NULL,
    revisada BOOLEAN DEFAULT FALSE NOT NULL,
    fecha_revision TIMESTAMP,
    CONSTRAINT chk_alerta_gravedad CHECK (nivel_gravedad IN ('leve', 'moderada', 'grave')),
    CONSTRAINT chk_alerta_revision CHECK (
        (revisada = FALSE AND fecha_revision IS NULL) OR 
        (revisada = TRUE AND fecha_revision IS NOT NULL AND fecha_revision >= fecha_alerta)
    ),
    FOREIGN KEY (id_registro_medicion) REFERENCES Registro_Medicion(id_registro_medicion),
    FOREIGN KEY (id_medico) REFERENCES Medico(id_medico)
);

-- 10. Tabla Registro_Clinico
CREATE TABLE Registro_Clinico (
    id_registro_clinico INT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_medico INT NOT NULL,
    id_alerta INT,
    fecha_registro TIMESTAMP NOT NULL,
    diagnostico TEXT,
    observaciones TEXT,
    FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente),
    FOREIGN KEY (id_medico) REFERENCES Medico(id_medico),
    FOREIGN KEY (id_alerta) REFERENCES Alerta_Clinica(id_alerta)
);