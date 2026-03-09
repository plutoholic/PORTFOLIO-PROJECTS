select top 10 * from PORTOFLIO..CovidDeaths order by 3,4

-- select top 10 * from PORTOFLIO..CovidVaccinations order by 3,4

--Looking at Total Cases vs Total Deaths
select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage 
from PORTOFLIO..CovidDeaths
order by 1,2


--Looking at Total Cases vs Total Deaths Per Country
--Shows likelihood of dying if you get covid in your country
select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage 
from PORTOFLIO..CovidDeaths
where location like '%states%'
order by 1,2


--Looking at Total Cases vs Total Population Per Country
SELECT location, date, total_cases, population,
-- Multiply by 1.0 to force decimal math, then CAST to remove extra decimals
CAST((total_cases*1.0/population) * 100 AS DECIMAL(18,3)) as DeathPercentage 
FROM PORTOFLIO..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


--countries had the highest percentage of their population infected.
SELECT location, population,
MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases*1.0 / population)) * 100 AS PercentPopulationInfected
FROM PORTOFLIO..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--countries with the highest total deaths.
SELECT location,
MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PORTOFLIO..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



--continents with the highest total deaths.
SELECT continent,
MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PORTOFLIO..CovidDeaths
WHERE continent IS not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Global cases and deaths
Select date, sum(new_cases) as Total_cases, sum(new_deaths) as Total_Deaths, 
cast((sum(new_deaths)*1.0/sum(new_cases))*100 as decimal(18,3)) as Death_Percentage
from PORTOFLIO..CovidDeaths
where continent is not null
group by date
order by date, Total_cases



--Looking Total People Vaccinated
with PopVac as (Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as PeopleVaccinated
from PORTOFLIO..CovidDeaths dea
join PORTOFLIO..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and dea.location like '%canada%'
--order by 2,3
)

select *, cast((PeopleVaccinated*1.0/Population)*100 as decimal (18,3)) as PercentageVaccinated from PopVac



--Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continet nvarchar(255),
Location nvarchar(255),
DAte datetime,
Population numeric,
New_vaccinations numeric,
PeopleVaccinated numeric)

insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as PeopleVaccinated
from PORTOFLIO..CovidDeaths dea
join PORTOFLIO..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date


--display temp table
Select top 10 * from #PercentPopulationVaccinated


--Creating view to store data for later visualizations
Create view PercentagePopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as PeopleVaccinated
from PORTOFLIO..CovidDeaths dea
join PORTOFLIO..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * from PercentagePopulationVaccinated