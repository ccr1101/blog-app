----------------------------VIEWS------------------------------------

--Blogs with Authors
CRETE VIEW vw_BlogsWithAuthors AS 
SELECT b.BlogId, b.Title, b.CreatedAt, u.Username, u.Email
FROM Blogs b
INNER JOIN Users u ON b.CreatedBy = u.Id
WHERE b.IsDeleted = 0;

--Comments with Blog + User
CREATE VIEW vw_CommentsWithDetails AS
SELECT c.CommentId, c.Content, c.CreatedAt,
       b.Title AS BlogTitle,
       u.Username AS Commenter
FROM Comments c
INNER JOIN Blogs b ON c.BlogId = b.BlogId
INNER JOIN Users u ON c.CreatedBy = u.Id
WHERE c.IsDeleted = 0;

--Trending Blogs by Comments
