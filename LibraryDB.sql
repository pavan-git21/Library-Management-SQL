-- Drop the database if it exists to avoid conflicts
DROP DATABASE IF EXISTS LibraryDB;

-- Create Database
CREATE DATABASE LibraryDB;
USE LibraryDB;

-- Create Tables
CREATE TABLE Books (
    BookID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(100) NOT NULL,
    Author VARCHAR(50) NOT NULL,
    Genre VARCHAR(30),
    PublicationYear INT,
    ISBN VARCHAR(13) UNIQUE,
    AvailableCopies INT DEFAULT 1
);

CREATE TABLE Members (
    MemberID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    JoinDate DATE DEFAULT (CURRENT_DATE())
);

CREATE TABLE BorrowRecords (
    BorrowID INT PRIMARY KEY AUTO_INCREMENT,
    BookID INT,
    MemberID INT,
    BorrowDate DATE DEFAULT (CURRENT_DATE()),
    ReturnDate DATE,
    DueDate DATE NOT NULL,
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE
);

-- Insert Sample Data
INSERT INTO Books (Title, Author, Genre, PublicationYear, ISBN, AvailableCopies) VALUES
('To Kill a Mockingbird', 'Harper Lee', 'Fiction', 1960, '9780446310789', 3),
('1984', 'George Orwell', 'Dystopian', 1949, '9780451524935', 2),
('The Great Gatsby', 'F. Scott Fitzgerald', 'Fiction', 1925, '9780743273565', 1),
('Pride and Prejudice', 'Jane Austen', 'Romance', 1813, '9780141439518', 4);

INSERT INTO Members (FirstName, LastName, Email, Phone, JoinDate) VALUES
('John', 'Doe', 'john.doe@email.com', '555-0101', '2023-01-15'),
('Jane', 'Smith', 'jane.smith@email.com', '555-0102', '2023-03-22'),
('Alice', 'Johnson', 'alice.j@email.com', '555-0103', '2024-02-10'),
('Bob', 'Williams', 'bob.w@email.com', '555-0104', '2024-06-05');

INSERT INTO BorrowRecords (BookID, MemberID, BorrowDate, ReturnDate, DueDate) VALUES
(1, 1, '2025-03-01', NULL, '2025-03-15'),
(2, 2, '2025-03-05', '2025-03-12', '2025-03-19'),
(3, 3, '2025-04-01', NULL, '2025-04-15'),
(1, 4, '2025-04-10', NULL, '2025-04-24');

-- Sample Queries
-- 1. List all books with their available copies
SELECT Title, Author, AvailableCopies
FROM Books
WHERE AvailableCopies > 0;

-- 2. Find members who have overdue books (as of current date: 2025-04-22)
SELECT m.FirstName, m.LastName, b.Title, br.DueDate
FROM Members m
JOIN BorrowRecords br ON m.MemberID = br.MemberID
JOIN Books b ON br.BookID = b.BookID
WHERE br.ReturnDate IS NULL AND br.DueDate < CURRENT_DATE();

-- 3. Count the number of books borrowed by each member
SELECT m.FirstName, m.LastName, COUNT(br.BorrowID) AS BooksBorrowed
FROM Members m
LEFT JOIN BorrowRecords br ON m.MemberID = br.MemberID
GROUP BY m.MemberID, m.FirstName, m.LastName;

-- 4. List the most popular genre based on borrowing records
SELECT b.Genre, COUNT(br.BorrowID) AS BorrowCount
FROM Books b
JOIN BorrowRecords br ON b.BookID = br.BookID
GROUP BY b.Genre
ORDER BY BorrowCount DESC
LIMIT 1;

-- 5. Update available copies when a book is borrowed
UPDATE Books
SET AvailableCopies = AvailableCopies - 1
WHERE BookID = 1 AND AvailableCopies > 0;

-- 6. Trigger to prevent borrowing if no copies are available
DELIMITER //
CREATE TRIGGER PreventBorrowIfNoCopies
BEFORE INSERT ON BorrowRecords
FOR EACH ROW
BEGIN
    DECLARE copies INT;
    SELECT AvailableCopies INTO copies
    FROM Books
    WHERE BookID = NEW.BookID;
    IF copies <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot borrow book: No copies available';
    END IF;
END //
DELIMITER ;

-- 7. View to show current borrowing status
CREATE VIEW CurrentBorrows AS
SELECT m.FirstName, m.LastName, b.Title, br.BorrowDate, br.DueDate
FROM Members m
JOIN BorrowRecords br ON m.MemberID = br.MemberID
JOIN Books b ON br.BookID = b.BookID
WHERE br.ReturnDate IS NULL;

-- Select from the view
SELECT * FROM CurrentBorrows;