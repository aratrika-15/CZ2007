---- Query 1 ---- DONE
-- Question: Find the average price of “iPhone Xs” on Sharkee from 1 August 2020 to 31 August 2020.

SELECT AVG(price) AS AvgPrice
FROM PriceHistory
WHERE pName = 'iPhone X'
AND ((startdate >= '2020.08.01 00:00:00' AND startdate < '2020.09.01 00:00:00')
    OR (enddate >= '2020.08.01 00:00:00' AND enddate < '2020.09.01 00:00:00'));

	


---- Query 2 ---- version 1 DONE
-- Quesiton: Find products that received at least 100 ratings of “5” in August 2020, and order them by their average ratings.

-- create temporary table which stores product name with more than 100 ratings of "5"
SELECT pName INTO Pdts
FROM Feedback
WHERE rating = 5 AND MONTH(feedbackDate) = 8 AND YEAR(feedbackDate) = 2020
GROUP BY pName
HAVING COUNT(rating)>=100;

-- printing the average ratings for these products
SELECT pName, ROUND(AVG(Cast(rating as Float)),2) AS AvgRatings
FROM Feedback
WHERE pName IN(SELECT * FROM Pdts) AND MONTH(feedbackDate) = 8 AND YEAR(feedbackDate) = 2020
GROUP BY pName
ORDER BY AVG(rating) DESC;




---- Query 2 ---- version 2 DONE
-- Question: Find products that received at least 100 ratings of “5” in August 2020, and order them by their average ratings.

-- Only extract those rows whereby the month of the feedback is August(08) and the year is 2020
WITH F0 AS ( --products that receive feedback in August 2020
SELECT * 
FROM Feedback f
WHERE MONTH(feedbackDate) = 8 AND YEAR(feedbackDate) = 2020),
 
-- products that received ratings 5
F1 AS(
SELECT *
FROM F0
WHERE rating=5),

-- products with at least 100 ratings of 5
F2 AS(
SELECT pName, COUNT(rating) AS NumRatings5
FROM F1
GROUP BY pName
HAVING COUNT(rating)>=100)
 
-- First cast Rating to be a Float so we can get the decimal point values, then Average all the Rating values
-- Round the average rating to be 2 decimal point
SELECT F2.pName, ROUND(AVG(Cast(F0.rating as Float)),2) AS AvgRatings
FROM F2
JOIN F0 ON F2.pName=F0.pName
GROUP BY F2.pName
ORDER BY AvgRatings DESC;




---- Query 3 ---- DONE
-- Question: For all products purchased in June 2020 that have been delivered, find the average time from the ordering date to the delivery date.

-- print average time of delivery in hours
SELECT CAST(AVG(DATEDIFF(second,orderdatetime, deliverydate)) AS FLOAT)/3600 AS AvgTimeOnDelivery
FROM Orders, ProductsInOrders
WHERE Orders.oID= ProductsInOrders.oID
AND orderdatetime >= '2020-06-01 00:00:01' AND orderdatetime <= '2020-06-30 23:59:59'
AND (deliverystatus = 'Delivered' OR deliverystatus = 'Returned');



---- Query 4 ---- DONE
-- Question: Let us define the “latency” of an employee by the average that he/she takes to process a complaint. Find the employee with the smallest latency.

SELECT eID, AVG(DATEDIFF(second, filedatetime, handledatetime)) AS AvgLatency INTO LatencyRecord
FROM Complaint
GROUP BY eID;

-- cross-check table
-- SELECT *
-- FROM LatencyRecord;

SELECT eID 
FROM LatencyRecord
WHERE AvgLatency = (SELECT MIN(AvgLatency) FROM LatencyRecord);



---- Query 5 ---- DONE
-- Question: Produce a list that contains (i) all products made by Samsung, and (ii) for each of them, the number of shops on Sharkee that sell the product.

-- Part(i) --
SELECT pName
FROM Product
WHERE maker = 'Samsung';

-- Part(ii) -- version 1
SELECT Product.pName, COUNT(Sname) AS noOfShops
FROM ProductsInShops RIGHT JOIN Product ON Product.pName = ProductsInShops.pName
WHERE maker = 'Samsung' 
GROUP BY Product.pName;

-- Part(ii) -- version 2
SELECT Product.pName AS Product, COUNT(ProductsInShops.PName) AS noOfShops
FROM Product
LEFT JOIN ProductsInShops
ON Product.pName = ProductsInShops.pName
WHERE maker = 'Samsung'
GROUP BY Product.pName;




---- Query 6 ---- DONE
-- Quesiton: Find shops that made the most revenue in August 2020.

WITH A1 AS
(
 SELECT t2.sName, SUM(t2.orderprice*t2.orderquantity) AS revenue
 FROM Orders as t1
 
 -- Left join on common attribute OrderID of both tables
 LEFT JOIN ProductsInOrders AS t2
 ON t1.oID = t2.oID
 
 -- OrderDateTime should fall under 2020/08
 WHERE MONTH(t1.orderdatetime) = 8 AND YEAR(t1.orderdatetime) = 2020
 -- Group by Shop name with aggregate function SUM of all revenue(OrderPrice*OrderQuantity) by this shop
 GROUP BY sName
)
-- crosscheck table
-- SELECT *
-- FROM A1;

SELECT sName
FROM A1
WHERE revenue = (SELECT MAX(revenue) FROM A1);




---- Query 7 ---- DONE
-- Question: For users that made the most amount of complaints, find the most expensive products he/she has ever purchased.
 
-- Counts the total number of complaints each user has made
WITH A1 AS
(
 SELECT UserID, COUNT(UserID) as noOfComplaints
 FROM Complaint
 GROUP BY UserID
),
 
-- Select the users in A1 that has made the most complaints and their orderID
A2 AS
(
 SELECT t1.UserID, t2.oID
 FROM A1 as t1
 LEFT JOIN Orders as t2
 ON t1.UserID = t2.UserID
 WHERE noOfComplaints = (SELECT MAX(noOfComplaints) FROM A1)
),
 
-- Find all products that these users in A2 has ever purchased
A3 AS
(
 SELECT t1.UserID, t2.oID, t2.pName, t2.orderprice
 FROM A2 as t1
 LEFT JOIN ProductsInOrders as t2
 ON t1.oID = t2.oID
 
),
 
-- Find the most expensive product that each user in A3 has purchased
A4 AS
(
 SELECT UserID, MAX(OrderPrice) as maxProductPrice FROM A3
 GROUP BY UserID
)

-- Get the product name by matching UserID and the Product price
SELECT t1.UserID, t2.pName, t2.orderprice
FROM A4 as t1
LEFT JOIN A3 as t2
ON t1.UserID = t2.UserID AND t1.maxProductPrice = t2.OrderPrice;



---- Query 8 ----
-- Question: Find products that have never been purchased by some users, but are the top 5 most purchased products by other users in August 2020.

-- Create a view with all products sold in August, group by PName, and find total quantity
GO
CREATE VIEW AllProducts AS
(SELECT pName, SUM(orderquantity) AS TotalQuantity
FROM ProductsInOrders PIO
JOIN Orders O ON PIO.oID =O.oID AND
(O.OrderDateTime >= '2020.08.01 00:00:00' AND O.OrderDateTime < '2020.09.01 00:00:00')
GROUP BY PName);

GO
-- View that excludes top product in August
CREATE VIEW NonTop1Products AS
(SELECT *
FROM AllProducts AP
WHERE AP.TotalQuantity <> (SELECT MAX(TotalQuantity)
                       	FROM Allproducts AP2));

GO
-- View that excludes top 2 product in August
CREATE VIEW NonTop2Products AS
(SELECT *
FROM NonTop1Products NT
WHERE NT.TotalQuantity <> (SELECT MAX(TotalQuantity)
                       	FROM NonTop1Products NT1));

GO
-- View that excludes top 3 product in August
CREATE VIEW NonTop3Products AS
(SELECT *
FROM NonTop2Products NT
WHERE NT.TotalQuantity <> (SELECT MAX(TotalQuantity)
                       	FROM NonTop2Products NT1));

GO
-- View that excludes top 4 product in August
CREATE VIEW NonTop4Products AS
(SELECT *
FROM NonTop3Products NT
WHERE NT.TotalQuantity <> (SELECT MAX(TotalQuantity)
                       	FROM NonTop3Products NT1));

GO
-- View that excludes top 5 product in August
CREATE VIEW NonTop5Products AS
(SELECT *
FROM NonTop4Products NT
WHERE NT.TotalQuantity <> (SELECT MAX(TotalQuantity)
                       	FROM NonTop4Products NT1));

GO
-- View that get top 5 product in August
-- Assume that there can be more than 5 products if products have the same order quantity.
CREATE VIEW TopProducts AS
(SELECT *
FROM AllProducts
EXCEPT
SELECT *
FROM NonTop5Products);

GO
-- View that gets the number of unique users
CREATE VIEW UserCount AS
SELECT COUNT(*) AS NumUniqueUsers
FROM Users;

GO
-- View that gets the number of unique purchases for each product
CREATE VIEW UniquePurchases AS
SELECT pName, Count(UserID) AS NumUniquePurchases
FROM (SELECT DISTINCT U.UserID, pName
      FROM Users U, Orders O ,ProductsInOrders PIO
      WHERE U.UserID=O.UserID AND O.oID=PIO.oID) AS UniquePurchase
GROUP BY pName;

GO
-- View that gets the products that are not bought by some users, but are top 5 products
SELECT DISTINCT TP.pName
FROM TopProducts TP, UserCount UC,UniquePurchases UP
WHERE TP.pName=UP.pName AND NumUniquePurchases < NumUniqueUsers;

GO

-- additional commands to visualise views : not the query answer, but additional visualisation for clarity
-- All products
SELECT *
FROM AllProducts
ORDER BY TotalQuantity DESC;

-- Top 5 products
SELECT *
FROM TopProducts
ORDER BY TotalQuantity DESC;

-- Number of unique users
SELECT *
FROM UserCount;

-- Number of  unique purchases for each product
SELECT *
FROM UniquePurchases;

-- Number of  unique purchases for each product with number of unique users added
SELECT TP.pName, NumUniquePurchases, NumUniqueUsers
FROM TopProducts TP, UserCount UC,UniquePurchases UP
WHERE TP.pName=UP.pName;



---- Query 9 ----
-- Question: Find products that are increasingly being purchased over at least 3 months.

GO
-- create a view of the products sold, their quantities, month and year
CREATE VIEW ProductsInMonthYear AS
( SELECT pName, orderquantity, MONTH(orderdatetime) AS Month, YEAR(orderdatetime) AS Year
FROM ProductsInOrders JOIN Orders ON ProductsInOrders.OID=Orders.OID) ;

GO
-- view showing the total quantity of each product for per month, per year
CREATE VIEW PdtMonthlySales AS
(SELECT pName, Month, Year, SUM(orderquantity) AS TotalQuantity
FROM ProductsInMonthYear
GROUP BY pName, Month, Year);

GO
SELECT DISTINCT P1.pName
FROM PdtMonthlySales P1, PdtMonthlySales P2, PdtMonthlySales P3
WHERE(P1.pName=P2.pName AND P2.pName=P3.pName)
AND   ((P1.Year=P2.Year AND (P3.Year-P2.Year)=1 AND P1.Month=11 AND P2.Month=12 AND P3.Month=1) --Eg Nov 2019, Dec 2019 and Jan 2020
	OR((P2.Year-P1.Year)=1 AND P2.Year=P3.Year AND P1.Month=12 AND P2.Month=1 AND P3.Month=2) --Eg Dec 2019, Jan 2020 and Feb 2020
	OR(P1.Year=P2.Year AND P2.Year=P3.Year AND (P3.Month-P2.Month)=1 AND (P2.Month-P1.Month)=1)) --any 3 consecutive months in 2020.
AND (P3.TotalQuantity>P2.TotalQuantity AND P2.TotalQuantity>P1.TotalQuantity);

SELECT * 
FROM PdtMonthlySales
ORDER BY pName, Month, Year;



