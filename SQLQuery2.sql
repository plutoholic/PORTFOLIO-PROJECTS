# /*

Project: Nashville Housing Data Cleaning
Author: Francis Agyemang
Tool: Microsoft SQL Server
Dataset: Nashville Housing

Description:
This project demonstrates SQL data cleaning techniques applied to a housing
dataset. The goal is to transform raw data into a structured and analysis-
ready format by standardizing values, handling missing data, splitting columns,
and removing duplicates.

Key SQL Skills Demonstrated:

* Data Cleaning
* Data Transformation
* Handling NULL values
* String Functions
* Common Table Expressions (CTEs)
* Data Standardization
* Removing Duplicate Records
  ================================================================================
  */

---

-- 1. Preview the Dataset
-- Understanding the structure of the dataset before cleaning
-------------------------------------------------------------

SELECT *
FROM PORTFOLIO.dbo.NashvilleHousing;

---

-- 2. Standardize Date Format
-- Convert SaleDate from datetime format to date format
-------------------------------------------------------

SELECT SaleDate, CONVERT(date, SaleDate) AS ConvertedSaleDate
FROM PORTFOLIO.dbo.NashvilleHousing;

-- Create a new column to store the converted date
ALTER TABLE PORTFOLIO.dbo.NashvilleHousing
ADD SaleDateConverted DATE;

-- Update the new column with the converted date values
UPDATE PORTFOLIO.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate);

---

-- 3. Populate Missing Property Address Data
-- Some records have missing PropertyAddress values.
-- We populate them by matching rows with the same ParcelID.
------------------------------------------------------------

SELECT
a.ParcelID,
a.PropertyAddress,
b.ParcelID,
b.PropertyAddress,
ISNULL(a.PropertyAddress, b.PropertyAddress) AS UpdatedAddress
FROM PORTFOLIO.dbo.NashvilleHousing a
JOIN PORTFOLIO.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Update missing PropertyAddress values
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PORTFOLIO.dbo.NashvilleHousing a
JOIN PORTFOLIO.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

---

-- 4. Split Property Address into Separate Columns
-- Extract Address and City from PropertyAddress
------------------------------------------------

SELECT PropertyAddress
FROM PORTFOLIO.dbo.NashvilleHousing;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PORTFOLIO.dbo.NashvilleHousing;

-- Create new columns for split address data
ALTER TABLE PORTFOLIO.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE PORTFOLIO.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

-- Populate the new columns
UPDATE PORTFOLIO.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

UPDATE PORTFOLIO.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

---

-- 5. Split Owner Address into Address, City, and State
-- Using PARSENAME to extract address components
------------------------------------------------

SELECT OwnerAddress
FROM PORTFOLIO.dbo.NashvilleHousing;

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PORTFOLIO.dbo.NashvilleHousing;

-- Add new columns
ALTER TABLE PORTFOLIO.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE PORTFOLIO.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

ALTER TABLE PORTFOLIO.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

-- Populate the new columns
UPDATE PORTFOLIO.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE PORTFOLIO.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE PORTFOLIO.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

---

-- 6. Standardize Values in "SoldAsVacant"
-- Convert Y/N values to Yes/No for better readability
------------------------------------------------------

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PORTFOLIO.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT
SoldAsVacant,
CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END AS UpdatedValue
FROM PORTFOLIO.dbo.NashvilleHousing;

-- Update the column
UPDATE PORTFOLIO.dbo.NashvilleHousing
SET SoldAsVacant =
CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END;

---

-- 7. Identify Duplicate Records
-- Use ROW_NUMBER() to detect duplicates
----------------------------------------

WITH RowNumCTE AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
PropertyAddress,
SalePrice,
SaleDate,
LegalReference
ORDER BY UniqueID
) AS row_num
FROM PORTFOLIO.dbo.NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

---

-- 8. Remove Unused Columns
-- Dropping columns that are no longer needed after transformation
------------------------------------------------------------------

ALTER TABLE PORTFOLIO.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

---

-- End of Data Cleaning Process
-- Dataset is now structured and ready for analysis or visualization.
---------------------------------------------------------------------
