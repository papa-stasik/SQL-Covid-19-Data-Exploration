/* 

Covid 19 Data Exploration

*/

-- Examine contents of CovidDeaths file
Select *
From Portfolio..CovidDeaths
Where continent is not null 
order by 3,4


-- Examine contents of CovidVaccinations file
Select *
From Portfolio..CovidVaccinations
Where continent is not null 
order by 1,2


-- Select data for further analysis
Select location, date, total_cases, new_cases, total_deaths, population
From Portfolio..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases VS Total Deaths (in Ireland as an example)
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio..CovidDeaths
Where location like '%ireland%'
order by 1,2


-- Total Cases VS Population
-- Shows percentage of population that has contracted Covid
Select location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
From Portfolio..CovidDeaths
Where location like '%moldova%'
order by 1,2


--Examining Countries with Highest Infection rate as per the respective Population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From Portfolio..CovidDeaths
Group by population, location
order by PercentPopulationInfected desc


-- Examine Countries with Highest Death Count per Population
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc


-- Examine Continents with the Highest Death Count per Population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc


-- Global Total Cases, Deaths and Death Percentages
Select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage 
From Portfolio..CovidDeaths
Where continent is not null
Group by date
order by 1,2


-- Total Population vs Vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as PeopleVaccinated
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 1,2,3


-- Using CTE to perform Calculation on Partition By in previous query
With PopVsVac (Continent, location, date, population, new_vaccinations, PeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as PeopleVaccinated
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (PeopleVaccinated/population)*100
From PopVsVac


-- Using Temp Table to perform Calculation on Partition By in previous query
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
PeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as PeopleVaccinated
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Select *, (PeopleVaccinated/population)*100 as RollingVaccinations
From #PercentPopulationVaccinated


-- Creating View to store data for later visualisation
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as PeopleVaccinated
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null