--SELECT *
--FROM first_project..CovidDeaths$
--WHERE continent is not null
--ORDER BY 3, 4

--SELECT *
--FROM first_project..CovidVaccinations$
--WHERE continent is not null
--ORDER BY 3, 4

--Select Data that we are going to be using

--Select Location, date, total_cases, new_cases, total_deaths, population
--FROM first_project..CovidDeaths$
--WHERE continent is not null
--ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelyhood of dying if you got covid 

--Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
--FROM first_project..CovidDeaths$
--WHERE location like 'ukraine'
--ORDER BY 1, 2

--Looking at Total cases vs Population
-- Shows percentage of population is infected

--Select Location, date, population, total_cases, (total_cases/population)*100 AS PopulationPercentage
--FROM first_project..CovidDeaths$
--WHERE location like 'ukraine'
--ORDER BY 1, 2

-- Looking at countries with highest infection rate compared to population

--Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PopulationPercentage
--FROM first_project..CovidDeaths$
--GROUP BY location, population
--ORDER BY PopulationPercentage DESC

-- Shows countriest with the highest death count per population

--Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
--FROM first_project..CovidDeaths$
--WHERE continent is not null
--GROUP BY location, population
--ORDER BY TotalDeathCount DESC

-- DATA PER CONTINENT

--Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
--FROM first_project..CovidDeaths$
--WHERE continent is null
--GROUP BY location
--ORDER BY TotalDeathCount DESC

--Showing continents with highest death rates

--Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
--FROM first_project..CovidDeaths$
--WHERE continent is not null
--GROUP BY continent
--ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS

Select date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM first_project..CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

--WORLD

Select SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM first_project..CovidDeaths$
WHERE continent is not null
ORDER BY 1, 2

--Total Population vs Total Vaccination

--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
--FROM first_project..CovidDeaths$ AS dea
--Join first_project..CovidVaccinations$ AS vac
--ON dea.location = vac.location
--and dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM first_project..CovidDeaths$ AS dea
Join first_project..CovidVaccinations$ AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

--USE CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM first_project..CovidDeaths$ AS dea
Join first_project..CovidVaccinations$ AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
)

Select *, (RollingPeopleVaccinated/population)*100
From PopVsVac

--TEMP TABLE

DROP Table if exists #percentPopulationVaccinated

Create Table #percentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #percentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM first_project..CovidDeaths$ AS dea
Join first_project..CovidVaccinations$ AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null

Select *, (RollingPeopleVaccinated/population)*100
From #percentPopulationVaccinated

--Creating view to store data for later visualization

CREATE VIEW percentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM first_project..CovidDeaths$ AS dea
Join first_project..CovidVaccinations$ AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null

SELECT * 
FROM percentPopulationVaccinated

--percent of vaccinated people by dates

SELECT dea.date, dea.location, 
CONVERT (int, vac.new_vaccinations)/dea.population * 100 AS PopulationVaccinated
FROM first_project..CovidDeaths$ AS dea
JOIN first_project..CovidVaccinations$ AS vac
ON dea.location = vac.location
WHERE dea.continent is not null
GROUP BY dea.date, dea.location, vac.new_vaccinations, dea.population
