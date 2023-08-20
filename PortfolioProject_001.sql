USE PortfolioProject
SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

--SELECT *
--FROM PortfolioProject..CovidVacinations
--ORDER BY 3, 4

-- SELECT data that we are going to using

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1, 2

-- Looking at the Total Cases versus Total Deaths
-- Shows how likely of dying if contract covid per country
SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS PercentDeaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at the Total Cases versus the Population 
-- Shows the running rate of infection
SELECT Location, Date, total_cases, population, (total_cases/population)*100 AS InfectionRate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 1, 2

-- Percentage of population thats been infected
SELECT Location, SUM(new_cases) AS AllCases, population, ROUND((SUM(new_cases)/population*100), 2) AS PercentInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL -- remove World, Asia etc as groupings don't have a continent
GROUP BY location, population
ORDER BY 4 DESC
-- Alternative
SELECT Location, MAX(total_cases) AS AllCases, population, ROUND((MAX(total_cases)/population*100), 2) AS PercentInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL -- remove World, Asia etc as groupings don't have a continent
GROUP BY location, population
ORDER BY PercentInfected DESC

-- How many people actually died in each country
SELECT Location, MAX(CAST(total_deaths AS int)) AS AllDeaths -- total_deaths is of data type nvarcahr
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL -- remove World, Asia etc as groupings don't have a continent
GROUP BY location, population
ORDER BY AllDeaths DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT

SELECT continent, MAX(CAST(total_deaths AS int)) AS AllDeaths -- total_deaths is of data type nvarcahr
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL -- remove World, Asia etc as groupings don't have a continent
GROUP BY continent
ORDER BY AllDeaths DESC

-- This is better as the last one missed Canada in North america etc.
-- Showing the Continent with highest death count
SELECT location AS Continent, MAX(CAST(total_deaths AS int)) AS AllDeaths -- total_deaths is of data type nvarcahr
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY AllDeaths DESC

-- GLOBAL NUMBERS

-- New cases and new deaths daily
SELECT Date, SUM(new_cases) AS NewCases, SUM(CAST(new_deaths AS INT)) AS NewDeaths, ROUND((SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100), 2) AS DailyPercentDead
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL -- remove the data set aggregates like World, Asia, etc
GROUP BY date
ORDER BY 1, 2 

-- Total number of new cases, new deaths and the % deaths to new cases

SELECT SUM(new_cases) AS NewCases, SUM(CAST(new_deaths AS INT)) AS NewDeaths, ROUND((SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100), 2) AS DailyPercentDead
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL -- remove the data set aggregates like World, Asia, etc

-- Looking at total population versus vaciantions

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
-- PARTITION BY gives us the running total
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
--, (RollingVaccinations/population)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
 ON dea.location = vac.location
 AND dea.date= vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- USE CTE
-- specify what you want. Number of columns in the CTE has to be the same as the number in the CTE
WITH CTE_PopVsVac (Continent, Location, Date, Population, new_vacination, RollingVaccinations) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
-- PARTITION BY gives us the running total
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
 ON dea.location = vac.location
 AND dea.date= vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingVaccinations/Population)*100
FROM CTE_PopVsVac
ORDER By 2, 3

-- USE a TEMP TABLE as an alternative

DROP TABLE IF EXISTS #PercentPpoluationVaccinated -- always add this for temp tables
CREATE TABLE #PercentPpoluationVaccinated
(
Continent nvarchar(255)
, Location nvarchar(255)
, Date datetime
, Population numeric
, New_Vaccinations numeric
, RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPpoluationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
-- PARTITION BY gives us the running total
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
 ON dea.location = vac.location
 AND dea.date= vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPpoluationVaccinated
ORDER By 2, 3