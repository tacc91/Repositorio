USE [D:\PERSONAL\UNIVERSIDAD\TITULACIÓN\2019\CÓDIGO FUENTE\PROYECTO\SAGA_UPS\APP_DATA\DB_SAGAUPS.MDF]
GO
/****** Object:  StoredProcedure [dbo].[spr_elitism]    Script Date: 19/02/2021 1:32:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[spr_elitism]
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @PeorHijo1 INT
	DECLARE @PeorHijo2 INT
	DECLARE @MejorPadre INT
	
	SELECT *, ROW_NUMBER() OVER(ORDER BY f_fitness ASC) Peores INTO #PeoresHijos FROM (
	SELECT DISTINCT i_individuo, f_fitness FROM tmp_hijos) a
	
	
	SELECT *, ROW_NUMBER() OVER(ORDER BY f_fitness DESC) Mejores INTO #MejoresPadres FROM (
	SELECT DISTINCT i_individuo, f_fitness FROM tmp_poblacion) a
	
	SET @PeorHijo1 = (SELECT i_individuo FROM #PeoresHijos WHERE Peores = 1)
	SET @PeorHijo2 = (SELECT i_individuo FROM #PeoresHijos WHERE Peores = 2)
	SET @MejorPadre = (SELECT i_individuo FROM #MejoresPadres WHERE Mejores = 1)
	
	
	UPDATE a SET
		a.i_id_dia_fenotipo = b.i_id_dia_fenotipo,
		a.s_id_dia_genotipo = b.s_id_dia_genotipo,
		a.i_id_hora_fenotipo = b.i_id_hora_fenotipo,
		a.s_id_hora_genotipo = b.s_id_hora_genotipo,
		a.i_id_aula_fenotipo = b.i_id_aula_fenotipo,
		a.s_id_aula_genotipo = b.s_id_aula_genotipo,
		a.f_fitness = b.f_fitness,
		a.i_parent1 = b.i_parent1,
		a.i_parent2 = b.i_parent2
	FROM tmp_hijos a
	INNER JOIN tmp_poblacion b
		ON b.i_individuo = @MejorPadre
		AND a.i_alelo = b.i_alelo
	WHERE a.i_individuo = @PeorHijo1
	
	
	UPDATE a SET
		a.i_id_dia_fenotipo = b.i_id_dia_fenotipo,
		a.s_id_dia_genotipo = b.s_id_dia_genotipo,
		a.i_id_hora_fenotipo = b.i_id_hora_fenotipo,
		a.s_id_hora_genotipo = b.s_id_hora_genotipo,
		a.i_id_aula_fenotipo = b.i_id_aula_fenotipo,
		a.s_id_aula_genotipo = b.s_id_aula_genotipo,
		a.f_fitness = b.f_fitness,
		a.i_parent1 = b.i_parent1,
		a.i_parent2 = b.i_parent2
	FROM tmp_hijos a
	INNER JOIN tmp_poblacion b
		ON b.i_individuo = @MejorPadre
		AND a.i_alelo = b.i_alelo
	WHERE a.i_individuo = @PeorHijo2
	
	
	DROP TABLE #MejoresPadres
	DROP TABLE #PeoresHijos
END