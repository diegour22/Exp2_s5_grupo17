
-- CASO 1

-- Clientes trabajadores dependientes (Contador / Vendedor)
-- inscritos después del promedio redondeado del año de inscripción.

SELECT
    (c.numrun || '-' || c.dvrun) AS rut_cliente,
    INITCAP(c.pnombre || ' ' || c.appaterno || ' ' || NVL(c.apmaterno, '')) AS nombre_cliente,
    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY') AS fecha_inscripcion,
    INITCAP(po.nombre_prof_ofic) AS profesion
FROM cliente c
JOIN profesion_oficio po
    ON c.cod_prof_ofic = po.cod_prof_ofic
WHERE 
    UPPER(po.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
    AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
        (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion))) FROM cliente)
ORDER BY c.numrun ASC;

--------------------------------------------------------------------------------------------------------


-- CASO 2

-- Crear tabla CLIENTES_CUPOS_COMPRA solo si no existe.
-- Esto elimina la tabla si existe, evitando ORA-00955.

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CLIENTES_CUPOS_COMPRA';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN  -- -942 = table not found
            RAISE;
        END IF;
END;
/

-- Crear la tabla limpia
CREATE TABLE CLIENTES_CUPOS_COMPRA (
    rut_cliente         VARCHAR2(20),
    nombre_cliente      VARCHAR2(100),
    cupo_total_compra   NUMBER(10),
    cupo_disponible     NUMBER(10),
    diferencia_cupo     NUMBER(10)
);


-- Insertar datos usando subconsulta y joins
INSERT INTO CLIENTES_CUPOS_COMPRA (
    rut_cliente,
    nombre_cliente,
    cupo_total_compra,
    cupo_disponible,
    diferencia_cupo
)
SELECT
    (c.numrun || '-' || c.dvrun) AS rut_cliente,
    INITCAP(c.pnombre || ' ' || c.appaterno || ' ' || NVL(c.apmaterno, '')) AS nombre_cliente,
    tc.cupo_compra AS cupo_total_compra,
    tc.cupo_disp_compra AS cupo_disponible,
    (tc.cupo_compra - tc.cupo_disp_compra) AS diferencia_cupo
FROM cliente c
JOIN profesion_oficio po 
    ON c.cod_prof_ofic = po.cod_prof_ofic
JOIN tarjeta_cliente tc
    ON c.numrun = tc.numrun
WHERE 
    UPPER(po.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
    AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
        (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion))) FROM cliente);

COMMIT;


-- SELECT final formateado del Caso 2
SELECT
    rut_cliente,
    nombre_cliente,
    cupo_total_compra AS cupo_total,
    cupo_disponible AS cupo_disponible,
    diferencia_cupo AS diferencia
FROM CLIENTES_CUPOS_COMPRA
ORDER BY cupo_disponible DESC;
