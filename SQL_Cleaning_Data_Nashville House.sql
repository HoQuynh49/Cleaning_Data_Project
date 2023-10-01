--Cleaning Data in SQL queries
Select *
From Portfolio_Project.dbo.nashville_House

--Standardize Date Format

Alter table Nashville_House
Add SaleDateConvert Date

Update Nashville_House
Set SaleDateConvert = convert(date, SaleDate)

Select SaleDateConvert
From Portfolio_Project.dbo.nashville_House

--Populate property address data
--Có một số PropertyAddress có giá trị NULL -> Đây là loại trường biểu thị một sự thât, không thể tùy ý điền thêm thông tin -> Cần phải tìm ra mối liên kết thông tin giữa các trường để tạo ra tham chiếu tự động điền thông tin chính xác
--Có thể nhận thấy rằng ParcelID có liên kết với PropertyAddress (VD: ParcelID "018 00 0 164" thì có cùng Property_Address "332  MONCRIEF AVE, GOODLETTSVILLE")

Select a.[UniqueID ], a.ParcelID, a.PropertyAddress, b.[UniqueID ], b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From Portfolio_Project.dbo.nashville_House a
Join Portfolio_Project.dbo.nashville_House b
On a.ParcelID = b.ParcelID
And a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From Portfolio_Project.dbo.nashville_House a
Join Portfolio_Project.dbo.nashville_House b
On a.ParcelID = b.ParcelID
And a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--Breaking out address into individual Columns (address, city, state)

--address
Select 
SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress,0) -1) as address
From Portfolio_Project.dbo.nashville_House

ALter table Portfolio_Project.dbo.nashville_House
Add OwnerSplitAddress Nvarchar(255);

Update Portfolio_Project.dbo.nashville_House
Set OwnerSplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress,0) -1)

--city:
Select
RIGHT(PropertyAddress,len(PropertyAddress) - CHARINDEX(',',PropertyAddress,0) -1) as city
From Portfolio_Project.dbo.nashville_House

ALter table Portfolio_Project.dbo.nashville_House
Add OwnerSplitCity Nvarchar(255);

Update Portfolio_Project.dbo.nashville_House
Set OwnerSplitCity = RIGHT(PropertyAddress,len(PropertyAddress) - CHARINDEX(',',PropertyAddress,0) -1)

--State

Select OwnerAddress
From Portfolio_Project.dbo.nashville_House

Select parsename(replace(OwnerAddress,',', '.'),1)
From Portfolio_Project.dbo.nashville_House

ALter table Portfolio_Project.dbo.nashville_House
Add OwnerSplitState Nvarchar(255);

Update Portfolio_Project.dbo.nashville_House
Set OwnerSplitState = parsename(replace(OwnerAddress,',', '.'),1)

--Change "Y" and "N" to "Yes" and "No" in "SoldAsVacant" field

Select distinct(SoldAsVacant), count(SoldAsVacant)
From Portfolio_Project.dbo.nashville_House
Group by SoldAsVacant

Select SoldAsVacant, Case when SoldAsVacant = 'Y' Then replace(SoldAsVacant, 'Y', 'Yes')
					When SoldAsVacant = 'N' Then replace(SoldAsVacant, 'N', 'No')
					Else SoldAsVacant
					End As SoldAsVacant_new
From Portfolio_Project.dbo.nashville_House

Update Portfolio_Project.dbo.nashville_House
Set SoldAsVacant = Case when SoldAsVacant = 'Y' Then replace(SoldAsVacant, 'Y', 'Yes')
					When SoldAsVacant = 'N' Then replace(SoldAsVacant, 'N', 'No')
					Else SoldAsVacant
					End 

--Remove Duplicates

With Row_number_CTE as
(
Select *,
ROW_NUMBER () over (
Partition by ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
Order by UniqueID ASC)
As row_number
From Portfolio_Project.dbo.nashville_House
)
Delete
From Row_number_CTE
Where row_number > 1

--Delete unsued Columns

ALter table Portfolio_Project.dbo.nashville_House
DROP column SaleDate, PropertyAddress, OwnerAddress, TaxDistrict, Address, City, State


