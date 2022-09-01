function Get-ErrorEvent
{
	param
	(
		# suggest today, yesterday, and last week:
		[ArgumentCompleter({ 
            $today = Get-Date -Format 'yyyy-MM-dd'
            $yesterday = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
            $lastWeek = (Get-Date).AddDays(-7).ToString('yyyy-MM-dd')
            
            # create the completions:
            [System.Management.Automation.CompletionResult]::new($today, "Today", "ParameterValue", "all errors after midnight")
            [System.Management.Automation.CompletionResult]::new($yesterday, "Yesterday", "ParameterValue", "all errors after yesterday")
            [System.Management.Automation.CompletionResult]::new($lastWeek, "Last Week", "ParameterValue", "all errors after last week")

            })]
		[DateTime]
		$After
	)

	# forward the parameter -After to Get-EventLog
	# if the user does not specify the parameter, all errors are returned:
	Get-EventLog -LogName System -EntryType Error @PSBoundParameters
}