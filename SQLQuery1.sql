/* ============================================================
   COVID-19 DATA EXPLORATION PROJECT
   Dataset: CovidDeaths & CovidVaccinations
   Database: PORTFOLIO

   This project analyzes:
   - Infection rates
   - Death percentages
   - Population infection percentages
   - Global statistics
   - Vaccination progress
============================================================ */


/* ============================================================
   Preview Dataset
============================================================ */

-- Preview first 10 rows of CovidDeaths table
SELECT TOP 10 *
FROM PORTFOLIO..CovidDeaths
ORDER BY 3,4;

-- Preview first 10 rows of CovidVaccinations table
-- SELECT TOP 10 *
-- FROM PORTFOLIO..CovidVaccinations
-- ORDER BY 3,4;



/* ============================================================
   Total Cases vs Total Deaths
   Shows likelihood of dying if infected with COVID
============================================================ */

SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths * 1.0 / total_cases) * 100 AS DeathPercentage
FROM PORTFOLIO..CovidDeaths
ORDER BY location, date;



/* ============================================================
   Total Cases vs Total Deaths (United States Example)
   Shows death percentage for a specific country
============================================================ */

SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths * 1.0 / total_cases) * 100 AS DeathPercentage
FROM PORTFOLIO..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY location, date;



/* ============================================================
   Total Cases vs Population
   Shows percentage of population infected
============================================================ */

SELECT 
    location,
    date,
    total_cases,
    population,
    CAST((total_cases * 1.0 / population) * 100 AS DECIMAL(18,3)) 
        AS PercentPopulationInfected
FROM PORTFOLIO..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY location, date;



/* ============================================================
   Countries with Highest Infection Rate
============================================================ */

SELECT 
    location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    CAST(MAX(total_cases * 1.0 / population) * 100 AS DECIMAL(18,5)) 
        AS PercentPopulationInfected
FROM PORTFOLIO..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;



/* ============================================================
   Countries with Highest Infection Rate by Date
============================================================ */

SELECT 
    location,
    date,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    CAST(MAX(total_cases * 1.0 / population) * 100 AS DECIMAL(18,5)) 
        AS PercentPopulationInfected
FROM PORTFOLIO..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC;



/* ============================================================
   Countries with Highest Total Deaths
============================================================ */

SELECT 
    location,
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PORTFOLIO..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;



/* ============================================================
   Continents with Highest Total Deaths
============================================================ */

SELECT 
    continent,
    SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PORTFOLIO..CovidDeaths
WHERE continent IS NOT NULL
AND location NOT IN ('World','European Union','International')
GROUP BY continent
ORDER BY TotalDeathCount DESC;



/* ============================================================
   Confirm Continent Death Totals
   Aggregates deaths per country first, then continent
============================================================ */

SELECT 
    continent,
    SUM(MaxDeaths) AS TotalDeaths
FROM
(
    SELECT 
        continent,
        location,
        MAX(total_deaths) AS MaxDeaths
    FROM PORTFOLIO..CovidDeaths
    WHERE continent IS NOT NULL
    AND location NOT IN ('World','European Union','International')
    GROUP BY continent, location
) AS DeathsByCountry
GROUP BY continent
ORDER BY TotalDeaths DESC;



/* ============================================================
   Global Cases and Deaths by Date
============================================================ */

SELECT 
    date,
    SUM(new_cases) AS TotalCases,
    SUM(new_deaths) AS TotalDeaths,
    CAST((SUM(new_deaths) * 1.0 / SUM(new_cases)) * 100 
        AS DECIMAL(18,3)) AS DeathPercentage
FROM PORTFOLIO..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;



/* ============================================================
   Total Global Cases and Deaths
============================================================ */

SELECT 
    SUM(new_cases) AS TotalCases,
    SUM(new_deaths) AS TotalDeaths,
    CAST((SUM(new_deaths) * 1.0 / SUM(new_cases)) * 100 
        AS DECIMAL(18,3)) AS DeathPercentage
FROM PORTFOLIO..CovidDeaths
WHERE continent IS NOT NULL;



/* ============================================================
   Vaccination Progress (CTE)
   Calculates cumulative vaccinations by location
============================================================ */

WITH PopVac AS
(
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,

        SUM(vac.new_vaccinations) 
        OVER (PARTITION BY dea.location 
        ORDER BY dea.location, dea.date) AS PeopleVaccinated

    FROM PORTFOLIO..CovidDeaths dea

    JOIN PORTFOLIO..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date

    WHERE dea.continent IS NOT NULL
)

SELECT *,
CAST((PeopleVaccinated * 1.0 / Population) * 100 AS DECIMAL(18,3)) 
AS PercentageVaccinated
FROM PopVac;



/* ============================================================
   Temporary Table for Vaccination Analysis
============================================================ */

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    PeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated

SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,

    SUM(vac.new_vaccinations)
    OVER (PARTITION BY dea.location 
    ORDER BY dea.location, dea.date) AS PeopleVaccinated

FROM PORTFOLIO..CovidDeaths dea

JOIN PORTFOLIO..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;



-- Preview temporary table
SELECT TOP 10 *
FROM #PercentPopulationVaccinated;



/* ============================================================
   Create View for Visualization (Power BI / Tableau)
============================================================ */

CREATE VIEW PercentagePopulationVaccinated AS

SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,

    SUM(vac.new_vaccinations)
    OVER (PARTITION BY dea.location 
    ORDER BY dea.location, dea.date) AS PeopleVaccinated

FROM PORTFOLIO..CovidDeaths dea

JOIN PORTFOLIO..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL;



-- Query the view
SELECT *
FROM PercentagePopulationVaccinated;
