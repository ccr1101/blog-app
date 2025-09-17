ALTER PROCEDURE proc_BlogApp
	@flag VARCHAR(50),

	-- Common IDs
	@UserId UNIQUEIDENTIFIER = NULL,
	@BlogId UNIQUEIDENTIFIER = NULL,
	@CommentId INT = NULL,

    -- User Parameters
    @Username VARCHAR(100) = NULL,
	@Email VARCHAR(150) = NULL,
	@FullName VARCHAR(150) = NULL,
	@HashPassword VARCHAR(255) = NULL,
	@ProfilePicture VARCHAR(500) = NULL,
	@Roles VARCHAR(50) = NULL,
    @isActive BIT = NULL,
	
    -- Blog Parameters
    @Title VARCHAR(200) = NULL,
    @Content NVARCHAR(MAX) = NULL,
    @ImageUrl VARCHAR(500) = NULL,
	@Tags VARCHAR(300) = NULL,
    @IsPublished BIT = NULL,

	-- Comment Parameters
    @CommentContent NVARCHAR(500) = NULL,
    @ParentCommentId INT = NULL,
    @IsFlagged BIT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF @flag = 'user_insert'
	BEGIN
		IF EXISTS(SELECT 1 FROM Users WHERE Email = @Email)
		BEGIN
            EXEC proc_errorMsg 1, 'User already exists', @Email;
			RETURN;
		END
		IF EXISTS(SELECT 1 FROM Users WHERE Username = @UserId)
		BEGIN
            EXEC proc_errorMsg 1, 'User already exists', @UserId;
			RETURN;
		END

		INSERT INTO Users (Username, Email, FullName,HashPassword, ProfilePicture, Roles, isActive)
		VALUES (@Username, @Email, @FullName, @HashPassword, @ProfilePicture, ISNULL(@Roles, 'user'), 1);

		EXEC proc_errorMsg 0,'User created successfully', '';
		RETURN;
	END
    
	IF @flag = 'user_get'
	BEGIN
		SELECT * FROM Users WHERE (@UserId IS NULL OR Id = @UserId) AND isActive = 1;
		EXEC proc_errorMsg 0,'Success', '';
		RETURN;
	END

	IF @flag = 'user_update'
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Users WHERE Id = @UserId)
		BEGIN
            EXEC proc_errorMsg 1, 'User does not exists', '';
			RETURN;
		END

		UPDATE Users
        SET Username = ISNULL(@Username, Username), --If input parameter is null, the column keeps its current value.
            Email  = ISNULL(@Email, Email),
			FullName  = ISNULL(@FullName, FullName),
			ProfilePicture = ISNULL(@ProfilePicture, ProfilePicture),
			Roles = ISNULL(@Roles, Roles),
			IsActive = ISNULL(@IsActive, IsActive),
            updatedAt = GETDATE()
        WHERE id = @UserId;

		EXEC proc_errorMsg 0,'User updated successfully', '';
		RETURN;
	END

	IF @flag = 'user_delete'
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Users WHERE Id = @UserId)
		BEGIN
            EXEC proc_errorMsg 1, 'User does not exists', '';
			RETURN;
		END

		UPDATE Users
        SET isActive  = 0
        WHERE id = @UserId;

		EXEC proc_errorMsg 0,'User soft delete', '';
		RETURN;
	END

	IF @flag = 'blog-insert'
	BEGIN
        INSERT INTO Blogs (Title, Content, ImageUrl, Tags, CreatedBy, IsPublished)
        VALUES (@Title, @Content, @ImageUrl, @Tags, @UserId, ISNULL(@IsPublished, 0));

		EXEC proc_errorMsg 0,'Blog created successfully', '';
		RETURN;
	END

	IF @flag = 'blog_get'
	BEGIN
		SELECT * FROM Blogs WHERE (@BlogId IS NULL OR BlogId = @BlogId) AND IsDeleted = 0;
		EXEC proc_errorMsg 0,'Success', '';
		RETURN;
	END

	IF @flag = 'blog_update'
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Blogs WHERE BlogId = @BlogId)
		BEGIN
            EXEC proc_errorMsg 1, 'Blog does not exists', '';
			RETURN;
		END

		UPDATE Blogs
        SET Title = ISNULL(@Title, Title), --If input parameter is null, the column keeps its current value.
            Content  = ISNULL(@Content, Content),
			ImageUrl  = ISNULL(@ImageUrl, ImageUrl),
			Tags = ISNULL(@Tags, Tags),
			IsPublished = ISNULL(@IsPublished, IsPublished),
            updatedAt = GETDATE()
        WHERE BlogId = @BlogId;

		EXEC proc_errorMsg 0,'Blog updated successfully', '';
		RETURN;
	END

	IF @flag = 'blog_delete'
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Blogs WHERE BlogId = @BlogId)
		BEGIN
            EXEC proc_errorMsg 1, 'Blog does not exists', '';
			RETURN;
		END

		UPDATE Blogs
        SET IsDeleted  = 1
        WHERE BlogId = @BlogId;

		EXEC proc_errorMsg 0,'Blog soft delete', '';
		RETURN;
	END

	IF @flag = 'comment_insert'
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM Blogs WHERE BlogId = @BlogId AND IsDeleted = 0)
        BEGIN
            EXEC proc_errorMsg 1, 'Blog not found or deleted', '';
            RETURN;
        END

        INSERT INTO Comments (Content, CreatedBy, BlogId, ParentCommentId, IsFlagged)
        VALUES (@CommentContent, @UserId, @BlogId, @ParentCommentId, ISNULL(@IsFlagged, 0));

        EXEC proc_errorMsg 0, 'Comment added successfully', '';
        RETURN;
    END

    IF @flag = 'comment_get'
    BEGIN
        SELECT * FROM Comments WHERE (@BlogId IS NULL OR BlogId = @BlogId) AND IsDeleted = 0;
        EXEC proc_errorMsg 0, 'Success', '';
        RETURN;
    END

    IF @flag = 'comment_update'
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM Comments WHERE CommentId = @CommentId)
        BEGIN
            EXEC proc_errorMsg 1, 'Comment not found', '';
            RETURN;
        END

        UPDATE Comments
        SET Content = ISNULL(@CommentContent, Content),
            IsFlagged = ISNULL(@IsFlagged, IsFlagged),
            UpdatedAt = GETDATE()
        WHERE CommentId = @CommentId;

        EXEC proc_errorMsg 0, 'Comment updated successfully', '';
        RETURN;
    END

    IF @flag = 'comment_delete'
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM Comments WHERE CommentId = @CommentId)
        BEGIN
            EXEC proc_errorMsg 1, 'Comment not found', '';
            RETURN;
        END

        UPDATE Comments SET IsDeleted = 1 WHERE CommentId = @CommentId;
        EXEC proc_errorMsg 0, 'Comment soft deleted', '';
        RETURN;
    END

	--ADVANCED

	--Get all blogs with their authors (INNER JOIN Users + Blogs)
	IF @flag = 'blogs_with_users'
	BEGIN
		SELECT b.BlogId, b.Title, b.CreatedAt,
			   u.Username, u.Email
		From Blogs b
		INNER JOIN Users u ON b.CreatedBy = u.Id
		WHERE b.IsDeleted = 0; 

		EXEC proc_errorMsg 0, 'Success', '';
		RETURN;
	END

	--Get all comments with blog title + commenter name (INNER JOIN across 3 tables)
	IF @flag = 'comments_with_blog_user'
	BEGIN
		SELECT c.CommentId, c.Content AS CommentText, c.CreatedAt,
			   b.Title AS BlogTitle,
			   u.Username AS CommentedBy
		FROM Comments c
		INNER JOIN Blogs b ON c.BlogId = b.BlogId
		INNER JOIN Users u ON c.CreatedBy = u.Id
		WHERE c.IsDeleted = 0;

		EXEC proc_errorMsg 0, 'Success', '';
		RETURN;
	END

	--Left join → blogs with/without comments
	IF @flag = 'blogs_with_comments'
	BEGIN
		SELECT b.Title, b.CreatedAt,
			   COUNT(c.CommentId) AS TotalComments
		FROM Blogs b
		LEFT JOIN Comments c ON b.BlogId = c.BlogId AND c.IsDeleted = 0
		WHERE b.IsDeleted = 0
		GROUP BY b.Title, b.CreatedAt;

		EXEC proc_errorMsg 0, 'Success', '';
		RETURN;
	END

	--Users with number of blogs & comments (aggregates + GROUP BY)
	IF @flag = 'user_activity'
	BEGIN

	END
END;