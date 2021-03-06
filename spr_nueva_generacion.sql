USE [D:\PERSONAL\UNIVERSIDAD\TITULACIÓN\2019\CÓDIGO FUENTE\PROYECTO\SAGA_UPS\APP_DATA\DB_SAGAUPS.MDF]
GO
/****** Object:  StoredProcedure [dbo].[spr_nueva_generacion]    Script Date: 19/02/2021 1:33:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[spr_nueva_generacion](@TamanioPoblacion INT, @ProbabilidadCruza FLOAT, @ProbabilidadMutacion FLOAT)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @Parent_1 INT
	DECLARE @Parent_2 INT
	DECLARE @Contador INT
	DECLARE @MaxIndividuo INT
	DECLARE @MaxIndividuo2 INT
	
	SET @Contador = 0
	
	NuevaGeneracion:
	SET @Contador += 2
	
	SET @Parent_1 = dbo.fn_SeleccionRuleta()
	SET @Parent_2 = dbo.fn_SeleccionRuleta()
	
	--Cruza:
	EXEC spr_crossover @Parent_1, @Parent_2, @ProbabilidadCruza
	
	--Mutacion:
	SET @MaxIndividuo2 = (SELECT MAX(i_individuo) FROM tmp_hijos)
	SET @MaxIndividuo = @MaxIndividuo2 -1

	EXEC spr_mutation 0, @MaxIndividuo, @ProbabilidadMutacion
	EXEC spr_mutation 0, @MaxIndividuo2, @ProbabilidadMutacion
	

	IF (@Contador < @TamanioPoblacion)
		GOTO NuevaGeneracion

	--Elitismo:
	EXEC spr_elitism
END