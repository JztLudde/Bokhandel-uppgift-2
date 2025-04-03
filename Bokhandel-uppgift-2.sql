-- Skapa databasen
CREATE DATABASE Bokhandel; -- Skapar databasen Bokhandel
USE Bokhandel; -- Väljer Bokhandel som aktiv databas

-- Skapa tabeller
CREATE TABLE Böcker (
    ISBN INT AUTO_INCREMENT PRIMARY KEY, -- Unik identifierare för varje bok
    Titel VARCHAR(255) NOT NULL, -- Boktitel, kan inte vara NULL
    Författare VARCHAR(255) NOT NULL, -- Författarens namn, kan inte vara NULL
    Pris DECIMAL(10,2) NOT NULL CHECK (Pris > 0), -- Pris med decimaler, måste vara större än 0
    Lagerstatus INT NOT NULL -- 1 = Finns i lager, 0 = Slut i lager
);

CREATE TABLE Kunder (
    KundID INT AUTO_INCREMENT PRIMARY KEY, -- Unik identifierare för kunder
    Namn VARCHAR(255) NOT NULL, -- Kundens namn, kan inte vara NULL
    Email VARCHAR(255) UNIQUE NOT NULL, -- E-post måste vara unik och kan inte vara NULL
    Telefon VARCHAR(255), -- Telefonnummer, valfritt
    Adress VARCHAR(255) NOT NULL -- Kundens adress, kan inte vara NULL
);

CREATE TABLE Beställningar (
    Ordernummer INT AUTO_INCREMENT PRIMARY KEY, -- Unikt ordernummer
    KundID INT NOT NULL, -- Referens till KundID
    Datum DATE NOT NULL, -- Beställningsdatum
    Totalbelopp DECIMAL(10,2) NOT NULL, -- Totalt belopp för beställningen
    FOREIGN KEY (KundID) REFERENCES Kunder(KundID) -- Kopplar beställningar till kunder
);

CREATE TABLE Orderrader (
    OrderradID INT AUTO_INCREMENT PRIMARY KEY, -- Unik identifierare för varje orderrad
    Ordernummer INT NOT NULL, -- Referens till beställning
    ISBN INT NOT NULL, -- Referens till bok
    Antal INT NOT NULL, -- Antal böcker i ordern
    Pris DECIMAL(10,2) NOT NULL, -- Pris per bok i ordern
    FOREIGN KEY (Ordernummer) REFERENCES Beställningar(Ordernummer), -- Koppling till beställning
    FOREIGN KEY (ISBN) REFERENCES Böcker(ISBN) -- Koppling till böcker
);

-- Index på e-post för snabbare sökning
CREATE INDEX idx_email ON Kunder(Email); -- Skapar index på Email för snabbare uppslag

-- Lägga till testdata
INSERT INTO Böcker (Titel, Författare, Pris, Lagerstatus) VALUES
('Ark', 'Fredrik Florensson', 199.99, 1), -- Bok i lager
('Hur man kör BMW', 'Kevin Kosner', 4999.99, 0), -- Bok slut i lager
('Databaser 101', 'Alice Andersson', 299.50, 1); -- Bok i lager

INSERT INTO Kunder (Namn, Email, Telefon, Adress) VALUES
('Per Eriksson', 'Per@email.com', '0727455800', 'Jakobsgatan 26, 111 52 Stockholm'),
('Steffe Boi', 'Steffe@email.com', '072578634', 'Stagneliusgatan 55, 388 30 Kalmar'),
('Anna Svensson', 'Anna@email.com', '0734567890', 'Kungsgatan 12, 111 22 Göteborg');

INSERT INTO Beställningar (KundID, Datum, Totalbelopp) VALUES
(1, '2025-03-20', 4999.99), -- Beställning kopplad till Per Eriksson
(2, '2025-03-17', 199.99), -- Beställning kopplad till Steffe Boi
(3, '2025-03-22', 299.50); -- Beställning kopplad till Anna Svensson

INSERT INTO Orderrader (Ordernummer, ISBN, Antal, Pris) VALUES
(1, 2, 1, 4999.99), -- Order med bok "Hur man kör BMW"
(2, 1, 1, 199.99), -- Order med bok "Ark"
(3, 3, 1, 299.50); -- Order med bok "Databaser 101"

-- Filtrera och sortera data
SELECT * FROM Kunder WHERE Namn = 'Per Eriksson'; -- Hämtar en kund med namnet Per Eriksson
SELECT * FROM Kunder WHERE Email = 'Per@email.com'; -- Hämtar en kund via e-post
SELECT * FROM Böcker ORDER BY Pris ASC; -- Hämtar alla böcker sorterade efter pris stigande

-- Modifiera data med transaktion
START TRANSACTION; -- Startar en transaktion
UPDATE Kunder SET Email = 'nyemail@email.com' WHERE KundID = 1; -- Ändrar e-post för en kund
ROLLBACK; -- Ångrar ändringen

-- Ta bort en kund
DELETE FROM Kunder WHERE KundID = 2; -- Tar bort kund med ID 2

-- Arbeta med JOINs & GROUP BY
SELECT Kunder.Namn, Beställningar.Ordernummer, Beställningar.Totalbelopp
FROM Kunder
INNER JOIN Beställningar ON Kunder.KundID = Beställningar.KundID; -- Hämtar kunder och deras beställningar

SELECT Kunder.Namn, Beställningar.Ordernummer
FROM Kunder
LEFT JOIN Beställningar ON Kunder.KundID = Beställningar.KundID; -- Hämtar alla kunder även om de inte har beställningar

SELECT KundID, COUNT(Ordernummer) AS AntalBeställningar
FROM Beställningar
GROUP BY KundID; -- Räknar antal beställningar per kund

SELECT KundID, COUNT(Ordernummer) AS AntalBeställningar
FROM Beställningar
GROUP BY KundID
HAVING COUNT(Ordernummer) > 2; -- Hämtar kunder med mer än 2 beställningar

-- Skapa triggers
DELIMITER //
CREATE TRIGGER minska_lager
AFTER INSERT ON Orderrader
FOR EACH ROW
BEGIN
    UPDATE Böcker 
    SET Lagerstatus = Lagerstatus - NEW.Antal
    WHERE ISBN = NEW.ISBN;
END;
//
DELIMITER ; -- Skapar en trigger som minskar lagersaldo när en bok beställs

DELIMITER //
CREATE TRIGGER logga_ny_kund
AFTER INSERT ON Kunder
FOR EACH ROW
BEGIN
    INSERT INTO Loggning (Meddelande, Tidpunkt) 
    VALUES (CONCAT('Ny kund registrerad: ', NEW.Namn), NOW());
END;
//
DELIMITER ; -- Skapar en trigger som loggar nya kunder

-- Backup och återställning
-- Skapa en backup
mysqldump -u root -p Bokhandel > backup.sql -- Skapar en backup av databasen

-- Återställ databasen
mysql -u root -p Bokhandel < backup.sql -- Återställer databasen från backup

DROP DATABASE bokhandel;
