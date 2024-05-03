
#Krypter kode - Det er ligemeget hvad der står i brugernavn hvis brugernavn ikke skal bruges. Men der skal stå noget
(Get-Credential).Password | ConvertFrom-SecureString | Out-File "C:\Scripts\Password.txt"

#Dekrypter kode for at tjekke om det er rigtigt - Kør $password i shell for at få output
$securestring = convertto-securestring -string (get-content C:\Scripts\Password.txt)
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)