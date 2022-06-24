
# Install the latest version of PSReadLine
Install-Module -Name PSReadLine -Force

# Enable Historical Predictors
Set-PSReadLineOption -PredictionSource History

# Change the PSReadline Inline View style
Set-PSReadLineOption -PredictionViewStyle ListView

# Modifying colors of predictors
Set-PSReadLineOption -Colors @{ InLinePrediction = '#00CC00'} # Green
Set-PSReadLineOption -Colors @{ InLinePrediction = "$([char]0x1b)[36;7;238m"} #Dark 
Set-PSReadLineOption -Colors @{ InLinePrediction = 'Magenta'}
# Press F2 to Toggle between the two different views

# Enabling Plugin Predictors
Set-PSReadLineOption -PredictionSource HistoryAndPlugin

# Install Completion Predictor
# Note since there are no cmdlets in this module it will be needed to be included in your profile
Install-Module -Name CompletionPredictor
Import-Module -Name CompletionPredictor

# Install Az.Tools.Predictor 
Install-Module -Name Az.Tools.Predictor

# Enabling/Importing Az Predictor
# adding the -AllSessions Parameter saves it to your profile
Enable-AzPredictor -AllSession
