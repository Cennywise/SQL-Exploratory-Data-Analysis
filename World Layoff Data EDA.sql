# World Layoffs Dataset
SELECT *
FROM world_layoffs.layoffs_staging2;

# Date range of this layoff data
SELECT MIN(`date`), MAX(`date`)
FROM world_layoffs.layoffs_staging2;

# Largest layoff
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;
# FInd the entry of the largest layoff
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off = 12000;

# Total layoffs of each company
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY SUM(total_laid_off) DESC;

# Largest layoff by percentage of the company
SELECT MAX(percentage_laid_off)
FROM world_layoffs.layoffs_staging2;

# Calculate size of each company at time of layoff
SELECT company, total_laid_off, percentage_laid_off, ROUND(total_laid_off / percentage_laid_off) AS company_size
FROM world_layoffs.layoffs_staging2
ORDER BY company_size DESC;
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off = 8000;

# Companies that laid off all employees ordered by the amount of funds each raised
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

# Which stages of companies had the largest layoffs
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

# Layoffs by Month
# Total layoffs of all companies in each month of the year
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;
# Total layoffs in each month with the rolling total included
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS sum_tlo
FROM world_layoffs.layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC
)
SELECT `month`, sum_tlo, SUM(sum_tlo) OVER(ORDER BY `month`) AS rolling_total
FROM Rolling_Total;

# Layoffs by Year
# Companies ranked by total layoffs in a single year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY SUM(total_laid_off) DESC;
# Top 5 biggest layoffers of each year
WITH Company_Year (company, years, sum_tlo) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
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