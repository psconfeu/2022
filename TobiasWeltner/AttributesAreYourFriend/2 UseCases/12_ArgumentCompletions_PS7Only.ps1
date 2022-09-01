function Get-Country
{
  param
  (
    # suggest country names:
    [ArgumentCompletions('USA','Germany','Norway','Sweden','Austria','YouNameIt')]
    [string]
    $Name
  )

  # return parameter
  $PSBoundParameters
}