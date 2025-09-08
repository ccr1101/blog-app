-- Create the database
CREATE DATABASE Blog;
GO

--use the database
USE Blog;
GO 

-----------------------------------------------------
-- USERS TABLE
-----------------------------------------------------
CREATE TABLE Users (
	--user_id INT IDENTITY(1,1) PRIMARY KEY,
	Id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
	Username VARCHAR(100) NOT NULL,
	Email VARCHAR(150) UNIQUE NOT NULL,
	FullName VARCHAR(150), --Optioanl display name
	HashPassword VARCHAR(255) NOT NULL,
	ProfilePicture VARCHAR(500), -- URL to profile image
    Roles VARCHAR(50) DEFAULT 'user', -- Role-based access control
	isActive BIT NOT NULL DEFAULT 1,
	createdAt DATETIME NOT NULL DEFAULT GETDATE(),
	updatedAt DATETIME NULL -- Tracks last profile update
);


-----------------------------------------------------
-- BLOGS TABLE
-----------------------------------------------------

CREATE TABLE Blogs (
	BlogId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
	Title VARCHAR(200) NOT NULL,
	Content NVARCHAR(MAX) NOT NULL,
	ImageUrl VARCHAR(500) NULL,
    Tags VARCHAR(300) NULL, -- Comma-separated tags (consider Tags table for normalization)
	CreatedBy UNIQUEIDENTIFIER NOT NULL,
	CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
	UpdatedAt DATETIME NULL,
    IsPublished BIT NOT NULL DEFAULT 0, -- Draft vs published
	IsDeleted BIT NOT NULL DEFAULT 0, -- Soft delete
	FOREIGN KEY (CreatedBy) REFERENCES Users(Id)
);

-----------------------------------------------------
-- COMMENTS TABLE
-----------------------------------------------------
CREATE TABLE Comments(
	CommentId INT IDENTITY(1,1) PRIMARY KEY,
	Content NVARCHAR(500) NOT NULL,
	CreatedBy UNIQUEIDENTIFIER NOT NULL,
	BlogId UNIQUEIDENTIFIER NOT NULL,
	ParentCommentId INT NULL,
	IsFlagged BIT NOT NULL DEFAULT 0,	--for content moderation
	IsDeleted BIT NOT NULL DEFAULT 0,
	CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
	UpdatedAt DATETIME NULL,
	FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
	FOREIGN KEY (BlogId) REFERENCES Blogs(BlogId),
	FOREIGN KEY (ParentCommentId) REFERENCES Comments(CommentId)
);

-- Simple index for performance
CREATE INDEX IX_Comments_Blog_Parent ON Comments(BlogId, ParentCommentId);