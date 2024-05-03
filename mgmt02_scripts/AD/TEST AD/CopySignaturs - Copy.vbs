
'create the objects and set the initial vars
Set WshShell = WScript.CreateObject("WScript.Shell")
Set FileSysObj = CreateObject("Scripting.FileSystemObject")

Set objADSysInfo = CreateObject("ADSystemInfo")
Set UserObj = GetObject("LDAP://" & objADSysInfo.UserName)
strAppData = WshShell.ExpandEnvironmentStrings("%APPDATA%")

'checker for om User har en mail
	strMail =""
	strMail= UserObj.mail
	if strMail ="" then
		WScript.Quit 1
	end if

	Function CopyToFolder(sigfile)
		sSource = mUserFolderROOT & sigfile
		sDest = SigFolder & sigfile
		FileSysObj.CopyFile sSource,sDest,TRUE
	end Function

''
'Make Directory's
''
	'Source DIR
	' Is user does not have a root folder, then user is not valid domain user. exit the script
		usAMAccountName = UserObj.sAMAccountName
		mUserFolderROOT = "\\aura.dk\services\Deployment\GPO\MailSignature\UserProfiles\" & usAMAccountName &"\"
		if not FileSysObj.FolderExists(mUserFolderROOT) then
			WScript.Quit 1
		end if

	'Destination DIR
	'check the existence of the sig dir, if not there create it
		SigFolder = StrAppData & "\Microsoft\Signaturer\"
		if not FileSysObj.FolderExists(SigFolder) then
			FileSysObj.CreateFolder(SigFolder)
		end if

''
' MAKE IT ALL HAPPEN
''
	CopyToFolder "AD-signature" & ".htm"
	CopyToFolder "AD-signature-umobilnr" & ".htm"
	CopyToFolder "AD-signature" & ".rtf"
	CopyToFolder "AD-signature-umobilnr" & ".rtf"
	CopyToFolder "AD-signature" & ".txt"
	CopyToFolder "AD-signature-umobilnr" & ".txt"

''
'Done Create Logfile
	UsrlogFile="\\aura.dk\services\Deployment\GPO\MailSignature\mailSignaturLog\MailSigDone " & objADSysInfo.UserName &".txt"
	Set CreateLogFile=FileSysObj.CreateTextFile (UsrlogFile, 8, True)
