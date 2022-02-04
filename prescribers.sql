/* 1.

a. Which prescriber had the highest total number of claims (totaled over all drugs)?
Report the npi and the total number of claims. */
SELECT NPI,
	SUM(TOTAL_CLAIM_COUNT) AS TCC
FROM PRESCRIPTION
GROUP BY NPI
ORDER BY TCC DESC
LIMIT 1;

-- NPI 1881634483, 99,707 claims.
 /* b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
specialty_description, and the total number of claims. */
SELECT NPI,
	NPPES_PROVIDER_FIRST_NAME,
	NPPES_PROVIDER_LAST_ORG_NAME,
	SPECIALTY_DESCRIPTION,
	SUM(TOTAL_CLAIM_COUNT) AS TCC
FROM PRESCRIPTION
INNER JOIN PRESCRIBER USING (NPI)
GROUP BY NPI,
	NPPES_PROVIDER_FIRST_NAME,
	NPPES_PROVIDER_LAST_ORG_NAME,
	SPECIALTY_DESCRIPTION
ORDER BY TCC DESC
LIMIT 1;

-- Bruce Pendley, Family Practice
 -- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT SPECIALTY_DESCRIPTION,
	SUM(TOTAL_CLAIM_COUNT) AS TCC_BY_SPECIALTY
FROM PRESCRIPTION
INNER JOIN PRESCRIBER USING (NPI)
GROUP BY SPECIALTY_DESCRIPTION
ORDER BY TCC_BY_SPECIALTY DESC
LIMIT 1;

--Family Practice.
 -- b. Which specialty had the most total number of claims for opioids?

SELECT SPECIALTY_DESCRIPTION,
	SUM(TOTAL_CLAIM_COUNT) AS TCC_BY_SPECIALTY
FROM PRESCRIPTION
INNER JOIN PRESCRIBER USING (NPI)
WHERE PRESCRIPTION.DRUG_NAME IN
		(SELECT DRUG.DRUG_NAME
			FROM DRUG
			WHERE OPIOID_DRUG_FLAG = 'Y')
GROUP BY SPECIALTY_DESCRIPTION
ORDER BY TCC_BY_SPECIALTY DESC
LIMIT 1;

-- Nurse Practitioner
 /* c. **Challenge Question:** Are there any specialties that appear in the prescriber table that
have no associated prescriptions in the prescription table? */
SELECT DISTINCT SPECIALTY_DESCRIPTION
FROM PRESCRIBER
WHERE SPECIALTY_DESCRIPTION NOT IN
		(SELECT DISTINCT SPECIALTY_DESCRIPTION
			FROM PRESCRIBER
			WHERE NPI IN
					(SELECT NPI
						FROM PRESCRIPTION));

--Yes, there are 15 such specialties.
 /* d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!*
For each specialty, report the percentage of total claims by that specialty which are for opioids.
Which specialties have a high percentage of opioids? */
SELECT SPECIALTY_DESCRIPTION,
	ROUND(OCC_BY_SPECIALTY / TCC_BY_SPECIALTY * 1.0, 2) AS OPIOID_PERC
FROM
	(SELECT SPECIALTY_DESCRIPTION,
			SUM(TOTAL_CLAIM_COUNT) AS OCC_BY_SPECIALTY
		FROM PRESCRIPTION
		INNER JOIN PRESCRIBER USING (NPI)
		WHERE PRESCRIPTION.DRUG_NAME IN
				(SELECT DRUG.DRUG_NAME
					FROM DRUG
					WHERE OPIOID_DRUG_FLAG = 'Y' )
		GROUP BY SPECIALTY_DESCRIPTION) AS OPIOIDS
INNER JOIN
	(SELECT SPECIALTY_DESCRIPTION,
			SUM(TOTAL_CLAIM_COUNT) AS TCC_BY_SPECIALTY
		FROM PRESCRIPTION
		INNER JOIN PRESCRIBER USING (NPI)
		GROUP BY SPECIALTY_DESCRIPTION) AS ALL_DRUGS USING (SPECIALTY_DESCRIPTION)
ORDER BY OPIOID_PERC DESC;

-- Case Manager/Care Coordinator, Orthopaedic Surgery, Interventional Pain Management, Pain Management, etc.
 -- 3. a. Which drug (generic_name) had the highest total drug cost?

SELECT GENERIC_NAME,
	SUM(TOTAL_DRUG_COST) AS TDC
FROM DRUG
INNER JOIN PRESCRIPTION USING (DRUG_NAME)
WHERE TOTAL_DRUG_COST IS NOT NULL
GROUP BY GENERIC_NAME
ORDER BY TDC DESC
LIMIT 1;

-- INSULIN GLARGINE,HUM.REC.ANLOG, $104,264,066.35.
 /* b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places.
Google ROUND to see how this works. */
SELECT GENERIC_NAME,
	ROUND(SUM(TOTAL_DRUG_COST) / SUM(TOTAL_30_DAY_FILL_COUNT) / 30, 2) AS COST_PER_DAY
FROM DRUG
INNER JOIN PRESCRIPTION USING (DRUG_NAME)
GROUP BY GENERIC_NAME
ORDER BY COST_PER_DAY DESC
LIMIT 1;

--CHENODIOL	$2,891.37
 -- total 30 day supply? Maybe better.
 /* 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says
'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y',
and says 'neither' for all other drugs. */
SELECT DRUG_NAME,
	CASE WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'opioid'
	WHEN ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS DRUG_TYPE
FROM DRUG;

/* b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
Hint: Format the total costs as MONEY for easier comparision. */
SELECT DRUG_TYPE,
	SUM(TOTAL_DRUG_COST) AS CATEGORY_DRUG_COST
FROM
	(SELECT CAST(TOTAL_DRUG_COST AS MONEY) AS TOTAL_DRUG_COST,
			DRUG_NAME,
			CASE WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'opioid'
	 		WHEN ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS DRUG_TYPE
		FROM DRUG
		INNER JOIN PRESCRIPTION USING (DRUG_NAME)) AS CATEGORIES
WHERE DRUG_TYPE != 'neither'
GROUP BY DRUG_TYPE;

--More was spent on opioids.
 -- 5. a. how many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT CBSANAME)
FROM CBSA
INNER JOIN FIPS_COUNTY USING (FIPSCOUNTY)
WHERE STATE = 'TN';

--10.
 -- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT CBSANAME,
	SUM(POPULATION) AS SUM_POP
FROM CBSA
INNER JOIN FIPS_COUNTY USING (FIPSCOUNTY)
INNER JOIN POPULATION USING (FIPSCOUNTY)
GROUP BY CBSANAME
ORDER BY SUM_POP DESC
LIMIT 1;

-- Nashville is the largest at 1,830,410.

SELECT CBSANAME,
	SUM(POPULATION) AS SUM_POP
FROM CBSA
INNER JOIN FIPS_COUNTY USING (FIPSCOUNTY)
INNER JOIN POPULATION USING (FIPSCOUNTY)
GROUP BY CBSANAME
ORDER BY SUM_POP
LIMIT 1;

-- Morristown is the smallest at 116,352.
 -- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT COUNTY,
	STATE,
	POPULATION
FROM FIPS_COUNTY
INNER JOIN POPULATION USING (FIPSCOUNTY)
WHERE FIPSCOUNTY NOT IN
		(SELECT FIPSCOUNTY
			FROM CBSA)
ORDER BY POPULATION DESC;

-- Sevier County, TN with 95,523.
 -- 6. a. Find all rows in the prescription table where total_claims are at least 3000. Report the drug_name and the total_claim_count.

SELECT DRUG_NAME,
	TOTAL_CLAIM_COUNT
FROM PRESCRIPTION
WHERE TOTAL_CLAIM_COUNT >= 3000
GROUP BY DRUG_NAME;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT DRUG_NAME,
	OPIOID_DRUG_FLAG,
	TOTAL_CLAIM_COUNT
FROM PRESCRIPTION
INNER JOIN DRUG USING (DRUG_NAME)
WHERE TOTAL_CLAIM_COUNT >= 3000
GROUP BY DRUG_NAME,
	OPIOID_DRUG_FLAG;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT NPPES_PROVIDER_FIRST_NAME,
	NPPES_PROVIDER_LAST_ORG_NAME,
	DRUG_NAME,
	OPIOID_DRUG_FLAG,
	TOTAL_CLAIM_COUNT
FROM PRESCRIPTION
INNER JOIN DRUG USING (DRUG_NAME)
INNER JOIN PRESCRIBER USING (NPI)
WHERE TOTAL_CLAIM_COUNT >= 3000;

/* 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville
and the number of claims they had for each opioid. */ /* a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management')
in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
**Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables. */
SELECT PR.NPI,
	DR.DRUG_NAME
FROM PRESCRIBER AS PR
CROSS JOIN DRUG AS DR
WHERE (PR.SPECIALTY_DESCRIPTION = 'Pain Management')
	AND (PR.NPPES_PROVIDER_CITY = 'NASHVILLE')
	AND (DR.OPIOID_DRUG_FLAG = 'Y');

/* b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations,
whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count). */
SELECT SQ.NPI,
	SQ.DRUG_NAME,
	PN.TOTAL_CLAIM_COUNT
FROM
	(SELECT PR.NPI,
			DR.DRUG_NAME
		FROM PRESCRIBER AS PR
		CROSS JOIN DRUG AS DR
		WHERE (PR.SPECIALTY_DESCRIPTION = 'Pain Management')
			AND (PR.NPPES_PROVIDER_CITY = 'NASHVILLE')
			AND (DR.OPIOID_DRUG_FLAG = 'Y') ) AS SQ
LEFT JOIN PRESCRIPTION AS PN ON (SQ.NPI = PN.NPI)
AND (SQ.DRUG_NAME = PN.DRUG_NAME);

/* c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
Hint - Google the COALESCE function. */
SELECT SQ.NPI,
	SQ.DRUG_NAME,
	COALESCE(PN.TOTAL_CLAIM_COUNT, 0) AS TOTAL_CLAIM_COUNT
FROM
	(SELECT PR.NPI,
			DR.DRUG_NAME
		FROM PRESCRIBER AS PR
		CROSS JOIN DRUG AS DR
		WHERE (PR.SPECIALTY_DESCRIPTION = 'Pain Management')
			AND (PR.NPPES_PROVIDER_CITY = 'NASHVILLE')
			AND (DR.OPIOID_DRUG_FLAG = 'Y') ) AS SQ
LEFT JOIN PRESCRIPTION AS PN ON (SQ.NPI = PN.NPI)
AND (SQ.DRUG_NAME = PN.DRUG_NAME)
ORDER BY TOTAL_CLAIM_COUNT DESC;

---------------------------------------------------------------------------------------------------------------------------------
 -- PART 2
 -- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(*)
FROM
	(SELECT NPI
		FROM PRESCRIBER
		EXCEPT
			(SELECT NPI
				FROM PRESCRIPTION)) AS SQ;

--4,458 NPIs
 -- 2.
-- a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT GENERIC_NAME,
	SUM(TOTAL_CLAIM_COUNT) AS TCC
FROM PRESCRIPTION
INNER JOIN DRUG USING (DRUG_NAME)
WHERE NPI IN
		(SELECT NPI
			FROM PRESCRIBER
			WHERE SPECIALTY_DESCRIPTION = 'Family Practice' )
GROUP BY GENERIC_NAME
ORDER BY TCC DESC
LIMIT 5;

--LEVOTHYROXINE SODIUM, LISINOPRIL, ATORVASTATIN CALCIUM, AMLODIPINE BESYLATE, OMEPRAZOLE
 -- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT GENERIC_NAME,
	SUM(TOTAL_CLAIM_COUNT) AS TCC
FROM PRESCRIPTION
INNER JOIN DRUG USING (DRUG_NAME)
WHERE NPI IN
		(SELECT NPI
			FROM PRESCRIBER
			WHERE SPECIALTY_DESCRIPTION = 'Cardiology' )
GROUP BY GENERIC_NAME
ORDER BY TCC DESC
LIMIT 5;

--ATORVASTATIN CALCIUM, CARVEDILOL, METOPROLOL TARTRATE, CLOPIDOGREL BISULFATE, AMLODIPINE BESYLATE.
 /* c. Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists?
Combine what you did for parts a and b into a single query to answer this question. */ 
WITH CARDIO AS
	(SELECT GENERIC_NAME,
			SUM(TOTAL_CLAIM_COUNT) AS TCC
		FROM PRESCRIPTION
		INNER JOIN DRUG USING (DRUG_NAME)
		WHERE NPI IN
				(SELECT NPI
					FROM PRESCRIBER
					WHERE SPECIALTY_DESCRIPTION = 'Cardiology' )
		GROUP BY GENERIC_NAME
		ORDER BY TCC DESC
		LIMIT 5),
	FP AS
	(SELECT GENERIC_NAME,
			SUM(TOTAL_CLAIM_COUNT) AS TCC
		FROM PRESCRIPTION
		INNER JOIN DRUG USING (DRUG_NAME)
		WHERE NPI IN
				(SELECT NPI
					FROM PRESCRIBER
					WHERE SPECIALTY_DESCRIPTION = 'Family Practice' )
		GROUP BY GENERIC_NAME
		ORDER BY TCC DESC
		LIMIT 5)
SELECT GENERIC_NAME
FROM FP
INNER JOIN CARDIO USING (GENERIC_NAME);

--ATORVASTATIN CALCIUM, AMLODIPINE BESYLATE
 -- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
/* a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count)
across all drugs. Report the npi, the total number of claims, and include a column showing the city. */
SELECT NPI,
	NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TCC
FROM PRESCRIPTION
INNER JOIN PRESCRIBER USING (NPI)
WHERE NPPES_PROVIDER_CITY ILIKE 'Nashville'
GROUP BY NPI,
	NPPES_PROVIDER_CITY
ORDER BY TCC DESC
LIMIT 5;

--1538103692, 1497893556, 1659331924, 1881638971, 1962499582
 -- b. Now, report the same for Memphis.

SELECT NPI,
	NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TCC
FROM PRESCRIPTION
INNER JOIN PRESCRIBER USING (NPI)
WHERE NPPES_PROVIDER_CITY ILIKE 'Memphis'
GROUP BY NPI,
	NPPES_PROVIDER_CITY
ORDER BY TCC DESC
LIMIT 5;

--1346291432, 1225056872, 1801896881, 1669470316, 1275601346
 -- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

	(SELECT NPI,
			NPPES_PROVIDER_CITY,
			SUM(TOTAL_CLAIM_COUNT) AS TCC
		FROM PRESCRIPTION
		INNER JOIN PRESCRIBER USING (NPI)
		WHERE NPPES_PROVIDER_CITY ILIKE 'Nashville'
		GROUP BY NPI,
			NPPES_PROVIDER_CITY
		ORDER BY TCC DESC
		LIMIT 5)
UNION
	(SELECT NPI,
			NPPES_PROVIDER_CITY,
			SUM(TOTAL_CLAIM_COUNT) AS TCC
		FROM PRESCRIPTION
		INNER JOIN PRESCRIBER USING (NPI)
		WHERE NPPES_PROVIDER_CITY ILIKE 'Memphis'
		GROUP BY NPI,
			NPPES_PROVIDER_CITY
		ORDER BY TCC DESC
		LIMIT 5)
UNION
	(SELECT NPI,
			NPPES_PROVIDER_CITY,
			SUM(TOTAL_CLAIM_COUNT) AS TCC
		FROM PRESCRIPTION
		INNER JOIN PRESCRIBER USING (NPI)
		WHERE NPPES_PROVIDER_CITY ILIKE 'Knoxville'
		GROUP BY NPI,
			NPPES_PROVIDER_CITY
		ORDER BY TCC DESC
		LIMIT 5)
UNION
	(SELECT NPI,
			NPPES_PROVIDER_CITY,
			SUM(TOTAL_CLAIM_COUNT) AS TCC
		FROM PRESCRIPTION
		INNER JOIN PRESCRIBER USING (NPI)
		WHERE NPPES_PROVIDER_CITY ILIKE 'Chattanooga'
		GROUP BY NPI,
			NPPES_PROVIDER_CITY
		ORDER BY TCC DESC
		LIMIT 5);

/* 4. Find all counties which had an above-average (for the state) number of overdose deaths in 2017.
Report the county name and number of overdose deaths. */
SELECT DISTINCT COUNTY,
	OVERDOSE_DEATHS
FROM FIPS_COUNTY
INNER JOIN OVERDOSE_DEATHS USING (FIPSCOUNTY)
WHERE STATE ILIKE 'TN'
	AND OVERDOSE_DEATHS >=
		(SELECT AVG(OVERDOSE_DEATHS)
			FROM OVERDOSE_DEATHS
			WHERE YEAR = 2017)
	AND YEAR = 2017;

-- 5.
-- a. Write a query that finds the total population of Tennessee.

SELECT SUM(POPULATION) AS TN_POP
FROM POPULATION
WHERE FIPSCOUNTY IN
		(SELECT FIPSCOUNTY
			FROM FIPS_COUNTY
			WHERE STATE = 'TN' );
--6,597,381.

 /* b. Build off of the query that you wrote in part a to write a query that returns for each
county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county. */ 
WITH TN_POPULATION AS (
	SELECT SUM(POPULATION) AS TN_POP 
	FROM POPULATION 
	WHERE FIPSCOUNTY IN 
				(SELECT FIPSCOUNTY 
				 FROM FIPS_COUNTY
				 WHERE STATE = 'TN')
)
SELECT 
	COUNTY, 
	POPULATION, 
	ROUND(POPULATION / (SELECT TN_POP FROM TN_POPULATION) * 100.0, 2) AS TN_POP_PERC
FROM FIPS_COUNTY
INNER JOIN POPULATION USING (FIPSCOUNTY) 
WHERE STATE = 'TN';

------------------------------------------------------------------------------------------------------------------------------------
 --BONUS QUESTIONS
 -- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres.
 /* For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management
Specialists compared to those from Pain Managment specialists. */ 

/* 1. Write a query which returns the total number of claims for these two groups. Your output should look like this:

| specialty_description          | total_claims |
| ------------------------------ | ------------ |
| Interventional Pain Management | 55906        |
| Pain Management                | 70853        |

*/

SELECT 
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
WHERE specialty_description = 'Interventional Pain Management'
OR specialty_description = 'Pain Management'
GROUP BY specialty_description;

/* 2. Now, let's say that we want our output to also include the total number of claims between these two groups. 
Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

| specialty_description | total_claims |
| --------------------- | ------------ |

                              |      126759|

Interventional Pain Management|       55906|
Pain Management               |       70853|
*/


WITH primary_query AS (
	SELECT 
		specialty_description, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING (npi)
	WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
	GROUP BY specialty_description
	)
SELECT *
FROM primary_query
UNION
(SELECT 
	'' AS specialty_description,
	SUM(total_claims) AS total_claims
FROM primary_query)
ORDER BY total_claims DESC;


/* 3. Now, instead of using UNION, make use of GROUPING SETS 
(https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output. */ 

WITH primary_query AS (
	SELECT 
		specialty_description, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING (npi)
	WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
	GROUP BY specialty_description
	)
SELECT specialty_description, SUM(total_claims) AS sum_claims
FROM primary_query
GROUP BY GROUPING SETS ((specialty_description), ())
ORDER BY sum_claims DESC;

/* 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information
about the number of opioid vs. non-opioid claims by these two specialties. Modify your query
(still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs.
non-opioid claims by these two specialites:

| specialty_description | opioid_drug_flag | total_claims |
| --------------------- | ---------------- | ------------ |

                              |                |      129726|
                              |Y               |       76143|
                              |N               |       53583|

Pain Management               |                |       72487|
Interventional Pain Management|                |       57239|
*/

WITH primary_query AS (
	SELECT
		opioid_drug_flag,
		specialty_description, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING (npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
	GROUP BY specialty_description, opioid_drug_flag
)

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claims) AS total_claims
FROM primary_query
GROUP BY GROUPING SETS ((specialty_description), (opioid_drug_flag), ())
ORDER BY specialty_description DESC, opioid_drug_flag DESC, total_claims DESC;

/* 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description).
How is the result different from the output from the previous query? 
--Breaks sums down by opioid_drug_flag and each specialty_description with each opioid_drug_flag.-- */ 

WITH primary_query AS (
	SELECT
		opioid_drug_flag,
		specialty_description, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING (npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
	GROUP BY specialty_description, opioid_drug_flag
)

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claims) AS total_claims
FROM primary_query
GROUP BY ROLLUP(opioid_drug_flag, specialty_description)
ORDER BY total_claims DESC, opioid_drug_flag DESC, specialty_description DESC;

/* 6. Switch the order of the variables inside the ROLLUP.
That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result? 
--Breaks sums down by each specialty_description and each opioid_drug_flag by each specialty_description. */ 

WITH primary_query AS (
	SELECT
		opioid_drug_flag,
		specialty_description, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING (npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
	GROUP BY specialty_description, opioid_drug_flag
)

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claims) AS total_claims
FROM primary_query
GROUP BY ROLLUP(specialty_description, opioid_drug_flag)
ORDER BY total_claims DESC, opioid_drug_flag DESC, specialty_description DESC;


-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?
--Provides every single sum for each combination or non-combination of specialty_description and opioid_drug_flag.


WITH primary_query AS (
	SELECT
		opioid_drug_flag,
		specialty_description, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING (npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
	GROUP BY specialty_description, opioid_drug_flag
)

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claims) AS total_claims
FROM primary_query
GROUP BY CUBE(specialty_description, opioid_drug_flag)
ORDER BY specialty_description DESC, opioid_drug_flag DESC, total_claims DESC;

 /* 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee
(Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids:
Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question,
we will put a drug into one of the six listed categories if it has the category name as part of its generic name.
For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the
purposes of this question.

The end result of this question should be a table formatted like this:

| city        | codeine | fentanyl | hyrdocodone | morphine | oxycodone | oxymorphone |
| ----------- | ------- | -------- | ----------- | -------- | --------- | ----------- |
| CHATTANOOGA | 1323    | 3689     | 68315       | 12126    | 49519     | 1317        |
| KNOXVILLE   | 2744    | 4811     | 78529       | 20946    | 84730     | 9186        |
| MEMPHIS     | 4697    | 3666     | 68036       | 4898     | 38295     | 189         |
| NASHVILLE   | 2043    | 6119     | 88669       | 13572    | 62859     | 1261        |

For this question, you should look into use the crosstab function, which is part of the tablefunc extension 
(https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
CREATE EXTENSION tablefunc;

Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
*/ 
--CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT 
	drug_name,
	new_name
FROM
	(
		SELECT 
			drug_name,
			generic_name,
			CASE WHEN generic_name ILIKE '%CODEINE%' THEN 'codeine'
			WHEN generic_name ILIKE '%FENTANYL%' THEN 'fentanyl'
			WHEN generic_name ILIKE '%HYDROCODONE%' THEN 'hydrocodone'
			WHEN generic_name ILIKE '%MORPHINE%' THEN 'morphine'
			WHEN generic_name ILIKE '%OXYCODONE%' THEN 'oxycodone'
			WHEN generic_name ILIKE '%OXYMORPHONE%' THEN 'oxymorphone'
			END AS new_name
		FROM drug
		WHERE opioid_drug_flag = 'Y'
	) AS sq
WHERE new_name IS NOT NULL;


/* 
Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column,
one category column, and one value column. So in this case, you need to have a city column, a drug label column, and
a total claim count column.
*/
WITH new_drug_names AS (
	SELECT 
		drug_name,
		new_name
	FROM
		(
			SELECT 
				drug_name,
				CASE WHEN generic_name ILIKE '%CODEINE%' THEN 'codeine'
				WHEN generic_name ILIKE '%FENTANYL%' THEN 'fentanyl'
				WHEN generic_name ILIKE '%HYDROCODONE%' THEN 'hydrocodone'
				WHEN generic_name ILIKE '%MORPHINE%' THEN 'morphine'
				WHEN generic_name ILIKE '%OXYCODONE%' THEN 'oxycodone'
				WHEN generic_name ILIKE '%OXYMORPHONE%' THEN 'oxymorphone'
				END AS new_name
			FROM drug
			WHERE opioid_drug_flag = 'Y'
		) AS sq
	WHERE new_name IS NOT NULL
)

SELECT 
	nppes_provider_city,
	new_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN new_drug_names
USING (drug_name)
WHERE nppes_provider_city IN ('NASHVILLE',
							  'MEMPHIS',
							  'CHATTANOOGA',
							  'KNOXVILLE')
GROUP BY nppes_provider_city, new_name
ORDER BY nppes_provider_city, new_name;

--Need to understand why Morphine is different.

/* 
Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes.
If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.
*/

SELECT *
FROM 
CROSSTAB(
'SELECT 
	nppes_provider_city,
	new_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN 
	(
	SELECT 
		drug_name,
		new_name
	FROM
		(
			SELECT 
				drug_name,
				CASE WHEN generic_name ILIKE ''%CODEINE%'' THEN ''codeine''
				WHEN generic_name ILIKE ''%FENTANYL%'' THEN ''fentanyl''
				WHEN generic_name ILIKE ''%HYDROCODONE%'' THEN ''hydrocodone''
				WHEN generic_name ILIKE ''%MORPHINE%'' THEN ''morphine''
				WHEN generic_name ILIKE ''%OXYCODONE%'' THEN ''oxycodone''
				WHEN generic_name ILIKE ''%OXYMORPHONE%'' THEN ''oxymorphone''
				END AS new_name
			FROM drug
			WHERE opioid_drug_flag = ''Y''
		) AS sq
	WHERE new_name IS NOT NULL
) AS new_drug_names
USING (drug_name)
WHERE nppes_provider_city IN (''NASHVILLE'',
							  ''MEMPHIS'',
							  ''CHATTANOOGA'',
							  ''KNOXVILLE'')
GROUP BY nppes_provider_city, new_name
ORDER BY nppes_provider_city, new_name')
AS ct (
	"city" text,
	"codeine" numeric,
	"fentanyl" numeric,
	"hyrdocodone" numeric,
	"morphine" numeric,
	"oxycodone" numeric,
	"oxymorphone" numeric
);




