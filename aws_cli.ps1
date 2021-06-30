
cls

try
{
    $api = "https://mysecretserver/SecretServer/api/v1"
    $tokenRoute = "https://mercury/SecretServer/oauth2/token";

    $creds = @{
        username = "MYUSERNAME"
        password = "MYPASSWORD"
        grant_type = "password"
 }
    $token = ""
    $response = Invoke-RestMethod $tokenRoute -Method Post -Body $creds
    $token = $response.access_token;

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")
      
    $acc_key = Invoke-RestMethod "$api/secrets/9/fields/access-key" -Headers $headers  -Method get
    $sec_key = Invoke-RestMethod "$api/secrets/9/fields/secret-key" -Headers $headers  -Method get

     Write-Host "current_key:"$acc_key
       # $sec_key="garbagekey"
       # Write-Host $sec_key
    

     Set-AWSCredential `
                 -AccessKey $acc_key `
                 -SecretKey $sec_key `
                 -StoreAs AWSProfile1

    Initialize-AWSDefaultConfiguration -ProfileName AWSProfile1 -Region us-west-2
 
    Write-host "AWS API Output:" 
    Get-STSCallerIdentity | out-host
    
    $secretArgs =
    @{comment="Changed via API"} | ConvertTo-Json

    $rota = Invoke-RestMethod "$api/secrets/9/change-password" -Headers $headers  -Method Post  -Body $secretArgs -ContentType application/json
   
    Start-Sleep 13
    $acc_key1 = Invoke-RestMethod "$api/secrets/9/fields/access-key" -Headers $headers  -Method get
    Write-Host "new_key:"$acc_key1
    Write-Host 
  



}
catch [System.Net.WebException]
{
    Write-Host "----- Exception -----"
    Write-Host  $_.Exception
    Write-Host  $_.Exception.Response.StatusCode
    Write-Host  $_.Exception.Response.StatusDescription
    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd() | ConvertFrom-Json
    Write-Host  $responseBody.errorCode " - " $responseBody.message
    foreach($modelState in $responseBody.modelState)
    {
        $modelState
    }
}
