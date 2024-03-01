﻿<# This script enables archiving for users who have reached > <setamount> on their mailbox, in order to clear up space and maintain retention policy.
you simply need to set your threshold for archiving to kick off.#>


Import-Module ExchangeOnlineManagement
# Connect to EXO
Connect-ExchangeOnline -ManagedIdentity -Organization brasfieldgorrie.com

#threshold (in gb) in which you want archiving to be enabled.
$mbthreshold = '<insert threshold in which you want archiving to be enabled when reached>'

# Retrieve all mailboxes and gather current mailbox size
$mbabove89 = ForEach ($mailbox in (Get-EXOMailbox)) {
    $stats = $mailbox | Get-EXOMailboxStatistics | Where-Object {$_.TotalItemSize.Value.ToGB() -gt $mbthreshold}
    New-Object -TypeName PSObject -Property @{
        'Name' = $mailbox.UserPrincipalName
        'TotalItemSize' = $stats.TotalItemSize
    }
}

# Merging Properties into one table
$mbtoenablearchive = $mbabove89 | Select-Object Name, @{Name="TotalItemSize";Expression={$_.TotalItemSize.Value.ToGB()}} | Where-Object { $_.TotalItemSize -gt $mbthreshold } | Sort-Object -Property TotalItemSize -Descending

# Enabling archive and setting retention policy
ForEach ($mb in $mbtoenablearchive) {
    Enable-Mailbox -Identity $mb.Name -Archive
    Set-Mailbox -Identity $mb.Name -RetentionPolicy "Office 365 3 Year Retention Policy"
}


# Writing to screen for logging purposes
$mbtoenablearchive | Write-Output
