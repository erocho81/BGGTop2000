--**************************************************************
---SQL queries sobre la BBDD TOP 2000 juegos de mesa de la BGG obtenido en kaggle. He considerado 2000 juegos como muestra representativa, 
--ya que aunque la BBDD original tiene más de 200k de juegos, muchos de ellos tienen pocas valoraciones e información.
--Debido a problemas al cargar los datos del csv original, he tenido que crear nuevas columnas calculadas.

--------------------
---SQL queries for the Database BGG TOP 2000 boardgames from kaggle. I have considered 2000 games a representative sample.
---The original BGG database includes more than 200k boardgames, but many of them have not enough ratings or are missing info.
---Due to problems when loading the csv data, I've had to create new calculated columns.

--**************************************************************
--Primero adjunto la sentencias de drop para las columnas en caso de que ya hayan sido creadas:
--The first queries are used to drop the calculated columns in case they have already been created:

ALTER TABLE BGG_TOP_2000
DROP COLUMN new_avg_rating

ALTER TABLE BGG_TOP_2000
DROP COLUMN new_std_dev_rtg

ALTER TABLE BGG_TOP_2000
DROP COLUMN new_weight

--**************************************************************
--Creamos nueva columna a partir de avg rating pero donde todos los nums tengan 5 dígitos, para facilitar calculos posteriores.
--We create a new calculated column using avg_rating where all numbers have 5 digits to help with later calculations on them.

ALTER TABLE BGG_TOP_2000
ADD new_avg_rating AS CAST

		(CASE  WHEN LEN(avg_rating) = 3
			   THEN CONCAT (avg_rating, 0)
			   WHEN LEN (avg_rating) = 2
			   THEN CONCAT (avg_rating, 0,0)
			   WHEN LEN(avg_rating) = 1
	           THEN CONCAT (avg_rating, 0,0,0)
			   ELSE avg_rating
	     END  AS DECIMAL)

--Creamos nueva columna a partir de std_dev_rating pero donde todos los nums tengan 3 dígitos, para facilitar calculos posteriores.
--We create a new calculated column using std_dev_rating  where all numbers have 3 digits to help with later calculations on them.

ALTER TABLE BGG_TOP_2000
ADD new_std_dev_rtg AS CAST

		(CASE  WHEN LEN(std_dev_rating) = 2
			 THEN CONCAT (std_dev_rating, 0)
			 WHEN LEN(std_dev_rating) = 1
		     THEN CONCAT (std_dev_rating, 0,0)
			 ELSE std_dev_rating
        END  AS DECIMAL)

--Creamos nueva columna a partir de weight pero donde todos los nums tengan 3 dígitos, para facilitar calculos posteriores.
--We create a new calculated column using weight where all numbers have 3 digits to help with later calculations on them.

ALTER TABLE BGG_TOP_2000
ADD new_weight AS CAST

		(CASE  WHEN LEN(weight) = 2
			  THEN CONCAT (weight, 0)
			  WHEN LEN(weight) = 1
			  THEN CONCAT (weight, 0,0)
			  ELSE weight
        END  As decimal)


--**************************************************************
--No podemos usar un alter table para incluir decimales en las columnas calculadas, por lo que tendremos que hacerlo en las sentencias de Select, etc.
--Usamos select para calcular las columnas que necesitamos y ver cómo quedan las columnas originales respecto a las calculadas:
--------------------
--We can't alter the calculated columns due to sql requirements, so we can't include decimal places for the calculated column, we will need to do that with every Select sentence, etc.
--Here we are using Select to calculate once again the decimals we need using the already calculted columns.

SELECT TOP (1000) 
		title,
		avg_rating,
		new_avg_rating,
		CAST (new_avg_rating/1000 AS DECIMAL (4,3)) AS rtg,
		new_std_dev_rtg,
		CAST (new_std_dev_rtg/100 AS DECIMAL (3,2)) AS dev_rtg,
		new_weight,
		CAST (new_weight/100 AS DECIMAL (3,2)) AS weight_amended

FROM PortfolioProject.dbo.BGG_TOP_2000
ORDER BY rtg DESC

--**************************************************************
-- Ahora podemos establecer una query select con todo lo que queremos para usar como subquery en calculos posteriores, con las columnas que pueden ser más interesantes:
-- Now we can establish a select query with all we need to use it as subquery in further calculations:

SELECT
		rank,
		title,
		year,
		CAST (new_avg_rating/1000 AS DECIMAL (4,3)) AS rtg,
		num_rating,
		CAST (new_std_dev_rtg/100 AS DECIMAL (3,2)) AS dev_rtg,
		CAST (new_weight/100 AS DECIMAL (3,2)) AS weight_amended,
		min_player,
		max_player,
		min_time,
		max_time,
		min_age,
		num_own,
		total_play

FROM PortfolioProject.dbo.BGG_TOP_2000

--**************************************************************
--- Vamos a calcular 3 categorías de juegos según su dificultad (weight) para ver la puntuación media según la dificultad. 
---Serán categorías que irán de dificultad 1 a 2,5/ 2,5 a 4/ y más de 4
---Queremos ver si hay relación entre una mayor dificultad y un mayor rating.
---He tenido que incluir un filtro de num_rating para reducir el num de resultados y mejorar el tiempo de respuesta a la query.
--- Se aprecia un claro aumento de rating avg según el aumento de dificultad. Esto se ha detectado en otros estudios con muestras más grandes.
--------------------
--- We are going to calculate 3 different categories according to the game's difficulty (weight) and check the avg rating related to it.
---The categories will have difficulties from 1 to 2.5-2.5 to 4 and higher than 4.
---I have included a Where filter to decrease the results number and improve the querie's time response.
---A clear raise of rating can be appreciated as the difficulty also increases. This has been noted with higher samples too.


----CTE light difficulty

WITH light AS

	(SELECT
		new_avg_rating,
		new_weight,
		CAST (new_weight/100 AS DECIMAL (3,2)) AS weight_amended

	FROM PortfolioProject.dbo.BGG_TOP_2000
---Necesitamos hacer el cast otra vez porque no podemos llamar a weight_amended desde el where
	WHERE CAST (new_weight/100 AS DECIMAL (3,2)) <=2.5 and num_rating>5000
	),

---CTE medium difficulty
medium AS

	(SELECT 
		new_avg_rating,
		new_weight,
		CAST (new_weight/100 AS DECIMAL (3,2)) AS weight_amended

	FROM PortfolioProject.dbo.BGG_TOP_2000
	WHERE CAST (new_weight/100 AS DECIMAL (3,2)) >2.5 and CAST (new_weight/100 AS DECIMAL (3,2))<4 and num_rating>5000 
	),

---CTE hard difficulty
hard AS

	(SELECT 
		new_avg_rating,
		new_weight,
		CAST (new_weight/100 AS DECIMAL (3,2)) AS weight_amended

	FROM PortfolioProject.dbo.BGG_TOP_2000
	WHERE CAST (new_weight/100 AS DECIMAL (3,2)) >=4 and num_rating>5000
	)


SELECT 
AVG (light.new_avg_rating/1000) AS avg_light,
AVG (medium.new_avg_rating/1000) AS avg_medium,
AVG (hard.new_avg_rating/1000) AS avg_hard

FROM light, 
	medium,
	hard


--**************************************************************
--- Vamos a hacer un count de los juegos con más de 8 de rating y ver cuantos de esos juegos con más de un 8 de rtg tienen más de 10000 num_own 
---(es decir, personas que han marcado como que lo tienen en su colección).
--- Solo el 37,03% de esos juegos tienen más de 10000 num owned
--------------------
--- We are going to create a COUNT for the board games with a rating higher than 8 and check how many of them are owned by more than 10000 users.
---Only 37.03% of these games are owned by more than 10000 users.

WITH Own AS

	(SELECT 
		COUNT(new_avg_rating) AS Total_Games_8rtg_own10000
	
	FROM PortfolioProject.dbo.BGG_TOP_2000
	WHERE CAST (new_avg_rating/1000 AS DECIMAL (4,3))>8 AND num_own>10000),

NotOwn AS

	(SELECT 
		COUNT(new_avg_rating) AS Total_Games_8rtg
	
	FROM PortfolioProject.dbo.BGG_TOP_2000
	WHERE CAST (new_avg_rating/1000 AS DECIMAL (4,3))>8)

SELECT 

CONVERT (VARCHAR(20), CAST (Own.Total_Games_8rtg_own10000 AS DECIMAL (5,2)) / CAST (NotOwn.Total_Games_8rtg AS DECIMAL (5,2))*100) + '%'  
		AS Perc_Owned

FROM Own, NotOwn


--**************************************************************
--- Vamos a ver cuantos juegos hay para un máximo de 2,3,4,5,6 jugadores.
---Now we are checking how many games are in this sample for 2,3,4,5,6 players.

WITH one AS

	(SELECT

		COUNT (max_player) AS One_player

	FROM PortfolioProject.dbo.BGG_TOP_2000

	WHERE max_player = 1),

two AS

	(SELECT

		COUNT (max_player) AS Two_player

	FROM PortfolioProject.dbo.BGG_TOP_2000

	WHERE max_player = 2),


three AS

	(SELECT

		COUNT (max_player) AS Three_player

	FROM PortfolioProject.dbo.BGG_TOP_2000

	WHERE max_player = 3),


four AS

	(SELECT

		COUNT (max_player) AS Four_player

	FROM PortfolioProject.dbo.BGG_TOP_2000

	WHERE max_player = 4),


five AS

	(SELECT

		COUNT (max_player) AS Five_player

	FROM PortfolioProject.dbo.BGG_TOP_2000

	WHERE max_player = 5),


six AS

	(SELECT

		COUNT (max_player) AS Six_player

	FROM PortfolioProject.dbo.BGG_TOP_2000

	WHERE max_player = 6)


SELECT 

	one.One_player,
	two.Two_player,
	three.Three_player,
	four.Four_player,
	five.Five_player,
	six.Six_player

FROM one, 
	two,
	three,
	four,
	five,
	six


---**************************************************************
---Queremos conocer la info de los juegos con el num máximo de jugadores:
---We check now the general information for the games with the highest max_player

SELECT 
	title,
	year,
	CAST (new_avg_rating/1000 AS DECIMAL (4,3)) AS rtg,
	num_rating,
	CAST (new_std_dev_rtg/100 AS DECIMAL (3,2)) AS dev_rtg,
	CAST (new_weight/100 AS DECIMAL (3,2)) AS weight_amended,
	min_player,
	max_player,
	min_time,
	max_time,
	min_age,
	num_own,
	total_play

FROM PortfolioProject.dbo.BGG_TOP_2000

--- Ahora la Subquery para filtrar por el num máximo de jugadores:
---We include a Subquery to filter by the max_player column:
WHERE max_player=
	(SELECT
		MAX (max_player)
	FROM PortfolioProject.dbo.BGG_TOP_2000)


--**************************************************************
---Vamos a hacer particiones OVER según los años para saber cuantos juegos, rtg_avg, min y max por año.
---Primero cambiamos Year a numeric para poder ordenar correctamente por año después.
--------------------
--We are going to create OVER partitions according to the year column, to check the quantity, avg_rtg, min and max rtg they have per year.
---First we CAST Year to numeric to be able to order by year later.

SELECT 
DISTINCT CAST (YEAR AS NUMERIC) AS Year_,

--- Hacemos las particiones usando cast para poder obtener los valores correctos a decimales.
--- We create the partitions using cast to get the correct decimal values.

COUNT(*) OVER (PARTITION BY year) AS Total_Games,
CAST (AVG (new_avg_rating) OVER (PARTITION BY year)/1000 AS DECIMAL (4,3)) AS AvgRtg_PerYear,
CAST (MIN (new_avg_rating) OVER (PARTITION BY year)/1000 AS DECIMAL (4,3)) AS MinRtg_PerYear,
CAST (MAX (new_avg_rating) OVER (PARTITION BY year)/1000 AS DECIMAL (4,3)) AS MaxRtg_PerYear

FROM PortfolioProject.dbo.BGG_TOP_2000

WHERE ISNUMERIC(YEAR) = 1

ORDER BY Year_

