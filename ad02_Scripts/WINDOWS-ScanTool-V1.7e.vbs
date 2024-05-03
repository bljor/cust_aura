Option explicit 
'*********************************************************************************************
'*	AUDIT SCRIPT
'*  Must be executed locally on each server in scope.
'*******************************************************************************************
Dim strUserDomain,strComputerDomain,RSOP, WMI, WMIPOWER,REG, StrComputer, FSO, FullPath, WSH, GroupList, objTrans, DNC, DSE, strNetBiosDomain, adGroup_Dict,LocalGroup_dict, AD_UserInfoDict, outputFile, objDNC, AdminRights, Win2kMode, strOS, strOSNAME
Dim args: Set args = CreateObject("Scripting.Dictionary")
Set GroupList = Nothing
set AD_UserInfoDict= Nothing
Dim bADDomainFound: bADDomainFound = False
Dim objNetwork :Set objNetwork = CreateObject("Wscript.Network")
Dim strDomainRole: strDomainRole = ""
Set WSH = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
'********************************************
Const ForReading = 1, ForWriting = 2, ForAppending = 8
Const TristateUseDefault = -2, TristateTrue = -1, TristateFalse = 0
Const HKCU = &H80000001 'HKEY_CURRENT_USER
Const HKLM = &H80000002 'HKEY_LOCAL_MACHINE
Const HKU  = &H80000003 'HKEY_USERS
Const PktPrivacy = 6:Const wbemAuthenticationLevelPkt = 6
Const BuildNumber=10004
Dim quote: quote = chr(34)

'********************************************************************************
'*This section is used to Toggle script "modules" *******************************
'********************************************************************************
Const ScriptName = "WINDOWS-ScanTool-V1.7e.vbs" 'Do not change
Const bCheckHardware			=True'Collect motherboard and bios information  
Const bListSoftware				=True'List software for change management review
Const bMSIInstaller 			=True'List software installation info, for change
Const bCheckShares				=True'Collect Share data                         
Const bCheckServices			=True'Collect data abount installed services    
Const bListLocalUsers			=True'collect local user and group information 
Const bListPasswordPolicy		=True 'List Domain Password Policy			    
Const bLocalPolicy				=True 'Spawn process to list local sec policy   
Const bReboot					=True 'Collect uptime and reboot information    
Const blistHotFix				=True 'Collect hotfix information               
Const bSecurityCenterCheck      =True' check AV, spyware,firewall
Const bCheckEvtLogSettings 		=True' Check eventlog settings                 
Const bCheckDomainInfo          =True' Collect domain information                
Const bDebug					=False' Debug info								
Const bListProcesses			=TRUE' List running processes and owner
Const bAuditPol					=True ' List local Audit Policy 				
Const bGetAVStatus				=True ' list aV software for clients			
Const bComputer_OS				=True ' List OS information					
Const bNetLogin					=True  ' List Login information
Const bGatherIISInformation 	=False 'List IIS information
Const bListSpecialAdGroups		=True ' List domain admins etc.
Const LISTALLADGROups			=False 'List every group in AD, small domains only!
Const bGetAdRoles 				=True 'List FSMO roles.
Const bADComputers				=True ' List Computer objects from AD
Const bCSVDE_Users				=True ' List user objects from AD using csvde on DC
Const bCSVDE_Computers			=True ' List Computer objects from AD  using csvde on DC
Const bAD_Users					=True ' List AD Users of system is in AD.
Const bGPResult					=True ' Dump GPO using gp policies
Const bShowTrust				=True ' List Trusts
Const bLocal_Groups				=True ' List local groups
Const bUserRightsAssignments	=False ' list UserRightsAssignments via WMI (Only for DC)
Const bWindowsUpdateLog			=True ' Get Windows update log
Const bNTP						=True ' List NTP settings
Const bListWindowsFirewallRules	=True ' List Windows firewall rules
Const bEventLogAccountManagement=True ' Get eventlog entries related to account management
Const bScreenSaverInfo 			=True ' Grab screensaver info (Windows 2012, power blank, and password on resume
Const bScheduledTask 			=True ' List scheduled tasks
Const bfilesystem	 			=True ' List file systems for Fixed drives (NTFS/FATxx)
Const MaxLogLines				=100000' Max amount of eventlog lines extracted
'Special groups must be AD groups, and not local groups.
Const cMaxGroupsToListall		=500 ' If the domain contains less that this amout of groups, every group is listed.
Dim arrSpecialGroups:arrSpecialGroups=ARRAY("domain admins","administrators","schema admins", "dnsadmins","enterprise admins","group policy creator owners", "account operators", "Remote Desktop Users", "server operators", "Backup Operators")
'********************************************************************************
Function ShowTrust()
	 on error Resume Next
	 err.clear
	 If Not bADDomainFound Then:  Wscript.echo "******* " & strComputer & " is not part of a domain, not listing Trusts":exit function: END IF
	 Wscript.Echo "------- Listing Trust from " & strComputer & " -------"
	 AppendToFile "*****Trust Start"  
	 Dim  TrustDirection, trusttype, TrustAttribute
	 DIM WMIAD:Set WMIAD = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\MicrosoftActiveDirectory")
	 dim o,r:Set r = wmiAD.ExecQuery ("Select * from Microsoft_DomainTrustStatus")
	 For each o in r 
		select case o.TrustDirection
		   case 0 TrustDirection = "Disabled"
		   case 1 TrustDirection = "Inbound trust"
		   case 2 TrustDirection = "Outbound trust"
		   case 3 TrustDirection = "Two-way trust"
		   case else TrustDirection = "Unknown"
		end select
		select case o.TrustType
		   case 1 TrustType =  "DOWNLEVEL"
		   case 2 TrustType =  "UPLEVEL"
		   case 3 TrustType =  "MIT"
		   case 4 TrustType =  "DCE"
		   case else TrustType =  "Unknown"
		end select
		select case o.TrustAttributes
		   case 1  TrustAttribute = "ATTRIBUTES_NON_TRANSITIVE"
		   case 2                 TrustAttribute = "ATTRIBUTES_UPLEVEL_ONLY"
		   case 4                 TrustAttribute = "ATTRIBUTES_QUARANTINED_DOMAIN"
		   case 8                 TrustAttribute = "ATTRIBUTES_FOREST_TRANSITIVE"
		   case 16              TrustAttribute = "ATTRIBUTES_CROSS_ORGANIZATION"
		   case 32              TrustAttribute = "ATTRIBUTES_WITHIN_FOREST"
		   case 64              TrustAttribute = "ATTRIBUTES_TREAT_AS_EXTERNAL"
		   case else TrustAttribute = "unknown"
		End select 
		AppendToFile CSV(ARRAY(strComputer, strComputerDomain,o.TrustedDomain,TrustDirection,trusttype,TrustAttribute,o.TrustedDCName,o.TrustStatus,o.TrustIsOK,o.TrustStatusString))
	 Next
	 AppendToFile "*****Trust End"  
End Function   
'********************************************************************************
Sub GatherIISInformation
	on error Resume Next
	Err.clear
	'Name space often not present, known MS feature.
	Wscript.Echo "------- Listing IIS information from " & strComputer & " -------"
	AppendToFile "*****IIS Start"  
	'Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\MicrosoftIISv2")
	Dim WMIIIS: Set WMIIIS = CreateObject("WbemScripting.SWbemLocator")
	WMIIIS.Security_.AuthenticationLevel = PktPrivacy
	Set objWMIService = WMIIIS.ConnectServer(strComputer,"root\MicrosoftIISv2")
	If (Err <> 0) Then:Err.Clear:Exit sub:	END IF
	Dim r,o,o2:Set r = objWMIService.ExecQuery("Select Name, ServerBindings, ServerComment from IISWebServerSetting","WQL",48)
	Dim Line:Line=""
	For Each o In r
		For Each o2 In o.ServerBindings
			with o2
				AppendToFile CSV(ARRAY(strComputer, "ServerBindings",o.Name, "", o.ServerComment, o.HostName, .IP,.port))
			End with
 		Next
	Next
	' Virtual Directories
	Set r = objWMIService.ExecQuery("Select Name, Path from IISWebVirtualDirSetting","WQL",48)
	For Each o In r
		AppendToFile CSV(ARRAY(strComputer, "VirtualDirectories", o.Name, o.Path, "", "", "", ""))
	Next
	AppendToFile "*****IIS End"  
End sub ' GatherIISInformation()
'********************************************
sub screenSaverInfo
	on error Resume Next
	Err.clear
	WScript.Echo "------- ScreenSaver Information from "& strComputer & " -------"
	Dim o,q: Set q = WMI.ExecQuery("Select * from Win32_Desktop")
	AppendToFile "*****ScreenSaverInfo Start"  
	For Each o In q
	With o
		if .screensaverActiveVal <> "" then
			AppendToFile CSV(Array(strComputer, "WMI", .name, .screensaverActive, .screenSaverSecure, .ScreensaverTimeout))
		end if
	End With
	Next
	
	Dim strKeyPath,paths: paths = Array("Control Panel\Desktop","SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop")
	dim strValueName, strValueScreenSaveTimeout, strScreenSaveActive, strScreenSaveIsSecure, screenSaveTimeout,name,screenSaverSecureVal, screensaverActiveVal
	strValueScreenSaveTimeout = "ScreenSaveTimeout"
	strScreenSaveActive = "ScreenSaveActive"
	strScreenSaveIsSecure = "ScreenSaverIsSecure"
	
	for each strKeyPath in paths
		REG.GetStringValue HKCU,strKeyPath,strValueScreenSaveTimeout,screenSaveTimeout
		REG.GetStringValue HKCU,strKeyPath,strScreenSaveActive,screensaverActiveVal
		REG.GetStringValue HKCU,strKeyPath,strScreenSaveIsSecure,screenSaverSecureVal
		if screensaverActiveVal <> "" then
			AppendToFile CSV(Array(strComputer, "RegEdit", "", screensaverActiveVal, screenSaverSecureVal, screenSaveTimeout))
		end if
	next

	' Get active power plan
	Dim opower,qpower: Set qpower = WMIPOWER.ExecQuery("select * from Win32_PowerPlan")
	dim powerSchemeGUID
	For Each opower In qpower
	With opower
		if instr(LCase(.isActive),"true") then
			powerSchemeGUID = "%" & replace(replace(.instanceid, "Microsoft:PowerPlan\{",""),"}","") & "%"
		end if
	End With
	Next
	
	'powerSchemeGUID = "%8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c%"
	dim passwordSettings:passwordSettings = "%0e796bdb-100d-47d6-a2d5-f7d2daa51f51%"
	dim displaySetting:displaySetting = "%3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e%"
	
	dim wmiqueryPowerSettings:wmiqueryPowerSettings = "select * from Win32_PowerSettingDataIndex where instanceid like " & quote & passwordSettings & quote & " and instanceid like " & quote & powerSchemeGUID & quote & " or instanceid like " & quote & displaySetting & quote & " and instanceid like " & quote & powerSchemeGUID & quote
	Dim obpower,qupower: Set qupower = WMIPOWER.ExecQuery(wmiqueryPowerSettings)
	
	For Each obpower In qupower
	With obpower
		if instr(.instanceid,replace(displaySetting,"%","")) then
			'wscript.echo "Turn of display after" & .settingIndexValue
			AppendToFile CSV(Array(strComputer, "WMIPowerSetting", "Turn of display after", .settingIndexValue, .InstanceID))
		elseif instr(.instanceid,replace(passwordSettings,"%","")) then
			'wscript.echo "Require a password on wakeup" & .settingIndexValue
			AppendToFile CSV(Array(strComputer, "WMIPowerSetting", "Require a password on wakeup", .settingIndexValue, .InstanceID))
		end if
	End With
	Next

	
	AppendToFile "*****ScreenSaverInfo End"
End Sub
'********************************************
sub Services
	on error Resume Next
	Err.clear
	WScript.Echo "------- Service Information from "& strComputer & " -------"
	Dim o,q: Set q = WMI.ExecQuery("Select * from Win32_Service")
	AppendToFile "*****Services Start"  
	For Each o In q
	With o
		Dim strDisplay: strDisplay = ""&.DisplayName
		Dim path: path = Replace(""&.PathName, chr(34), "")
		If Not (InStr(""&.PathName, path) > 0) Then: path = ""&.PathName: END IF
		AppendToFile CSV(Array(strComputer, strDisplay, .Name, .State, .StartMode, path, .description, .startName))
	End With
	Next
	AppendToFile "*****Services End"
End Sub
'********************************************
Sub WindowsUpdateLog
	on error Resume Next
	WScript.Echo "------- Windows Update Log from "& strComputer & " -------"
	AppendToFile "*****WindowsUpdateLog Start"
	readtextfile wsh.ExpandEnvironmentStrings("%windir%") & "\Windowsupdate.log","Windows Update Log"
	AppendToFile "*****WindowsUpdateLog End"
End sub
'********************************************
Function Win32_ShareACE(ACE)
	on error Resume Next
	Err.clear
	Dim strName
	' Prepend domain IF available
	If ACE.Trustee.Domain <> "" Then
		strName = ACE.Trustee.Domain & "\" & ACE.Trustee.Name
	Else
		strName = ACE.Trustee.Name
	END IF
	' ACE type
	Dim strAceType: IF ACE.AceType = 0 Then: strAceType = "Allow": Else: strAceType = "Deny": END IF
	' Access right types
	Dim v,AR: Set AR = CreateObject("Scripting.Dictionary")
	AR.Add 536870912, "Generic_Execute"
	AR.Add 268435456, "FullControl(Sub Only)"
	AR.Add 2032127, "FullControl"
	AR.Add 1048576, "Synchronize"
	AR.Add 524288, "TakeOwnership"
	AR.Add 262144, "ChangePermissions"
	AR.Add 197055, "Modify"
	AR.Add 131241, "ReadAndExecute"
	AR.Add 131209, "Read"
	AR.Add 131072, "ReadPermissions"
	AR.Add 65536, "Delete"
	AR.Add 278, "Write"
	AR.Add 256, "WriteAttributes"
	AR.Add 128, "ReadAttributes"
	AR.Add 64, "DeleteSubdirectoriesAndFiles"
	AR.Add 32, "ExecuteFile"
	AR.Add 16, "WriteExtendedAttributes"
	AR.Add 8, "ReadExtendedAttributes"
	AR.Add 4, "AppendData"
	AR.Add 2, "CreateFiles"
	AR.Add 1, "ReadData"
	' Overflow prevention
	Dim AM: AM = ACE.AccessMask AND (Not &H80000000)
	' Access rights
	Dim strAR: strAR = ""
	For Each v In AR
		If (v AND AM) = v Then
			AM = AM - v
			strAR = strAR & AR(v) & ","
		END IF
	Next
	
	if strAR = "" then
		strAR = AM & ","
	end if
	
	Win32_ShareACE=CSV(Array(UCase(strName), strAR, strAceType))
	
End Function
'********************************************
Sub UserRightsAssignments
	on error resume next
	AppendToFile "*****UserRightsAssignments Start"
	Wscript.Echo "------- UserRightsAssignments from "& strComputer & " -------"	
	
	Dim ColItems,Objitem,strAccountList:Set colItems = RSOP.ExecQuery("Select * from RSOP_UserPrivilegeRight")
	For Each objItem in colItems
		if isnull(objItem.AccountList) then
			   'Wscript.Echo csv(Array(strComputer,objItem.UserRight,objItem.Precedence,"null"))
			   AppendToFile csv(Array(strComputer,objItem.UserRight,objItem.Precedence,"null"))
		else
			For Each strAccountList in objItem.AccountList
				'Wscript.Echo csv(Array(strComputer,objItem.UserRight,objItem.Precedence,strAccountList))
				AppendToFile csv(Array(strComputer,objItem.UserRight,objItem.Precedence,strAccountList))
			Next
		End if
	Next
	AppendToFile "*****UserRightsAssignments End"
End Sub
'********************************************
Sub filesystem
	on error Resume Next
	Err.clear
	dim strNameOfUser,strUserDomain
	AppendToFile "*****Filesystem Start"
	Wscript.Echo "------- Filesystem Information from "& strComputer & " -------"	
	Dim o,q:Set q = WMI.ExecQuery ("select * from Win32_LogicalDisk where drivetype=3 and filesystem is not null")
	For Each o in q
	with o	
		AppendToFile CSV(ARRAY(strComputer,.Caption,.description, .deviceid, .filesystem,(.freespace/1024/1024/1024), (.size/1024/1024/1024), .name, .volumename))
	end with
	Next
	AppendToFile "*****Filesystem End"
End Sub
'********************************************
Sub ListProcesses
	on error Resume Next
	Err.clear
	dim strNameOfUser,strUserDomain
	AppendToFile "*****Processes Start"
	Wscript.Echo "------- Process Information from "& strComputer & " -------"	
	Dim o,q:Set q = WMI.ExecQuery ("Select * from Win32_Process")
	For Each o in q 
		o.getOwner strNameOfUser,strUserDomain
		AppendToFile CSV(ARRAY(strComputer,o.Name,o.ExecutablePath, strNameOfUser, StrUserDomain))
	Next
	AppendToFile "*****Processes End"
End Sub
'End ListProcesses
'******************************************************************************
Function Local_Shares
	on error Resume Next
	Err.clear
	Dim SS, SD, ACE
	WScript.Echo "------- Share Information from "& strComputer & " -------"
	AppendToFile "*****Shares Start"
	Dim o,q: Set q = WMI.ExecQuery("Select * from Win32_Share Where Type='0'")
	For Each o In q
	With o
		' NTFS share
		Set SS = WMI.Get("Win32_LogicalFileSecuritySetting='" & .Path & "'")
		Call SS.GetSecurityDescriptor(SD)
		For Each ACE In SD.DACL
			AppendToFile CSV(Array(strComputer, .Name, .Path, "NTFS")) & Win32_ShareACE(ACE)
		Next
		' Sharesecurity
		Set SS = WMI.Get("Win32_LogicalFileSecuritySetting='" & .Name & "'")
		Call SS.GetSecurityDescriptor(SD)
		For Each ACE In SD.DACL
			AppendToFile CSV(Array(strComputer, .Name, .Path, "Sharesecurity")) & Win32_ShareACE(ACE)
		Next
	End With
	Next
	AppendToFile "*****Shares End"
End Function
'********************************************
'********************************************
Sub AD_Computers
	on error Resume Next
	Err.clear
	If Not bADDomainFound Then:  Wscript.echo "******* " & strComputer & " is not part of a domain, not listing computers in AD":exit sub: END IF
	WScript.Echo "------- Listing AD COMPUTER objects From " & DNC & " -------"
	Dim I,T
	AppendToFile "*****DomainList Start"  
	Dim adoRS, WhenCreatedDate
	
	' ADODB connection
	Dim adoConn: Set adoConn = CreateObject("ADODB.Connection")
	Dim adoCmd:  Set adoCmd = CreateObject("ADODB.Command")
	adoConn.Provider = "ADsDSOObject"
	adoConn.Open "Active Directory Provider"
	Set adoCmd.ActiveConnection = adoConn
	
	' Domain listing
	Set adoRS = adoConn.Execute("<GC://" & DNC & ">;(objectcategory=domainDNS);name;SubTree")
	AppendToFile CSV(Array("DNC", DNC))
	Do Until adoRS.EOF
		AppendToFile CSV(Array("Other", adoRS.Fields("Name").Value))
		adoRS.MoveNext
	Loop
	adoRS.Close
	
	AppendToFile "*****DomainList End"  
	AppendToFile "*****AD_Computers Start"  
	' Server listing
	adoCmd.CommandText = "<LDAP://" & DNC & ">;(objectCategory=computer);Name,operatingSystem,operatingSystemVersion,pwdLastSet,whenCreated,distinguishedName;subtree"
	adoCmd.Properties("Page Size") = 500
	adoCmd.Properties("Timeout") = 25
	adoCmd.Properties("Cache Results") = True
	Set adoRS = adoCmd.Execute
	Dim objectCount:objectCount=ADOrs.RecordCount
	WScript.Echo "------- " & objectCount & " Computer objects found in " & DNC & " -------"
	Do Until adoRS.EOF
		I=I+1
		if I mod round((1+(objectCount/10))) = 0  Then
			t=t+1
			if t < 10 then
				WScript.StdOut.Write t & "0% . "
			End if			
		end if

		whenCreatedDATE=convertdate(adoRS.Fields("whenCreated"))
		AppendToFile CSV(Array(UCase(Trim(adoRS.Fields("Name").Value)),DateDiff("d", Integer8Date(adoRS.Fields("pwdLastSet").Value), Now),Trim(adoRS.Fields("operatingSystem").Value),Trim(adoRS.Fields("operatingSystemVersion").Value),adoRS.Fields("whenCreated"),whenCreatedDate,adoRS.Fields("distinguishedName"),DNC))
		adoRS.MoveNext
	Loop
	WScript.StdOut.Write "100% . " & vbCRLF
	adoRS.Close
	AppendToFile "*****AD_Computers End"  
End Sub
'********************************************
'********************************************
Sub NetLogin
	on error Resume Next
	Err.clear
	Wscript.Echo "------- Listing NetLogin information from " & strComputer & " -------"
	IF instr(strDomainRole,"Domain Controller") > 0 Then
		wscript.echo "******* Not listing Netlogin because " & strComputer & " is a " & strDomainRole
		exit Sub
	END IF
	AppendToFile "*****Netlogin Start"  
	Dim WMITemp : Set WMITemp = GetObject("winmgmts:{impersonationLevel=impersonate, (Restore)}!root/cimv2")
	Dim o,q: Set q = WMITemp.ExecQuery ("Select * from Win32_NetworkLoginProfile")
	For Each o in q
		with o
			AppendToFile CSV(Array(strComputer, .LastLogon, .PasswordAge, .PasswordExpires, .FullName, .Name, .BadPasswordCount, .Comment, .NumberOfLogons, .AccountExpires, .UserType, .PrimaryGroupId, .Flags, .userID ))
		end with
	Next
	AppendToFile "*****Netlogin End"  
End Sub
'********************************************
'Local Group listing
Dim StrAdminGroup, CurrentGroup,CurrentGroupSID

Sub ListLocalGroup (objGroup)
	on error Resume Next
	Err.clear
	StrAdminGroup=""
	CurrentGroup=objGroup.name
	CurrentGroupSID=objGroup.SID
	WScript.StdOut.Write "."
	strNetBIOSDomain = objNetwork.UserDomain
	set ADGroup_Dict= Nothing
	Set LocalGroup_Dict = Nothing
	Dim objLocalGroup:Set objLocalGroup = GetObject("WinNT://" & strComputer & "/" & objGroup.name & ",group")
	If ADGroup_Dict Is Nothing Then: Set ADGroup_Dict = CreateObject("Scripting.Dictionary"): END IF
	If LocalGroup_Dict Is Nothing Then: Set LocalGroup_Dict = CreateObject("Scripting.Dictionary"): END IF
	Call EnumLocalGroup(objLocalGroup)
	AppendToFile left(StrAdminGroup,len(strAdminGroup) -2) 'Suppress blank line, improvement possible, Note to self, please look for more elegant solution
End Sub
'********************************************
Sub EnumLocalGroup(ByVal objGroup)
	on error Resume Next
	Err.clear
	If LocalGroup_Dict.Exists(objGroup.Name) Then:Exit sub:Else:Call LocalGroup_Dict.Add(objGroup.Name,1):END IF
    Dim objMember, ObjectType
    For Each objMember In objGroup.Members
		if (instr(lcase(objmember.AdsPath),lcase(strComputer)) > 0) or (instr(lcase(objmember.adsPath),"nt ") > 0) or (instr(lcase(objmember.adsPath),"://builtin/") > 0)then 'NT Service & NT AUTHORITY
			ObjectType="LOCAL"
		else
			ObjectType="AD"
		end if
	   StrAdminGroup=StrAdminGroup & CSV(Array(strComputer, CurrentGroup, CurrentGroupSID, objGroup.name, objmember.Name, ObjectType,objMember.AdsPath,  objmember.Class)) & vbCRLF
       IF (LCase(objMember.Class) = "group") Then
	  
            IF (InStr(LCase(objMember.AdsPath), "/" & LCase(strComputer) & "/") > 0) Then				   
                Call EnumLocalGroup(objMember)
            ElseIf (InStr(LCase(objMember.AdsPath), "/nt authority/") > 0) Then
				'Call EnumLocalGroup(objMember)' Does not contain members
            Else
                Call EnumDomainGroup(objMember, True)
            END IF
        END IF
    Next
End Sub
'******************************************************************************
Sub Get_OS
	on error Resume Next
	'Only effective when computer_os is disabled
	Err.clear	
	With Query1(WMI, "Select * from Win32_OperatingSystem")
		strOS=.Version
		strOSName= .caption
	end with
'5.1 – Windows XP '5.2 – Windows Server 2003 '5.2.3 – Windows Server 2003 R2 '6.0 – Windows Vista & Windows Server 2008  '6.1 – Windows 7 & Windows Server 2008 R2
'6.2 – Windows 8 & Windows Server 2012 '6.3 – Windows 8.1 & Windows Server 2012 R2
End Sub
'******************************************************************************
Sub Computer_OS
	on error Resume Next
	Err.clear
	WScript.Echo "------- Operating system information from " & strComputer & " -------"
	AppendToFile "*****Operating_System Start"
	With Query1(WMI, "Select * from Win32_OperatingSystem")
		strComputer = UCase(strComputer)
		strOS=.Version
		strOSName=.caption
		AppendToFile CSV(Array(strComputer, strDomainRole, .Caption, .Version, .BuildNumber, .BuildType, .OSType, .OtherTypeDescription, .ServicePackMajorVersion & "." &  .ServicePackMinorVersion)) 
	End With
	AppendToFile "*****Operating_System End"
End Sub
'******************************************************************************
Function Hardware
	on error Resume Next
	Err.clear
	WScript.Echo "------- Hardware information from " & strComputer & " -------"
	AppendToFile "*****Hardware Start"
	Dim line: line = ""
	With Query1(WMI, "Select * from Win32_ComputerSystem")
		line = line & CSV(Array(strComputer, FormatNumber(.TotalPhysicalMemory/1024/1024,0) & "GB", .Model, .Manufacturer))
	End With
	With Query1(WMI, "Select * from Win32_BIOS")
		line = line & CSV(Array(.Caption, .Manufacturer, .SerialNumber, .Version))
	End With
	With Query1(WMI, "Select * from Win32_BaseBoard")
		line = line & CSV(Array(.Product, .Manufacturer))
	End With
	With Query1(WMI, "Select * from Win32_SystemEnclosure")
		line = line & CSV(Array(.SerialNumber, .Model, .Name, .Manufacturer))
	End With
	AppendToFile line
	AppendToFile "*****Hardware End"
End Function
'********************************************
Sub GPresult
	on error Resume Next
	Err.clear
	if win2kmode then:Wscript.echo "******* Not running GPResult on " & strComputer & " because it is running Windows 2000": exit sub:end if
	Wscript.Echo "------- Checking GPO using GPResult "& strComputer & " -------"
	Dim strText
	AppendToFile "*****GPResult Start" 	
	dim r:Set r = WSH.Exec ("" & chr(34) & "%comspec% " &  chr(34) & " /u /c gpresult /v 2>NUL")
	If Not r is Nothing Then
		Do While Not r.StdOut.AtEndOfStream
			strText=trim(Replace(Replace("" & r.StdOut.ReadLine, chr(13), ""), chr(10), ""))
			Do While InStr(strText, "  ")
				strText = trim(Replace(strText, "  ", " "))
			Loop
			if strText <> "" then
				AppendToFile csv(Array(strComputer,strText))				
			END IF
		Loop
	End If
	set r= nothing
	AppendToFile "*****GPResult END" 
End sub
'********************************************
Sub CSVDE_Computers
	on error Resume Next
	Err.clear
	IF instr(strDomainRole,"Domain Controller") > 0 Then
		Wscript.Echo "------- Running CSVDE Computers ON "& strComputer & " -------"
	Else
		Wscript.echo "******* " & strComputer & " is not DC, not running CSVDE Computers"
		exit Sub
	END IF
	Dim TempFile:TempFile=chr(34) & FullPath & strComputer & "-CSVDE.csv" &  chr(34)
	AppendToFile "*****CSVDE_Computers Start" 
	
	Dim r:Set r = WSH.Exec ("" & chr(34) & "%comspec% " &  chr(34) & " /c csvde -u -f " & TempFile & " -r ObjectCategory=Computer -l " & chr(34) & "dn, nc, name, whencreated, ObjectSID, lastlogontimestamp,operatingsystem, pwdLastSet, description" & chr(34) & " >NUL 2>NUL && type " & TempFile)
	If Not r is Nothing Then
	Do While Not r.StdOut.AtEndOfStream
		AppendToFile r.StdOut.ReadLine()
	Loop
	End If
	set r= nothing
	AppendToFile "*****CSVDE_Computers END" 
	fso.deletefile(FullPath & strComputer & "-CSVDE.csv" ) ' Object does not work qith quotes
End Sub
'********************************************
Sub CSVDE_Users
	on error Resume Next
	Err.clear
	IF instr(strDomainRole,"Domain Controller") > 0 Then
		Wscript.Echo "------- Running CSVDE Users ON "& strComputer & " -------"
	Else
		Wscript.echo "******* " & strComputer & " is not DC, not running CSVDE Users"
		exit Sub
	END IF
	Dim TempFile:TempFile=chr(34) & FullPath & strComputer & "-CSVDE.csv" &  chr(34)
	AppendToFile "*****CSVDE_Users Start" 
	Dim r:Set r = WSH.Exec ("" & chr(34) & "%comspec% " &  chr(34) & " /c csvde -u -f " & TempFile & " -r " & chr(34) & "(&(objectCategory=person)(objectClass=user))"& chr(34) & " -l " & chr(34) & "cn,description, name, dn, displayname, pwdlastset, userAccountControl, sAMAccountType, lastlogon, whencreated, accountExpires, badpwdcount, dn, givenName, sn, objectclass, samAccountName, userPrincipalName,lastlogontimestamp" & chr(34) & " >NUL 2>NUL && type " & TempFile)
	If Not r is Nothing Then
	Do While Not r.StdOut.AtEndOfStream
		AppendToFile r.StdOut.ReadLine()
	Loop
	End If
	set r= nothing
	AppendToFile "*****CSVDE_Users END" 
	fso.deletefile(FullPath & strComputer & "-CSVDE.csv" ) ' Object does not work with quotes
End Sub
'********************************************
Sub LocalPolicy
	on error Resume Next
	Err.clear
	if Win2kMode then:Wscript.echo "******* Not running secedit on " & strComputer & " because it is running Windows 2000": exit sub:end if	
	Wscript.Echo "------- Checking Local security Policy on "& strComputer & " -------"
	Dim strText, tempArr	
	Dim TempFile:TempFile=chr(34) & FullPath & strComputer & "-secpol.txt" &  chr(34)
	AppendToFile "*****LocalPasswordPolicy Start" 
	Dim r:Set r = WSH.Exec ("" & chr(34) & "%comspec% " &  chr(34) & " /u /c secedit /export /cfg " & TempFile & " 2>NUL 1>NUL")
	If Not r is Nothing Then
	Do While Not r.StdOut.AtEndOfStream
		strText=replace(trim(r.StdOut.ReadLine()),vbtab,"")
		if "" & strText <> "" then
			AppendToFile CSV(Array(strComputer,"Output",strText))
		END IF
	loop
	End If
	strText=""
	'Open result file	
	IF not FSO.FileExists(FullPath & strComputer & "-secpol.txt") Then
		Wscript.echo " Error: Secedit Output file not found, are you sure you are running this as an Administrator in an elevated prompt?"
		exit sub
	End if
	
	Dim file:Set File = fso.OpenTextFile(FullPath & strComputer & "-secpol.txt", ForReading,False,TriStateTrue)
	If Not file is Nothing Then
		Do While not File.AtEndOfStream 
			strText = File.ReadLine
			if instr(strText,"=") > 0 then
				TempArr=split(strText,"=")
				AppendToFile CSV(Array(strComputer,Trim(TempArr(0)),trim(TempArr(1))))
			END IF
		Loop
	End If
	file.close
	set r= nothing
	AppendToFile "*****LocalPasswordPolicy END" 
	fso.deletefile(FullPath & strComputer & "-secpol.txt")
End Sub
'******************************************************************************
Sub ListHotFix 
	on error Resume Next
	Wscript.Echo "------- Listing Hotfix information from " & strComputer & " -------"
	AppendToFile "*****HotFix Start"  
	Dim o,q: Set q = WMI.ExecQuery ("SELECT * FROM Win32_QuickFixEngineering")
	For Each o in q
		with o
			AppendToFile CSV(Array(strComputer, .CSNAME, .Description, .HotFixID, .installedon, .installedby, .caption))
		end with
	Next
	AppendToFile "*****HotFix END" 
End Sub
'******************************************************************************
Sub EnumDomainGroup(ByVal objDomainGroup, ByVal blnNT)
	on error Resume Next
	Err.clear
	Const ADS_NAME_INITTYPE_GC = 3
	Const ADS_NAME_TYPE_NT4 = 3
	Const ADS_NAME_TYPE_1779 = 1
	
	If ADGroup_Dict.Exists(objDomainGroup.name) Then:Exit sub:Else:	Call ADGroup_Dict.Add(objDomainGroup.Name,1):END IF
    Dim strNTName, strGroupDN, objGroup, objMember, StrDomain

	Dim TempArr
	if instr(objDomainGroup.adspath,"/") > 0 then
		temparr=split(objDomainGroup.adspath,"/")
		strDomain=TempArr(2)
	Else	
		strDomain=strNetBIOSDomain
	end if
		
    IF (IsEmpty(objTrans) = True) Then
        Set objTrans = CreateObject("NameTranslate")
        objTrans.Init ADS_NAME_INITTYPE_GC, ""
        strNTName = strDomain & "\" & objDomainGroup.Name
		
        objTrans.Set ADS_NAME_TYPE_NT4, strNTName
        strGroupDN = objTrans.Get(ADS_NAME_TYPE_1779)
        strGroupDN = Replace(strGroupDN, "/", "\/")
    Else
        IF (blnNT = True) Then
            strNTName = StrDomain & "\" & objDomainGroup.Name
            objTrans.Set ADS_NAME_TYPE_NT4, strNTName
            strGroupDN = objTrans.Get(ADS_NAME_TYPE_1779)
            strGroupDN = Replace(strGroupDN, "/", "\/")
        Else
            strGroupDN = objDomainGroup.distinguishedName
            strGroupDN = Replace(strGroupDN, "/", "\/")
        END IF
    END IF

    IF (blnNT = True) Then
        Set objGroup = GetObject("LDAP://" & strGroupDN)
    Else
        Set objGroup = objDomainGroup
    END IF
    For Each objMember In objGroup.Members
		StrAdminGroup=StrAdminGroup & CSV(Array(strComputer, CurrentGroup,CurrentGroupSID, objDomainGroup.name, REPLACE(objMember.AdsPath,"LDAP://","") ,"AD", replace(objMember.name,"CN=",""), objMember.Class )) & vbCRLF
        IF (LCase(objMember.Class) = "group") Then
            Call EnumDomainGroup(objMember, False)
        END IF
    Next
End Sub
'******************************************************************************
Sub ListPasswordPolicy
	on error Resume Next
	Dim TempResult
	TempResult =  "*****Domain_policy Start" & vbCrLF 
	If Not bADDomainFound Then:wscript.echo "******* " & strComputer & " is not part of a domain, skipping Domain password policy":Exit Sub: END IF
	Wscript.Echo "------- Listing Domain Password policy "
	dim maximumPasswordAge, minimumPasswordAge, minimumPasswordLength, accountLockoutDuration, lockoutThreshold, lockoutObservationWindow, passwordHistory
	maximumPasswordAge = Integer8Seconds(objDNC.get("maxPwdAge")) / 86400 'Days
	minimumPasswordAge = Integer8Seconds(objDNC.get("minPwdAge")) / 86400 'Days
	minimumPasswordLength = objDNC.get("minPwdLength")
	accountLockoutDuration = Integer8Seconds(objDNC.get("lockoutDuration")) / 60  'Min
	lockoutThreshold = objDNC.get("lockoutThreshold") 
	lockoutObservationWindow = Integer8Seconds(objDNC.get("lockoutObservationWindow")) / 60 'Min
	passwordHistory = objDNC.get("pwdHistoryLength")
	TempResult=TempResult & "Maximum Password Age: " & maximumPasswordAge & " days" & vbcrlf 
	TempResult=TempResult & "Minimum Password Age: " & minimumPasswordAge & " days" & vbcrlf
	TempResult=TempResult & "Enforce Password History: " & passwordHistory & " passwords remembered" & vbcrlf 
	TempResult=TempResult & "Minimum Password Length: " & minimumPasswordLength & " characters" & vbcrlf 
	TempResult=TempResult & "Account Lockout Duration: " & accountLockoutDuration & " minutes" & vbcrlf 
	TempResult=TempResult & "Account Lockout Threshold: " & lockoutThreshold & " invalid logon attempts" & vbcrlf
	TempResult=TempResult & "Reset account lockout counter after: " & lockoutObservationWindow & " minutes"
	TempResult = TempResult & "*****Domain_policy END" & vbCrLF 
End Sub
'********************************************
Sub AD_Users
	on error Resume Next
	Err.clear
	If Not bADDomainFound Then: wscript.echo "******* " & strComputer & " is not part of a domain, skipping ADUsers":Exit Sub: END IF
	WScript.Echo "------- Listing AD Users From " & DNC & " -------"
	AppendToFile "*****AD_Users Start"
	Dim adoConn: Set adoConn = CreateObject("ADODB.Connection")
	Dim adoCmd:  Set adoCmd = CreateObject("ADODB.Command")
	adoConn.Provider = "ADsDSOObject"
	adoConn.Open "Active Directory Provider"
	Set adoCmd.ActiveConnection = adoConn
	
	adoCmd.CommandText = "<LDAP://" & DNC & ">;(&(objectCategory=person)(objectClass=user));distinguishedName,whenCreated,pwdLastSet, WhenChanged,LastLogOnTimeStamp ;subtree"
	adoCmd.Properties("Page Size") = 1000
	adoCmd.Properties("Timeout") = 25
	adoCmd.Properties("Cache Results") = True
	adoCmd.Properties("Chase referrals") = &h60
	Dim adoRS: Set adoRS = adoCmd.Execute
	Dim objectCount:objectCount=ADOrs.RecordCount
	WScript.Echo "------- " & objectCount & " Users Found in " & DNC & " -------"
	Dim I,t
	Do Until adoRS.EOF
		I=I+1
		if I mod (1+(objectCount/10)) = 0  Then
			t=t+1
			if t < 10 then ' For low user counts
				WScript.StdOut.Write t & "0% . "
			End if	
		end if
		AppendToFile AD_UserInfo(adoRS.Fields("DistinguishedName").Value)
		adoRS.MoveNext
	Loop
	WScript.StdOut.Write "100% . " & vbCRLF
	adoRS.Close
	AppendToFile "*****AD_Users End"
End Sub
'********************************************
Function AD_GroupInfo(path)
	on error Resume Next
	Err.clear
	Const GROUP_TYPE_BUILTIN_LOCAL_GROUP= &h00000001
	Const GROUP_TYPE_ACCOUNT_GROUP 		= &h00000002
	Const GROUP_TYPE_RESOURCE_GROUP 	= &h00000004
	Const GROUP_TYPE_UNIVERSAL_GROUP 	= &h00000008
	Const GROUP_TYPE_SECURITY_ENABLED	= &h80000000
	Dim tmpobj:set tmpobj=GetObject("LDAP://" & path)
	With tmpobj
		Dim strGroupType: strGroupType = ""
		If .GroupType AND GROUP_TYPE_BUILTIN_LOCAL_GROUP Then: strGroupType = strGroupType & "Builtin Local,": END IF
		If .GroupType AND GROUP_TYPE_ACCOUNT_GROUP       Then: strGroupType = strGroupType & "GlobalGroup,": END IF
		If .GroupType AND GROUP_TYPE_RESOURCE_GROUP      Then: strGroupType = strGroupType & "Domain Local,": END IF
		If .GroupType AND GROUP_TYPE_UNIVERSAL_GROUP     Then: strGroupType = strGroupType & "Universal": END IF
		If .GroupType AND GROUP_TYPE_SECURITY_ENABLED    Then: strGroupType = strGroupType & "security-enabled group,": END IF
		Dim WhenChangedDate, WhenCreatedDate
		WhenCreatedDate=convertdate(.WhenCreated)
		WhenChangedDate=ConvertDate(.WhenChanged)
		AD_GroupInfo = CSV(Array(.sAMAccountName, .Description, .Class, strGroupType, .DistinguishedName, .WhenCreated, WhenCreatedDate, .WhenChanged, WhenChangedDate,HexSIDToDec(OctetToHexStr(.objectSid))))
	End With
End Function
'********************************************
Function Integer8Date(d)
	on error Resume Next
	Integer8Date = CDate(#1/1/1601# + (((d.HighPart * (2 ^ 32)) + d.LowPart) / 600000000 ) / 1440)
End Function
'*******************************************************************************
Function Integer8Seconds(ByVal objInt8)
    on error Resume Next
	Dim  lngHigh, lngLow, lngAdjust
    lngHigh = objInt8.HighPart
    lngLow = objInt8.LowPart
    IF  (lngLow < 0) Then
        lngAdjust = 1
    END IF
    Integer8Seconds = -((lngHigh+lngAdjust) * (2 ^32) + lngLow) / (10000000)
End Function
'********************************************
Sub AD_GroupMembers(path, groups, strGroupInfo)
	on error Resume Next
	Err.clear
	'Group members
	Dim o, q: Set q = GetObject("LDAP://" & path)
	For Each o In q.Members
	With o
		select case UCASE(.class)
			case "GROUP" Dim ADsPath: ADsPath = Replace(.ADsPath,"LDAP://","")' Nested group
					If Not groups.Exists(ADsPath) Then' Follow IF not seen before
						groups.Add ADsPath, 1:Call AD_GroupMembers(ADsPath, groups, strGroupInfo)
					END IF
			case "USER" AppendToFile strGroupInfo & CSV(Array(.DistinguishedName,.Class))
			case "COMPUTER" AppendToFile strGroupInfo & CSV(Array(.DistinguishedName,.Class))
			case "FOREIGNSECURITYPRINCIPAL"  AppendToFile strGroupInfo & CSV(Array(.DistinguishedName,.Class))
			case "INETORGPERSON"  AppendToFile strGroupInfo & CSV(Array(.DistinguishedName,.Class))
			case else wscript.echo "Unknown class:" & .class
		end select
	End With
	Next
End Sub
'********************************************
Sub EventLogSettings
	on error Resume Next
	Err.clear
	AppendToFile "*****EventLog_Settings Start"
	Dim o,q: Set q = wmi.ExecQuery("Select LogFileName, MaxFileSize, Name, OverwritePolicy from Win32_NTEventLogFile",,48)
	For Each o in q
		With o
			AppendToFile CSV(Array(strComputer,.LogFileName, .MaxFileSize, .Name, .Overwritepolicy)) 
		End with
	Next	 
	AppendToFile "*****EventLog_Settings End"
End Sub
'*******************************************************************************
Function OctetToHexStr(ByVal arrbytOctet)
	on error Resume Next
    OctetToHexStr = ""
    Dim k:For k = 1 To Lenb(arrbytOctet)
        OctetToHexStr = OctetToHexStr & Right("0" & Hex(Ascb(Midb(arrbytOctet, k, 1))), 2)
    Next
End Function
Function HexSIDToDec(ByVal strSID)
	on error Resume Next
	Dim arrbytSID, lngTemp, j

    ReDim arrbytSID(Len(strSID)/2 - 1)
    For j = 0 To UBound(arrbytSID)
        arrbytSID(j) = CInt("&H" & Mid(strSID, 2*j + 1, 2))
    Next

    If (UBound(arrbytSID) = 11) Then
        HexSIDToDec = "S-" & arrbytSID(0) & "-" _
            & arrbytSID(1) & "-" & arrbytSID(8)

        Exit Function
    End If

    If (UBound(arrbytSID) = 15) Then
        HexSIDToDec = "S-" & arrbytSID(0) & "-" & arrbytSID(1) & "-" & arrbytSID(8)
        lngTemp = arrbytSID(15)
        lngTemp = lngTemp * 256 + arrbytSID(14)
        lngTemp = lngTemp * 256 + arrbytSID(13)
        lngTemp = lngTemp * 256 + arrbytSID(12)
        HexSIDToDec = HexSIDToDec & "-" & CStr(lngTemp)
        Exit Function
    End If

    HexSIDToDec = "S-" & arrbytSID(0) & "-" _
        & arrbytSID(1) & "-" & arrbytSID(8)
    lngTemp = arrbytSID(15)
    lngTemp = lngTemp * 256 + arrbytSID(14)
    lngTemp = lngTemp * 256 + arrbytSID(13)
    lngTemp = lngTemp * 256 + arrbytSID(12)
    HexSIDToDec = HexSIDToDec & "-" & CStr(lngTemp)
    lngTemp = arrbytSID(19)
    lngTemp = lngTemp * 256 + arrbytSID(18)
    lngTemp = lngTemp * 256 + arrbytSID(17)
    lngTemp = lngTemp * 256 + arrbytSID(16)
    HexSIDToDec = HexSIDToDec & "-" & CStr(lngTemp)
    lngTemp = arrbytSID(23)
    lngTemp = lngTemp * 256 + arrbytSID(22)
    lngTemp = lngTemp * 256 + arrbytSID(21)
    lngTemp = lngTemp * 256 + arrbytSID(20)
    HexSIDToDec = HexSIDToDec & "-" & CStr(lngTemp)
    If (UBound(arrbytSID) > 23) Then
        lngTemp = arrbytSID(27)
        lngTemp = lngTemp * 256 + arrbytSID(26)
        lngTemp = lngTemp * 256 + arrbytSID(25)
        lngTemp = lngTemp * 256 + arrbytSID(24)
        HexSIDToDec = HexSIDToDec & "-" & CStr(lngTemp)
    End If
End Function
'********************************************
Function PadTime (time)
	on error Resume Next
	if len(time) = 1 then 
		time= 0 & time
	End if
	padtime=time
end Function
'********************************************
Function ConvertTimeWritten(WMIDate) 
	on error Resume Next
	Dim y,m,d,h,min,s
	y=LEFT(wmidate,4): m=mid(wmidate,5,2): d=mid(wmidate,7,2): h=mid(wmidate,9,2): Min=mid(wmidate,11,2): s=mid(wmidate,13,2) 
	ConvertTimeWritten=d & "-" & m & "-" & y & " " & h & ":" & min & ":" & s
End Function
'********************************************
function unUDate(intTimeStamp)
	on error Resume Next
	unUDate = DateAdd("s", intTimeStamp, "01/01/1970 00:00:00")
end function
'********************************************
function ConvertDate(strDate)
	on error resume next
	if isnull(strdate) then	exit function:if strdate="" Then exit function
	if strdate=0 then
		set Convertdate = nothing
		exit function
	end if
	if strdate="1/01/1970" then
		set Convertdate = nothing
		exit function
	end if
		
	Dim DateResult
	if isdate(strDate) Then
		DateResult=padtime(day(strdate)) & "-"& padtime(month(strdate)) & "-" & year(strdate) & " " & padtime(hour(strdate)) & ":" & padtime(Minute(strdate)) & ":" & padtime(Second(strdate))
		ConvertDate=dateresult:Exit Function
	else
		if isdate(cdate(strDate)) Then
			strdate=cdate(strDate)
			DateResult=padtime(day(strdate)) & "-"& padtime(month(strdate)) & "-" & year(strdate) & " " & padtime(hour(strdate)) & ":" & padtime(Minute(strdate)) & ":" & padtime(Second(strdate))
			ConvertDate=dateresult:Exit Function
		else
			ConvertDate=strDate:Exit Function
		end if
	End if
End function
'********************************************
SUB NTP
	on error Resume Next
	WScript.Echo "------- Listing NTP Data From (This check can take some time)" & DNC & " -------"
	AppendToFile "*****NTP Start"  
	cmdwrap("w32tm /monitor")
	AppendToFile "*****NTP End"  
End sub
'********************************************
SUB WindowsFW
	on error Resume Next
	WScript.Echo "------- Listing Windows firewall rules from "& strComputer & " -------"
	AppendToFile "*****WindowsFirewall Start"  
	cmdwrap("netsh advfirewall firewall show rule name=all")
	cmdwrap("netsh advfirewall show domain")
	cmdwrap("netsh advfirewall show private")
	cmdwrap("netsh advfirewall show public")
	AppendToFile "*****WindowsFirewall End"  
End sub
'********************************************
SUB scheduledTask
	on error Resume Next
	WScript.Echo "------- Listing ScheduledTask from "& strComputer & " -------"
	AppendToFile "*****ScheduledTask Start"  
	dim r:Set r = WSH.Exec ("schtasks -v -query -fo csv") '2>NUL"
	dim ar,val,tmpstr, line, counter
	dim arrFinal(29)

	If Not r is Nothing Then
		Do While Not r.StdOut.AtEndOfStream
			line = r.StdOut.ReadLine
			if instr(line,",") then 'To protect against binary someday using ; or other delimiter.
				ar = split(line,quote & ","& quote) ' split on ","
				tmpstr = LCase(Replace(ar(0),quote,""))
				if not instr(tmpstr,"hostname") > 0 then
					arrFinal(0) = strComputer
					arrFinal(1) = "schtasks.exe"
					counter = 2
					if UBound(ar) < 29 then ' to protect against array length
						for each val in ar
							if counter = 2 then
								arrFinal(counter) = replace(val,quote,"")
							elseif counter = 29 then
								arrFinal(counter) = replace(val,quote,"")
							else
								arrFinal(counter) = val
							end if
							counter = counter + 1
						next
					else
						wscript.echo "***** Function scheduledTask - Error  Ar size over 29" & ar
					end if
					AppendToFile csv(arrFinal)
				end if
			Else
				wscript.echo "***** Function scheduledTask - Error comma not found in: " & ar
			End if
		Loop
	End If
	set r= nothing
	AppendToFile "*****ScheduledTask End"  
End sub
'********************************************
Function AD_UserInfo(path)
	on error Resume Next
	Err.clear
	Dim LDAPobj
	path=replace(path,"/","\/") 'Fix for forward slash in CN.
	If AD_UserInfoDict Is Nothing Then: Set AD_UserInfoDict = CreateObject("Scripting.Dictionary"): END IF
	If AD_UserInfoDict.Exists(path) Then
		AD_UserInfo = AD_UserInfoDict.Item(path)
		Exit Function
	END IF
	'UserFlags	
	Const ADS_UF_SCRIPT = &H0001 
	Const ADS_UF_ACCOUNTDISABLE = &H0002 
	Const ADS_UF_HOMEDIR_REQUIRED = &H0008 
	Const ADS_UF_LOCKOUT = &H0010 
	Const ADS_UF_PASSWD_NOTREQD = &H0020 
	Const ADS_UF_PASSWD_CANT_CHANGE = &H0040 
	Const ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED = &H0080 
	Const ADS_UF_DONT_EXPIRE_PASSWD = &H10000 
	Const ADS_UF_SMARTCARD_REQUIRED = &H40000 
	Const ADS_UF_PASSWORD_EXPIRED = &H800000	
	set LDAPobj =GetObject("LDAP://" & path)
	
	With LDAPObj ' Prevent none recoverable error when object is nothing.
		Dim strPwdLastSet,strPasswordLastSet,strPasswordLastSetDate, strLastLogon, LastLogonDate, bPwdRequired, strDisabled, strPwdExpired, strLockOut,strPwdExpires,strReversibleEncryptionAllowed,PasswordChangeable,strAccountExpiration, AccountExpirationDate, strobjectSid,tempsid, WhenCreatedDate,WhenChangedDate
        strAccountExpiration = .AccountExpirationDate
		Dim strMustChangePasswordNextLogon:strMustChangePasswordNextLogon=""
		Dim struserWorkstations:struserWorkstations=""
		If Err.Number = -2147467259 Or strAccountExpiration = "1/1/1970" or strAccountExpiration="01-01-1970" or strAccountExpiration ="01-01-1601 01:00:00" Then
			strAccountExpiration=""		
		End If
		AccountExpirationDate=ConvertDate(strAccountExpiration)
		
		if ("" & .userWorkstations <> "") then
			strUserWorkstations="" & .UserWorkstations 
		end if
		
		If .PasswordLastChanged = "" Then: strPasswordLastSet = "Never": Else strPasswordLastSet = .PasswordLastChanged: END IF
		strPasswordLastSetDATE=ConvertDate(.PasswordLastChanged)
		strMustChangePasswordNextLogon="No"
		if (.Get("pwdLastSet").HighPart + .Get("pwdLastSet").LowPart) = 0 then 
			strMustChangePasswordNextLogon="Yes"
		End if
		
		If .PasswordRequired Then: bPwdRequired = True: Else bPwdRequired = False: END IF
		If .userAccountControl AND ADS_UF_ACCOUNTDISABLE Then strDisabled = "True":	Else: strDisabled = "False": END IF
		If .userAccountControl AND ADS_UF_PASSWORD_EXPIRED Then strPwdExpired = "True":	Else: strPwdExpired = "False": END IF
		If .userAccountControl AND ADS_UF_DONT_EXPIRE_PASSWD Then strPwdExpires = "False":	Else: strPwdExpires = "True": END IF
		If .userAccountControl AND ADS_UF_PASSWD_CANT_CHANGE Then PasswordChangeable = "False":	Else: PasswordChangeable = "True": END IF
		If .userAccountControl AND ADS_UF_LOCKOUT Then strLockOut = "True":	Else: strLockOut = "False": END IF
		if .userAccountControl and ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED then strReversibleEncryptionAllowed= "True": Else: strReversibleEncryptionAllowed = "False": End if
		strLastLogon = Integer8Date(.Get("lastLogonTimestamp"))
		LastLogonDate=convertdate(strLastLogon)
		tempsid=OctetToHexStr(.objectSid)
		strObjectSid="" & HexSIDToDec(tempsid)
		if LDAPObj is nothing then 
		       AD_UserInfo = CSV(Array("ERROR:" & PATH, "","","","","", "","","","", "", "", "", path, "", "","", "", ""))
                else
				   WhenChangedDate=convertdate(.WhenChanged)
				   WhenCreatedDate=ConvertDate(.WhenCreated)
                   AD_UserInfo = CSV(Array(.sAMAccountName, .Description, .Class, .DisplayName, .GivenName, .SN, strPasswordLastSet,strPasswordLastSetDate,strPwdExpires,strMustChangePasswordNextLogon,PasswordChangeable,_
                   strLastLogon,LastLogonDate, bPwdRequired, strDisabled, strPwdExpired, strReversibleEncryptionAllowed, .DistinguishedName, .WhenCreated, WhenCreatedDate, .WhenChanged, WhenChangedDate, strLockOut, strAccountExpiration, AccountExpirationDate,strObjectSid,strUserWorkstations,DNC))
                End if
	End With
	Call AD_UserInfoDict.Add(path, AD_UserInfo)
End Function
'********************************************
Sub AD_Groups (rArgs)
	on error Resume Next
	Err.clear
	If Not bADDomainFound Then: wscript.echo "******* " & strComputer & " is not part of a domain, skipping AD Groups":Exit Sub: END IF
	WScript.Echo "------- Listing AD Groups From " & DNC & " -------"
	AppendToFile "*****AD_Groups Start"
	' ADODB connection
	Dim adoConn: Set adoConn = CreateObject("ADODB.Connection")
	Dim adoCmd:  Set adoCmd = CreateObject("ADODB.Command")
	adoConn.Provider = "ADsDSOObject"
	adoConn.Open "Active Directory Provider"
	Set adoCmd.ActiveConnection = adoConn
	Dim strFilter:strFilter = "(&(objectCategory=Group)"
	Dim objectCount
	Dim bListallGroups:bListallGroups=FALSE 
	Dim adoRS
	
	if isnull(rArgs) then
		bListallGroups=True
		adoCmd.CommandText = "<LDAP://" & DNC & ">;"& strFilter & ");distinguishedName;subtree"
		adoCmd.Properties("Page Size") = 1000
		adoCmd.Properties("Timeout") = 25
		adoCmd.Properties("Cache Results") = TRUE
		Set adoRS = adoCmd.Execute
		objectCount=ADOrs.RecordCount
	Else
		adoCmd.CommandText = "<LDAP://" & DNC & ">;"& strFilter & ");distinguishedName;subtree"
		adoCmd.Properties("Page Size") = 1000
		adoCmd.Properties("Timeout") = 25
		adoCmd.Properties("Cache Results") = TRUE
		Set adoRS = adoCmd.Execute
		objectCount=ADOrs.RecordCount
		if objectCount < cMaxGroupsToListall then
			bListallGroups=True
		End if
	End if
		
	if not bListallGroups then
		strFilter=strFilter & "(|"
		Dim tempstr
		Dim i:for i=0 to Ubound(rArgs)			 
			tempstr= tempstr & "(name=" & rArgs(i) & ")"
		Next
		strFilter=strFilter & tempstr & ")"
		adoCmd.CommandText = "<LDAP://" & DNC & ">;"& strFilter & ");distinguishedName;subtree"
		adoCmd.Properties("Page Size") = 1000
		adoCmd.Properties("Timeout") = 25
		adoCmd.Properties("Cache Results") = TRUE
		'adoCmd.Properties("Chase referrals") = &h60  
		Set adoRS = adoCmd.Execute
		objectCount=ADOrs.RecordCount
	END IF
	
	' Groups
	Dim groups: set groups = CreateObject("Scripting.Dictionary")
	Dim t
	I=0
	WScript.Echo "------- " & objectCount & " Group objects found in " & DNC & " -------"
	Do Until adoRS.EOF
		if objectCount > 100 then
			I=I+1
			if I mod round((1+(objectCount/100))) = 0  Then
				t=t+1
				WScript.StdOut.Write t & "% . "
			end if
		else
			'wscript.echo "no indicator due, to low # of groups:" & objectCount
		end if
		
		Dim strDN: strDN = adoRS.Fields("DistinguishedName").Value
		Dim strGI: strGI = AD_GroupInfo(strDN)
		groups.RemoveAll
		groups.Add strDN, 1
		Call AD_GroupMembers(strDN, groups, strGI)
		adoRS.MoveNext
	Loop
	adoRS.Close
	AppendToFile "*****AD_Groups End"
End Sub
'********************************************
Sub Local_Groups
	on error Resume Next
	Err.clear
	IF instr(strDomainRole,"Domain Controller") > 0 Then
		wscript.echo "******* Not listing Local Groups because " & strComputer & " is a " & strDomainRole
		exit Sub
	END IF
	WScript.StdOut.Write "------- Listing Local Groups From " & strComputer & " "
	AppendToFile "*****Local_Groups Start"
	Dim o,q: Set q = WMI.ExecQuery("Select * from Win32_Group  Where LocalAccount = True")
	For Each o In q
		ListLocalGroup(o)
	Next
	If q.Count = 0 Then
		AppendToFile CSV(Array("No local groups", "", "", "", "", strComputer, ""))
	END IF
	wscript.echo  " -------"
	AppendToFile "*****Local_Groups End"
End sub
'********************************************
Function AppendToFile(StrResult)
	on error Resume Next
	Err.clear
	Dim ObjFile
	OutPutFile.close ' Just to be sure.
	Set objFile = FSO.OpenTextFile(OutPutFile, ForAppending,True, True) 
	objFile.WriteLine StrResult
	objFile.close
End Function 'Appendtofile
'******************************************************************************
Sub Computer_LocalName
	on error Resume Next
	Err.clear
	Dim o: Set o = WScript.CreateObject("WScript.Network")
	If Err = 0 Then: strComputer = UCase(Trim(o.ComputerName)): Else: strComputer = "." END IF
End Sub
'********************************************
Sub ConnectWMI
	on error Resume Next' required
	Err.clear
	' Use credentials of current user
		Set WMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
		If Err<>0 Then: wscript.echo "**** FATAL ERROR, UNABLE TO CONNECT TO WMI ON " & STRCOMPUTER & " AdminRights = " & adminright: END IF
		Set WMIPOWER = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2\power")
		If Err<>0 Then: wscript.echo "**** FATAL ERROR, UNABLE TO CONNECT TO WMI ON " & STRCOMPUTER & " AdminRights = " & adminright: END IF
		Set RSOP = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\rsop\computer") 
		If Err<>0 Then: wscript.echo "**** FATAL ERROR, UNABLE TO CONNECT TO RSOP ON " & STRCOMPUTER & " AdminRights = " & adminright: END IF
		Set REG = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
		If Err <> 0 Then
			Err.clear
			Set REG = GetObject("winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!\\" & strComputer & "\root\default:StdRegProv")
			If Err<>0 Then: wscript.echo "**** FATAL ERROR, UNABLE TO CONNECT TO REGISTRY ON " & STRCOMPUTER & " AdminRights = " & adminright: END IF
		END IF
	If bDebug then : Wscript.echo "**WMI CONNECTED" : END IF
End Sub
'********************************************
Sub GetDomain
	on error Resume Next
	err.clear	
	If Not bADDomainFound Then:Exit Sub: END IF
	Dim objSysInfo:Set objSysInfo = CreateObject( "WinNTSystemInfo" )
	strUserDomain = objSysInfo.DomainName
	Dim o,r:Set r = wmi.ExecQuery("Select * from Win32_ComputerSystem")
	For Each o in r
		strComputerDomain = o.Domain	
	Next
End sub
'********************************************
Sub ConnectDSE
	on error Resume Next
	Err.clear
	Set DSE = GetObject("LDAP://RootDSE")
	' Default Naming Context
	DNC = DSE.Get("DefaultNamingContext")
	Set objDNC = GetObject ("LDAP://" & DSE.Get("defaultNamingContext"))
	If Trim(DNC) = "" Then
		bADDomainFound = False
	Else
		bADDomainFound = True
	END IF
	If bDebug then : Wscript.echo "**DSE CONNECTED DOMAIN FOUND=" & bADDomainFound: END IF
End Sub
'********************************************
Sub ADRoles
	on error Resume Next
	Err.clear
	If Not bADDomainFound Then: wscript.echo "******* " & strComputer & " is not part of a domain, skipping ADRoles":Exit Sub: END IF
	WScript.Echo "------- Listing AD Roles From " & strComputer & " -------"
	AppendToFile "*****AD_Roles Start"
	Dim SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster
	
	SchemaMaster = GetObject(GetObject("LDAP://" & GetObject("LDAP://" & DSE.Get("schemaNamingContext")).Get("fSMORoleOwner")).Parent).dNSHostName
	DomainNamingMaster = GetObject(GetObject("LDAP://" & GetObject("LDAP://CN=Partitions," & DSE.Get("configurationNamingContext")).Get("fSMORoleOwner")).Parent).dNSHostName
	PDCEmulator = GetObject(GetObject("LDAP://" & objDNC.Get("fSMORoleOwner")).Parent).dNSHostName
	RIDMaster = GetObject(GetObject("LDAP://" & GetObject("LDAP://CN=RID Manager$,CN=System," &  DSE.Get("defaultNamingContext")).Get("fSMORoleOwner")).Parent).dNSHostName
	InfrastructureMaster = GetObject(GetObject("LDAP://" & GetObject("LDAP://CN=Infrastructure," & DSE.Get("defaultNamingContext")).Get("fSMORoleOwner")).Parent).dNSHostName
	
	AppendToFile CSV(Array(strComputer, "Schema Master", SchemaMaster))	
	AppendToFile CSV(Array(strComputer, "Domain Naming Master", DomainNamingMaster))	
	AppendToFile CSV(Array(strComputer, "PDC Emulator", PDCEmulator))	
	AppendToFile CSV(Array(strComputer, "RID Master", RIDMaster))	
	AppendToFile CSV(Array(strComputer, "Infrastructure Master Master", InfrastructureMaster))	
	AppendToFile "*****AD_Roles End"
	'Functional Levels
	AppendToFile "*****AD_FunctionalLevel Start"
    Select Case DSE.Get("domainFunctionality")
        Case "0" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainFunctionality","Windows 2000 Mixed Domain Mode"))
        Case "1" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainFunctionality","Windows 2003 With Mixed domains"))
        Case "2" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainFunctionality","Windows Server 2003 Interim Domain Mode"))
        Case "3" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainFunctionality","Windows Server 2008"))
		Case "4" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainFunctionality","Windows Server 2008R2 Domain Mode"))
		Case "5" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainFunctionality","Windows Server 2012 Domain Mode"))
        Case Else AppendToFile CSV(ARRAY(strComputer,strUserDomain, "n/a","n/a"))
    End Select
	 'Find Forest Function Level
    Select Case DSE.Get("forestFunctionality")
        Case "0" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"forestFunctionality","Windows 2000 Mixed Domain Mode"))
        Case "1" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"forestFunctionality","Windows 2003 With Mixed domains"))
        Case "2" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"forestFunctionality","Windows Server 2003 Interim Domain Mode"))
        Case "3" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"forestFunctionality","Windows Server 2008"))
		Case "4" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"forestFunctionality","Windows Server 2008R2 Domain Mode"))
		Case "5" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"forestFunctionality","Windows Server 2012 Domain Mode"))
        Case Else AppendToFile CSV(ARRAY(strComputer,strUserDomain,"forestFunctionality", "n/a","n/a"))
    End Select

    'Find DC Function Level        
    Select Case DSE.Get("domainControllerFunctionality")
        Case "0" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainControllerFunctionality","Windows 2000 Mixed Domain Mode"))
        Case "1" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainControllerFunctionality","Windows 2003 With Mixed domains"))
        Case "2" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainControllerFunctionality","Windows Server 2003 Interim Domain Mode"))
        Case "3" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainControllerFunctionality","Windows Server 2008"))
		Case "4" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainControllerFunctionality","Windows Server 2008R2 Domain Mode"))
		Case "5" AppendToFile CSV(ARRAY(StrComputer, strUserDomain,"domainControllerFunctionality","Windows Server 2012 Domain Mode"))
        Case Else AppendToFile CSV(ARRAY(strComputer,strUserDomain,"domainControllerFunctionality", "n/a"))
    End Select
	AppendToFile "*****AD_FunctionalLevel End"
End Sub
'********************************************
Function Query1(WMI, query)
	on error Resume Next
	Err.clear
	Set Query1 = Nothing
	If Not IsNull(WMI) Then
		Dim q,r: Set q = WMI.ExecQuery(query)
		If Err = 0 Then
			If q.Count > 0 Then: For Each r In q: Set Query1 = r: Exit Function: Next: END IF
		END IF
	END IF
End Function
'********************************************
Sub Computer_DomainRole
	on error Resume Next
	Err.clear
	With Query1(WMI, "Select DomainRole from Win32_ComputerSystem")
		Select Case .DomainRole
			Case 0: strDomainRole = "Standalone Workstation"
			Case 1: strDomainRole = "Member Workstation"
			Case 2: strDomainRole = "Standalone Server"
			Case 3: strDomainRole = "Member Server"
			Case 4: strDomainRole = "Backup Domain Controller"
			Case 5: strDomainRole = "Primary Domain Controller"
		End Select
	End With
	If bDebug then : Wscript.echo "**DOMAIN ROLE=" & strDomainRole: END IF
End Sub
'********************************************
Function CSV(arr)
	on error Resume Next
	Err.clear
	Dim quote: quote = chr(34)
	Dim sep:   sep   = ";"
	Dim str, field
	CSV = ""
	For Each Field in arr
		str = "" & Replace(Replace("" & field, chr(13), ""), chr(10),"")
		CSV = CSV & quote & Replace(str, quote, quote & quote) & quote & sep
	Next
End Function
'********************************************
Function CreateFile(filename)
	on error Resume Next
	Err.clear
	if ifexist (FullPath & strComputer & filename) then:FSO.DeleteFile(FullPath & strComputer & filename):end if
	Set CreateFile = FSO.CreateTextFile(filename, True, True)
End Function
'******************************************************************************
'This function is TRUE IF the file exists
Function IfExist (sFileName)
	on error Resume Next
	IF FSO.FileExists(sFileName) Then:IfExist = TRUE:End IF
End Function  ' Delete file
'******************************************************************************
Function Local_Users
	on error Resume Next
	Err.clear
	WScript.Echo "------- Listing Local Users From " & strComputer & " -------"
	If(Instr(strDomainRole,"Domain") > 0) Then
		WScript.Echo("******* Not lising local users since " & strComputer & " is a " & strDomainRole)
		Local_Users = True 
		Exit Function
	END IF
	AppendToFile "*****LocalUsers Start"
	Dim o,q: Set q = WMI.ExecQuery("Select * from Win32_UserAccount Where LocalAccount = True and SidType=1")
	For Each o In q
	With o
		Err.clear
		Dim r: Set r = GetObject("WinNT://" & strComputer & "/" & .Name & ", user")
		Dim strLastLogin: strLastLogin = r.LastLogin
		If Err<>0 Then: strLastLogin = "Never": END IF
		Dim Caption: Caption = .Caption
		If Instr(Caption,"\") > 0 Then: Caption = Split(.Caption,"\")(1): END IF
		AppendToFile CSV(Array(strComputer, Caption, .AccountType, .Description, .Disabled, .Domain, .Lockout, _
			.Name, .PasswordChangeable, .PasswordExpires, .PasswordRequired, .SID, SIDType(.SIDType), .Status, _
			strLastLogin, DateAdd("s", r.PasswordAge * -1, Now), r.PasswordMinimumLength, .LocalAccount))
	End With
	Next
	AppendToFile "*****LocalUsers End"
End Function
'********************************************
Function SIDType(sid)
	on error Resume Next
	Select Case SID
		Case 1: SIDType = "User"
		Case 2: SIDType = "Group"
		Case 3: SIDType = "Domain"
		Case 4: SIDType = "Alias"
		Case 5: SIDType = "WellKnownGroup"
		Case 6: SIDType = "DeletedAccount"
		Case 7: SIDType = "Invalid"
		Case 8: SIDType = "Unknown"
		Case 9: SIDType = "Computer"		
		Case Else: SIDType = "Unknown"
	End Select
End Function
'********************************************
Function domainInfo
	on error Resume Next
	Err.clear
	If Not bADDomainFound Then: wscript.echo "******* " & strComputer & " is not part of a domain, skipping domainInfo":Exit Function: END IF
	CONST ADS_SYSTEMFLAG_CR_NTDS_DOMAIN  = &H2 
	WScript.Echo "------- Listing domains from "& strComputer & " -------"
	AppendToFile "*****DomainInfo Start"
	Dim o,r:Set r = GetObject("LDAP://" & strComputerDomain & "/rootdse") 
	Dim configContainer:configContainer = r.get("ConfigurationNamingContext") 
	Set r = GetObject("LDAP://" & strComputerDomain & "/CN=Partitions,"& ConfigContainer) 
	For each o in r
		 if ADS_SYSTEMFLAG_CR_NTDS_DOMAIN AND o.systemFlags then 
			AppendToFile CSV(Array(strComputer,o.dnsRoot, o.ncname,o.netbiosname))
		 end if 
	 next 
	AppendToFile "*****DomainInfo End"
End Function
'********************************************
Function reboot
	on error Resume Next
	Err.clear
	Dim bInclude
	WScript.Echo "------- Reboot information from "& strComputer & " -------"
	AppendToFile "*****Reboot Start"
	Dim o,q: Set q = WMI.ExecQuery("Select * from Win32_NTLogEvent Where logfile='System'")
	dim bPrint
	For Each o In q
	With o
		Dim strMessage: strMessage = Replace(Replace(Replace("" & .Message, ";", ","), chr(13), ""), chr(10), "")
		Dim WMIDATE:WMIDATE=(ConvertTimeWritten(.timewritten))
		' Fix, because we had problems using many where condition. Uses a lot of "if then"" solved the problem:
		if (.EventCode=6005 OR .EventCode=6006) and (lcase(.sourceName))="eventlog" then bPrint=true
		if (UCASE(.SourceName)="USER32" AND .EventCode=1074) then bPrint=true
		if bPrint then 
			AppendToFile CSV(Array(strComputer, .ComputerName, .EventCode, strMessage, .TimeWritten, WMIDATE, .User))
			bPrint=False
		end if
	End With
	Next
	AppendToFile "*****Reboot End"
End Function
'********************************************
Sub EventLogAccountManagement
	on error Resume Next
	Dim o,q
	Err.clear
	'5.1 – Windows XP '5.2 – Windows Server 2003 '5.2.3 – Windows Server 2003 R2 ,6.0 – Windows Vista & Windows Server 2008  '6.1 – Windows 7 & Windows Server 2008 R2,'6.2 – Windows 8 & Windows Server 2012 '6.3 – Windows 8.1 & Windows Server 2012 R2
	WScript.Echo "------- Fetching Account Management log entries from "& strComputer & " -------"
	AppendToFile "*****EventLogAccountManagement Start"
	
	Set q = WMI.ExecQuery("Select * from Win32_NTLogEvent Where ( LogFile='security' AND ( categorystring='User Account Management' or categorystring='Security Group Management'))")
	Dim  strEventType
	Dim	i
	I=0
	For Each o In q
		i=i+1
		With o
			select Case 0 + o.Eventtype
				Case 1  strEevntType="Error"
				case 2  strEventType="Warning"
				Case 3  strEventType="Information"
				Case 4 	strEventType="Security Audit Success"
				case 5  strEventType="Security Audit Failure"
				case else strEventType="Unknown:" & .EventType 
			End select
			Dim strMessage: strMessage = Replace(Replace(Replace("" & .Message, ";", ","), chr(13), ""), chr(10), "")
			Dim WMIDATE:WMIDATE=(ConvertTimeWritten(.timewritten))
			AppendToFile CSV(Array(strComputer, .ComputerName,.EventCode, .Type, strEventType,.CategoryString, strMessage, .TimeWritten,WMIDATE, .User))
		End With
		if i = MaxLogLines then exit for
	Next
	AppendToFile "*****EventLogAccountManagement End"	
End Sub
'********************************************
Function MSIInstaller
	on error Resume Next
	Err.clear
	Dim bInclude
	WScript.Echo "------- Msinstaller information from "& strComputer & " -------"
	'MSIInstaller events ,ID 1033=Installed software,ID 1034=Removed software,ID 1035=Reconfigured software,ID 1036=Installed update,ID 11707=Installed software(win2003),ID 11724=Removed software(win2003)
	AppendToFile "*****MSIInstaller Start"
	Dim o,q: Set q = WMI.ExecQuery("Select * from Win32_NTLogEvent Where LogFile='Application' And SourceName Like 'msiinstaller' AND (EventCode=1033 or EventCode=1034 or EventCode=1036 OR EventCode=11707 OR EventCode=11724)")
	For Each o In q
	With o
		Dim strMessage: strMessage = Replace(Replace(Replace("" & .Message, ";", ","), chr(13), ""), chr(10), "")
		Dim WMIDATE:WMIDATE=(ConvertTimeWritten(.timewritten))
		AppendToFile(CSV(Array(strComputer, .ComputerName, .EventCode, strMessage, .TimeWritten, WMIDATE, .Type, .User)))
	End With
	Next
	AppendToFile "*****MSIInstaller End"
End Function
'********************************************
Sub GetAVStatus
	on error Resume Next
	'Does not exist on SERVERS ' 
	Err.clear
	Wscript.Echo "------- Listing AV information from " & strComputer & " -------"	
	'For Clients and servers:
	AppendToFile "*****AV_Check Start"
	call AV_Symantec()
	call av_mcafee()
	call av_TrendMicro()
	AppendToFile "*****AV_Check End"
	'For Clients below
	With Query1(WMI, "Select * from Win32_OperatingSystem")
		if instr(Ucase(.Caption),"SERVER") > 0 then exit sub 'This only works on Client OS
	End With
	AppendToFile "*****AV_STATUS START"
	
	
	Dim objSecurityCenter2:Set objSecurityCenter2 = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\SecurityCenter2")	
	if Err <> 0 then
		Set objSecurityCenter2 = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\SecurityCenter")	
		if err <> 0 then			
			AppendToFile CSV(Array(strComputer,"AV_CHECK", "ERROR","ERROR"))
			AppendToFile CSV(Array(strComputer,"SPYWARE", "ERROR","ERROR"))
			AppendToFile CSV(Array(strComputer,"FIREWALL_Check", "ERROR","ERROR"))
			AppendToFile CSV(Array(strComputer,"FIREWALL_Check", "ERROR","ERROR"))
			AppendToFile "*****AV_STATUS End"
			exit sub
		END IF
	END IF
	dim o,r:Set r = objSecurityCenter2.ExecQuery("Select * from AntiVirusProduct")
	if r.count = 0 then
		AppendToFile CSV(Array(strComputer,"AV_CHECK","",""))
	Else
		For Each o in r
			AppendToFile CSV(Array(strComputer,"AV_CHECK", o.Displayname,o.ProductState))
		Next
	END IF
	
	Set r = objSecurityCenter2.ExecQuery("Select * from AntiSpywareProduct")
	if r.count = 0 then
		AppendToFile CSV(Array(strComputer,"SPYRWARE_CHECK", o.Displayname,o.ProductState))
	Else
		For Each o in r
			AppendToFile CSV(Array(strComputer,"SPYWARE_CHECK", o.Displayname, o.ProductState))
		Next
	END IF		
	Set r = objSecurityCenter2.ExecQuery("Select * from FirewallProduct")
	if r.count = 0 then
		AppendToFile CSV(Array(strComputer,"FIREWALL_CHECK", o.Displayname,o.ProductState))
	Else
		For Each o in r
			AppendToFile CSV(Array(strComputer,"FIREWALL_CHECK", o.Displayname, q(o.ProductState)))
		Next
	END IF
	AppendToFile "*****AV_STATUS End"
End Sub
'*******************************************************************************
Sub Software_Helper(hive, path)
	on error Resume Next
	Err.clear
	Dim vals(6)
	If REG.GetStringValue(hive, path, "DisplayName", vals(0)) <> 0 Then
		Call REG.GetStringValue(hive, path, "QuietDisplayName", vals(0))
	END IF
	If Trim(vals(0)) <> "" Then
		Call REG.GetStringValue (hive, path, "InstallDate", vals(1))
		Call REG.GetDWORDValue  (hive, path, "VersionMajor", vals(2))
		Call REG.GetDWORDValue  (hive, path, "VersionMinor", vals(3))
		Call REG.GetStringValue (hive, path, "DisplayVersion", vals(4))
		Call REG.GetStringValue (hive, path, "Publisher", vals(5))
		' Version
		vals(2) = Trim(vals(2)) & "." & Trim(vals(3))
		If vals(2) = "." Then: vals(2) = "": END IF
		AppendToFile CSV(Array(strComputer, vals(0), vals(1), vals(2), vals(4), vals(5)))
	END IF
End Sub
'********************************************
Sub AuditPol
	on error Resume Next
	Err.clear
	WScript.Echo "------- Listing Audit Policy From " & strComputer & " -------"
	AppendToFile "*****Audit_Policy Start"
	Dim o,r:Set r = RSOP.ExecQuery("Select * from RSOP_AuditPolicy")
	For Each o in r  
		with o
			AppendToFile csv(Array(strComputer, .Category, .Precedence, .Failure, .Success))
		End with
	Next
	AppendToFile "*****Audit_Policy End"
	AppendToFile "*****Audit_Pol Start"
	' Get Auditpol output
	Set r=Nothing
	Set r = WSH.Exec ("" & chr(34) & "%comspec% " &  chr(34) & " /u /c auditpol /get /category:*")
	If Not r is Nothing Then
	Do While Not r.StdOut.AtEndOfStream
		AppendToFile CSV(Array(strComputer,replace(replace(Trim("" & r.StdOut.ReadLine()), chr(13),""), chr(10),"")))
	Loop
	End If
	AppendToFile "*****Audit_Pol End"
End sub
'********************************************
Function Software
	on error Resume Next
	Err.clear
	WScript.Echo "------- Installed Application from " & strComputer & " -------"
	AppendToFile "*****Software Start"
	Dim paths: paths = Array("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\")
	Dim path: For Each path In paths		
		Dim subKey, subKeys
		Call REG.EnumKey(HKLM, path, subKeys)
		If IsArray(subKeys) Then
			For Each subKey In subKeys
				Call Software_Helper(HKLM, path & subKey)
			Next
		END IF
		Dim subUser, subUsers
		Call REG.EnumKey(HKU, "", subUsers)
		For Each subUser In subUsers
			Call REG.EnumKey(HKU, subUser & "\" & path, subKeys)
			If IsArray(subKeys) Then
				For Each subKey In subKeys
					Call Software_Helper(HKU, subUser & "\" & path & subKey)
				Next
			END IF
		Next
	Next
	AppendToFile "*****Software End"
End Function
'********************************************
Function scantoolQuit
	AppendToFile "Done"
	wscript.quit
End Function
'********************************************
Function AV_TrendMicro
	on error Resume Next
	Err.clear
	'WScript.Echo "------- Listing Trend Micro Def Version from " & strComputer & " -------"
	
	Dim strKeyPath,paths: paths = Array("SOFTWARE\Wow6432Node\TrendMicro\UniClient\1700\Scan","SOFTWARE\TrendMicro\UniClient\1700\Scan")
	for each strKeyPath in paths
		Dim strValueName:strValueName = "VirusScanEngineVersion"
		dim strVirusScanEngineVersion
		
		REG.GetStringValue HKLM,strKeyPath,strValueName,strVirusScanEngineVersion
		if strVirusScanEngineVersion & "" <> "" then
			appendtofile(csv(array(strComputer,"Trend Micro VirusScanEngineVersion",strVirusScanEngineVersion)))
		end if
	next
	
	paths = Array("SOFTWARE\Wow6432Node\TrendMicro\AMSP","SOFTWARE\TrendMicro\AMSP")
	for each strKeyPath in paths
		strValueName = "Version"
		dim strVersion
		
		REG.GetStringValue HKLM,strKeyPath,strValueName,strVersion
		if strVersion & "" <> "" then
			appendtofile(csv(array(strComputer,"Trend Micro Version",strVersion)))
		end if
	next
	
	paths = Array("SOFTWARE\Wow6432Node\TrendMicro\Vizor","SOFTWARE\TrendMicro\Vizor")
	for each strKeyPath in paths
		strValueName = "LastUpdateDate"
		dim strLastUpdateDate
		
		REG.GetDwordValue HKLM,strKeyPath,strValueName,strLastUpdateDate
		if strLastUpdateDate & "" <> "" then
			appendtofile(csv(array(strComputer,"Trend Micro LastUpdateDate",unUDate(strLastUpdateDate))))
			appendtofile(csv(array(strComputer,"Trend Micro LastUpdateDateConverted",convertDate(unUDate(strLastUpdateDate)))))
		end if
	next
End Function
'********************************************
Function AV_McAfee
	on error Resume Next
	Err.clear
	'WScript.Echo "------- Listing McAfee Def Version from " & strComputer & " -------"
	Dim strKeyPath,paths: paths = Array("SOFTWARE\Wow6432Node\McAfee\AVEngine","SOFTWARE\McAfee\AVEngine")
	for each strKeyPath in paths
		Dim strValueName:strValueName = "AVDatVersion"
		dim AVDatVersion:AVDatVersion=""
		Dim EngineVersionMajor:EngineVersionMajor=""
		Dim EngineVersionMinor:EngineVersionMinor=""
		dim AVDatDate:AVDatDate=""
		Reg.GetDWORDValue HKLM, strKeyPath, strValueName, AVDatVersion
		Reg.GetDWORDValue HKLM, strKeyPath, "EngineVersionMajor", EngineVersionMajor
		Reg.GetDWORDValue HKLM, strKeyPath, "EngineVersionMinor", EngineVersionMinor
		Reg.GetStringValue HKLM, strKeyPath, "AVDatDate", AVDatDate	
		if "" & AVDatVersion <> "" then
			appendtofile(csv(array(strComputer,"McAfee, EngineVersionMajor",EngineVersionMajor)))
			appendtofile(csv(array(strComputer,"McAfee, EngineVersionMinor",EngineVersionMinor)))
			appendtofile(csv(array(strComputer,"McAfee, AVDatVersion",AVDatVersion)))
			appendtofile(csv(array(strComputer,"McAfee, AVDatDate",AVDatDate)))
		End if
	next
End Function
'********************************************
Function AV_Symantec
	on error Resume Next
	Err.clear
	'WScript.Echo "------- Listing Symantec Def Version from " & strComputer & " -------"
	Dim strKeyPath,paths: paths = Array("SOFTWARE\Wow6432Node\Symantec\Symantec Endpoint Protection\AV","SOFTWARE\Symantec\Symantec Endpoint Protection\AV")
	for each strKeyPath in paths
		Dim strValueName:strValueName = "PatternFileDate"
		dim strValue
		REG.GetBinaryValue HKLM,strKeyPath,strValueName,strValue
		Dim strDate
		Dim i:For i = lBound(strValue) to uBound(strValue)
			select case i
			case 0 strdate= 1970 + strValue(i)
			case 1 strdate=strdate & padtime(strValue(i) +1)
			case 2 strdate=strDate & padtime(strValue(i))
			end select
		Next
		
		if strdate & "" <> "" then
			appendtofile(csv(array(strComputer,"Symantec EndPoint Protection, PatternFileDate",strDate)))
		end if
	next
End Function
'********************************************
Function ChangeProcessPriority()
	on error Resume Next
	err.clear
	Const BELOW_NORMAL = 16384
	Dim o,r:Set r = wmi.ExecQuery("Select * from Win32_Process Where caption = 'cscript.exe'")
	For Each o in r
		if instr(o.Commandline,ScriptName) > 0 then
			o.SetPriority(BELOW_NORMAL) 
		end if
	Next
End Function
'********************************************
Function CmdWrap(sCMD)
	on error resume next
	dim bWaitOnReturn:bWaitOnReturn=true
	WScript.Echo "------- running " & sCMD & " on " & strComputer & " -------"
	Dim TempOut: TempOut=fso.BuildPath(FSo.GetAbsolutePathName("."), FSo.GetTempName())
	Dim TempErr: TempErr=fso.BuildPath(FSo.GetAbsolutePathName("."), FSo.GetTempName())
	Dim File
	Dim strText
	Dim r:Set r = WSH.run ("%comspec% /u /c " & sCMD &  " 1>" & chr(34) & TempOut & chr(34) & " 2>" &chr(34) & TempErr & chr(34),0,bWaitOnReturn)
	ReadTextFile tempOut,"Output " & scmd
	readtextfile TempErr,"Error " & scmd
	fso.deletefile(tempOut)
	fso.deletefile(TempErr)
End Function
'******************************************************************************
Function readTextFile(sFileName, sCMD)
	on error resume next
	Dim file,strtext, tempResult
	if NOT fso.FileExists(sFileName) then	
		wscript.echo "***** Error file not found:" & sFileName
		AppendToFile csv(array(, sCMD, "File not found"))
'		& vbcrLF
		EXIT FUNCTION
	End if
	
	Set file = FSO.OpenTextFile(sFileName, ForReading,false, TristateUseDefault) 
	If Not file is Nothing Then
		Do While not File.AtEndOfStream 
			strText =replace(File.ReadLine, vbcrLF,"")
			if "" & strText <> "" then
				AppendToFile csv(array(strComputer, sCMD, strtext))
			END IF
		Loop
	End If
	file.close
End function
'********************************************
Function DetectWin2k
	on error Resume Next
	Err.clear
	With Query1(WMI, "Select * from Win32_OperatingSystem")
		if left(.Version,3) = "5.0" then
			Win2kMode=TRUE
		ELSE
			Win2kMode=FALSE
		END IF
	End With	
End Function
'********************************************
Function CheckAdmin
	on error Resume Next
	err.clear
	Dim tmpfile
	tmpfile=wsh.ExpandEnvironmentStrings("%windir%\system32\config") & "\audit_test_admin.txt"	
	FSO.CreateTextFile tmpfile,True,True
	if err = 0 then 
		wscript.echo "******* You have elevated rights." 
		AdminRights=true
		FSO.DeleteFile(tmpfile) 
	else
		wscript.echo "*************************************************************"
		wscript.echo " You are not running the script with elevated rights!"
		wscript.echo " To exit, press <ctrl> + <c>."
		wscript.echo " It is not recommended to run the script without administrator"
		wscript.echo " access and elevated rights."
		wscript.echo " if you still want to do this, press <enter> to continue."
		wscript.echo "*************************************************************"
		dim z:z = WScript.StdIn.Read(1)
		AdminRights=false
	end if
End Function
'********************************************
function show(sStr)
	inputbox "Shwoing","",sStr
End Function
'********************************************
sub ShowSettings
	on error Resume Next
	err.clear
	AppendToFile "*****Settings Start"  
	dim objSysinfo:Set objSysInfo = Createobject("ADSystemInfo")
	AppendToFile csv(array(strComputer,"The current user is",objNetwork.UserName))
	AppendToFile csv(array(strComputer , "DN of current user" , objSysInfo.UserName))
	if (err <> 0 and err<>424) then:AppendToFile csv(array(strComputer , "DN of current user","n\a")):err.clear:END IF
	AppendToFile csv(array(strComputer , "UserDomain=" , strUserDomain))
	AppendToFile csv(array(strComputer , "ComputerDomain=" , strComputerDomain))
	AppendToFile csv(array(strComputer , "ScriptName=" , ScriptName))
	AppendToFile csv(array(strComputer , "Execution date=" , day(date) &"-"& month(date) & "-" & year(date)))
	AppendToFile csv(array(strComputer , "Execution time=" , time))
	AppendToFile csv(array(strComputer , "Admin Rights=" , AdminRights))
	AppendToFile csv(array(strComputer , "Output file=" , outputFile))
	AppendToFile csv(array(strComputer , "Fullpath=" , FullPath))
	AppendToFile csv(array(strComputer , "ScriptEngineVersion=" , ScriptEngineMajorVersion & "." &  ScriptEngineMinorVersion))
	AppendToFile csv(array(strComputer , "ScriptEngineBuild=" , ScriptEngineBuildVersion))
	AppendToFile csv(array(strComputer , "BuildNumber=" , BuildNumber))
	AppendToFile csv(array(strComputer , "bCheckHardware=" , bCheckHardware))
	AppendToFile csv(array(strComputer , "bListSoftware=" , bListSoftware))
	AppendToFile csv(array(strComputer , "bMSIInstaller=" , bMSIInstaller))
	AppendToFile csv(array(strComputer , "bCheckShares=" , bCheckShares))
	AppendToFile csv(array(strComputer , "bLocal_Groups=" , bLocal_Groups))
	AppendToFile csv(array(strComputer , "bCheckServices=" , bCheckServices))
	AppendToFile csv(array(strComputer , "bListLocalUsers=" , bListLocalUsers))
	AppendToFile csv(array(strComputer , "bListPasswordPolicy=" , bListPasswordPolicy))
	AppendToFile csv(array(strComputer , "bLocalPolicy=" , bLocalPolicy))
	AppendToFile csv(array(strComputer , "bReboot=" , bReboot))
	AppendToFile csv(array(strComputer , "blistHotFix=" , blistHotFix))
	AppendToFile csv(array(strComputer , "bSecurityCenterCheck=" , bSecurityCenterCheck))
	AppendToFile csv(array(strComputer , "bCheckEvtLogSettings=" , bCheckEvtLogSettings))
	AppendToFile csv(array(strComputer , "bEventLogAccountManagement=" , bEventLogAccountManagement))
	AppendToFile csv(array(strComputer , "bCheckDomainInfo=" , bCheckDomainInfo))
	AppendToFile csv(array(strComputer , "bNTP=" , bNTP))
	AppendToFile csv(array(strComputer , "bDebug=" , bDebug))
	AppendToFile csv(array(strComputer , "bAuditPol=" , bAuditPol))
	AppendToFile csv(array(strComputer , "bGetAVStatus=" , bGetAVStatus))
	AppendToFile csv(array(strComputer , "bComputer_OS=" , bComputer_OS))
	AppendToFile csv(array(strComputer , "bNetLogin=" , bNetLogin))
	AppendToFile csv(array(strComputer , "bGatherIISInformation=" , bGatherIISInformation))
	AppendToFile csv(array(strComputer , "bListSpecialAdGroups=" , bListSpecialAdGroups))
	AppendToFile csv(array(strComputer , "bscreenSaverInfo=" , bscreenSaverInfo))
	AppendToFile csv(array(strComputer , "bscheduledTask=" , bscheduledTask))
	AppendToFile csv(array(strComputer , "bfilesystem=" , bfilesystem))
	AppendToFile csv(array(strComputer , "/BLISTWINDOWSFIREWALLRULES:=" , BLISTWINDOWSFIREWALLRULES))
	AppendToFile csv(array(strComputer , "/LISTSPECIALADGROUPSOVERRIDE:=" , args("/LISTSPECIALADGROUPSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/CHECKEVENTLOGSETTINGSOVERRIDE:=" , args("/CHECKEVENTLOGSETTINGSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/EVENTLOGACCOUNTMANAGEMENTOVERRIDE:=" , args("/EVENTLOGACCOUNTMANAGEMENTOVERRIDE:")))
	AppendToFile csv(array(strComputer , "arrSpecialGroups=" , join(arrSpecialGroups,":")))
	AppendToFile csv(array(strComputer , "LISTALLADGROups=" , LISTALLADGROups))
	AppendToFile csv(array(strComputer , "bGetAdRoles=" , bGetAdRoles))
	AppendToFile csv(array(strComputer , "bADComputers=" , bADComputers))
	AppendToFile csv(array(strComputer , "bCSVDE_Users=" , bCSVDE_Users))
	AppendToFile csv(array(strComputer , "bCSVDE_Computers=" , bCSVDE_Computers))
	AppendToFile csv(array(strComputer , "bAD_Users=" , bAD_Users))
	AppendToFile csv(array(strComputer , "/LISTADGROUP:=" , args("/LISTADGROUP:")))
	AppendToFile csv(array(strComputer , "/LOCAL_GROUPSOVERRIDE:=" , args("/LOCAL_GROUPSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/CHECKHARDWAREOVERRIDE:=" , args("/CHECKHARDWAREOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTSOFTWEAREOVERRIDE:=" , args("/LISTSOFTWEAREOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/MSIINSTALLEROVERRIDE:=" , args("/MSIINSTALLEROVERRIDE:")))
	AppendToFile csv(array(strComputer , "/CHECKSHARESOVERRIDE:=" , args("/CHECKSHARESOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/CHECKSERVICESOVERRIDE:=" , args("/CHECKSERVICESOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTLOCALUSERSOVERRIDE:=" , args("/LISTLOCALUSERSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTPASSWORDPOLICYOVERRIDE:=" , args("/LISTPASSWORDPOLICYOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LOCALPOLICYOVERRIDE:=" , args("/LOCALPOLICYOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/NTPOVERRIDE:=" , args("/NTPOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/REBOOTOVERRIDE:=" , args("/REBOOTOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTHOTFIXOVERRIDE:=" , args("/LISTHOTFIXOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/CHECKDOMAININFOOVERRIDE:=" , args("/CHECKDOMAININFOOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/AUDITPOLOVERRIDE:=" , args("/AUDITPOLOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/GETAVSTATUSOVERRIDE:=" , args("/GETAVSTATUSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/COMPUTER_OSOVERRIDE:=" , args("/COMPUTER_OSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/NETLOGINOVERRIDE:=" , args("/NETLOGINOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/GATHERIISINFORMATIONOVERRIDE:=" , args("/GATHERIISINFORMATIONOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTSPECIALADGROUPSOVERRIDE:=" , args("/LISTSPECIALADGROUPSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTALLADGROUPSOVERRIDE:=" , args("/LISTALLADGROUPSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTWINDOWSFIREWALLRULESOVERRIDE:=" , args("/LISTWINDOWSFIREWALLRULESOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/SCREENSAVERINFOOVERRIDE:=" , args("/SCREENSAVERINFOOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/LISTSCHEDULEDTASKOVERRIDE:=" , args("/LISTSCHEDULEDTASKOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/FILESYSTEMOVERRIDE:=" , args("/FILESYSTEMOVERRIDE:")))
	
	
	AppendToFile csv(array(strComputer , "/GETADROLESOVERRIDE:=" , args("/GETADROLESOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/AD_COMPUTERSOVERRIDE:=" , args("/AD_COMPUTERSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/CSVDE_USERSOVERRIDE:=" , args("/CSVDE_USERSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/CSVDE_COMPUTERSOVERRIDE:=" , args("/CSVDE_COMPUTERSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/AD_USERSOVERRIDE:=" , args("/AD_USERSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/GPRESULTOVERRIDE:=" , args("/GPRESULTOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/USERRIGHTSASSIGNMENTSOVERRIDE:=" , args("/USERRIGHTSASSIGNMENTSOVERRIDE:")))
	AppendToFile csv(array(strComputer , "/SHOWTRUSTOVERRIDE:=" , args("/SHOWTRUSTOVERRIDE:")))
	AppendToFile "*****Settings End"  
End sub
'********************************************
sub ArgumentError 
	wscript.echo "The script audits a local computer ONLY!"
	wscript.echo "The script can not be used to audit remote computers."
	Wscript.echo " "
	Wscript.echo "Script usage:"
	wscript.echo "cscript " & ScriptName & " [OPTIONS]"
	WSCRIPT.ECHO "   OPTIONS:"
	WSCRIPT.ECHO "/LISTADGROUP:GroupName" 
	wscript.echo "   Groups with spaces must be container via quotes"
	wscript.echo " "
	wscript.echo "Override switches, can be used by bypass the default settings,"
	wscript.echo "These should only be used when instructed to do so by the auditor"
	DIM ITEM: for each item in args
		if instr(ucase(item), "OVERRIDE") >0 THEN
			wscript.echo "   " & item & "[ON|OFF]"
		END IF
	next
	wscript.echo " "
	Wscript.echo "Examples (All examples are to be executed from an elevated command prompt)"
	wscript.echo "*  Run the script:"
	wscript.echo "   " & "cscript " & ScriptName 
	wscript.echo " "
	wscript.echo "*  List members of the Domain Admins group:"
	wscript.echo "   " & "cscript " & ScriptName & " /LISTADGROUP:" & chr(34) & "Domain Admins" & chr(34)
	wscript.echo " "
	wscript.echo "*  Force csvde_users module NOT to execute:"
	wscript.echo "   " & "cscript " & ScriptName & " /CSVDE_USERSOVERRIDE:OFF"
	wscript.echo " "
	wscript.echo "*  Force the list ALL AD groups module to execute:"
	wscript.echo "   " & "cscript " & ScriptName & " /LISTALLADGROUPSOVERRIDE:On"
	wscript.echo " "
	Wscript.echo "*  If you just want to scan specific items, use the /ONLY switch. ut will turn everything off, if not specified explicit on the command line"
	wscript.echo "   To just list AD users run:"
	wscript.echo "   " & "cscript " & ScriptName & " /AD_USERSOVERRIDE:ON /ONLY"
	wscript.echo " "
	wscript.quit
End sub
'********************************************
Sub Initialize
	on error Resume Next
	Err.clear
	' Force cscript
	If Right(UCase(WScript.fullname),11)= "WSCRIPT.EXE" Then
		WScript.Echo "Not running in cscript.exe"
		WScript.Echo "Please start the script from a command prompt, with elevated rights"
		WScript.Echo "Like this: "& vbcrlf & "cscript " & scriptName
		WScript.Quit
	END IF
	' Script name
	If Not Instr(UCase(WScript.ScriptFullName),UCase(ScriptName)) > 0 Then
		WScript.Echo "Wrong script name, please rename to: " & UCase(ScriptName)
		WScript.Quit
	END IF
	
	Call Computer_LocalName()	
	' Set default computer
	' Directory
	FullPath = Replace(UCase(WScript.ScriptFullName),UCase(ScriptName),"")
	'Program starts
	' All recognized commandline options
	ARGS.ADD "/AD_COMPUTERSOVERRIDE:", 0
	ARGS.ADD "/AD_USERSOVERRIDE:", 0
	ARGS.ADD "/AUDITPOLOVERRIDE:", 0
	ARGS.ADD "/CHECKDOMAININFOOVERRIDE:", 0
	ARGS.ADD "/CHECKEVENTLOGSETTINGSOVERRIDE:", 0
	ARGS.ADD "/EVENTLOGACCOUNTMANAGEMENTOVERRIDE:", 0
	ARGS.ADD "/CHECKHARDWAREOVERRIDE:", 0
	ARGS.ADD "/CHECKSERVICESOVERRIDE:", 0
	ARGS.ADD "/CHECKSHARESOVERRIDE:", 0
	ARGS.ADD "/COMPUTER_OSOVERRIDE:", 0
	ARGS.ADD "/CSVDE_COMPUTERSOVERRIDE:", 0
	ARGS.ADD "/CSVDE_USERSOVERRIDE:", 0
	ARGS.ADD "/GATHERIISINFORMATIONOVERRIDE:", 0
	ARGS.ADD "/GETADROLESOVERRIDE:", 0
	ARGS.ADD "/GETAVSTATUSOVERRIDE:", 0
	ARGS.ADD "/GPRESULTOVERRIDE:", 0
	ARGS.Add "/LISTADGROUP:", 0
	ARGS.ADD "/LISTALLADGROUPSOVERRIDE:", 0
	ARGS.ADD "/LISTHOTFIXOVERRIDE:", 0
	ARGS.ADD "/LISTLOCALUSERSOVERRIDE:", 0
	ARGS.ADD "/LISTPASSWORDPOLICYOVERRIDE:", 0
	ARGS.ADD "/LISTPROCESSESOVERRIDE:", 0
	ARGS.ADD "/LISTSOFTWEAREOVERRIDE:", 0
	ARGS.ADD "/LISTSPECIALADGROUPSOVERRIDE:", 0
	ARGS.ADD "/LISTSCHEDULEDTASKOVERRIDE:", 0
	ARGS.ADD "/LOCAL_GROUPSOVERRIDE:", 0
	ARGS.ADD "/LOCALPOLICYOVERRIDE:", 0
	ARGS.ADD "/MSIINSTALLEROVERRIDE:", 0
	ARGS.ADD "/NETLOGINOVERRIDE:", 0
	ARGS.ADD "/NTPOVERRIDE:", 0
	ARGS.ADD "/FILESYSTEMOVERRIDE:", 0
	ARGS.ADD "/REBOOTOVERRIDE:", 0
	ARGS.ADD "/SHOWTRUSTOVERRIDE:", 0
	ARGS.ADD "/SCREENSAVERINFOOVERRIDE:", 0
	ARGS.ADD "/USERRIGHTSASSIGNMENTSOVERRIDE:", 0
	Args.Add "/WINDOWSUPDATELOGOVERRIDE:", 0
	Args.Add "/LISTWINDOWSFIREWALLRULESOVERRIDE:", 0
		
	ARGS.ADD "/ONLY", 0
	' Parse command line options and store values in args
	
	Dim arg: For Each arg In WScript.Arguments
		Dim bFound: bFound = False
		Dim key: For Each key In args
			If (InStr(UCase(arg),key) > 0) And (Len(arg) > 0) Then
				bFound = True
				args(key) = Mid(Trim(arg),Len(key)+1)
			END IF
		Next
		If Not bFound Then
		call argumentError()
			WScript.Echo "Unknown argument: """ & arg & """"
			WScript.Quit
		END IF
	Next
	'
	If varType(args("/ONLY")) = 8 Then 
		for each key in ARGS
			if (vartype(args(key)) <> 8) AND (instr(key,"OVERRIDE") > 0) then:args(key)="OFF":end if
		next
	END IF
	
	checkadmin()
	Call ConnectWMI
	Call ConnectDSE()
	DetectWin2k()
	ChangeProcessPriority()
	call Computer_DomainRole	
	call Get_OS ' required if computer_os is disabled
	
	If varType(args("/LISTADGROUP:")) = 8 Then 
		wscript.echo "*** Script running in list AD group mode!"
		OutputFile = FullPath & strComputer & "-AD_Group-"& replace(args("/LISTADGROUP:")," ","_") &".txt"
		CreateFile(OutputFile)
		ad_groups(ARRAY(args("/LISTADGROUP:")))
	Else
		OutputFile = FullPath & strComputer & "-Audit.txt"
		CreateFile(FullPath & strComputer & "-Audit.txt")
		getDomain
		call showSettings()	

		select Case UCASE(ARGS("/LOCAL_GROUPSOVERRIDE:"))
			Case "ON" CALL Local_Groups()
			Case "OFF"
			Case else 
				if vartype(args("/LOCAL_GROUPSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bLocal_Groups then :CALL Local_Groups(): END IF
		End select
		
		select Case UCASE(ARGS("/SCREENSAVERINFOOVERRIDE:"))
			Case "ON" CALL screenSaverInfo()
			Case "OFF"
			Case else 
				if vartype(args("/SCREENSAVERINFOOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bscreenSaverInfo then :CALL screenSaverInfo(): END IF
		End select
		
		select Case UCASE(ARGS("/CHECKSERVICESOVERRIDE:"))
			Case "ON" CALL services()
			Case "OFF"
			Case else 
				if vartype(args("/CHECKSERVICESOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bCheckServices then :CALL services(): END IF
		End select
		select Case UCASE(ARGS("/GPRESULTOVERRIDE:"))
			Case "ON" CALL GPRESULT()
			Case "OFF"
			Case else 
				if vartype(args("/GPRESULTOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bgpresult then :CALL gpresult(): END IF
		End select
		
		
		select Case UCASE(ARGS("/CHECKSHARESOVERRIDE:"))
			Case "ON" call local_Shares()
			Case "OFF"
			Case else 
				if vartype(args("/CHECKSHARESOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bCheckShares then:call local_Shares():END IF
		End select
		select Case UCASE(ARGS("/CSVDE_USERSOVERRIDE:"))
			Case "ON" call CSVDE_Users()
			Case "OFF"
			Case else 
				if vartype(args("/CSVDE_USERSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bCSVDE_Users then:call CSVDE_Users():END IF
		End select
		select Case UCASE(ARGS("/CSVDE_COMPUTERSOVERRIDE:"))
			Case "ON" 	call CSVDE_computers()
			Case "OFF"
			Case else 
				if vartype(args("/CSVDE_COMPUTERSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bCSVDE_Computers then:call CSVDE_computers():END IF
		End select
		select Case UCASE(ARGS("/NETLOGINOVERRIDE:"))
			Case "ON" call NetLogin()
			Case "OFF"
			Case else 
				if vartype(args("/NETLOGINOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bNetLogin then: call NetLogin(): END IF
		End select
		
		select Case UCASE(ARGS("/EVENTLOGACCOUNTMANAGEMENTOVERRIDE:"))
			Case "ON" call EventLogAccountManagement()
			Case "OFF"
			Case else 
				if vartype(args("/EVENTLOGACCOUNTMANAGEMENTOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bEventLogAccountManagement then: call EventLogAccountManagement(): END IF
		End select
		
		select Case UCASE(ARGS("/LISTSCHEDULEDTASKOVERRIDE:"))
			Case "ON" call scheduledTask()
			Case "OFF"
			Case else 
				if vartype(args("/LISTSCHEDULEDTASKOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bscheduledTask then: call scheduledTask(): END IF
		End select
		
		select Case UCASE(ARGS("/WINDOWSUPDATELOGOVERRIDE:"))
			Case "ON" call WindowsUpdateLog()
			Case "OFF"
			Case else 
				if vartype(args("/WINDOWSUPDATELOGOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bWindowsUpdateLog then: call WindowsUpdateLog(): END IF
		End select
		
		select Case UCASE(ARGS("/LISTWINDOWSFIREWALLRULESOVERRIDE:"))
			Case "ON" call WindowsFW()
			Case "OFF"
			Case else 
				if vartype(args("/LISTWINDOWSFIREWALLRULESOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bLISTWINDOWSFIREWALLRULES then: call WindowsFW(): END IF
		End select

		select Case UCASE(ARGS("/NTPOVERRIDE:"))
			Case "ON" call ntp()
			Case "OFF"
			Case else 
				if vartype(args("/NTPOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bNTP then: call ntp(): END IF
		End select
		
		select Case UCASE(ARGS("/GATHERIISINFORMATIONOVERRIDE:"))
			Case "ON" call GatherIISInformation()
			Case "OFF"
			Case else 
				if vartype(args("/GATHERIISINFORMATIONOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bGatherIISInformation then: call GatherIISInformation():END IF
		End select
		select Case UCASE(ARGS("/GETAVSTATUSOVERRIDE:"))
			Case "ON" Call GetAVStatus()
			Case "OFF"
			Case else 
				if vartype(args("/GETAVSTATUSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bGetAVStatus then: Call GetAVStatus(): END IF
		End select
		
		select Case UCASE(ARGS("/COMPUTER_OSOVERRIDE:"))
			Case "ON" Call Computer_OS()
			Case "OFF"
			Case else 
				if vartype(args("/COMPUTER_OSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bComputer_OS then: Call Computer_OS():END IF
		End select
		
		select Case UCASE(ARGS("/AUDITPOLOVERRIDE:"))
			Case "ON" call AuditPol()
			Case "OFF"
			Case else 
				if vartype(args("/AUDITPOLOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bAuditPol then:call AuditPol(): END IF
		End select
		
		select Case UCASE(ARGS("/LISTSOFTWEAREOVERRIDE:"))
			Case "ON" call Software()
			Case "OFF"
			Case else 
				if vartype(args("/LISTSOFTWEAREOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bListSoftware Then:call Software():END IF
		End select
		select Case UCASE(ARGS("/MSIINSTALLEROVERRIDE:"))
			Case "ON" call MSIInstaller()
			Case "OFF"
			Case else 
				if vartype(args("/MSIINSTALLEROVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bMSIInstaller then : call MSIInstaller(): END IF
		End select
		select Case UCASE(ARGS("/LISTHOTFIXOVERRIDE:"))
			Case "ON" Call ListHotFix()
			Case "OFF"
			Case else 
				if vartype(args("/LISTHOTFIXOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bListHotFix then: Call ListHotFix():END IF
		End select
		select Case UCASE(ARGS("/LISTLOCALUSERSOVERRIDE:"))
			Case "ON" call Local_Users()
			Case "OFF"
			Case else 
				if vartype(args("/LISTLOCALUSERSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bListLocalUsers then:Local_Users():END IF
		End select
					
		select Case UCASE(ARGS("/USERRIGHTSASSIGNMENTSOVERRIDE:"))
			Case "ON" call UserRightsAssignments
			Case "OFF"
			Case else 
				if vartype(args("/USERRIGHTSASSIGNMENTSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bUserRightsAssignments then:call UserRightsAssignments: END IF
		End select
		
		select Case UCASE(ARGS("/CHECKEVENTLOGSETTINGSOVERRIDE:"))
			Case "ON" call EventLogSettings
			Case "OFF"
			Case else 
				if vartype(args("/CHECKEVENTLOGSETTINGSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bCheckEvtLogSettings then:call EventLogSettings: END IF
		End select
		select Case UCASE(ARGS("/LOCALPOLICYOVERRIDE:"))
			Case "ON" call LocalPolicy
			Case "OFF"
			Case else 
				if vartype(args("/LOCALPOLICYOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bLocalPolicy then: call LocalPolicy: END IF
		End select
		select Case UCASE(ARGS("/CHECKHARDWAREOVERRIDE:"))
			Case "ON" call hardware ()
			Case "OFF"
			Case else 
				if vartype(args("/CHECKHARDWAREOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bCheckHardware then:hardware ():END IF
		End select
		select Case UCASE(ARGS("/AD_USERSOVERRIDE:"))
			Case "ON" CALL AD_USERS
			Case "OFF"
			Case else 
				if vartype(args("/AD_USERSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bAD_Users then: CALL AD_USERS :END IF
		End select
		select Case UCASE(ARGS("/GETADROLESOVERRIDE:"))
			Case "ON" call ADRoles
			Case "OFF"
			Case else 
				if vartype(args("/GETADROLESOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bGetAdRoles then:call ADRoles:END IF
		End select
		
		select Case UCASE(ARGS("/LISTSPECIALADGROUPSOVERRIDE:"))
			Case "ON" CALL AD_Groups(arrSpecialGroups)
			Case "OFF"
			Case else 
				if vartype(args("/LISTSPECIALADGROUPSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bListSpecialAdGroups then :CALL AD_Groups(arrSpecialGroups) : END IF
		End select
		select Case UCASE(ARGS("/CHECKDOMAININFOOVERRIDE:"))
			Case "ON" call DomainInfo()
			Case "OFF"
			Case else 
				if vartype(args("/CHECKDOMAININFOOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bCheckDomainInfo then:call DomainInfo():END IF
		End select
		select Case UCASE(ARGS("/LISTPASSWORDPOLICYOVERRIDE:"))
			Case "ON" call ListPasswordPolicy()
			Case "OFF"
			Case else 
				if vartype(args("/LISTPASSWORDPOLICYOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bListPasswordPolicy then:call ListPasswordPolicy():END IF
		End select
		
		select Case UCASE(ARGS("/AD_COMPUTERSOVERRIDE:"))
			Case "ON" call AD_Computers
			Case "OFF"
			Case else 
				if vartype(args("/AD_COMPUTERSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bADComputers then:call AD_Computers:END IF
		End select

		select Case UCASE(ARGS("/LISTPROCESSESOVERRIDE:"))
			Case "ON" CALL ListProcesses
			Case "OFF"
			Case else 
				if vartype(args("/LISTPROCESSESOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bListProcesses then :CALL ListProcesses: END IF
		End select
		
		select Case UCASE(ARGS("/FILESYSTEMOVERRIDE:"))
			Case "ON" CALL filesystem
			Case "OFF"
			Case else 
				if vartype(args("/FILESYSTEMOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bfilesystem then :CALL filesystem: END IF
		End select
		
		select Case UCASE(ARGS("/LISTALLADGROUPSOVERRIDE:"))
			Case "ON" CALL AD_Groups(NULL)
			Case "OFF"
			Case else 
				if vartype(args("/LISTALLADGROUPSOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if LISTALLADGROups then :CALL AD_Groups(NULL): END IF
		End select
		
		select Case UCASE(ARGS("/SHOWTRUSTOVERRIDE:"))
			Case "ON" call showTrust
			Case "OFF"
			Case else 
				if vartype(args("/SHOWTRUSTOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bShowTrust then:call ShowTrust:END IF
		End select
		
		select Case UCASE(ARGS("/REBOOTOVERRIDE:"))
			Case "ON" call Reboot()
			Case "OFF"
			Case else 
				if vartype(args("/REBOOTOVERRIDE:")) = 8 then:wscript.echo "only On/Off supported for OVERRIDE arguments":wscript.quit:END IF
				if bReboot then: call Reboot():END IF
		End select
		
	END IF
	scantoolQuit()
End Sub
Call Initialize()