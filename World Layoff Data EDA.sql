# DATA CLEANING
# Uncleaned Dataset
SELECT *
FROM world_layoffs.layoffs;

#1. Create Staging Dataset
CREATE TABLE world_layoffs.layoffs_staging
(
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# Insert data
INSERT INTO world_layoffs.layoffs_staging
# A row_num column is added to easily detect duplicates
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs;



#2. Delete Duplicates
DELETE
FROM world_layoffs.layoffs_staging
WHERE row_num > 1;

# Drop row_num since it's no longer needed
ALTER TABLE world_layoffs.layoffs_staging
DROP COLUMN row_num;

#3. Standardize Data
# company: Trim whitespace
# Find entries with unnecessary whitespace
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company != TRIM(company);

# Compare untrimmed with trimmed
SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging
WHERE company != TRIM(company);

UPDATE world_layoffs.layoffs_staging
SET company = TRIM(company);

# industry: Standardize crypto variants
# Look for redundant industries
SELECT DISTINCT(industry)
FROM world_layoffs.layoffs_staging
ORDER BY industry;

# Find crypto variants
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry LIKE 'Crypto%' AND industry != 'Crypto';

# Rename redundant crypto industries
UPDATE world_layoffs.layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

# location: Location is fine
SELECT DISTINCT(location)
FROM world_layoffs.layoffs_staging
ORDER BY 1;

# country: Standardize variations of United States
# Look for redundant countries
SELECT DISTINCT(country)
FROM world_layoffs.layoffs_staging
ORDER BY 1;

# Find variations of United States
SELECT *
FROM world_layoffs.layoffs_staging
WHERE country LIKE 'United States%' AND country != 'United States';

# Standardize United States entries
UPDATE world_layoffs.layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

# date: Convert strings dates to DATE objects
# Compare formats
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM world_layoffs.layoffs_staging;

# Modify format of date entries
UPDATE world_layoffs.layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

# Convert date entries to DATE objects
ALTER TABLE world_layoffs.layoffs_staging
MODIFY COLUMN `date` DATE;



# 4. Address Blank and Null Values
# Some companies have multiple entries. Some entries may be are missing the industry data while others have it.
# If at least one entry from a company has the industry data, the other entries with an empty industry can be filled in.

# Find entries without industry data
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry IS NULL OR TRIM(industry) = '';

# Standardize data by converting whitespace to NULL
UPDATE world_layoffs.layoffs_staging
SET industry = NULL
WHERE TRIM(industry) = '';

# Self-join the table on company.
# This will have the effect of pairing entries within a company that don't have industry data to entries that does have the data.
# When such a pairings happen, the industry data is copied into the empty entry.
UPDATE world_layoffs.layoffs_staging t1 JOIN world_layoffs.layoffs_staging t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

# The only entry this doesn't work for is Bally's Intereactive since that company only has one entry.
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = "Bally's Interactive";



# 5. Remove Unnecessary Rows and Columns
# Find entries with no layoff data
SELECT *
FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL and percentage_laid_off IS NULL;

# Delete those entries
DELETE
FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL and percentage_laid_off IS NULL;

# Cleaned Dataset
SELECT *
FROM world_layoffs.layoffs_staging;





# EPLORATORY DATA ANALYSIS
# Date range of this layoff data
SELECT MIN(`date`), MAX(`date`)
FROM world_layoffs.layoffs_staging;

# Largest layoff
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging;
# FInd the entry of the largest layoff
SELECT *
FROM world_layoffs.layoffs_staging
WHERE total_laid_off = 12000;

# Total layoffs of each company
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging
GROUP BY company
ORDER BY SUM(total_laid_off) DESC;

# Largest layoff by percentage of the company
SELECT MAX(percentage_laid_off)
FROM world_layoffs.layoffs_staging;

# Calculate size of each company at time of layoff
SELECT company, total_laid_off, percentage_laid_off, ROUND(total_laid_off / percentage_laid_off) AS company_size
FROM world_layoffs.layoffs_staging
ORDER BY company_size DESC;
SELECT *
FROM world_layoffs.layoffs_staging
WHERE total_laid_off = 8000;

# Companies that laid off all employees ordered by the amount of funds each raised
SELECT *
FROM world_layoffs.layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

# Which stages of companies had the largest layoffs
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging
GROUP BY stage
ORDER BY 2 DESC;

# Layoffs by Month
# Total layoffs of all companies in each month of the year
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;
# Total layoffs in each month with the rolling total included
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS sum_tlo
FROM world_layoffs.layoffs_staging
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC
)
SELECT `month`, sum_tlo, SUM(sum_tlo) OVER(ORDER BY `month`) AS rolling_total
FROM Rolling_Total;

# Layoffs by Year
# Companies ranked by total layoffs in a single year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging
GROUP BY company, YEAR(`date`)
ORDER BY SUM(total_laid_off) DESC;
# Top 5 biggest layoffers of each year
WITH Company_Year (company, years, sum_tlo) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging
GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS #Table to create the Ranking column
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY sum_tlo DESC) AS Ranking #Arranges entires by year and orders by biggest layoffs
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;