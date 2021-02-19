USE [D:\PERSONAL\UNIVERSIDAD\TITULACIÓN\2019\CÓDIGO FUENTE\PROYECTO\SAGA_UPS\APP_DATA\DB_SAGAUPS.MDF]
GO

SET NOCOUNT ON

--Variables Del Algoritmo
DECLARE @TamanioPoblacion INT
DECLARE @ProbabilidadCruza FLOAT
DECLARE @ProbabilidadMutacion FLOAT
DECLARE @TotalGeneraciones INT
--Variables Auxiliares
DECLARE @Contador INT
DECLARE @SumFitness FLOAT

--Asignamos Los Parametros A Las Variables Del Algoritmo
SET @TamanioPoblacion = (SELECT TOP 1 i_valor FROM tbl_parametros_ag 
						 WHERE s_cod_parametro = 'nPbl')
SET @ProbabilidadCruza = (SELECT TOP 1 f_valor FROM tbl_parametros_ag
						  WHERE s_cod_parametro = 'prbCru')
SET @ProbabilidadMutacion = (SELECT TOP 1 f_valor FROM tbl_parametros_ag
							  WHERE s_cod_parametro = 'prbMut')
SET @TotalGeneraciones = (SELECT TOP 1 i_valor FROM tbl_parametros_ag
						  WHERE s_cod_parametro = 'MaxGen')

--Asignamos Los Valores A Las Variables Auxiliares
SET @Contador = 0

--Truncamos Los Datos De Las Tablas De Trabajo
TRUNCATE TABLE tmp_poblacion
TRUNCATE TABLE tmp_ruleta
TRUNCATE TABLE tmp_hijos
TRUNCATE TABLE tmp_mejores_individuos

--Creamos la Primera Generación de Soluciones Aleatorias
CreateFirstGeneration:
EXEC spr_poblacion_inicial
SET @Contador += 1

IF (@Contador < @TamanioPoblacion)
	GOTO CreateFirstGeneration


INSERT INTO tmp_mejores_individuos
SELECT i_individuo, f_fitness, 0 FROM (
SELECT *, ROW_NUMBER() OVER(ORDER BY f_fitness DESC) the_best FROM (
SELECT DISTINCT i_individuo, f_fitness FROM tmp_poblacion) a) a
WHERE the_best = 1


SET @Contador = 0


--Iniciamos La Ejecución del Algoritmo
GeneticAlgorithm:
SET @Contador += 1

--Limpiamos y Llenamos la Ruleta
TRUNCATE TABLE tmp_ruleta

SELECT 
	i_individuo,
	MAX(f_fitness) f_fitness
INTO ##TemporalRuleta
FROM tmp_poblacion
GROUP BY i_individuo

SET @SumFitness = (SELECT SUM(f_fitness) FROM ##TemporalRuleta)

INSERT INTO tmp_ruleta
SELECT
	i_individuo,
	f_fitness/@SumFitness Participacion,
	f_fitness
FROM ##TemporalRuleta

--Creamos la nueva generación
EXEC spr_nueva_generacion @TamanioPoblacion, 
						  @ProbabilidadCruza,
						  @ProbabilidadMutacion


--Limpliamos y asignamos la nueva población
TRUNCATE TABLE tmp_poblacion

INSERT INTO tmp_poblacion 
	(i_individuo
	,i_alelo
	,i_id_gru_carrera
	,i_id_materia
	,i_id_dia_fenotipo
	,s_id_dia_genotipo
	,i_id_hora_fenotipo
	,s_id_hora_genotipo
	,i_id_aula_fenotipo
	,s_id_aula_genotipo
	,f_fitness
	,i_parent1
	,i_parent2
	,f_guia_mutacion)
SELECT
	 i_individuo
	,i_alelo
	,i_id_gru_carrera
	,i_id_materia
	,i_id_dia_fenotipo
	,s_id_dia_genotipo
	,i_id_hora_fenotipo
	,s_id_hora_genotipo
	,i_id_aula_fenotipo
	,s_id_aula_genotipo
	,f_fitness
	,i_parent1
	,i_parent2
	,f_guia_mutacion
FROM tmp_hijos

TRUNCATE TABLE tmp_hijos

INSERT INTO tmp_mejores_individuos
SELECT i_individuo, f_fitness, @Contador FROM (
SELECT *, ROW_NUMBER() OVER(ORDER BY f_fitness DESC) the_best FROM (
SELECT DISTINCT i_individuo, f_fitness FROM tmp_poblacion) a) a
WHERE the_best = 1


DROP TABLE ##TemporalRuleta
IF (@Contador < @TotalGeneraciones AND (SELECT TOP 1 f_fitness FROM tmp_mejores_individuos WHERE i_generacion = @Contador) < 1)
	GOTO GeneticAlgorithm