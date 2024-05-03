
''' get all EMPLOYEES
Set objConnection = CreateObject("ADODB.Connection")
Set objCommand =   CreateObject("ADODB.Command")

strConnectionString = "Provider=SQLOLEDB; Data Source=DB-SQL-2016-HOT;Initial Catalog=ITstore; Integrated Security=SSPI;"
objConnection.Open strConnectionString

Set objCommand.ActiveConnection = objConnection
strCommandString="SELECT * FROM [ITstore].[dbo].[IT_ADupdate] where Init='PNH'"
'strCommandString="SELECT * FROM [ITstore].[dbo].[IT_ADupdate]"

objCommand.CommandText = strCommandString
Set objRecordSet = objCommand.Execute

objRecordSet.MoveFirst

''' Loop all users in recordset.
Do Until objRecordSet.EOF

	''' Start by clearing variables:
	ClearVariables

	''' put info into variables for each employee
	uNavn = objRecordSet.fields("Navn")
	uFornavn = trim(objRecordSet.fields("Fornavn"))
	uMellemnavn = trim(objRecordSet.fields("Mellemnavn"))
	uEfternavn = objRecordSet.fields("Efternavn")
	uInit = objRecordSet.fields("Init")
	uVistNavn = objRecordSet.fields("Vist navn")
	uLokation = objRecordSet.fields("Lokation")
	uEmail = objRecordSet.fields("E-mail")
	uTlf = objRecordSet.fields("Tlf")
	uMobil = objRecordSet.fields("Mobil")
	uVistTitel = objRecordSet.fields("Vist Titel")
	uAfdelingsnavn = objRecordSet.fields("AfdelingsNavn")
	uAfdTelefon = objRecordSet.fields("Afd Telefon")
	uAfdAddress = objRecordSet.fields("Address")
	uAfdZip = objRecordSet.fields("Zipcode")
	uAfdCity = objRecordSet.fields("City")
	uAfdWeb =objRecordSet.fields("www")
	uCompany =objRecordSet.fields("Company")
	uManager =objRecordSet.fields("Leder Init")

	'Skype phone format: tel:+4501020304
	IF NOT ISNULL(objRecordSet.fields("Tlf")) THEN
		umsRTCSIPLine = "tel:" & replace(objRecordSet.fields("Tlf")," ","")
		if  umsRTCSIPLine = "tel:" then umsRTCSIPLine=""
	END IF	
	
	
WScript.echo "start " & umsRTCSIPLine
	
	uInit=ucase(uInit)
	uFornavn = trim(uFornavn &" "& uMellemnavn)
	if uVistNavn ="" then uVistNavn = uNavn

	''' Find and update Current user 
	
		StartUpdate
	
	
    objRecordSet.MoveNext
	
Loop

'WScript.echo "DONE" 


Function StartUpdate()

	''' Find and update Current user 
	if uInit ="" OR uEmail =""  then exit function

	on error resume next
	mUser = AD_Get_Info(uInit)
	If Err.Number <> 0 Then
		'WScript.Echo "Error AD_Get_Info User: "& uInit &": " & Err.Description
		Err.Clear
	End If

	uManagerDN = AD_Get_Info(uManager)
	If Err.Number <> 0 Then
		'WScript.Echo "Error AD_Get_Info Manager: "& uManager &": " & Err.Description
		Err.Clear
	End If

	UpdateUser mUser,uManagerDN 
	If Err.Number <> 0 Then
		'WScript.Echo "Error UpdateUser : "& uInit & " : " & Err.Description
		Err.Clear
	End If

End Function	
	


	
Function ClearVariables()

	uNavn = ""
	uFornavn =""
	uMellemnavn =""
	uEfternavn =""
	uInit = ""
	uVistNavn = ""
	uLokation = ""
	uEmail = ""
	uTlf = ""
	uMobil = ""
	uVistTitel = ""
	uAfdelingsnavn = ""
	uAfdTelefon = ""
	uAfdAddress = ""
	uAfdZip = ""
	uAfdCity = ""
	uAfdWeb =""
	uCompany = ""
	uManager = ""
	uManagerDN = ""
	umsRTCSIPLine = ""
	uPager = ""
		
End Function
	
	
	
Function UpdateUser(sADname, sADmanager)

	' Bind to user object.
	dim objUser
    	Set objUser = GetObject("LDAP://" & sADname)
	
	' Assign new value value to attributes.
	If not uFornavn="" then objUser.givenName = uFornavn ' Firstname
	If not uInit="" then objUser.initials = uInit
	If not uEfternavn="" then objUser.sn = uEfternavn
	If not uVistNavn="" then objUser.displayName = uVistNavn
	If not uVistTitel="" then objUser.title = uVistTitel
	If not uTlf="" then objUser.telephoneNumber = uTlf ' Direkte telefonnr
	If not uMobil="" then objUser.mobile = uMobil 'Mobilnr.
	If not uAfdTelefon="" then objUser.ipPhone = uAfdTelefon ' Afdelingsnr.
	If not uAfdelingsnavn="" then objUser.department = uAfdelingsnavn 'Afdelingsnavn
	If not uCompany="" then objUser.company = uCompany
	If not uAfdWeb="" then objUser.wWWHomePage = uAfdWeb
	If not uInit="" then objUser.description = UCASE(uInit) 'Beskrivelse std. er sat til UCASE(samaccountname)
	If not uAfdAddress="" then objUser.streetAddress = uAfdAddress
	If not uAfdCity="" then objUser.l = uAfdCity 'By
	If not uAfdZip="" then objUser.postalCode = uAfdZip ' Postnr
	If not sADmanager="" then objUser.manager = sADmanager '
	' skype phone
	If not umsRTCSIPLine="" then objUser.Put "msRTCSIP-Line", umsRTCSIPLine 
	
	
	'clear attributes
	If uFornavn="" then objUser.PutEx 1, "givenName", 0
	If uInit="" then objUser.PutEx 1, "initials", 0
	If uEfternavn="" then objUser.PutEx 1, "sn", 0
	If uVistNavn="" then objUser.PutEx 1, "displayName", 0
	If uVistTitel="" then objUser.PutEx 1, "title", 0 
	If uTlf="" then objUser.PutEx 1, "telephoneNumber", 0 
	If uMobil="" then objUser.PutEx 1, "mobile", 0
	If uAfdTelefon="" then objUser.PutEx 1, "ipPhone", 0 
	If uAfdelingsnavn="" then objUser.PutEx 1, "department", 0 
	If uCompany="" then objUser.PutEx 1, "company", 0 
	If uAfdWeb="" then objUser.PutEx 1, "wWWHomePage", 0 
	If uInit="" then objUser.PutEx 1, "description", 0 
	If uAfdAddress="" then objUser.PutEx 1, "streetAddress", 0 
	If uAfdCity="" then objUser.PutEx 1, "l", 0 
	If uAfdZip="" then objUser.PutEx 1, "postalCode", 0
	If sADmanager="" then objUser.PutEx 1, "manager", 0
	If umsRTCSIPLine="" then objUser.PutEx 1, "msRTCSIP-Line", 0
	If uPager="" then objUser.PutEx 1, "pager", 0
		
    ' Save change.
    objUser.SetInfo

	'WScript.echo "finish update "  
end Function
	
	
	
Function AD_Get_Info(sInit)
	'Get specific AD/LDAP user info. given sAmaccountname.
	
	Dim oCmd , oConn, oRecSet , objField, objRoot,sReturn
	
    Set objRoot = GetObject("LDAP://RootDSE")
    GetNC = objRoot.get("defaultNamingContext")
	
	'Set up ADO query and excute to find group matches
	Set oCmd = CreateObject("ADODB.Command")
	Set oConn = CreateObject("ADODB.Connection")
	Set oRecSet = CreateObject("ADODB.Recordset")
	oConn.Open "Provider=ADsDSOObject;"
	
	'What to get and filter criteria
	oCmd.CommandText = "SELECT distinguishedname,samaccountname from 'LDAP://" & GetNC & "' WHERE objectCategory = 'user' and samaccountname = '" & sInit & "'"
	oCmd.activeconnection = oConn
	Set oRecSet = oCmd.Execute  'Go get the info if it exists!
	
	If oRecSet.EOF = True And oRecSet.BOF = True Then Exit Function  'Nothing found
	
	Do Until oRecSet.EOF
		sReturn = oRecSet.Fields("distinguishedName").Value
		oRecSet.MoveNext
	Loop
	
	AD_Get_Info = sReturn
	
	oConn.Close
	Set oRecSet = Nothing
	Set oConn = Nothing
	Set oCmd = Nothing
	Set objRoot = Nothing
	
End Function

