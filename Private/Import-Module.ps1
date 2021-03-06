function Import-Module
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
        [Parameter(ParameterSetName='Name', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string[]]
        ${Name} = $null,

        [Parameter(ParameterSetName='FullyQualifiedName', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='FullyQualifiedNameAndPSSession', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Microsoft.PowerShell.Commands.ModuleSpecification[]]
        ${FullyQualifiedName} = $null,

        [Parameter(ParameterSetName='Assembly', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [System.Reflection.Assembly[]]
        ${Assembly},

        [ValidateNotNull()]
        [string[]]
        ${Function} = $null,

        [ValidateNotNull()]
        [string[]]
        ${Cmdlet} = $null,

        [ValidateNotNull()]
        [string[]]
        ${Variable} = $null,

        [ValidateNotNull()]
        [string[]]
        ${Alias} = $null,

        [switch]
        ${Force},

        [switch]
        ${AsCustomObject},

        [Parameter(ParameterSetName='Name')]
        [Alias('Version')]
        [version]
        ${MinimumVersion} = $null,

        [Parameter(ParameterSetName='Name')]
        [string]
        ${MaximumVersion} = $null,

        [Parameter(ParameterSetName='Name')]
        [version]
        ${RequiredVersion} = $null,

        [Parameter(ParameterSetName='ModuleInfo', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [psmoduleinfo[]]
        ${ModuleInfo} = $null,

        [Alias('Args')]
        [System.Object[]]
        ${ArgumentList} = $null,

        [switch]
        ${DisableNameChecking},

        [Alias('NoOverwrite')]
        [switch]
        ${NoClobber}
        )

    begin
    {
        $WarningPreference = 'stop'
        $oldVerbosePreference = $VerbosePreference
        $VerbosePreference = $PSBoundParameters['Verbose']

        try 
        {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\Import-Module', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } 
        catch 
        {
            throw
        }
    }

    process
    {
        try 
        {
            $steppablePipeline.Process($_)
        } 
        catch 
        {
            throw
        }
    }

    end
    {
        $VerbosePreference = $oldVerbosePreference
        try 
        {
            $steppablePipeline.End()
            $module = Get-Module $Name
            $hasModule = $Global:CidneyImportedModules | Where-Object Name -eq $module.Name
            if (-not $hasModule)
            {
                $null = $Global:CidneyImportedModules += $module
            }
        } 
        catch 
        {
            throw
        }
    }
}
