/* 1. 

a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
Report the npi and the total number of claims. */

SELECT npi, total_claim_count
FROM prescription
ORDER BY total_claim_count DESC
LIMIT 1;
-- NPI 1912011792, 4,538 claims.

/* b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, 
specialty_description, and the total number of claims. */

SELECT 
	npi, 
	nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description,
	total_claim_count
FROM prescription
INNER JOIN prescriber
USING (npi)
ORDER BY total_claim_count DESC
LIMIT 1;
-- David Coffey, Family Practice

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT  
	specialty_description,
	SUM(total_claim_count) AS tcc_by_specialty
FROM prescription
INNER JOIN prescriber
USING (npi)
GROUP BY specialty_description
ORDER BY tcc_by_specialty DESC
LIMIT 1;
--Family Practice.

-- b. Which specialty had the most total number of claims for opioids?

SELECT  
	specialty_description,
	SUM(total_claim_count) AS tcc_by_specialty
FROM prescription
INNER JOIN prescriber
USING (npi)
WHERE prescription.drug_name IN
	(
		SELECT drug.drug_name
		FROM drug
		WHERE opioid_drug_flag = 'Y'
	)
GROUP BY specialty_description
ORDER BY tcc_by_specialty DESC
LIMIT 1;
-- Nurse Practitioner 

/* c. **Challenge Question:** Are there any specialties that appear in the prescriber table that 
have no associated prescriptions in the prescription table? */

SELECT DISTINCT specialty_description
FROM prescriber
WHERE specialty_description NOT IN
	(
		SELECT DISTINCT specialty_description
		FROM prescriber
		WHERE npi IN (SELECT npi FROM prescription)
	);
--Yes, there are 15 such specialties.

/* d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
For each specialty, report the percentage of total claims by that specialty which are for opioids. 
Which specialties have a high percentage of opioids? */

SELECT 
	specialty_description, 
	ROUND(occ_by_specialty / tcc_by_specialty * 1.0, 2) AS opioid_perc
FROM
	(
		SELECT
			specialty_description,
			SUM(total_claim_count) AS occ_by_specialty
		FROM prescription
		INNER JOIN prescriber
		USING (npi)
		WHERE prescription.drug_name IN
			(
				SELECT drug.drug_name
				FROM drug
				WHERE opioid_drug_flag = 'Y'
			)
		GROUP BY specialty_description
	) AS opioids
	INNER JOIN
	(
		SELECT
			specialty_description,
			SUM(total_claim_count) AS tcc_by_specialty
		FROM prescription
		INNER JOIN prescriber
		USING (npi)
		GROUP BY specialty_description
	) AS non_opioids
USING (specialty_description)
ORDER BY opioid_perc DESC;
-- Case Manager/Care Coordinator, Orthopaedic Surgery, Interventional Pain Management, Pain Management, etc.

-- 3. a. Which drug (generic_name) had the highest total drug cost?

SELECT 
	generic_name, 
	total_drug_cost
FROM drug
INNER JOIN prescription
USING (drug_name)
WHERE total_drug_cost IS NOT NULL
ORDER BY total_drug_cost DESC
LIMIT 1;
-- Pirfenidone.

/* b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. 
Google ROUND to see how this works. */

SELECT 
	generic_name, 
	ROUND(total_drug_cost / total_30_day_fill_count / 30, 2) AS cost_per_day
FROM drug
INNER JOIN prescription
USING (drug_name)
ORDER BY cost_per_day DESC
LIMIT 1;
--Asfotase Alfa ###Double-check this one.###

/* 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 
'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
and says 'neither' for all other drugs. */

SELECT 
	drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;

/* b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
Hint: Format the total costs as MONEY for easier comparision. */

SELECT 
	drug_type, 
	SUM(total_drug_cost) AS category_drug_cost
FROM
	(
		SELECT 
			CAST(total_drug_cost AS MONEY) AS total_drug_cost,
			drug_name,
			CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
				WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
				ELSE 'neither' END AS drug_type
		FROM drug
		INNER JOIN prescription
		USING (drug_name)
	) AS categories
WHERE drug_type != 'neither'
GROUP BY drug_type;
--More was spent on opioids.

-- 5. a. how many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN';
--10.

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS sum_pop
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY sum_pop DESC
LIMIT 1;
-- Nashville is the largest at 1,830,410.

SELECT cbsaname, SUM(population) AS sum_pop
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY sum_pop
LIMIT 1;
-- Morristown is the smallest at 116,352.

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, state, population
FROM fips_county
INNER JOIN population
USING (fipscounty)
WHERE fipscounty NOT IN 
	(
		SELECT fipscounty
		FROM cbsa
	)
order by population DESC;
-- Sevier County, TN with 95,523.

-- 6. a. Find all rows in the prescription table where total_claims are at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, SUM(total_claim_count)
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, opioid_drug_flag, SUM(total_claim_count)
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000
GROUP BY drug_name, opioid_drug_flag;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	drug_name, 
	opioid_drug_flag, 
	total_claim_count
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count >= 3000;

/* 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
and the number of claims they had for each opioid. */

/* a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') 
in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
**Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables. */
	
SELECT pr.npi, dr.drug_name
FROM prescriber AS pr
CROSS JOIN drug AS dr
WHERE (pr.specialty_description = 'Pain Management')
AND (pr.nppes_provider_city = 'NASHVILLE')
AND (dr.opioid_drug_flag = 'Y');
 
/* b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count). */

SELECT sq.npi, sq.drug_name, pn.total_claim_count
FROM 
	(
		SELECT pr.npi, dr.drug_name
		FROM prescriber AS pr
		CROSS JOIN drug AS dr
		WHERE (pr.specialty_description = 'Pain Management')
		AND (pr.nppes_provider_city = 'NASHVILLE')
		AND (dr.opioid_drug_flag = 'Y')
	) AS sq
LEFT JOIN prescription AS pn
ON (sq.npi = pn.npi) 
AND (sq.drug_name = pn.drug_name);

/* c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
Hint - Google the COALESCE function. */

SELECT 
	sq.npi, 
	sq.drug_name, 
	COALESCE(pn.total_claim_count, 0) AS total_claim_count
FROM 
	(
		SELECT pr.npi, dr.drug_name
		FROM prescriber AS pr
		CROSS JOIN drug AS dr
		WHERE (pr.specialty_description = 'Pain Management')
		AND (pr.nppes_provider_city = 'NASHVILLE')
		AND (dr.opioid_drug_flag = 'Y')
	) AS sq
LEFT JOIN prescription AS pn
ON (sq.npi = pn.npi) 
AND (sq.drug_name = pn.drug_name)
ORDER BY total_claim_count DESC;