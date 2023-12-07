Select * from PortfolioProject..CovidDeaths


Select Location, date, total_cases, total_deaths, --(convert(float, total_deaths)/total_cases)*100
 convert (float, total_deaths) as total_deathsf, (total_deathsf/total_cases)*100
 
 from PortfolioProject..CovidDeaths
 where total_cases <> 0
 order by 1,2
 
-- Using the new table created as 'DeathPercentage' we have found the percentage of people who have 
--  died vs the number of cases
 Select Location, date, total_cases, total_deaths, (total_deathsf/total_cases)*100
  from PortfolioProject..DeathsPercentage
  where location like '%states%'
  order by 1,2

-- Total population vs the amount of cases

Select Location, date, population, total_cases, convert(float, total_cases)/population*100 as PercentPopulationInfected
  from PortfolioProject..CovidDeaths
  Where location like '%states%'
  order by 1,2

 -- Comparing Countries with the higest infection rate

 Select Location, population, MAX(total_cases) as HighestInfection, MAX(convert(float, total_cases))/population*100 as PercentPopulationInfected 
  from PortfolioProject..CovidDeaths
  Group by location, population
  order by PercentPopulationInfected desc

  -- Showing the countries with the highest Death Count per Population
  Select location, Max(population) as MaxPop, Max(total_deaths) as MaxDeath 
  from PortfolioProject..CovidDeaths
  Where location not like '%world' and location not like '%income'
  Group by location 
  order by MaxDeath DESC
  
  -- Showing results by continent
  Select continent, Max(total_deaths) as TotalDeath 
  from PortfolioProject..CovidDeaths
  Where continent is not null 
  Group by continent
  order by TotalDeath DESC 

  -- Global Numbers
;with temp as (select SUM(convert(float, new_cases)) as NewCases , SUM(cast(new_deaths as float)) as NewDeaths
from PortfolioProject..CovidDeaths
Where Continent is not null
--Group by date
) 
select case when NewCases = 0 then null else NewCases end as NewCases, 
           case when NewDeaths = 0 then null else NewDeaths end as NewDeaths,
		   (convert(float, NewDeaths)/case when NewCases = 0.00 then null else NewCases end)*100 as DeathsPercentage
from temp
Order by 1,2

--Looking the Total Population vs Vaccinations

Select  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(float, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
 from PortfolioProject..CovidVaccinations vac
 join PortfolioProject..CovidDeaths dea
    on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

--Using CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(float, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
 from PortfolioProject..CovidVaccinations vac
 join PortfolioProject..CovidDeaths dea
    on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3
)

Select *, (RollingPeopleVaccinated/population)*100 
 from PopvsVac

 -- Recreating the previous column (percentage of people vaccinated by location) using a temp table
 DROP table if exists #PercentPopulationVaccinated
 CREATE table #PercentPopulationVaccinated
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 Population numeric,
 new_vaccinations float,
 RollingPeopleVaccinated numeric
 )
 Insert into #PercentPopulationVaccinated
 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(float, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
 from PortfolioProject..CovidVaccinations vac
 join PortfolioProject..CovidDeaths dea
    on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating views for later visualization

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(float, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
 from PortfolioProject..CovidVaccinations vac
 join PortfolioProject..CovidDeaths dea
    on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select * from PercentPopulationVaccinated

