function Has-MsmqQueueWithName([string]$name)
{
	$msmq = new-object –comObject MSMQ.MSMQApplication
	$queues = $msmq.PrivateQueues

	$found = $FALSE
	foreach ($queue in $queues) 
	{    
		if ($queue.ToLower().EndsWith($name.ToLower()))
		{
			$found = $TRUE
			break;
		}
	}

	return $found
}

function set-msmqqueue($computerName, $queuename, $private, $user, $permission, $transactional)
{
	if (!(Has-MsmqQueueWithName $queuename))
	{
		Write-Host "Creating Queue $queuename"
		Create-MsmqQueue $computerName $queuename $private $user $permission $transactional
	}
}

function Create-MsmqQueue($computerName, $queuename, $private, $user, $permission, $transactional)
{
	[Reflection.Assembly]::LoadWithPartialName("System.Messaging")
	$createQueuename = ""
	
	if ($computerName.ToLower() -eq "localhost")
	{
		$computerName = "."
	}

	if ($private)
	{
		$createQueuename = $computerName + "\private$\" + $queuename.ToLower()
	}
	else
	{
		$createQueuename = $computerName + "\" + $queuename.ToLower()
	}
	
	write-host "Creating queue $createQueuename"
	$qb = [System.Messaging.MessageQueue]::Create($createQueuename, $transactional) 
	
	if($qb -eq $null)
	{
		exit
	}
	
	$qb.label = $queuename
		   
	if ($permission -ieq "all")
	{
		Write-Host "Granting all permissions to " $user
		$qb.SetPermissions($user, [System.Messaging.MessageQueueAccessRights]::FullControl, [System.Messaging.AccessControlEntryType]::Allow) 
	}
	else
	{
		Write-Host "Restricted Control for user: "  $user
		$qb.SetPermissions($user, [System.Messaging.MessageQueueAccessRights]::DeleteMessage, [System.Messaging.AccessControlEntryType]::Set) 
		$qb.SetPermissions($user, [System.Messaging.MessageQueueAccessRights]::GenericWrite, [System.Messaging.AccessControlEntryType]::Allow) 
		$qb.SetPermissions($user, [System.Messaging.MessageQueueAccessRights]::PeekMessage, [System.Messaging.AccessControlEntryType]::Allow) 
		$qb.SetPermissions($user, [System.Messaging.MessageQueueAccessRights]::ReceiveJournalMessage, [System.Messaging.AccessControlEntryType]::Allow)
	}
}

export-modulemember -function Has-MsmqQueueWithName, Create-MsmqQueue, set-msmqqueue

