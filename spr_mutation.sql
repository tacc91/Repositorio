USE [D:\PERSONAL\UNIVERSIDAD\TITULACIÓN\2019\CÓDIGO FUENTE\PROYECTO\SAGA_UPS\APP_DATA\DB_SAGAUPS.MDF]
GO
/****** Object:  StoredProcedure [dbo].[spr_mutation]    Script Date: 19/02/2021 1:33:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[spr_mutation] (@Validador INT, @Individuo INT, @ProbabilidadMutacion FLOAT)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @NewDia INT
	DECLARE @NewHora INT
	DECLARE @NewAula INT
	DECLARE @PuntoMutacion INT
	DECLARE @TamanioCromosoma INT

	DECLARE @MaximoIdDia INT
	DECLARE @MaximoIdHora INT
	DECLARE @MaximoIdAula INT
	DECLARE @Fitness2 FLOAT
	DECLARE @GuiaMutacion FLOAT

	DECLARE @AuxLengthDia INT
	DECLARE @AuxLengthHora INT
	DECLARE @AuxLengthAula INT

	SET @MaximoIdDia = (SELECT MAX(i_id_dia) FROM tbl_dia_semana)
	SET @MaximoIdHora = (SELECT MAX(i_id_hora) FROM tbl_hora)
	SET @MaximoIdAula = (SELECT MAX(i_id_aula) FROM tbl_aula)

	SET @AuxLengthDia = (SELECT TOP 1 i_valor FROM tbl_parametros_ag WHERE s_cod_parametro = 'nDia')
	SET @AuxLengthHora = (SELECT TOP 1 i_valor FROM tbl_parametros_ag WHERE s_cod_parametro = 'nHor')
	SET @AuxLengthAula = (SELECT TOP 1 i_valor FROM tbl_parametros_ag WHERE s_cod_parametro = 'nAul')

	SET @TamanioCromosoma = (SELECT MAX(i_alelo) FROM tmp_hijos)


	TRUNCATE TABLE tmp_planificacion
	INSERT INTO tmp_planificacion
		(i_id_gru_carrera,
		i_id_materia,
		i_id_dia,
		i_id_hora,
		i_id_aula)
	SELECT
		i_id_gru_carrera,
		i_id_materia,
		i_id_dia_fenotipo,
		i_id_hora_fenotipo,
		i_id_aula_fenotipo
	FROM tmp_hijos WHERE i_individuo = @Individuo
	EXEC spr_fitness
		@Fitness = @Fitness2 OUTPUT,
		@GuiaMutacion = @GuiaMutacion OUTPUT;
	
	--IF(@Validador = 0)
	--	EXEC [spr_mutation] 1, @Individuo, 1

	UPDATE a SET
		a.f_fitness = @Fitness2,
		a.f_guia_mutacion = @GuiaMutacion
	FROM tmp_hijos a
	WHERE a.i_individuo = @Individuo

	IF(dbo.fn_flip(@ProbabilidadMutacion) = 1)
	BEGIN
		SET @PuntoMutacion = CONVERT(INT,ROUND(dbo.fn_ObtenerAleatorio(1,@TamanioCromosoma),0))--184
		SET @NewDia = (ABS(CHECKSUM(NewId())) % @MaximoIdDia)+1
		SET @NewHora = (ABS(CHECKSUM(NewId())) % @MaximoIdHora)+1
		SET @NewAula = (ABS(CHECKSUM(NewId())) % @MaximoIdAula)+1


		UPDATE a SET
			a.i_id_dia_fenotipo = IIF(a.f_guia_mutacion = 4, @NewDia, a.i_id_dia_fenotipo),
			a.i_id_hora_fenotipo = IIF(a.f_guia_mutacion IN (4,3), @NewHora,a.i_id_hora_fenotipo),
			a.i_id_aula_fenotipo = IIF(a.f_guia_mutacion IN (4,3,2), @NewAula,a.i_id_aula_fenotipo),
			a.s_id_dia_genotipo = IIF(a.f_guia_mutacion = 4, RIGHT(dbo.fn_decimal_to_binary(@NewDia),@AuxLengthDia),s_id_dia_genotipo),
			a.s_id_hora_genotipo = IIF(a.f_guia_mutacion IN (4,3), RIGHT(dbo.fn_decimal_to_binary(@NewHora),@AuxLengthHora),s_id_hora_genotipo),
			a.s_id_aula_genotipo = IIF(a.f_guia_mutacion IN (4,3,2), RIGHT(dbo.fn_decimal_to_binary(@NewAula),@AuxLengthAula),s_id_aula_genotipo)
		FROM tmp_hijos a WHERE i_individuo = @Individuo AND i_alelo = @PuntoMutacion

		--UPDATE a SET
		--	a.i_id_dia_fenotipo = @NewDia,
		--	a.i_id_hora_fenotipo = @NewHora,
		--	a.i_id_aula_fenotipo = @NewAula,
		--	a.s_id_dia_genotipo = RIGHT(dbo.fn_decimal_to_binary(@NewDia),@AuxLengthDia),
		--	a.s_id_hora_genotipo = RIGHT(dbo.fn_decimal_to_binary(@NewHora),@AuxLengthHora),
		--	a.s_id_aula_genotipo = RIGHT(dbo.fn_decimal_to_binary(@NewAula),@AuxLengthAula)
		--FROM tmp_hijos a WHERE i_individuo = @Individuo AND i_alelo = @PuntoMutacion
	END

	TRUNCATE TABLE tmp_planificacion
	INSERT INTO tmp_planificacion
		(i_id_gru_carrera,
		i_id_materia,
		i_id_dia,
		i_id_hora,
		i_id_aula)
	SELECT
		i_id_gru_carrera,
		i_id_materia,
		i_id_dia_fenotipo,
		i_id_hora_fenotipo,
		i_id_aula_fenotipo
	FROM tmp_hijos WHERE i_individuo = @Individuo

	EXEC spr_fitness
		@Fitness = @Fitness2 OUTPUT,
		@GuiaMutacion = @GuiaMutacion OUTPUT;
	
	--IF(@Validador = 0)
	--	EXEC [spr_mutation] 1, @Individuo, 1

	UPDATE a SET
		a.f_fitness = @Fitness2,
		a.f_guia_mutacion = @GuiaMutacion
	FROM tmp_hijos a
	WHERE a.i_individuo = @Individuo
END