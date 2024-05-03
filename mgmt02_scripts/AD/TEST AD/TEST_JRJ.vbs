

Set objADSysInfo = CreateObject("ADSystemInfo")
Set UserObj = GetObject("LDAP://" & objADSysInfo.UserName)
wscript.echo UserObj.sAMAccountName

