	SET NOCOUNT ON;
	
	DECLARE @BeginTranCount			INT	=	@@TRANCOUNT
	DECLARE @TranCount				INT	=	0

	SET @Debug						=	ISNULL(@Debug, 0)
	SET @UpdateStatusAsProcessing	=	ISNULL(@UpdateStatusAsProcessing, 0)
	SET @KeysInXMLFormat			=	''
	SET @ReturnSelectList			=	ISNULL(@ReturnSelectList, 0)

	-- SSIS CHEAT
	IF 1 = 0
		SELECT Keys

	BEGIN TRAN MarkAsPicked
	SET @TranCount = @BeginTranCount + 1

	IF @Debug = 1
		PRINT '@@TRANCOUNT:' + CONVERT(VARCHAR, @@TRANCOUNT) + ' Begin Count:' + CONVERT(VARCHAR, @BeginTranCount) + ' Local TranCount:' + CONVERT(VARCHAR, @TranCount)

	BEGIN TRY
	
		IF @TranCount > @BeginTranCount
		BEGIN
			COMMIT TRANSACTION MarkAsPicked
			SET @TranCount = @TranCount - 1
			IF @Debug = 1
				PRINT 'Transaction Committed.'
		END

		IF @Debug = 1
			PRINT 'Inside Try @@TRANCOUNT:' + CONVERT(VARCHAR, @@TRANCOUNT) + ' Begin Count:' + CONVERT(VARCHAR, @BeginTranCount) + ' Local TranCount:' + CONVERT(VARCHAR, @TranCount)

	END TRY	
	BEGIN CATCH

		DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE()
		RAISERROR(@ErrMsg, -1, -1)

		IF @TranCount > @BeginTranCount
		BEGIN
			IF @Debug = 1
				PRINT 'Rolling Back on Error'
			ROLLBACK TRANSACTION MarkAsPicked
			SET @TranCount = @TranCount - 1
		END
		IF @Debug = 1
			PRINT 'In Catch Block. @@TRANCOUNT:' + CONVERT(VARCHAR, @@TRANCOUNT) + ' Begin Count:' + CONVERT(VARCHAR, @BeginTranCount) + ' Local TranCount:' + CONVERT(VARCHAR, @TranCount)
	END CATCH

	IF @TranCount > @BeginTranCount
	BEGIN
		IF @Debug = 1
			PRINT 'Rolling Back BUT NO ERROR'
		ROLLBACK TRANSACTION MarkAsPicked
		SET @TranCount = @TranCount - 1
	END

	IF @Debug = 1
		PRINT 'Final Count. @@TRANCOUNT:' + CONVERT(VARCHAR, @@TRANCOUNT) + ' Begin Count:' + CONVERT(VARCHAR, @BeginTranCount) + ' Local TranCount:' + CONVERT(VARCHAR, @TranCount)
