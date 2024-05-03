if ([threading.thread]::CurrentThread.ApartmentState.ToString() -eq 'MTA') {
    Write-Error "This script requires PowerShell to run in Single-Threaded Apartment. Please run powershell.exe with parameter -STA"
    Exit
}
 
Add-Type -AssemblyName PresentationFramework 
[xml]$XAML = Get-Content "C:\Scripts\AD\KG\Set-ThumbnailPhotoGUI-mainform.xaml"
$XAML.Window.RemoveAttribute("x:Class")
  
$global:userinfo = @{
    dn = $null
    photo = [byte[]]$null
}
  
function Invoke-FileBrowser {
    param([string]$Title,[string]$Directory,[string]$Filter="jpeg (*.jpg)|*.jpg")
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $FileBrowser.InitialDirectory = $Directory
    $FileBrowser.Filter = $Filter
    $FileBrowser.Title = $Title
    $Show = $FileBrowser.ShowDialog()
    If ($Show -eq "OK") { Return $FileBrowser.FileName }
}
  
function Get-LDAPUsers($sam) {
    $activeDomain = New-Object DirectoryServices.DirectoryEntry
    $domain = $activeDomain.distinguishedName
    $searcher = [System.DirectoryServices.DirectorySearcher]"[ADSI]LDAP://$domain"
    $searcher.filter = "(&(samaccountname=$sam)(objectClass=user)(objectClass=person))"
    $result = $searcher.findall()
      
    if ($result.count -gt 1) {
        Write-Warning "More than one user found. Please refine your search."
    } elseif ($result.count -eq 1) {
        $result = $searcher.findone().getDirectoryEntry()
        [pscustomobject]@{
            UserPrincipalName = $result.userprincipalname[0]
            DistinguishedName = $result.distinguishedname[0]
            samAccountName = $result.samaccountname[0]
            Givenname = $result.givenname[0]
            Surname = $result.sn[0]
            ThumbnailPhoto = $result.thumbnailphoto
        }
    }
}
  
function Update-WPFForm($sam) {
   $selecteduser = Get-LDAPUsers $sam
   if ($selecteduser) {
        $global:userinfo.dn = $selecteduser.DistinguishedName
        $global:userinfo.photo = [byte[]]$($selecteduser.thumbnailphoto)
  
        $lblGivenName.Content = $selecteduser.GivenName
        $lblSN.Content = $selecteduser.SurName
        $lblUPN.Content = $selecteduser.UserPrincipalName
        $lblDN.Content = $global:userinfo.dn
        $txtSearch.Text = $selecteduser.SamAccountName
        $imgThumb.Source = $global:userinfo.photo
        $btnImg.IsEnabled = $true
    }
}
  
#region GUI
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $window=[Windows.Markup.XamlReader]::Load($reader)
  
    $btnSearch = $window.FindName("btnSearch")
    $btnImg = $window.FindName("btnImg")
    $btnApply = $window.FindName("btnApply")
    $txtSearch = $window.FindName("txtSearch")
    $lblGivenName = $window.FindName("lblGivenName")
    $lblSn = $window.FindName("lblSn")
    $lblUPN = $window.FindName("lblUPN")
    $lblDN = $window.FindName("lblDN")
    $imgThumb = $window.FindName("imgThumb")
#endregion GUI
  
#region Events
  
    #region btnSearchClick
        $btnSearch_click = $btnSearch.add_Click
        $btnSearch_click.Invoke({
            Update-WPFForm($txtSearch.Text)
        })
    #endregion btnSearchClick
  
    #region btnImgClick
        $btnImg_click = $btnImg.add_Click
        $btnImg_click.Invoke({
            $file = Invoke-FileBrowser -Title "Choose a thumbnail photo" -Filter "Jpeg pictures (*.jpg)|*.jpg"
            if ($file) {
                if ((Get-Item $file).length -gt 10kB) {
                    Write-Warning "Picture too large. Maximum size is 10 kB."
                } else {
                    $global:userinfo.photo = [byte[]](Get-Content $file -encoding byte)
                    $imgThumb.Source = $global:userinfo.photo
                    $btnApply.IsEnabled = $true
                }
            }
        })
    #endregion btnImgClick
      
    #region btnApplyClick
        $btnApply_click = $btnApply.add_Click
        $btnApply_click.Invoke({
            $user = New-Object DirectoryServices.DirectoryEntry "LDAP://$($global:userinfo.dn)"
            $user.put("thumbnailPhoto", $global:userinfo.photo)
            $user.setinfo()
            $btnApply.IsEnabled = $false
            Write-Verbose "User $($global:userinfo.dn) updated."
        })
    #endregion btnApplyClick
      
    #region textChange
        $txtSearch_Change = $txtSearch.add_KeyDown
        $txtSearch_Change.Invoke({
            if ($_.Key -ieq 'Return') {
                Update-WPFForm($txtSearch.Text)
            }
        })
    #endregion textChange
  
#endregion Events
  
$window.ShowDialog() | Out-Null