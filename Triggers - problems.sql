

--Problem 01
--В базе Northwind для таблицы, указанной преподавателем индивидуально, создайте соответствующую таблицу (TableName)_history для хранения истории изменений.
--Напишите триггеры для выбранной таблицы FOR INSERT, FOR UPDATE, FOR DELETE, позволяющие хранить историю изменений в соответствующей исторической таблице.
--После тестирования работы триггеров, сделайте триггеры disabled и напишите единственный общий триггер, выполняющий ту же задачу.

USE Northwind;
GO

DROP TABLE IF EXISTS CustomersAudit;
GO
CREATE TABLE CustomersAudit(
  AuditID INTEGER NOT NULL IDENTITY(1, 1),
  CustomerID NCHAR(5),
  CompanyName NCHAR(40),
  ContactName NCHAR(30),
  ContactTitle NCHAR(30),
  Address NCHAR(60),
  City NCHAR(15),
  Region NCHAR(15),
  PostalCode NCHAR(10),
  Country NCHAR(15),
  Phone NCHAR(24),
  Fax NCHAR(24),
  ModifiedBy VARCHAR(128),
  ModifiedDate DATETIME,
  Operation CHAR(1),
  PRIMARY KEY CLUSTERED (AuditID)
)
GO    


--TRIGGER INSERT!
DROP TRIGGER IF EXISTS TR_AuditCustomer_Insert;
GO

CREATE TRIGGER TR_AuditCustomer_Insert ON dbo.Customers
  FOR INSERT
AS
  DECLARE @login_name VARCHAR(128);

  SELECT @login_name = login_name
    FROM sys.dm_exec_sessions
    WHERE session_id = @@SPID;

  INSERT INTO dbo.CustomersAudit (CustomerID, CompanyName, ContactName, ContactTitle, Address, City,  Region, PostalCode, Country, Phone, Fax, ModifiedBy, ModifiedDate, Operation)
    SELECT I.CustomerID, I.CompanyName, I.ContactName, I.ContactTitle,  I.Address,  I.City,  I.Region,  I.PostalCode,  I.Country,  I.Phone,  I.Fax, @login_name, GETDATE(), 'I'
      FROM inserted AS I;
GO

--TRIGGER UPDATE!
DROP TRIGGER IF EXISTS TR_AuditCustomer_Update;
GO

CREATE TRIGGER TR_AuditCustomer_Update ON dbo.Customers
  FOR UPDATE
AS
  DECLARE @login_name VARCHAR(128);

  SELECT @login_name = login_name
    FROM sys.dm_exec_sessions
    WHERE session_id = @@SPID;

  INSERT INTO dbo.CustomersAudit (CustomerID, CompanyName, ContactName, ContactTitle, Address, City,  Region, PostalCode, Country, Phone, Fax, ModifiedBy, ModifiedDate, Operation)
    SELECT D.CustomerID, D.CompanyName, D.ContactName, D.ContactTitle,  D.Address,  D.City,  D.Region,  D.PostalCode,  D.Country,  D.Phone,  D.Fax, @login_name, GETDATE(), 'U'
      FROM deleted AS D;
GO

--TRIGGER DELETE!
DROP TRIGGER IF EXISTS TR_AuditCustomer_Delete;
GO

CREATE TRIGGER TR_AuditCustomer_Delete ON dbo.Customers
  FOR DELETE
AS
  DECLARE @login_name VARCHAR(128);

  SELECT @login_name = login_name
    FROM sys.dm_exec_sessions
    WHERE session_id = @@SPID;

  INSERT INTO dbo.CustomersAudit (CustomerID, CompanyName, ContactName, ContactTitle, Address, City,  Region, PostalCode, Country, Phone, Fax, ModifiedBy, ModifiedDate, Operation)
    SELECT D.CustomerID, D.CompanyName, D.ContactName, D.ContactTitle,  D.Address,  D.City,  D.Region,  D.PostalCode,  D.Country,  D.Phone,  D.Fax, @login_name, GETDATE(), 'D'
      FROM deleted AS D;
GO

--Testing:

--INSERT
BEGIN TRANSACTION;
INSERT INTO dbo.Customers ( CustomerID, CompanyName, ContactName, ContactTitle)
  VALUES
    ('QQQQ', 'CompanyName1', 'ContactName1', 'ContactTitle1'),
    ('WWWW', 'CompanyName2', 'ContactName2', 'ContactTitle2');
    
SELECT *
  FROM dbo.Customers;
  
SELECT *
  FROM dbo.CustomersAudit;
ROLLBACK TRANSACTION;


--UPDATE
BEGIN TRANSACTION;
SELECT *
  FROM dbo.Customers
  WHERE CustomerID = 'QQQQ';
 
UPDATE Customers
  SET CompanyName = 'CompanyName3'
  WHERE CustomerID = 'QQQQ';
 
SELECT *
  FROM dbo.Customers
  WHERE CustomerID = 'QQQQ';
 
SELECT *
  FROM dbo.CustomersAudit
ROLLBACK TRANSACTION;


--DELETE
BEGIN TRANSACTION;
SELECT *
  FROM dbo.Customers
  WHERE CustomerID = 'QQQQ';

DELETE FROM dbo.Customers
  WHERE CustomerID = 'QQQQ';
 
 SELECT *
  FROM dbo.Customers
  WHERE CustomerID = 'QQQQ';

SELECT *
  FROM dbo.CustomersAudit;

ROLLBACK TRANSACTION;   

--or general trigger:
DISABLE TRIGGER TR_AuditCustomer_Insert ON dbo.Customers;
DISABLE TRIGGER TR_AuditCustomer_Update ON dbo.Customers;
DISABLE TRIGGER TR_AuditCustomer_Delete ON dbo.Customers;


DROP TRIGGER IF EXISTS TR_AuditCustomers;
GO

CREATE TRIGGER TR_AuditCustomers ON dbo.Customers
  FOR INSERT, UPDATE, DELETE
AS
DECLARE @login_name VARCHAR(128)

SELECT @login_name = login_name
  FROM sys.dm_exec_sessions
  WHERE session_id = @@SPID;

IF EXISTS (SELECT * FROM deleted) BEGIN

  IF EXISTS (SELECT * FROM inserted) BEGIN
  INSERT INTO dbo.CustomersAudit (CustomerID, CompanyName, ContactName, ContactTitle, Address, City,  Region, PostalCode, Country, Phone, Fax, ModifiedBy, ModifiedDate, Operation)
    SELECT D.CustomerID, D.CompanyName, D.ContactName, D.ContactTitle,  D.Address,  D.City,  D.Region,  D.PostalCode,  D.Country,  D.Phone,  D.Fax, @login_name, GETDATE(), 'U'
      FROM deleted AS D;
  END 
  
  ELSE BEGIN
  INSERT INTO dbo.CustomersAudit (CustomerID, CompanyName, ContactName, ContactTitle, Address, City,  Region, PostalCode, Country, Phone, Fax, ModifiedBy, ModifiedDate, Operation)
    SELECT D.CustomerID, D.CompanyName, D.ContactName, D.ContactTitle,  D.Address,  D.City,  D.Region,  D.PostalCode,  D.Country,  D.Phone,  D.Fax, @login_name, GETDATE(), 'D'
      FROM deleted AS D;
  END

END 

ELSE BEGIN
  INSERT INTO dbo.CustomersAudit (CustomerID, CompanyName, ContactName, ContactTitle, Address, City,  Region, PostalCode, Country, Phone, Fax, ModifiedBy, ModifiedDate, Operation)
    SELECT I.CustomerID, I.CompanyName, I.ContactName, I.ContactTitle,  I.Address,  I.City,  I.Region,  I.PostalCode,  I.Country,  I.Phone,  I.Fax, @login_name, GETDATE(), 'I'
      FROM inserted AS I;
END
GO

--Problem 02
--В таблице Something имеются числовые поля Value1, Value2, Value3, значения которых устанавливаются и изменяются пользователями. Создайте триггер, 
--с помощью которого  значение поля ValueSum поддерживается равным сумме полей Value1, Value2, Value3 при операциях вставки и изменения.  
--Продемонстрируйте работу триггера посредством кода T-SQL и при ручном редактировании таблицы в SSMS.
 
 USE Temp;
GO
DROP TABLE IF EXISTS Something;
GO
CREATE TABLE Something (
  ID integer NOT NULL IDENTITY(1, 1),
  Value1 INT,
  Value2 INT,
  Value3 INT,
  ValueSum INT,
  PRIMARY KEY CLUSTERED (ID)
 );
GO

INSERT INTO dbo.Something ( Value1, Value2, Value3, ValueSum)
  VALUES
  ( 1, 2, 3, 6),
  ( 4, 5, 6, 15),
  ( 7, 8, 9, 24)
GO 

GO
DROP TRIGGER IF EXISTS TR_Something_Insert;
GO
CREATE TRIGGER TR_Something_Insert ON dbo.Something
  FOR INSERT
AS
  UPDATE dbo.Something
    SET ValueSum = Value1 + Value2 + Value3
      WHERE dbo.Something.ID IN (SELECT ID FROM inserted);
GO

GO
DROP TRIGGER IF EXISTS TR_Something_Update;
GO
CREATE TRIGGER TR_Something_Update ON dbo.Something
  FOR UPDATE
AS
  UPDATE dbo.Something
    SET ValueSum = Value1 + Value2 + Value3
      WHERE dbo.Something.ID IN (SELECT ID FROM inserted);
GO
 
 -- insert demo:
SELECT * FROM dbo.Something;

INSERT INTO dbo.Something (Value1, Value2, Value3)
  VALUES
  (1, 2, 3),
  (4, 5, 6),
  (7, 8, 9)
GO 
    
SELECT * FROM dbo.Something;


-- update demo:
SELECT * FROM dbo.Something;

UPDATE dbo.Something
  SET Value1 = 5, Value2 = 6, Value3 = 7
  WHERE ID = 1;

SELECT * FROM dbo.Something;


--Problem 03
--В таблицу Something добавьте поле ModifiedDate и создайте триггер, устанавливающий дату и время модификации строки при операциях вставки и изменения.
--Продемонстрируйте работу триггера посредством кода T-SQL и при ручном редактировании таблицы в SSMS.
 USE Temp;
GO
ALTER TABLE dbo.Something
ADD ModifiedDate DATETIME;

SELECT * FROM dbo.Something;

GO
DROP TRIGGER IF EXISTS TR_Something_Insert;
GO
CREATE TRIGGER TR_Something_Insert ON dbo.Something
  FOR INSERT
AS
  UPDATE dbo.Something
	SET ModifiedDate = GETDATE()
      WHERE dbo.Something.ID IN (SELECT ID FROM inserted);
GO

GO
DROP TRIGGER IF EXISTS TR_Something_Update;
GO
CREATE TRIGGER TR_Something_Update ON dbo.Something
  FOR UPDATE
AS
  UPDATE dbo.Something
    SET ModifiedDate = GETDATE()
      WHERE dbo.Something.ID IN (SELECT ID FROM inserted);
GO


 -- insert demo:
SELECT * FROM dbo.Something;

INSERT INTO dbo.Something (Value1, Value2, Value3)
  VALUES
  (1, 2, 3),
  (4, 5, 6),
  (7, 8, 9)
GO 
    
SELECT * FROM dbo.Something;


-- update demo:
SELECT * FROM dbo.Something;

UPDATE dbo.Something
  SET Value1 = 5, Value2 = 6, Value3 = 7
  WHERE ID = 1;

SELECT * FROM dbo.Something;


--Problem 04
--В таблице OrderDetails базы Northwind создайте триггер TR_Check_Order, который вызывал бы исключения
--ROLLBACK TRANSACTION;
--THROW 50000, N'Превышена допустимая сумма заказа ($100000)', 1; 
--и 
--ROLLBACK TRANSACTION;
--THROW 50001, N'Превышено допустимое количество строк OrderDetails в заказе (10)', 1; 
--в случаях нарушений соответствующих правил при добавлении/изменении записей OrderDetails.

use Northwind;
GO
DROP TRIGGER IF EXISTS TR_Check_Order_Insert;
GO
CREATE TRIGGER TR_Check_Order_Insert ON dbo.OrderDetails
  FOR INSERT
AS
  UPDATE dbo.OrderDetails
    SET Quantity = Quantity, UnitPrice = UnitPrice
      WHERE dbo.OrderDetails.OrderID IN (SELECT OrderID FROM inserted);
    
   --cancellation demo
  IF EXISTS(SELECT * FROM inserted WHERE Quantity > 10) BEGIN
    ROLLBACK TRANSACTION;
    THROW 50001, N'Превышено допустимое количество строк OrderDetails в заказе (10)', 1;
  END  
    IF EXISTS(SELECT * FROM inserted WHERE UnitPrice > 100000) BEGIN
    ROLLBACK TRANSACTION;
    THROW 50002, N'Превышена допустимая сумма заказа ($100000)', 1;
  END  
GO

DROP TRIGGER IF EXISTS TR_Check_Order_Update;
GO
CREATE TRIGGER TR_Check_Order_Update ON dbo.OrderDetails
  FOR UPDATE
AS
  UPDATE dbo.OrderDetails
    SET Quantity = Quantity, UnitPrice = UnitPrice
      WHERE dbo.OrderDetails.OrderID IN (SELECT OrderID FROM inserted);
    
   --cancellation demo
  IF EXISTS(SELECT * FROM inserted WHERE Quantity > 10) BEGIN
    ROLLBACK TRANSACTION;
    THROW 50001, N'Превышено допустимое количество строк OrderDetails в заказе (10)', 1;
  END  
    IF EXISTS(SELECT * FROM inserted WHERE UnitPrice > 100000) BEGIN
    ROLLBACK TRANSACTION;
    THROW 50002, N'Превышена допустимая сумма заказа ($100000)', 1;
  END  
GO

-- insert demo:
SELECT * FROM dbo.OrderDetails where OrderID = 10727;

INSERT INTO dbo.OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
  VALUES
    (10627, 11, 500000, 9, 0.2);
    
    
SELECT * FROM dbo.OrderDetails;


-- update demo:
SELECT * FROM dbo.OrderDetails WHERE OrderID = 10727;

UPDATE dbo.OrderDetails
  SET Quantity = 13
  WHERE OrderID = 10727;

 UPDATE dbo.OrderDetails
  SET UnitPrice = 101000
  WHERE OrderID = 10727;

SELECT * FROM dbo.OrderDetails WHERE OrderID = 10727;

