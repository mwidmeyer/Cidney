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
        On:
        When:
        Invoke-Cidney
    #>

    [cmdletbinding(DefaultParameterSetName = 'Pipeline')]
    param
    (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'pipeline')]
        [string]
        $PipelineName,
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'pipeline')]
        [scriptblock]
        $PipelineBlock,
        [Parameter(Position = 2, ParameterSetName = 'pipeline')]
        [switch]
        $PassThru,
        # Added so that the adavanced parameters like Verbose wont be shown. -Verbose is passed 
        # via cmdlet Invoke-Cidney 
        [Parameter(DontShow)]
        [switch]
        $Dummy
    )

    end
    {
        $functionName = "Global:Pipeline: $PipelineName"
        if ($Script:CidneyPipelineFunctions.ContainsKey($functionName))
        {
            $Script:CidneyPipelineFunctions.Remove($functionName)
        }
        $Script:CidneyPipelineFunctions.Add($functionName, $PSBoundParameters)

        $functionScript = {
            [CmdletBinding()]
            param
            (
                [string]
                $PipelineName,
                [scriptblock]
                $PipelineBlock,
                [switch]
                $ShowProgress,
                [hashtable]
                $Context
            )

            $Script:CidneyPipelineCount++
            $context = New-CidneyContext
            $context.Add('ShowProgress', $ShowProgress)
            $context.Add('CurrentStage', '')
            $Context.Add('PipelineName', $PipelineName)

            if ($ShowProgress) 
            { 
                Write-Progress -Activity "Pipeline $PipelineName" -Status 'Starting' -Id 0 
            }

            Write-CidneyLog "[Start] Pipeline $PipelineName" 

            if ($ShowProgress) 
            { 
                Write-Progress -Activity "Pipeline $PipelineName" -Status 'Processing' -Id 0 
            }
        
            try
            {
                Initialize-CidneyVariables -ScriptBlock $PipelineBlock -Context $context
                $stages = Get-CidneyStatements -ScriptBlock $PipelineBlock -BoundParameters $PSBoundParameters 

                $count = 0
                foreach($stage in $stages)
                {
                    if ($ShowProgress) 
                    { 
                        Write-Progress -Activity "Pipeline $PipelineName" -Status 'Processing' -Id 0 -PercentComplete ($count / $stages.Count * 100) 
                    }
                    $count++           
    
                    Invoke-Command -Command $stage -ArgumentList $context
                }    
            }
            finally
            {
                foreach($cred in $context.CredentialStore.GetEnumerator())
                {
                    Remove-Item $cred.Value -Force -ErrorAction SilentlyContinue
                }
        
                foreach($var in $context.LocalVariables)
                {
                    Remove-Variable -Name $var.Name -Scope Local -ErrorAction SilentlyContinue
                }

                $Script:CidneyPipelineCount--
            }   
    
            Write-CidneyLog "[Done] Pipeline $PipelineName" 
        }

        $result = New-item Function:\$functionName -Value $functionScript -Force

        if ($PassThru)
        {
            $result
        }
    }
}