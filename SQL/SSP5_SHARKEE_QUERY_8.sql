-- Question: Find products that have never been purchased by some users,
-- but are the top 5 most purchased products by other users in August 2020.

--first, products which have never been purchased by some users


CREATE VIEW UniqueUsers AS --this view has the total number of unique users in the system
(SELECT COUNT(UserID) AS NoOfUniqueUsers
FROM Users);
GO
SELECT * FROM UniqueUsers;

GO
CREATE VIEW UsersOfProducts AS -- this view has the names of the products and the number of unique users who have purchased them at some point
(SELECT pName, Count(UserID) AS NumUniquePurchasers
FROM (SELECT DISTINCT U.UserID, pName
      FROM Users U, Orders O ,ProductsInOrders PIO
      WHERE U.UserID=O.UserID AND O.oID=PIO.oID) AS UniquePurchase
GROUP BY pName);
GO
SELECT * FROM UsersOfProducts;


GO
CREATE VIEW PdtsNotBoughtByAll AS -- this view shows the pName, no. of unique purchasers for that product, and the total number of unique users on Sharkee
--it only selects those products which have never been purchased by some users
(SELECT pName, NumUniquePurchasers, NoOfUniqueUsers FROM UsersOfProducts, UniqueUsers
WHERE UsersOfProducts.NumUniquePurchasers<UniqueUsers.NoOfUniqueUsers);
GO
SELECT * FROM PdtsNotBoughtByAll;

GO
CREATE VIEW UnpopularPdts AS -- this view stores only the names of those products which have never been purchased by some users
(SELECT pName FROM PdtsNotBoughtByAll);
GO
SELECT * FROM UnpopularPdts;


GO
CREATE VIEW PdtPurchasesInAugust AS --this view stores product names with the number of their purchases in the month of august
(SELECT pName, SUM(orderquantity) AS TotalQuantity
FROM ProductsInOrders PIO
JOIN Orders O ON PIO.oID =O.oID AND
(O.OrderDateTime >= '2020.08.01 00:00:00' AND O.OrderDateTime < '2020.09.01 00:00:00')
GROUP BY pName
);
GO
SELECT * FROM PdtPurchasesInAugust ORDER BY TotalQuantity DESC;

GO
CREATE VIEW Top5MostPurchasedPdts AS -- creating a view of the top 5 most purchased products in August
(SELECT TOP 5 * FROM PdtPurchasesInAugust ORDER BY TotalQuantity DESC); 
GO
SELECT * FROM Top5MostPurchasedPdts;

--this is the final query that returns those products which have never been purchased by some users but are the top 5 products purchased by others in August 2020.
SELECT pName
FROM Top5MostPurchasedPdts 
INTERSECT
SELECT pName
FROM UnpopularPdts;