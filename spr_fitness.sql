USE [D:\PERSONAL\UNIVERSIDAD\TITULACIÓN\2019\CÓDIGO FUENTE\PROYECTO\SAGA_UPS\APP_DATA\DB_SAGAUPS.MDF]
GO
/****** Object:  StoredProcedure [dbo].[spr_fitness]    Script Date: 19/02/2021 1:33:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[spr_fitness]
(@Fitness FLOAT OUTPUT
,@GuiaMutacion INT OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @Conflictos FLOAT
	DECLARE @ConflictosTipo1 FLOAT
	DECLARE @ConflictosTipo2 FLOAT
	DECLARE @ConflictosTipo3 FLOAT
	
	
	SET @Conflictos = 0
	SET @ConflictosTipo1 = 0
	SET @ConflictosTipo2 = 0
	SET @ConflictosTipo3 = 0
	
	
	SELECT @ConflictosTipo1+=COUNT(1) FROM tmp_planificacion a
	INNER JOIN tbl_dia_semana b
		ON a.i_id_dia = b.i_id_dia
	WHERE b.b_dia_laborable = 0
	
	SELECT @ConflictosTipo1+=COUNT(1) FROM (
	SELECT i_id_gru_carrera, i_id_materia, i_id_dia, COUNT(1) Contador FROM tmp_planificacion 
	GROUP BY i_id_gru_carrera, i_id_materia, i_id_dia
	HAVING COUNT(1) <> 2) ax
	
	SELECT @ConflictosTipo1+=COUNT(1) FROM (
	SELECT i_id_gru_carrera, i_id_dia, COUNT(1) Contador FROM tmp_planificacion
	GROUP BY i_id_gru_carrera, i_id_dia
	HAVING COUNT(1)/2 > 2) ax


	
	--Se Cambia
	--SELECT @ConflictosTipo2+=COUNT(1) FROM tmp_planificacion a
	--INNER JOIN tbl_hora b
	--	ON a.i_id_hora = b.i_id_hora
	--WHERE b.b_estado = 0

	--SELECT i_id_gru_carrera, i_id_dia INTO #Temporal FROM tmp_planificacion 
	--GROUP BY i_id_gru_carrera, i_id_materia, i_id_dia
	
	
	--SELECT @ConflictosTipo2+=COUNT(1) FROM (
	--SELECT a.i_id_gru_carrera, a.i_id_materia, a.i_id_dia, a.i_id_hora, ROW_NUMBER() OVER(PARTITION BY a.i_id_gru_carrera, a.i_id_materia, a.i_id_dia ORDER BY a.i_id_hora) Orden FROM tmp_planificacion a
	--INNER JOIN #Temporal b
	--	ON a.i_id_gru_carrera = b.i_id_gru_carrera
	--	AND a.i_id_materia = b.i_id_materia
	--	AND a.i_id_dia = b.i_id_dia) a
	--PIVOT(MAX(i_id_hora) FOR Orden IN ([1],[2])) b
	--WHERE ABS([1]-[2]) <> 1
	---- Se cambió el erro

	SELECT * INTO #Temporal FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY i_id_gru_carrera, i_id_dia ORDER BY i_id_aula) Orden FROM tmp_planificacion) a
	WHERE Orden = 1

	SELECT i_id_gru_carrera, i_id_dia, COUNT(1) MaximoHoras INTO #Auxiliar2 FROM tmp_planificacion
	GROUP BY i_id_gru_carrera, i_id_dia
	
	SELECT @ConflictosTipo3 += COUNT(1) FROM #Temporal a
	INNER JOIN #Auxiliar2 b
		ON a.i_id_gru_carrera = b.i_id_gru_carrera
		AND a.i_id_dia = b.i_id_dia
	LEFT JOIN tbl_aula c
		ON c.i_id_aula = a.i_id_aula
	WHERE ISNULL(c.b_estado,0) = 0

	SELECT @ConflictosTipo3 += COUNT(1) FROM #Temporal a
	INNER JOIN #Auxiliar2 b
		ON a.i_id_gru_carrera = b.i_id_gru_carrera
		AND a.i_id_dia = b.i_id_dia
	LEFT JOIN tbl_aula c
		ON c.i_id_aula = a.i_id_aula
	LEFT JOIN tbl_tip_aula d
		ON c.i_id_tip_aula = d.i_id_tip_aula
	LEFT JOIN tbl_materia e
		ON a.i_id_materia = e.i_id_materia
	WHERE (b_laboratorio = 1 AND s_descripcion <> 'Laboratorio') OR (b_laboratorio = 0 AND s_descripcion = 'Laboratorio')

	SELECT @ConflictosTipo3 += COUNT(1) FROM tmp_planificacion a
	LEFT JOIN #Temporal b
		ON a.i_id_gru_carrera = b.i_id_gru_carrera
		AND a.i_id_dia = b.i_id_dia
	LEFT JOIN #Auxiliar2 c
		ON a.i_id_gru_carrera = c.i_id_gru_carrera
		AND a.i_id_dia = c.i_id_dia
	WHERE a.i_id_aula <> b.i_id_aula



	--SELECT @ConflictosTipo3 = COUNT(1) FROM tmp_planificacion a
	--INNER JOIN tbl_hora b
	--	ON a.i_id_hora = b.i_id_hora
	--WHERE b.b_estado = 0

	--SELECT @ConflictosTipo3 = COUNT(1) FROM (
	--SELECT a.i_id_gru_carrera, a.i_id_dia, COUNT(DISTINCT i_id_hora) Contador2 FROM tmp_planificacion a
	--INNER JOIN #Temporal b
	--	ON a.i_id_gru_carrera = b.i_id_gru_carrera
	--	AND a.i_id_gru_carrera = b.i_id_gru_carrera
	--GROUP BY a.i_id_gru_carrera, a.i_id_dia
	--HAVING MAX(b.Contador) <> COUNT(DISTINCT i_id_hora)) a
	
	SELECT * INTO #Temporal2 FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY i_id_gru_carrera, i_id_dia ORDER BY i_id_materia, i_id_hora) Orden FROM tmp_planificacion) a
	WHERE Orden = 1

	SELECT i_id_gru_carrera, i_id_dia, COUNT(1) MaximoHoras INTO #Auxiliar FROM tmp_planificacion
	GROUP BY i_id_gru_carrera, i_id_dia
	
	SELECT @ConflictosTipo2 = COUNT(1) FROM #Temporal2 a
	INNER JOIN #Auxiliar b
		ON a.i_id_gru_carrera = b.i_id_gru_carrera
		AND a.i_id_dia = b.i_id_dia
	LEFT JOIN tbl_hora c
		ON c.i_id_hora BETWEEN a.i_id_hora AND a.i_id_hora + b.MaximoHoras-1
	WHERE ISNULL(c.b_estado,0) = 0

	SELECT a.*, b.i_id_hora i_id_hora_base, c.MaximoHoras, ROW_NUMBER() OVER(PARTITION BY a.i_id_gru_carrera, a.i_id_dia ORDER BY a.i_id_materia, a.i_id_hora) Orden INTO #Temporal3 FROM tmp_planificacion a
	LEFT JOIN #Temporal2 b
		ON a.i_id_gru_carrera = b.i_id_gru_carrera
		AND a.i_id_dia = b.i_id_dia
	LEFT JOIN #Auxiliar c
		ON a.i_id_gru_carrera = c.i_id_gru_carrera
		AND a.i_id_dia = c.i_id_dia

	SELECT @ConflictosTipo2 += COUNT(1) FROM #Temporal3 WHERE Orden = 2 AND i_id_hora-i_id_hora_base <> 1
	SELECT @ConflictosTipo2 += COUNT(1) FROM #Temporal3 WHERE Orden = 3 AND i_id_hora-i_id_hora_base <> 2
	SELECT @ConflictosTipo2 += COUNT(1) FROM #Temporal3 WHERE Orden = 4 AND i_id_hora-i_id_hora_base <> 3
	SELECT @ConflictosTipo2 += COUNT(1) FROM #Temporal3 WHERE Orden = 5 AND i_id_hora-i_id_hora_base <> 4
	SELECT @ConflictosTipo2 += COUNT(1) FROM #Temporal3 WHERE Orden = 6 AND i_id_hora-i_id_hora_base <> 5
	
	/************************
	TRUNCATE TABLE tmp_planificacion
	INSERT INTO tmp_planificacion
	SELECT
		i_id_gru_carrera,
		i_id_materia,
		i_id_dia_fenotipo,
		i_id_hora_fenotipo,
		i_id_aula_fenotipo
	FROM tmp_poblacion WHERE f_fitness = 1
	***********************/


	--SELECT @ConflictosTipo2+=COUNT(1) FROM (
	--SELECT i_id_gru_carrera, i_id_dia, COUNT(1) Errores FROM tmp_planificacion
	--GROUP BY i_id_gru_carrera, i_id_dia
	--HAVING COUNT(1) > 1) a


	--SET @GuiaMutacion = 4

	--IF (@Conflictos = 0)
	--BEGIN
		
		
		
	--	SET @GuiaMutacion = 3

	--	IF (@Conflictos = 0)
	--	BEGIN
			

	--		SET @GuiaMutacion = 2

	--		IF (@Conflictos = 0)
	--		BEGIN
				
	--			SELECT
	--				*,
	--				ROW_NUMBER() OVER(PARTITION BY i_id_malla, i_id_nivel, i_id_grupo, i_id_dia ORDER BY i_id_hora, i_id_aula) Orden,
	--				ROW_NUMBER() OVER(PARTITION BY i_id_malla, i_id_nivel, i_id_grupo, i_id_dia ORDER BY i_id_hora, i_id_aula)+1 Orden2
	--			INTO #Temporal2
	--			FROM (
	--			SELECT DISTINCT
	--				b.i_id_malla,
	--				b.i_id_nivel,
	--				b.i_id_grupo,
	--				a.i_id_dia,
	--				a.i_id_hora,
	--				a.i_id_aula
	--			FROM tmp_planificacion a
	--			INNER JOIN tbl_gru_carrera b
	--				ON a.i_id_gru_carrera = b.i_id_gru_carrera) a
				
	--			SELECT @Conflictos+=AVG(PromedioDistancia) FROM (
	--			SELECT
	--				a.i_id_malla,
	--				a.i_id_nivel,
	--				a.i_id_grupo,
	--				a.i_id_dia,
	--				AVG(c.i_distancia) PromedioDistancia,
	--				MAX(c.i_distancia) DistanciaMaxima,
	--				MIN(c.i_distancia) DistanciaMinima
	--			FROM #Temporal2 a
	--			INNER JOIN #Temporal2 b
	--				ON a.i_id_malla = b.i_id_malla
	--				AND a.i_id_nivel = b.i_id_nivel
	--				AND a.i_id_grupo = b.i_id_grupo
	--				AND a.i_id_dia = b.i_id_dia
	--				AND a.Orden2 = b.Orden
	--			INNER JOIN tbl_matriz_distancia c
	--				ON a.i_id_aula = c.i_id_aul_origen
	--				AND b.i_id_aula = c.i_id_aul_destino
	--			--WHERE a.i_id_malla = 1 AND a.i_id_nivel = 1 AND a.i_id_grupo = 1 AND a.i_id_dia = 1
	--			GROUP BY a.i_id_malla, a.i_id_nivel, a.i_id_grupo, a.i_id_dia) a
		
	--			DROP TABLE #Temporal2
	--		END
	--	END

	--	DROP TABLE #Temporal
	--END
	
	--SET @ConflictosTipo2 = 0

	IF(@ConflictosTipo1 > 0)
		SET @GuiaMutacion = 4
	ELSE IF(@ConflictosTipo2 > 0)
		SET @GuiaMutacion = 3
	ELSE IF(@ConflictosTipo3 > 0)
		SET @GuiaMutacion = 2
	ELSE
		SET @GuiaMutacion = 1


	SET @Fitness = 1/((@ConflictosTipo1*(IIF(@ConflictosTipo2+@ConflictosTipo3 > 0,@ConflictosTipo2+@ConflictosTipo3,1))*10+@ConflictosTipo2*(IIF(@ConflictosTipo3>0,@ConflictosTipo3,1))+@ConflictosTipo3) + 1)
	--SET @Fitness = 1/((@ConflictosTipo1+@ConflictosTipo2+@ConflictosTipo3) + 1)
	
	DROP TABLE #Temporal
	DROP TABLE #Auxiliar2
	DROP TABLE #Auxiliar
	DROP TABLE #Temporal2
	DROP TABLE #Temporal3
	

	RETURN
END