USE mingle
GO

/*
	This script answers question like why member in DNE is not exported to Maropost.

	eg: Ticket: DATA-
*/

-- First check if the email is in out DNE Tables
SELECT * FROM dbo.MingleDoNotEmail WHERE email IN (
'james.shearer64@yahoo.com'
, 'allredca@gmail.com'
, 'maryhope@me.com'
, 'marlenemorrow@comcast.net'
, 'whaupshank@gmail.com'
, 'donshearer@me.com'
, 'bwallbaumesb@yahoo.com'
, 'sueb1530@comcast.net'
, 'tsapp1@roadrunner.com'
, 'ashleycampbell24@yahoo.com'
, 'marlenemorrow@comcast.net'
, 'lenamaemckinney@yahoo.com'
, 'markm@bendbroadband.com'
, 'LSUGARNSPICE@CHARTER.NET'
, 'bwallbaumesb@yahoo.com'
, 'g.lapple@icloud.com'
, 'swimstar@att.net'
, 'dewaine@cox.net'
, 'nextleesa@cox.net'
, 'sguerra1992@gmail.com'
, 'rbabb28@comcast.net'
, 'saporito09@yahoo.com'
, 'kaj72388@yahoo.com'
, 'rbabb28@comcast.net'
, 'Sdholichand@yahoo.com'
, 'bengalfantew@hotmail.com'
, 'mnbra28@yahoo.com'
)

SELECT * FROM dbo.MingleDoNotEmailNotes WHERE email IN (
'james.shearer64@yahoo.com'
, 'allredca@gmail.com'
, 'maryhope@me.com'
, 'marlenemorrow@comcast.net'
, 'whaupshank@gmail.com'
, 'donshearer@me.com'
, 'bwallbaumesb@yahoo.com'
, 'sueb1530@comcast.net'
, 'tsapp1@roadrunner.com'
, 'ashleycampbell24@yahoo.com'
, 'marlenemorrow@comcast.net'
, 'lenamaemckinney@yahoo.com'
, 'markm@bendbroadband.com'
, 'LSUGARNSPICE@CHARTER.NET'
, 'bwallbaumesb@yahoo.com'
, 'g.lapple@icloud.com'
, 'swimstar@att.net'
, 'dewaine@cox.net'
, 'nextleesa@cox.net'
, 'sguerra1992@gmail.com'
, 'rbabb28@comcast.net'
, 'saporito09@yahoo.com'
, 'kaj72388@yahoo.com'
, 'rbabb28@comcast.net'
, 'Sdholichand@yahoo.com'
, 'bengalfantew@hotmail.com'
, 'mnbra28@yahoo.com'
)


-- IF emails not in MingleDoNotEmail check in source
-- NOTE UserID should be > 0 or else it won't be in DNE export. REason is UserID is used to find BH Member ID and BH Site ID which is required for export.
-- UserID are mostly 0 for majority of records because these are not REGISTERED members who were subscribed through our affiliates and are now being removed.
SELECT * FROM OPENQUERY(LAADMINDB02, 'SELECT * FROM support.do_not_email WHERE email in (
 ''james.shearer64@yahoo.com''
, ''allredca@gmail.com''
, ''maryhope@me.com''
, ''marlenemorrow@comcast.net''
, ''whaupshank@gmail.com''
, ''donshearer@me.com''
, ''bwallbaumesb@yahoo.com''
, ''sueb1530@comcast.net''
, ''tsapp1@roadrunner.com''
, ''ashleycampbell24@yahoo.com''
, ''marlenemorrow@comcast.net''
, ''lenamaemckinney@yahoo.com''
, ''markm@bendbroadband.com''
, ''LSUGARNSPICE@CHARTER.NET''
, ''bwallbaumesb@yahoo.com''
, ''g.lapple@icloud.com''
, ''swimstar@att.net''
, ''dewaine@cox.net''
, ''nextleesa@cox.net''
, ''sguerra1992@gmail.com''
, ''rbabb28@comcast.net''
, ''saporito09@yahoo.com''
, ''kaj72388@yahoo.com''
, ''rbabb28@comcast.net''
, ''Sdholichand@yahoo.com''
, ''bengalfantew@hotmail.com''
, ''mnbra28@yahoo.com''

) ')

				
SELECT * FROM dbo.MingleUser MU WITH (READUNCOMMITTED)
WHERE email IN (
'james.shearer64@yahoo.com'
, 'allredca@gmail.com'
, 'maryhope@me.com'
, 'marlenemorrow@comcast.net'
, 'whaupshank@gmail.com'
, 'donshearer@me.com'
, 'bwallbaumesb@yahoo.com'
, 'sueb1530@comcast.net'
, 'tsapp1@roadrunner.com'
, 'ashleycampbell24@yahoo.com'
, 'marlenemorrow@comcast.net'
, 'lenamaemckinney@yahoo.com'
, 'markm@bendbroadband.com'
, 'LSUGARNSPICE@CHARTER.NET'
, 'bwallbaumesb@yahoo.com'
, 'g.lapple@icloud.com'
, 'swimstar@att.net'
, 'dewaine@cox.net'
, 'nextleesa@cox.net'
, 'sguerra1992@gmail.com'
, 'rbabb28@comcast.net'
, 'saporito09@yahoo.com'
, 'kaj72388@yahoo.com'
, 'rbabb28@comcast.net'
, 'Sdholichand@yahoo.com'
, 'bengalfantew@hotmail.com'
, 'mnbra28@yahoo.com'
)


SELECT * FROM dbo.MingleUser MU WITH (READUNCOMMITTED)
WHERE Loginemail IN (
'james.shearer64@yahoo.com'
, 'allredca@gmail.com'
, 'maryhope@me.com'
, 'marlenemorrow@comcast.net'
, 'whaupshank@gmail.com'
, 'donshearer@me.com'
, 'bwallbaumesb@yahoo.com'
, 'sueb1530@comcast.net'
, 'tsapp1@roadrunner.com'
, 'ashleycampbell24@yahoo.com'
, 'marlenemorrow@comcast.net'
, 'lenamaemckinney@yahoo.com'
, 'markm@bendbroadband.com'
, 'LSUGARNSPICE@CHARTER.NET'
, 'bwallbaumesb@yahoo.com'
, 'g.lapple@icloud.com'
, 'swimstar@att.net'
, 'dewaine@cox.net'
, 'nextleesa@cox.net'
, 'sguerra1992@gmail.com'
, 'rbabb28@comcast.net'
, 'saporito09@yahoo.com'
, 'kaj72388@yahoo.com'
, 'rbabb28@comcast.net'
, 'Sdholichand@yahoo.com'
, 'bengalfantew@hotmail.com'
, 'mnbra28@yahoo.com'
)
