use [PortfolioProject]



SELECT *
FROM PortfolioProject..CO2EmissionsAfrica
ORDER BY  9, 6 DESC



SELECT *
FROM PortfolioProject..GDSustainableEnergy
ORDER BY 7 DESC, 8 DESC

--Selecting data for use



SELECT Country, [Sub-Region], Year, Population, [Total CO2 Emission including LUCF (Mt)], [Energy (Mt)]
FROM PortfolioProject..CO2EmissionsAfrica
ORDER BY 5, 3



--Looking at CO2 emissions per capita in the Eastern Subregion
--Demonstrates the CO2 emissions produced by each person


SELECT Country, [Sub-Region], Year, Population, [Total CO2 Emission including LUCF (Mt)], [Energy (Mt)], ([Total CO2 Emission including LUCF (Mt)]/Population)*1000000 AS [Emissions Per Capita (tons)]
FROM PortfolioProject..CO2EmissionsAfrica
WHERE [Sub-Region] like '%Eastern%'
ORDER BY 7, 3


--Looking at countries with yearly highest total CO2 emissions compared to percentage of total CO2 emissions produced by energy



SELECT Country, MAX([Total CO2 Emission including LUCF (Mt)]) as [Total Emissions (Mt)], MAX(ABS([Energy (Mt)]/[Total CO2 Emission including LUCF (Mt)])*100) AS [Energy Percentage]
FROM PortfolioProject..CO2EmissionsAfrica
GROUP BY Country
ORDER BY 3 DESC



--Looking at which region has the country with the highest Electricty/Heat emissions


SELECT [Sub-Region], MAX([Electricity/Heat (Mt)]) as 'Electricity/Heat(Mt)'
FROM PortfolioProject..CO2EmissionsAfrica 
GROUP BY [Sub-Region]
HAVING MAX([Electricity/Heat (Mt)]) is not null
ORDER BY 2 DESC




--Total emissions and total Energy emissions by year

SELECT Year, SUM([Total CO2 Emission including LUCF (Mt)]) as 'Total_Emissions', SUM([Energy (Mt)]) as 'Energy(Mt)', 
SUM([Energy (Mt)])/SUM([Total CO2 Emission including LUCF (Mt)])*100 as 'Energy_Percentage'
FROM PortfolioProject..CO2EmissionsAfrica 
GROUP BY Year
ORDER BY 2



--Looking at Electricity/Heat emissions versus access to clean fuels and electricy from renewables


SELECT Ems.Country, Ems.[Sub-Region], Ems.Year, Ems.[Electricity/Heat (Mt)], Ems.[Total CO2 Emission excluding LUCF (Mt)],
Enr.[Access to clean fuels for cooking] as 'Access to clean fuels for cooking (% of pop)', Enr.[Electricity from renewables (TWh)],
SUM(Ems.[Electricity/Heat (Mt)]) OVER (PARTITION BY Enr.Country ORDER BY Enr.Country, Enr.Year )
AS 'Electricity/Heat_Em_RollingSum'
FROM PortfolioProject..CO2EmissionsAfrica as Ems
JOIN PortfolioProject..GDSustainableEnergy as Enr
ON Ems.country = Enr.country
and Ems.year = Enr.year
ORDER BY 1,2,3


--Using CTE

With ElecHeat_vs_TotalEm (Country, [Sub-Region], Year, [Electricity/Heat (Mt)],
[Total CO2 Emission including LUCF (Mt)],
[Electricity from renewables (TWh)], [Electricity/Heat_Em_RollingSum], 
[RollingTotCO2Emission(Mt)])
AS
(
SELECT Ems.Country, Ems.[Sub-Region], Ems.Year, Ems.[Electricity/Heat (Mt)], Ems.[Total CO2 Emission including LUCF (Mt)], 
Enr.[Electricity from renewables (TWh)],
SUM(Ems.[Electricity/Heat (Mt)]) OVER (PARTITION BY Enr.Country ORDER BY Enr.Country, Enr.Year) AS 'Electricity/Heat_Em_RollingSum',
SUM(Ems.[Total CO2 Emission including LUCF (Mt)]) OVER (PARTITION BY Enr.Country ORDER BY Enr.Country, Enr.Year) AS
'RollingTotCO2Emission(Mt)'
FROM PortfolioProject..CO2EmissionsAfrica as Ems
JOIN PortfolioProject..GDSustainableEnergy as Enr
ON Ems.country = Enr.country
and Ems.year = Enr.year
--ORDER BY 1,2,3
)
SELECT *, ([Electricity/Heat_Em_RollingSum]/[RollingTotCO2Emission(Mt)])*100 AS
'Rolling%ofElec/HeatEm'
FROM ElecHeat_vs_TotalEm


--TEMP TABLE

DROP TABLE IF exists #PercentofEmissionsCausedbyElec_Heat
CREATE TABLE #PercentofEmissionsCausedbyElec_Heat
(
Country nvarchar(255),
[Sub-Region] nvarchar(255),
Year float,
[Electricity/Heat (Mt)] float,
[Total CO2 Emission including LUCF (Mt)] float,
[Electricity from renewables (TWh)] float,
[Electricity/Heat_Em_RollingSum] numeric,
[RollingTotCO2Emission(Mt)] numeric,
)

INSERT INTO #PercentofEmissionsCausedbyElec_Heat
SELECT Ems.Country, Ems.[Sub-Region], Ems.Year, Ems.[Electricity/Heat (Mt)], Ems.[Total CO2 Emission including LUCF (Mt)], 
Enr.[Electricity from renewables (TWh)],
SUM(Ems.[Electricity/Heat (Mt)]) OVER (PARTITION BY Enr.Country ORDER BY Enr.Country, Enr.Year) AS 'Electricity/Heat_Em_RollingSum',
SUM(Ems.[Total CO2 Emission including LUCF (Mt)]) OVER (PARTITION BY Enr.Country ORDER BY Enr.Country, Enr.Year) AS
'RollingTotCO2Emission(Mt)'
FROM PortfolioProject..CO2EmissionsAfrica as Ems
JOIN PortfolioProject..GDSustainableEnergy as Enr
ON Ems.country = Enr.country
and Ems.year = Enr.year
--ORDER BY 1,2,3

SELECT *, ([Electricity/Heat_Em_RollingSum]/NULLIF([RollingTotCO2Emission(Mt)],0))*100 AS
'Rolling%ofElec/HeatEm'
FROM  #PercentofEmissionsCausedbyElec_Heat


--Creating view for visualizations


CREATE VIEW  [RollingTotEm] AS
SELECT Ems.Country, Ems.[Sub-Region], Ems.Year, Ems.[Electricity/Heat (Mt)], Ems.[Total CO2 Emission including LUCF (Mt)], 
Enr.[Electricity from renewables (TWh)],
SUM(Ems.[Electricity/Heat (Mt)]) OVER (PARTITION BY Enr.Country ORDER BY Enr.Country, Enr.Year) AS 'Electricity/Heat_Em_RollingSum',
SUM(Ems.[Total CO2 Emission including LUCF (Mt)]) OVER (PARTITION BY Enr.Country ORDER BY Enr.Country, Enr.Year) AS
'RollingTotCO2Emission(Mt)'
FROM PortfolioProject..CO2EmissionsAfrica as Ems
JOIN PortfolioProject..GDSustainableEnergy as Enr
ON Ems.country = Enr.country
and Ems.year = Enr.year
--ORDER BY 1,2,3

SELECT *
FROM RollingTotEm