USE [D:\PERSONAL\UNIVERSIDAD\TITULACIÓN\2019\CÓDIGO FUENTE\PROYECTO\SAGA_UPS\APP_DATA\DB_SAGAUPS.MDF]
GO
/****** Object:  StoredProcedure [dbo].[spr_poblacion_inicial]    Script Date: 19/02/2021 1:33:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[spr_poblacion_inicial]
AS
BEGIN
	SET NOCOUNT ON 
	DECLARE @MaximoIdDia INT
	DECLARE @MaximoIdHora INT
	DECLARE @MaximoIdAula INT
	DECLARE @IndividuoActual INT
	DECLARE @Fitness2 FLOAT
	DECLARE @GuiaMutacion FLOAT

	DECLARE @AuxLengthDia INT
	DECLARE @AuxLengthHora INT
	DECLARE @AuxLengthAula INT

	SET @MaximoIdDia = (SELECT MAX(i_id_dia) FROM tbl_dia_semana)
	SET @MaximoIdHora = (SELECT MAX(i_id_hora) FROM tbl_hora)
	SET @MaximoIdAula = (SELECT MAX(i_id_aula) FROM tbl_aula)
	SET @IndividuoActual = ISNULL((SELECT MAX(i_individuo) FROM tmp_poblacion),0)+1

	SET @AuxLengthDia = (SELECT TOP 1 i_valor FROM tbl_parametros_ag WHERE s_cod_parametro = 'nDia')
	SET @AuxLengthHora = (SELECT TOP 1 i_valor FROM tbl_parametros_ag WHERE s_cod_parametro = 'nHor')
	SET @AuxLengthAula = (SELECT TOP 1 i_valor FROM tbl_parametros_ag WHERE s_cod_parametro = 'nAul')

	SELECT
		a.i_id_materia,
		a.i_can_horas,
		c.i_id_gru_carrera
	INTO #tmp_Datos
	FROM tbl_materia a
	INNER JOIN tbl_mencion b
		ON a.i_id_mencion = b.i_id_mencion
		AND b.b_estado = 1
	INNER JOIN tbl_gru_carrera c
		ON c.i_id_malla = b.i_id_malla 
		AND a.i_id_nivel = c.i_id_nivel
		AND c.b_estado = 1
	WHERE a.b_estado = 1;

	WITH Horario(i_id_materia, i_id_gru_carrera, nro_hora)
	AS
		(SELECT
			i_id_materia,
			i_id_gru_carrera,
			1 nro_hora
		FROM #tmp_Datos
		UNION ALL
		SELECT
			a.i_id_materia,
			a.i_id_gru_carrera,
			nro_hora+1
		FROM #tmp_Datos a
		INNER JOIN Horario x
			ON a.i_id_gru_carrera = x.i_id_gru_carrera
			AND a.i_id_materia = x.i_id_materia
			AND nro_hora+1 <= a.i_can_horas)
	SELECT
		i_id_gru_carrera,
		i_id_materia,
		(ABS(CHECKSUM(NewId())) % @MaximoIdDia)+1 i_id_dia,
		(ABS(CHECKSUM(NewId())) % @MaximoIdHora)+1 i_id_hora,
		(ABS(CHECKSUM(NewId())) % @MaximoIdAula)+1 i_id_aula
	INTO #FirstGeneration
	FROM Horario 
	ORDER BY i_id_gru_carrera, i_id_materia, nro_hora;

	INSERT INTO tmp_poblacion (
		i_individuo,
		i_alelo,
		i_id_gru_carrera,
		i_id_materia,
		i_id_dia_fenotipo,
		s_id_dia_genotipo,
		i_id_hora_fenotipo,
		s_id_hora_genotipo,
		i_id_aula_fenotipo,
		s_id_aula_genotipo,
		f_fitness,
		i_parent1,
		i_parent2,
		f_guia_mutacion)
	SELECT
		@IndividuoActual i_individuo,
		ROW_NUMBER() OVER(ORDER BY i_id_gru_carrera, i_id_materia) i_alelo,
		i_id_gru_carrera,
		i_id_materia,
		i_id_dia i_id_dia_fenotipo,
		RIGHT(dbo.fn_decimal_to_binary(i_id_dia),@AuxLengthDia) s_id_dia_genotipo,
		i_id_hora i_id_hora_fenotipo,
		RIGHT(dbo.fn_decimal_to_binary(i_id_hora),@AuxLengthHora) s_id_hora_genotipo,
		i_id_aula i_id_aula_fenotipo,
		RIGHT(dbo.fn_decimal_to_binary(i_id_aula),@AuxLengthAula) s_id_aula_genotipo,
		NULL f_fitness,
		NULL i_parent1,
		NULL i_parent2,
		NULL f_guia_mutacion
	FROM #FirstGeneration
	ORDER BY i_id_gru_carrera, i_id_materia, i_id_dia, i_id_hora;

	TRUNCATE TABLE tmp_planificacion
	INSERT INTO tmp_planificacion
		(i_id_gru_carrera
		,i_id_materia
		,i_id_dia
		,i_id_hora
		,i_id_aula)
	SELECT
		i_id_gru_carrera,
		i_id_materia,
		i_id_dia_fenotipo,
		i_id_hora_fenotipo,
		i_id_aula_fenotipo
	FROM tmp_poblacion WHERE i_individuo = @IndividuoActual

	
	EXEC spr_fitness 
		@Fitness = @Fitness2 OUTPUT,
		@GuiaMutacion = @GuiaMutacion OUTPUT;

	UPDATE a SET
		a.f_fitness = @Fitness2,
		a.f_guia_mutacion = @GuiaMutacion
	FROM tmp_poblacion a
	WHERE a.i_individuo = @IndividuoActual

	DROP TABLE #tmp_Datos
	DROP TABLE #FirstGeneration
END