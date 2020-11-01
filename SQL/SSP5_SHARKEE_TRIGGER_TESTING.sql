
-- Checking that UserID cannot be updated, due to the trigger created
GO
CREATE VIEW CheckUserID AS
(SELECT *
FROM Users
WHERE UserID=3);
GO
SELECT * FROM CheckUserID;
GO
UPDATE Users
SET UserID=1000
WHERE UserID=3;
GO
SELECT * FROM CheckUserID;

-- checking that employee ID cannot be updated due to the trigger created
GO
CREATE VIEW CheckEmpID AS
(SELECT *
FROM Employee
WHERE eID=3);
GO
SELECT * FROM CheckEmpID;
GO
UPDATE Employee
SET eID=1000
WHERE eID=3;
GO
SELECT * FROM CheckEmpID;

-- checking that order ID cannot be updated due to the trigger created
GO
CREATE VIEW CheckOrderID AS
(SELECT *
FROM Orders
WHERE oID=3);
GO
SELECT * FROM CheckOrderID;
GO
UPDATE Orders
SET oID=1000
WHERE oID=3;
GO
SELECT * FROM CheckOrderID;


-- Checking the UpdateDelivery trigger in ProductsInOrders
--DELETE FROM ProductsInOrders
--WHERE pName='Glass Cup' AND sName='Walmart' AND oID=257
--INSERT [dbo].[ProductsInOrders] ([sName], [pName], [oID], [orderprice], [orderquantity], [deliverystatus], [deliverydate]) VALUES (N'Walmart', N'Glass Cup', 257, 1, 600, N'being processed', NULL)
GO
CREATE VIEW CheckStatusOfGlassCup AS
(SELECT * FROM ProductsInOrders
WHERE pName='Glass Cup' AND sName='Walmart' AND oID=257);
GO
SELECT * FROM CheckStatusOfGlassCup; --check deliverystatus of glass cup
-- update should not happen because status cannot directly change from being processed to delivered
UPDATE ProductsInOrders
SET deliverystatus='delivered', deliverydate=getdate()
WHERE pName='Glass Cup'AND oID=257 AND sName='Walmart'
SELECT * FROM CheckStatusOfGlassCup; --check deliverystatus of glass cup

--Stepwise update of delivery status from 'being processed' -> 'shipped' -> 'delivered' and maybe, to 'returned'
UPDATE ProductsInOrders
SET deliverystatus = 'shipped'
WHERE oID=257 AND pName='Glass Cup';
SELECT * FROM CheckStatusOfGlassCup; --check deliverystatus of glass cup

--'shipped' -> 'delivered'. DateTime will be set to current date time by default. Avoids scam of inputting wrong date.
UPDATE ProductsInOrders
SET deliverystatus = 'delivered', deliverydate = '2019.12.01 18:00:00'
WHERE oID=257 AND pName='Glass Cup';
SELECT * FROM CheckStatusOfGlassCup; --check deliverystatus of glass cup

---> 'delivered' and maybe, to 'returned'. DateTime will not be changed.
UPDATE ProductsInOrders
SET deliverystatus = 'returned', deliverydate = '2019.12.01 18:00:00'
WHERE oID=257 AND pName='Glass Cup';
SELECT * FROM CheckStatusOfGlassCup; --check deliverystatus of glass cup

--cannot be changed to others onced DeliveryStatus is 'returned'
UPDATE ProductsInOrders
SET deliverystatus = 'being processed', deliverydate=null
WHERE oID=257 AND pName='Glass Cup';
SELECT * FROM CheckStatusOfGlassCup; --check deliverystatus of glass cup
GO

-- Trying out the ComplaintStatus trigger
-- Add a complaint to the table just to check if trigger is working
SET IDENTITY_INSERT [dbo].[Complaint] ON 
INSERT [dbo].[Complaint] ([cID], [complaintext], [complainstatus], [filedatetime], [UserID], [eID], [handledatetime]) VALUES (11, N'Horrible Service.', N'pending', CAST(N'2020-08-03T00:00:00.000' AS DateTime), 4,Null,Null)
SET IDENTITY_INSERT [dbo].[Complaint] OFF
 GO
 -- create a view for the Complaint which is to be checked
 CREATE VIEW checkempltrigger AS
 (SELECT*
 from Complaint
 WHERE cID=11);
go
 SELECT*
 from checkempltrigger
 -- complainstatus cannot be changed from pending to addressed directly
 GO
 UPDATE Complaint
 SET complainstatus='addressed'
 WHERE cID=11;
 GO
 SELECT * FROM checkempltrigger;
 -- complaint status can't be changed to being handled unless employee id is given
   GO
 UPDATE Complaint
 SET complainstatus='being handled'
 WHERE cID=11;
 GO
 SELECT * FROM checkempltrigger;
 -- complaint status changing to being handled along with eID
   GO
 UPDATE Complaint
 SET complainstatus='being handled', eID=1
 WHERE cID=11;
 GO
 SELECT * FROM checkempltrigger;
-- when status is changed to addressed then it also adds handledatetime
GO
 UPDATE Complaint
 SET complainstatus='addressed'
 WHERE cID=11;
 GO
 SELECT * FROM checkempltrigger;
 -- if status is addressed, cannot change status to anything else
   GO
 UPDATE Complaint
 SET complainstatus='being handled'
 WHERE cID=11;
 GO
 SELECT * FROM checkempltrigger;
 -- delete the record that was added in only to test the trigger
 DELETE FROM Complaint 
WHERE cID=11;
 