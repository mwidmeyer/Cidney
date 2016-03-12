﻿function Pipeline:
{
    <#
        .SYNOPSIS
        Cidney Pipeline:
        .DESCRIPTION
        Cidney Pipeline:
        .EXAMPLE
        .\HelloWorld.ps1
                
        Pipeline HelloWorld {
            Stage One {
                Do: { Get-Process }
            }
        }

        .EXAMPLE
        .\HelloWorld.ps1
        
        Pipeline HelloWorld {
            Stage One {
                Do: { Get-Process | Where Status -eq 'Running' }
            }
        }
        .LINK
        Pipeline:
        Stage:
        Do:
        Register-JobCommand
        Get-RegisteredJobCommand
        Get-RegisteredJobModule
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,
        [Parameter(Mandatory, Position = 1)]
        [scriptblock]
        $PipelineBlock,
        [switch]
        $ShowProgress,
        [hashtable]
        $ConfigurationData
    )

    if ($ShowProgress) { Write-Progress -Activity "Pipeline $Name" -Status 'Starting' -Id 0 }

    Write-Output ''
    Write-Log "[Start] Pipeline $Name"     
    $Global:CidneySession.Add('ShowProgress', $ShowProgress)

    if ($ShowProgress) { Write-Progress -Activity "Pipeline $Name" -Status 'Processing' -Id 0 }
        
    try
    {
        Initialize-CidneyVariables -ScriptBlock $PipelineBlock
        $stages = Get-CidneyBlocks -ScriptBlock $PipelineBlock -BoundParameters $PSBoundParameters 
        $count = 0
        foreach($stage in $stages)
        {
            if ($ShowProgress) { Write-Progress -Activity "Pipeline $Name" -Status 'Processing' -Id 0 -PercentComplete ($count / $stages.Count * 100) }
            $count++           
    
            #$stage = [scriptBlock]::Create("$stage")
            Invoke-Command -Command $stage -ArgumentList $ConfigurationData
        }    
    }
    finally
    {
        foreach($var in $Global:CidneySession['GlobalVariables'])
        {
            Remove-Variable -Name $var.Name -Scope Global
        }

        foreach($cred in $Global:CidneySession['CredentialStore'].GetEnumerator())
        {
            Remove-Item $cred.Value -Force -ErrorAction SilentlyContinue
        }
        
        $Global:CidneySession['CredentialStore'].Clear()
        $Global:CidneySession.Remove('GlobalVariables')
        $Global:CidneySession.Remove('ShowProgress')
    }   
    
    Write-Log "[Done] Pipeline $Name" 
    Write-Output ''
    if ($ShowProgress) { Write-Progress -Activity "Pipeline $Name" -Status 'Completed' -ID 0 -Completed }
}

