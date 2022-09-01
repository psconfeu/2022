function Get-CustomerInfo
{
  param
  (
    # suggest customer names:
    [MyAutoComplete(('Karl','Jenny','Zumsel'))]
    [string]
    $Customer
  )


  "Hello $Customer!"
}