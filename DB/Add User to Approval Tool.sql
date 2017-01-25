/*
	Script to Copy Permission for Pricing Approval (or Promotion tool)
	from an existing User (approver) to a new user.

	In this case we are copying Michael Egan's permission to Kari Sunderland.

	In order for this script to work, you need to provide the following:
		- Email address of the new user
		- Member ID corresponding to that Email address
		- Email addres from which user you want to copy the permission from.
	set these values in variables @NewUserEmailAddress, @NewUserMemberID, @CopyPermissionFrom respectively.

	PLEASE MAKE SURE YOU SET THE UPDATE  Flag to 1 If you want to actually commit the values or else just set to 0 
	to see what will happen if you commit.
*/
USE mnPricingApproval
GO
SET NOCOUNT ON


DECLARE @NewUserEmailAddress	VARCHAR(100)	=	'ksunderland@spark.net'
DECLARE @NewUserMemberID		INT				=	136397016
DECLARE @CopyPermissionFrom		VARCHAR(100)	=	'megan@spark.net'


DECLARE @NOW					DATETIME	= GETDATE()
DECLARE	@Debug					BIT			= 1
DECLARE	@Update					BIT			= 0

DECLARE	@SourceApproverMemberId		INT
DECLARE	@NewApproverMemberId		INT

SELECT @SourceApproverMemberId	= ApproverMemberId FROM dbo.Approver WHERE ApproverEmailAddress = @CopyPermissionFrom
SELECT @NewApproverMemberId		= ApproverMemberId FROM dbo.Approver WHERE ApproverMemberId = @NewUserMemberID

IF @Debug = 1
	SELECT	 Comments				= 'To be added Approver for ' + @NewUserEmailAddress
			,ApproverMemberId		= @NewUserMemberID
			,ApproverEmailAddress	= @NewUserEmailAddress
			,ApproverDomainAccount	= 'matchnet\' + LEFT(@NewUserEmailAddress, CHARINDEX('@', @NewUserEmailAddress) - 1)
			,UpdatedDateTime		= @NOW
			,InsertedDateTime		= @NOW
	WHERE	NOT EXISTS (SELECT * FROM dbo.Approver WHERE ApproverMemberId = @NewUserMemberID)

IF @Debug = 1
	SELECT	 Comments				=	'To be added Brand Approver for ' + @NewUserEmailAddress
			,PricingItemTypeId		=	BA.PricingItemTypeId
			,BrandId				=	BA.BrandId
			,ApproverMemberId		=	@NewUserMemberID
			,Active					=	BA.Active
			,UpdatedDateTime		=	@NOW
			,InsertedDateTime		=	@NOW
	FROM	dbo.BrandApprover	BA
	WHERE	BA.ApproverMemberId = @SourceApproverMemberId
	AND		NOT EXISTS (SELECT * FROM dbo.BrandApprover BA2 WHERE BA2.ApproverMemberId = @NewUserMemberID AND BA.BrandId = BA2.BrandId AND BA.PricingItemTypeId = BA2.PricingItemTypeId)

IF (@NewApproverMemberId IS NULL) AND (@SourceApproverMemberId IS NOT NULL)
BEGIN
	IF @Debug = 1
		SELECT Comments = CASE WHEN ApproverEmailAddress = @CopyPermissionFrom  THEN 'Copy from This account' 
							   WHEN ApproverEmailAddress = @NewUserEmailAddress THEN 'Copy to this account' 
							   ELSE '' END, * FROM dbo.Approver WHERE ApproverMemberId IN (@NewApproverMemberId, @SourceApproverMemberId)

	IF @Debug = 1
		SELECT	'Copy this to new Account', *
		FROM	dbo.Brand			B
		JOIN	dbo.BrandApprover	BA	ON	BA.BrandId = B.BrandId
		WHERE	BA.ApproverMemberId = @SourceApproverMemberId

	IF @Update = 1
		INSERT INTO dbo.Approver
				(ApproverMemberId
				,ApproverEmailAddress
				,ApproverDomainAccount
				,UpdatedDateTime
				,InsertedDateTime)
		SELECT	 ApproverMemberId		= @NewUserMemberID
				,ApproverEmailAddress	= @NewUserEmailAddress
				,ApproverDomainAccount	= 'matchnet\' + LEFT(@NewUserEmailAddress, CHARINDEX('@', @NewUserEmailAddress) - 1)
				,UpdatedDateTime		= @NOW
				,InsertedDateTime		= @NOW
		WHERE	NOT EXISTS (SELECT * FROM dbo.Approver WHERE ApproverMemberId = @NewUserMemberID)

	IF ((@Debug = 1) AND (@Update = 1))
		SELECT	 Comments				=	'After Update. Added Approver for ' + @NewUserEmailAddress + ' today.'
				,ApproverMemberId		
				,ApproverEmailAddress	
				,ApproverDomainAccount	
				,UpdatedDateTime		
				,InsertedDateTime
		FROM	dbo.Approver 
		WHERE	ApproverMemberId = @NewUserMemberID
		AND		InsertedDateTime = @NOW

	IF @Update = 1
		INSERT INTO dbo.BrandApprover
				(PricingItemTypeId
				,BrandId
				,ApproverMemberId
				,Active
				,UpdatedDateTime
				,InsertedDateTime)
		SELECT	 PricingItemTypeId		=	BA.PricingItemTypeId
				,BrandId				=	BA.BrandId
				,ApproverMemberId		=	@NewUserMemberID
				,Active					=	BA.Active
				,UpdatedDateTime		=	@NOW
				,InsertedDateTime		=	@NOW
		FROM	dbo.BrandApprover	BA
		WHERE	BA.ApproverMemberId = @SourceApproverMemberId
		AND		NOT EXISTS (SELECT * FROM dbo.BrandApprover BA2 WHERE BA2.ApproverMemberId = @NewUserMemberID AND BA.BrandId = BA2.BrandId AND BA.PricingItemTypeId = BA2.PricingItemTypeId)


	IF ((@Debug = 1) AND (@Update = 1))
		SELECT	 Comments				=	'After Update. Added Brand Approver for ' + @NewUserEmailAddress + ' today.'
				,PricingItemTypeId
				,BrandId
				,ApproverMemberId
				,Active
				,UpdatedDateTime
				,InsertedDateTime
		FROM	dbo.BrandApprover	BA
		WHERE	BA.ApproverMemberId = @NewUserMemberID
		AND		BA.InsertedDateTime = @NOW

END
