-- Create Tables
CREATE TABLE Users (
	UserID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	uName varchar(100) NULL
);
CREATE TABLE Product(
	pName nvarchar(500) NOT NULL PRIMARY KEY,
	category varchar(100) NOT NULL,
	maker nvarchar(100) NOT NULL
);
CREATE TABLE Employee(
	eID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	eName nvarchar(200) NOT NULL,
	salary float(24) NOT NULL DEFAULT 0.0 CHECK(salary >= 0.0)
);

CREATE TABLE Shop(
sName varchar(100) PRIMARY KEY,
);

CREATE TABLE Complaint(
	cID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	complaintext nvarchar(3000) NOT NULL,
	filedatetime datetime NOT NULL DEFAULT getdate(),
	complainstatus varchar(15) DEFAULT 'Pending' Check(complainstatus = 'Pending' OR complainstatus = 'Being handled' OR complainstatus = 'Addressed'),
	handledatetime datetime NULL,
	UserID int FOREIGN KEY REFERENCES Users(UserID) ON DELETE SET NULL,
	eID int FOREIGN KEY REFERENCES Employee(eID) ON DELETE SET NULL 
);
CREATE TABLE ComplaintOnShop(
	cID int FOREIGN KEY REFERENCES Complaint(cID) ON DELETE CASCADE,
	sName varchar(100) FOREIGN KEY REFERENCES Shop(sName) ON DELETE CASCADE ON UPDATE CASCADE
	PRIMARY KEY (cID),
);
CREATE TABLE Orders(
	oID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	shippingcost float(24) NOT NULL DEFAULT 0.0 CHECK(shippingcost>=0.0),
	shippingaddr nvarchar(500) NOT NULL,
	orderdatetime datetime DEFAULT getdate(),
	UserID int FOREIGN KEY REFERENCES Users(UserID) ON DELETE CASCADE,
);
CREATE TABLE ComplaintOnProduct(
	cID int FOREIGN KEY REFERENCES Complaint(cID) ON DELETE CASCADE,
	pName nvarchar(500) FOREIGN KEY REFERENCES Product(pName) ON DELETE CASCADE ON UPDATE CASCADE,
	sName varchar(100) FOREIGN KEY REFERENCES Shop(sName) ON DELETE CASCADE ON UPDATE CASCADE,
	oID int FOREIGN KEY REFERENCES Orders(oID) ON DELETE CASCADE,
	PRIMARY KEY (cID),
);
CREATE TABLE ProductsInShops(
	pName nvarchar(500) FOREIGN KEY REFERENCES Product(pName) ON DELETE CASCADE ON UPDATE CASCADE,
	sName varchar(100) FOREIGN KEY REFERENCES Shop(sName) ON DELETE CASCADE ON UPDATE CASCADE,
	quantity int NOT NULL DEFAULT 0 CHECK(quantity>=0),
	price float(24) NOT NULL DEFAULT 0.0 CHECK(price>=0.0),
	PRIMARY KEY (pName, sName),
);
CREATE TABLE ProductsInOrders(
	pName nvarchar(500) FOREIGN KEY REFERENCES Product(pName) ON DELETE CASCADE ON UPDATE CASCADE,
	sName varchar(100) FOREIGN KEY REFERENCES Shop(sName) ON DELETE CASCADE ON UPDATE CASCADE,
	oID int FOREIGN KEY REFERENCES Orders(oID) ON DELETE CASCADE,
	orderquantity int NOT NULL DEFAULT 0 CHECK(orderquantity>=0),
	orderprice float(24) NOT NULL DEFAULT 0.0 CHECK(orderprice>=0.0),
	deliverystatus varchar(50) NOT NULL DEFAULT 'being processed' 
	Check(deliverystatus = 'being processed' OR deliverystatus = 'shipped' OR deliverystatus = 'delivered' OR deliverystatus = 'returned'),
	deliverydate datetime DEFAULT NULL,
	--The product in order either has DeliveryStatus = 'delivered' or 'returned' and a DeliveryDateTime.
--or DeliveryStatus 'being processed' or 'shipped' and DeliveryDateTime = NULL.
CHECK((deliverystatus='delivered' AND deliverydate<>NULL)
OR (deliverystatus='returned' AND deliverydate<>NULL)
OR (deliverystatus='being processed' AND deliverydate=NULL)
OR (deliverystatus='shipped' AND deliverydate=NULL)),
PRIMARY KEY(pName, sName, oID),
);



CREATE TABLE PriceHistory(
	pName nvarchar(500) FOREIGN KEY REFERENCES Product(pName) ON DELETE CASCADE ON UPDATE CASCADE,
	sName varchar(100) FOREIGN KEY REFERENCES Shop(sName) ON DELETE CASCADE ON UPDATE CASCADE,
	startdate datetime NOT NULL DEFAULT getdate(),
	enddate datetime NULL,
	price float(24) NOT NULL DEFAULT 0.0 CHECK(price>=0.0),
	PRIMARY KEY(pName, sName, startdate),
);

CREATE TABLE Feedback(
	pName nvarchar(500) FOREIGN KEY REFERENCES Product(pName) ON DELETE CASCADE ON UPDATE CASCADE,
	sName varchar(100) FOREIGN KEY REFERENCES Shop(sName) ON DELETE CASCADE ON UPDATE CASCADE,
	oID int FOREIGN KEY REFERENCES Orders(oID) ON DELETE CASCADE,
	rating int NOT NULL CHECK(rating >=1 AND rating <=5),
	comment nvarchar(500) NULL,
	feedbackDate datetime DEFAULT getdate(),
	PRIMARY KEY(pName, sName, oID),
);

--Table Triggers
GO --syntax to define a batch of statements

--Update DeliveryDateTime when DeliveryStatus changed.
--If DeliveryStatus changed to 'Delivered', then DeliveryDateTime=GETDATE()
--If DeliveryStatus changed to 'Pending', then DeliveryDateTime=NULL
--One trigger, one batch of statements
CREATE TRIGGER UpdateDelivery
ON ProductsInOrders
AFTER UPDATE
NOT FOR REPLICATION
AS
BEGIN
	UPDATE	ProductsInOrders
	--DeliveryDateTime will not be updated unless DeliveryStatus changes from 'shipped' to 'delivered'
	SET		deliverydate=	CASE
									--If previous DeliveryStatus='shipped' and is changed to 'delivered', then DeliveryDateTime=GETDATE().
									WHEN d.deliverystatus='shipped' AND i.deliverystatus='delivered'
										THEN GETDATE()
									--DeliveryDateTime retains the old value
									ELSE
										d.deliverydate
								END
	--DeliveryStatus will not be updated unless if follows the sequence: 'being processed'->'shipped'->'delivered'->'returned'
			,deliverystatus=	CASE
									--If previous DeliveryStatus='being processed'. It can only be changed to 'shipped'.
									WHEN d.deliverystatus='being processed' AND i.deliverystatus<>'shipped'
										THEN 'being processed'
									--If previous DeliveryStatus='shipped'. It can only be changed to 'delivered'.
									WHEN d.deliverystatus='shipped' AND i.deliverystatus<>'delivered'
										THEN 'shipped'
									--If previous DeliveryStatus='delivered'. It can only be changed to 'returned'.
									WHEN d.deliverystatus='delivered' AND i.deliverystatus<>'returned'
										THEN 'delivered' --DeliveryStatus retains updated value
									WHEN d.deliverystatus='returned'
										THEN 'returned'
									
									ELSE
										i.deliverystatus
								END
	FROM	ProductsInOrders o, inserted i, deleted d
	--Get all the records that have just been updated, and find the previous value (inserted gives the updated rows, and deleted gives the previous values for these rows)
	WHERE 	o.SName=i.SName AND o.PName=i.PName AND o.oID=i.oID
	AND o.SName=d.SName AND o.PName=d.PName AND o.oID=d.oID;
END
GO

GO
CREATE TRIGGER ComplainStatus
ON Complaint
AFTER UPDATE
NOT FOR REPLICATION
AS
BEGIN
	UPDATE	Complaint
	SET		complainstatus=	CASE	
								WHEN d.complainstatus='pending' AND i.complainstatus='being handled' AND i.eID IS NULL
										THEN 'pending'
								
								 WHEN d.complainstatus='pending' AND i.complainstatus='being handled' AND i.eID IS NOT NULL
										THEN 'being handled'
								
									WHEN d.complainstatus='being handled' AND i.complainstatus<>'addressed'
										THEN 'being handled'

									WHEN d.complainstatus='pending' AND i.complainstatus<>'being handled'
										THEN 'pending'
									WHEN d.complainstatus='addressed'
										THEN 'addressed'
									ELSE
										i.complainstatus
								END,
			handledatetime=	CASE
									WHEN d.complainstatus='being handled' AND i.complainstatus='addressed'
										THEN getdate()
									ELSE
										d.handledatetime

								END
	FROM	Complaint o, inserted i, deleted d
	WHERE 	o.cID=i.cID AND o.cID = d.cID

END
GO
CREATE TRIGGER NoUserUpdate ON Users
AFTER UPDATE 
AS
IF UPDATE(UserID)
BEGIN
   ;THROW 51000, 'You can''t update the primary key UserID', 1;  
END
GO
CREATE TRIGGER NoEmployeeUpdate ON Employee
AFTER UPDATE 
AS
IF UPDATE(eID)
BEGIN
   ;THROW 51000, 'You can''t update the primary key employeeID', 1;  
END
GO
CREATE TRIGGER NoOrderUpdate ON Orders
AFTER UPDATE 
AS
IF UPDATE(oID)
BEGIN
   ;THROW 51000, 'You can''t update the primary key orderID', 1;  
END