<#
    2018.10.29:zG
    collect first/last events (date/time) & calc number of events
    2020.07.29:zG
    find reboots between Jan 7 and 25, 2020, for BAKE-200067 PFI
    2020.10.13:zG, from FindReboots_ME-PFI.ps1
    extract ScriptBlockText

    !!Works on .evt, not .evtx


    ToDo:  add cmd-line param to define date window
            test for existence of output files
            select events by event ID
            break up scripts by scriptblock ID
 #>

 param (
    [Parameter(Mandatory=$True,Position=1)] [string] $infile
 )

#Some variables we'll use
    $SelEvents=@()
    $myOutObjects=@()
#    $tmpfi='.\zG_evtparser_tmp.evt'
    $extractOut='.\extract.txt'
    $myScriptblockOut='.\ExtractedScriptblock_'
    $currentDir=(Get-Location)

$ErrorActionPreference = “Stop”
$null=New-Item $infile'.working'    #creates a marker, indicating which log is currently being processed
$thisFi=Get-Item $infile

    write-host "thisFi: " $thisFi
   
    foreach ($myEvtID in 4104) {         
    Write-Host "collecting events w/ eventID $myEvtID."
        $SelEvents += Get-WinEvent  -Path $thisFi  -Oldest  | Where-Object { $_.id -eq $myEvtID } 
		write-host ("selEvents.count: " + $selEvents.count)
            foreach ($myEvt in $selEvents) {
				$myOutObject = New-Object -TypeName psobject
                    $myOutObject | Add-Member -MemberType NoteProperty -Name Part -value $myEvt.Properties[0].value -PassThru |
				    Add-Member -MemberType NoteProperty -Name TotalParts -value $myEvt.Properties[1].value -PassThru |
				    Add-Member -MemberType NoteProperty -Name ScriptBlock -value $myEvt.Properties[2].value -PassThru |
				    Add-Member -MemberType NoteProperty -Name ScriptUID -value $myEvt.Properties[3].value 
				$myOutObjects+=$myOutObject

#write each script out into its own file, named using the ScriptBlockID
#toDo:  add header with datetime and total number of parts
    #Initial time:
    #Total pieces:
    #(only when msg# is 1, i.e., property[0].value -eq 1)
                $myEvt.Properties[2].value | Out-File -FilePath ($myScriptblockOut + $myEvt.Properties[3].value + ".txt" ) -Append
				}
		}
		
write-host ("Total found: "+ $SelEvents.Count)
<#$customObjOut=".\selectedObjects.xml"
Write-Host "writing object out as $customObjOut"
$myOutObjects | Export-Clixml $customObjOut
#>

Write-Host "finished, now cleaning up"

#cleanup/restore
$SelEvents=@()
remove-variable -name SelEvents
[GC]::Collect()
$sleepTime=1
Start-Sleep -Seconds $sleepTime
 <#do {                                            #need to close/stop processing the current log file
        #try {
            #Write-Host ("moving "+$tmpfi + " to " + $infile)
            #move-Item -Force  -literalpath "$tmpfi" "$infile"
            move-Item -Force  -literalpath  "$infile" "$tmpfi"
			cp $tmpfi $infile
            $success = $true
        #} catch { 
            $sleepTime=$sleepTime*2
			Start-Sleep -Seconds $sleepTime
        #}
        $count++
 #} until ($success -or $count -ge 0)
if (-not $success) { Write-Host ("Something has gone wrong while trying to close the file: $infile.")}
#>

Remove-Item -LiteralPath $infile'.working'

 #Then these two commands to extract into something we can work with:
    [xml]$XmlDocument = Get-Content -Path $customObjOut 
    foreach ( $evt in $XmlDocument.objs.Obj) { $evt.MS.s.innertext >> $extractOut}
    Write-Host ("Merging " + $XmlDocument.Objs.Obj.count +" event log entries into scriptblock at $extractOut")
