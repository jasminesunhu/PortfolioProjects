--View all data
Select *
From PortfolioProject..CovidDeaths
order by date

--Select the data that we will be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

--Total cases vs total deaths

Select Location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as death_percentage
From PortfolioProject..CovidDeaths
--Where location = 'Canada'
order by 1,2

--Total cases vs population

Select Location, date, total_cases, population, (cast(total_cases as float)/cast(population as float))*100 as case_percentage
From PortfolioProject..CovidDeaths
--Where location = 'Canada'
order by 1,2

--Countries with highest infection rate compared to population

Select Location, population, MAX(total_cases) as HighestCaseCount, (MAX(total_cases)/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location, population
order by PercentPopulationInfected desc

--Countries with the highest death count per population

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null --removes continents like asia, africa, etc.
Group by Location
order by TotalDeathCount desc

--Highest death count by continent

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where (continent is null) and (location not like '%income%') --removes income related results
Group by location
order by TotalDeathCount desc

--Global numbers (by week)

Select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'World' and (new_cases is not null) and (new_cases != 0)
Group by date
order by 1,2

--Global numbers (total)

Select SUM(new_cases) as total_new_cases, SUM(new_deaths) as total_new_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'World' and (new_cases != 0)

--Join the two datasets, look at total population vs vaccinations

Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(cast(CV.new_vaccinations as float)) OVER (Partition by CD.location Order by CD.location, CD.date) as rolling_count_vaccinations
From PortfolioProject..CovidDeaths CD
Join PortfolioProject..CovidVaccinations CV
	On CD.location = CV.location and CD.date = CV.date
Where CD.continent is not null
order by 2,3

--CTE

With PopvsVac (continent, location, date, population, new_vacciantions, RollingPeopleVaccinated)
as
(
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(cast(CV.new_vaccinations as float)) OVER (Partition by CD.location Order by CD.location, CD.date) as rolling_count_vaccinations
From PortfolioProject..CovidDeaths CD
Join PortfolioProject..CovidVaccinations CV
	On CD.location = CV.location and CD.date = CV.date
Where CD.continent is not null
)

Select *, (RollingPeopleVaccinated/population)*100
From PopvsVac
order by location, date

--Temp table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(cast(CV.new_vaccinations as float)) OVER (Partition by CD.location Order by CD.location, CD.date) as rolling_count_vaccinations
From PortfolioProject..CovidDeaths CD
Join PortfolioProject..CovidVaccinations CV
	On CD.location = CV.location and CD.date = CV.date
Where CD.continent is not null

Select *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated
Order by location,date

--Creating view to store data for future visualization

Create View PercentPopulationVaccinated as 
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(cast(CV.new_vaccinations as float)) OVER (Partition by CD.location Order by CD.location, CD.date) as rolling_count_vaccinations
From PortfolioProject..CovidDeaths CD
Join PortfolioProject..CovidVaccinations CV
	On CD.location = CV.location and CD.date = CV.date
Where CD.continent is not null