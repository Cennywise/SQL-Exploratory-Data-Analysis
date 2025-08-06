# World Layoffs Exploratory Data Analysis

This SQL analysis explores layoff data across the world from March of 2020 to March of 2023. The first half of the script cleans the dataset. I first copied the dataset into a new table to avoid altering the original data. This gave me the opportunity to add an additional column which marked duplicate entries. I deleted any duplicate entries as well as any entries missing essential data.

The most important columns of the table were total_laid_off and percentage_laid_off. When both those values were missing, the entire row was unusable because I didn't know if a layoff had actually happened. So, any rows missing both total_laid_off and percentage_laid_off were deleted.

I standardized the data by trimming whitespace, changing the date column from string to DATE objects, and removing variants within the industry column. For example, the industry column contained both "Crypto" and "Crypto Currency" which should be the same industry, so "Crypto Currency" was changed to "Crypto".

I addressed the blank and NULL values by first standardizing them; any blank strings were changed to NULL values. Then I filled the NULL data where possible. For entries missing an industry, I was generally able to find another entry from the same company that did have the industry data, so I was able to use that to fill in most of the NULL industry data.

These are the results of my exploratory data analysis. The single largest layoff was January 20, 2023 when Google laid off 12,000 employees. In total, Amazon had the most layoffs at 18,150, which makes sense because Amazon also employs more than any other company. For example, on January 4, 2023, it laid off 8000 employees, and that was only 2% of its company.

The highest percent of itself that any company laid off was 100%. This is obvious when you realize that any company going out of business lays off 100% of its employees. The wealthiest company to lay off all its employees was Britishvolt, which had raised $2.4 billion before going under.

While small companies are more likely to go out of business, it is big companies that are responsible for the most layoffs since they have more employees to potentially be laid off. Companies in the Post-IPO stage were responsible for 204,132 layoffs, which was more than the combined layoffs of the companies in every other stage. Those 204,132 layoffs are 53% of the total layoffs in this dataset. The grand total of all layoffs is 383,159.

Finally, I isolated the top 5 companies with the most layoffs for each year from 2020 to 2023, and the resultant table is shown below.

![Top 5 Graph](Biggest_Layoffs.png)
