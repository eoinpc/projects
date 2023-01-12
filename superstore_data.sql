/* Part A */
/* Part B */
.open --new "/Users/eoinpc/Desktop/UCF/eco_4444/sql/databases/Global_Superstore.db"

CREATE TABLE People
(
    Person  Text,
    Region  Text,
    PRIMARY KEY (Region)
);

.import --csv --skip 1 /Users/eoinpc/Desktop/UCF/eco_4444/sql/data/people_global.csv People

CREATE TABLE Returned
(
    Returned    Text,
    `Order ID`  Text,
    Market      Text,
    PRIMARY KEY (`Order ID`)
);

.import --csv --skip 1 /Users/eoinpc/Desktop/UCF/eco_4444/sql/data/returns_global.csv Returned

CREATE TABLE Orders
(
    `Row ID`            Text,
    `Order ID`          Text,
    `Order Date`        Text,
    `Ship Date`         Text,
    `Ship Mode`         Text,
    `Customer ID`       Text,
    `Customer Name`     Text,
    Segment             Text,
    City                Text,
    `State`             Text,
    Country             Text,
    `Postal Code`       Text,
    Market              Text,
    Region              Text,
    `Product ID`        Text,
    Category            Text,
    `Sub-category`      Text,
    `Product Name`      Text,
    Sales               Real,
    Quantity            Integer,
    Discount            Real,
    Profit              Real,
    `Shipping Cost`     Real,
    `Order Priority`    Text,
    PRIMARY KEY (`Row ID`),
    FOREIGN KEY (Region) REFERENCES People (Region),
    FOREIGN KEY (`Order ID`) REFERENCES Returned (`Order ID`)
);

.import --csv --skip 1 /Users/eoinpc/Desktop/UCF/eco_4444/sql/data/orders_global.csv Orders

.mode column
.headers on


/* Part C */
SELECT Country ,
COUNT(Country) AS `Number of Sales` 
FROM Orders 
GROUP BY Country
ORDER BY -`Number of Sales` ;


/* Part D */
SELECT Country ,
COUNT(Country) AS `Number of Sales` 
FROM Orders 
WHERE Country LIKE '%z%'
GROUP BY Country
ORDER BY -`Number of Sales` ;


/* Part E */
SELECT Country ,
COUNT(Country) AS `Number of Sales` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Sale`
FROM Orders 
WHERE Country LIKE '%z%'
GROUP BY Country
ORDER BY -`Profit Per Sale` ;


/* Part F */
SELECT Country ,
COUNT(Country) AS `Number of Sales` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Sale`
FROM Orders 
WHERE Country LIKE '%z%'
GROUP BY Country
HAVING `Total Profit` < 0 OR `Profit Per Sale` < 0 
ORDER BY -`Profit Per Sale` ;


/* Part G */
SELECT Country ,
COUNT(Country) AS `Number of Sales` ,
round(SUM(Sales), 2) AS `Total Sales Revenue` ,
round(AVG(Sales), 2) AS `Sales Revenue Per Unit` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Unit`
FROM Orders
WHERE Country = "Ireland"
OR Country = "Cuba"
GROUP BY Country ;


/* Part H */
SELECT Country ,
SUBSTR(`Order ID`, 4, 4) AS Year ,
COUNT(Country) AS `Number of Sales` ,
round(SUM(Sales), 2) AS `Total Sales Revenue` ,
round(AVG(Sales), 2) AS `Sales Revenue Per Unit` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Unit` /* calculate using sum and quantity */
FROM Orders
WHERE Country = "Ireland"
OR Country = "Cuba"
GROUP BY Country, Year
ORDER BY Year ;


/* Part I */
SELECT Country ,
SUBSTR(`Order ID`, 4, 4) AS Year ,
CAST(RTRIM(SUBSTR(`Order Date`, 1, 2), '/') AS INTEGER) AS Month ,
COUNT(Country) AS `Number of Sales` ,
round(SUM(Sales), 2) AS `Total Sales Revenue` ,
round(AVG(Sales), 2) AS `Sales Revenue Per Unit` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Unit`
FROM Orders
WHERE Country = "Ireland"
OR Country = "Cuba"
GROUP BY Country, Year, Month
ORDER BY Country, Year, Month ;


/* Part J */
SELECT Region ,
COUNT(Region) AS `Number of Sales` ,
round(SUM(Sales), 2) AS `Total Sales Revenue` ,
round(AVG(Sales), 2) AS `Sales Per Unit` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Unit`
FROM Orders
GROUP BY Region ;


/* Part K */
SELECT Region ,
SUBSTR(`Order ID`, 4, 4) AS Year ,
COUNT(Region) AS `Number of Sales` ,
round(SUM(Sales), 2) AS `Total Sales Revenue` ,
round(AVG(Sales), 2) AS `Sales Per Unit` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Unit`
FROM Orders
GROUP BY Region, Year ;


/* Part L */
SELECT O.Region, P.Person ,
SUBSTR(`Order ID`, 4, 4) AS Year ,
COUNT(O.Region) AS `Number of Sales` ,
round(SUM(Sales), 2) AS `Total Sales Revenue` ,
round(AVG(Sales), 2) AS `Sales Per Unit` ,
round(SUM(Profit), 2) AS `Total Profit` ,
round(AVG(Profit), 2) AS `Profit Per Unit`

FROM Orders as O
JOIN People as P ON O.Region = P.Region
GROUP BY P.Region, Year ;


/* Part M */
.headers on
.mode column
.output /Users/eoinpc/Desktop/UCF/eco_4444/sql/intermediate/lost_profits_by_region.csv
.headers on
.mode column
.mode csv

SELECT O.Region, P.Person ,
COUNT(O.Region) AS `Number of Returns` , /* average computed by profit divided by count returned */
round(SUM(Profit), 2) AS `Total Lost Profit` ,
round(AVG(Profit), 2) AS `Lost Profit Per Unit` 

FROM Orders as O
JOIN People as P ON O.Region = P.Region
JOIN Returned as R ON R.`Order ID` = O.`Order ID`
GROUP BY P.Region ;

/* Part N - adding something new */
SELECT
    `Order ID` ,
    Region ,
    Category ,
    `Sub-Category` ,
    `Product Name` ,
    Quantity ,
    Sales ,
    Discount ,
    Profit ,

    CASE
        WHEN (Profit/Sales) >= 0.35 THEN 'High'
        WHEN (Profit/Sales) >= 0.20 THEN 'Moderate'
        WHEN 0.00 <= (Profit/Sales) THEN 'Low'
        WHEN (Profit/Sales) < 0.00 THEN 'Negative' 
    
        END `Profit Margin`

FROM Orders
WHERE Region = 'South' 
AND `Sub-Category` = 'Phones' ;











