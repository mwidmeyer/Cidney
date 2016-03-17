﻿function Do:
{
    <#
        .SYNOPSIS
        Runs a scriptblock using Jobs. 
        
        .DESCRIPTION
        A Cindey Pipeline: will run each Stage: one right after the other synchronously.
        Each Do: Block found will create a Job so they can be run asyncronously or in Parallel.

        Note: Because the Do: keyword sets up jobs some may hang around in an error state if there are errors when executing. 
        If this happens you can use the job functions in powershell to investigate and clean up. Wait-Job, Receive-Job and Remove-Job.
        But if you just want to clean up quickly and do a reset you can call Invoke-Cidney -Force and it will clean up all Cidney jobs.
        
        .EXAMPLE
        .\HelloWorld.ps1

        Pipeline: HelloWorld {
            Stage: One {
                Do: { Dir C:\Windows\System32 | Where Name -match '.dll' | measure }
                Do: GetService { Get-Service B* }
            }
        }
        Invoke-Cidney HelloWorld -verbose

        This example will do a Dir list and count the number of dll files, and run Get-Process as separate jobs and the Stage: will complete once all jobs are finished.
        Notice that Get-Service finished first even when it was listed second in the code.

        VERBOSE: [03/06/16 4:53:39.556 PM] [Start] Pipeline HelloWorld
        VERBOSE: [03/06/16 4:53:39.591 PM] [Start] Stage One
        VERBOSE: [03/06/16 4:53:39.769 PM] [Start] Job28
        VERBOSE: [03/06/16 4:53:40.021 PM] [Start] GetService
        VERBOSE: [03/06/16 4:53:40.150 PM] [Results] GetService

        Status   Name               DisplayName                           
        ------   ----               -----------                           
        Running  BDESVC             BitLocker Drive Encryption Service    
        Running  BFE                Base Filtering Engine                 
        Running  BrokerInfrastru... Background Tasks Infrastructure Ser...
        Running  Browser            Computer Browser                      
        Running  BthHFSrv           Bluetooth Handsfree Service           
        Running  bthserv            Bluetooth Support Service             
        VERBOSE: [03/06/16 4:53:40.170 PM] [Completed] GetService
        VERBOSE: [03/06/16 4:53:40.496 PM] [Results] Job28

        Count    : 3001
        Average  : 
        Sum      : 
        Maximum  : 
        Minimum  : 
        Property : 

        VERBOSE: [03/06/16 4:53:40.499 PM] [Completed] Job28
        VERBOSE: [03/06/16 4:53:40.606 PM] [Done] Stage One
        VERBOSE: [03/06/16 4:53:40.607 PM] [Done] Pipeline HelloWorld
        .LINK
        Pipeline:
        Stage:
        On:
        When:
        Invoke-Cidney
    #>


    [cmdletbinding(DefaultParameterSetName='ScriptBlock')]
    param
    (
        [Parameter(Position = 0, ParameterSetName='Name')]
        [string]
        $Name = '',
        [Parameter(Mandatory, Position = 1, ParameterSetName='Name')]
        [Parameter(Mandatory, Position = 0, ParameterSetName='ScriptBlock')]
        [scriptblock]
        $DoBlock,
        [int]
        $TimeOut = [int]::MaxValue,
        [Parameter(DontShow)]
        [switch]
        $ImportModules,
        [Parameter(DontShow)]
        [string[]]
        $ComputerName,
        [Parameter(DontShow)]
        [string]
        $UserName,
        [Parameter(DontShow)]
        [hashtable]
        $Context
    )

    $importModulesScript = @'

    foreach($__module in $__Context.Modules) 
    { 
       
        if ((Get-Module -Name $__module) -eq $null)
        {
            $null = Import-Module -Name $__module -ErrorAction SilentlyContinue
        }
    };
'@ 

    $scriptHeader = ''
    if ($ImportModules)
    {
        $scriptHeader += $importModulesScript
    }

    $DoBlock = New-ParamScriptBlock -Script "$scriptHeader $($DoBlock.ToString())"
   
    $params = @{
        #ThrottleLimit = Get-ThrottleLimit
        WarningAction = 'SilentlyContinue'   
        ScriptBlock = $DoBlock 
        ArgumentList = $Context
    }

    if ($UserName)
    {
        $credential = Import-Clixml (Join-Path $Env:CidneyStore "$($UserName)Credentials.xml") 
        $params.Add('Credential', $Credential)
    }

    if ($ComputerName)
    {
        foreach($computer in $ComputerName)
        {
            $job = Invoke-Command @params -ComputerName $computer -AsJob 
            $job.Name = "CI [Job$($Job.Id)] $Name"
            $job.Name += " [$computer]"
            Write-CidneyLog "[Start] $($job.Name)"
            $Context.Jobs += [PSCustomObject]@{'Job' = $job; 'TimeOut' = $Timeout; 'ExecutionTime'= 0; ErrorAction = $ErrorActionPreference}
        }
    }
    else
    {
        $job = Start-Job @params 
        $job.Name = "CI [Job$($Job.Id)] $Name"
        $Context.Jobs += [PSCustomObject]@{'Job' = $job; 'TimeOut' = $Timeout; 'ExecutionTime' = 0; ErrorAction = $ErrorActionPreference}
        Write-CidneyLog "[Start] $($job.Name)"
    }
}