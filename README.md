# timedShutdown
Automaticaly shutdown a Windows computer when a daily connexion time is reached


## Installation

Execute command `Set-ExecutionPolicy RemoteSigned` from an Administrator prompt to allow execution of the script.  
Put this script in the private folders of an Administrator account.  
Execute command `Unblock-File timed shutdown.ps1` from an Administrator prompt.
Add a scheduled task to run the script every 5 minutes with the Admininistrator account.  

