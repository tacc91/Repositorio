USE [D:\PERSONAL\UNIVERSIDAD\TITULACIÓN\2019\CÓDIGO FUENTE\PROYECTO\SAGA_UPS\APP_DATA\DB_SAGAUPS.MDF]
GO
/****** Object:  StoredProcedure [dbo].[spr_crossover]    Script Date: 19/02/2021 1:32:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[spr_crossover](@Parent1 INT, @Parent2 INT, @ProbabilidadCruza FLOAT)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @TamanioCromosoma INT
	DECLARE @PuntoCruza INT
	DECLARE @MaxIndividuo INT
	DECLARE @MaxAlelo INT
	
	SET @TamanioCromosoma = (SELECT MAX(i_alelo) FROM tmp_poblacion)-2
	SET @MaxIndividuo = ISNULL((SELECT MAX(i_individuo) FROM tmp_hijos),0)
	SET @MaxAlelo = ISNULL((SELECT MAX(i_alelo) FROM tmp_hijos),(SELECT MAX(i_alelo) FROM tmp_poblacion))-2
	
	IF (dbo.fn_flip(@ProbabilidadCruza) = 1)
	BEGIN
		SET @PuntoCruza = CONVERT(INT,ROUND(dbo.fn_ObtenerAleatorio(1,@MaxAlelo),0))
	
		INSERT INTO tmp_hijos
		SELECT
			@MaxIndividuo+1 i_individuo,
			i_alelo,
			i_id_gru_carrera,
			i_id_materia,
			i_id_dia_fenotipo,
			s_id_dia_genotipo,
			i_id_hora_fenotipo,
			s_id_hora_genotipo,
			i_id_aula_fenotipo,
			s_id_aula_genotipo,
			NULL f_fitness,
			@Parent1 i_parent1,
			@Parent2 i_parent2,
			NULL f_guia_mutacion
		FROM tmp_poblacion WHERE i_individuo = @Parent1 AND i_alelo <= @PuntoCruza
		UNION ALL
		SELECT
			@MaxIndividuo+1 i_individuo,
			i_alelo,
			i_id_gru_carrera,
			i_id_materia,
			i_id_dia_fenotipo,
			s_id_dia_genotipo,
			i_id_hora_fenotipo,
			s_id_hora_genotipo,
			i_id_aula_fenotipo,
			s_id_aula_genotipo,
			NULL f_fitness,
			@Parent1 i_parent1,
			@Parent2 i_parent2,
			NULL f_guia_mutacion
		FROM tmp_poblacion WHERE i_individuo = @Parent2 AND i_alelo > @PuntoCruza
		
		INSERT INTO tmp_hijos
		SELECT
			@MaxIndividuo+2 i_individuo,
			i_alelo,
			i_id_gru_carrera,
			i_id_materia,
			i_id_dia_fenotipo,
			s_id_dia_genotipo,
			i_id_hora_fenotipo,
			s_id_hora_genotipo,
			i_id_aula_fenotipo,
			s_id_aula_genotipo,
			NULL f_fitness,
			@Parent1 i_parent1,
			@Parent2 i_parent2,
			NULL f_guia_mutacion
		FROM tmp_poblacion WHERE i_individuo = @Parent2 AND i_alelo <= @PuntoCruza
		UNION ALL
		SELECT
			@MaxIndividuo+2 i_individuo,
			i_alelo,
			i_id_gru_carrera,
			i_id_materia,
			i_id_dia_fenotipo,
			s_id_dia_genotipo,
			i_id_hora_fenotipo,
			s_id_hora_genotipo,
			i_id_aula_fenotipo,
			s_id_aula_genotipo,
			NULL f_fitness,
			@Parent1 i_parent1,
			@Parent2 i_parent2,
			NULL f_guia_mutacion
		FROM tmp_poblacion WHERE i_individuo = @Parent1 AND i_alelo > @PuntoCruza
	END
	ELSE
	BEGIN
		INSERT INTO tmp_hijos
		SELECT
			@MaxIndividuo+1 i_individuo,
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
			NULL i_parent1,
			NULL i_parent2,
			NULL f_guia_mutacion
		FROM tmp_poblacion WHERE i_individuo = @Parent1
		
		INSERT INTO tmp_hijos
		SELECT
			@MaxIndividuo+2 i_individuo,
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
			NULL i_parent1,
			NULL i_parent2,
			NULL f_guia_mutacion
		FROM tmp_poblacion WHERE i_individuo = @Parent2
	END
END