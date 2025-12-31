if ( -not ('UtilityProfile.CommandStopper' -as [type] ) ) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Linq.Expressions;
using System.Management.Automation;
using System.Management.Automation.Internal;
using System.Reflection;

namespace UtilityProfile
{
    [EditorBrowsable(EditorBrowsableState.Never)]
    [Cmdlet(VerbsLifecycle.Stop, "UpstreamCommand")]
    public class CommandStopper : PSCmdlet
    {
        private static readonly Func<PSCmdlet, Exception> s_creator;

        static CommandStopper()
        {
            ParameterExpression cmdlet = Expression.Parameter(typeof(PSCmdlet), "cmdlet");
            s_creator = Expression.Lambda<Func<PSCmdlet, Exception>>(
                Expression.New(
                    typeof(PSObject).Assembly
                        .GetType("System.Management.Automation.StopUpstreamCommandsException")
                        .GetConstructor(
                            BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance,
                            null,
                            new Type[] { typeof(InternalCommand) },
                            null),
                    cmdlet),
                "NewStopUpstreamCommandsException",
                new ParameterExpression[] { cmdlet })
                .Compile();
        }

        [Parameter(Position = 0, Mandatory = true)]
        [ValidateNotNull]
        public Exception Exception { get; set; }

        [Hidden, EditorBrowsable(EditorBrowsableState.Never)]
        public static void Stop(PSCmdlet cmdlet)
        {
            var exception = s_creator(cmdlet);
            cmdlet.SessionState.PSVariable.Set("__exceptionToThrow", exception);
            var variable = GetOrCreateVariable(cmdlet, "__exceptionToThrow");
            object oldValue = variable.Value;
            try
            {
                variable.Value = exception;
                ScriptBlock.Create("& $ExecutionContext.InvokeCommand.GetCmdletByTypeName([UtilityProfile.CommandStopper]) $__exceptionToThrow")
                    .GetSteppablePipeline(CommandOrigin.Internal)
                    .Begin(false);
            }
            finally
            {
                variable.Value = oldValue;
            }
        }

        private static PSVariable GetOrCreateVariable(PSCmdlet cmdlet, string name)
        {
            PSVariable result = cmdlet.SessionState.PSVariable.Get(name);
            if (result != null)
            {
                return result;
            }

            result = new PSVariable(name, null);
            cmdlet.SessionState.PSVariable.Set(result);
            return result;
        }

        protected override void BeginProcessing()
        {
            throw Exception;
        }
    }
}
'@

}
function Select-FirstObject {
    [Alias('first', 'top')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1
    )
    begin {
        $amountProcessed = 0
    }
    process {
        if ($null -eq $InputObject) {
            return
        }

        # yield
        $InputObject

        $amountProcessed++
        if ($amountProcessed -ge $Count) {
            [UtilityProfile.CommandStopper]::Stop($PSCmdlet)
        }
    }
}

function Select-LastObject {
    [Alias('last')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1
    )
    begin {
        if ($Count -eq 1) {
            $objStore = $null
            return
        }

        $objStore = [psobject[]]::new($Count)
        $currentIndex = 0
    }
    process {
        if ($null -eq $InputObject) {
            return
        }

        if ($Count -eq 1) {
            $objStore = $InputObject
            return
        }

        $objStore[$currentIndex] = $InputObject
        $currentIndex++
        if ($currentIndex -eq $objStore.Length) {
            $currentIndex = 0
        }
    }
    end {
        if ($Count -eq 1) {
            return $objStore
        }

        for ($i = $currentIndex; $i -lt $objStore.Length; $i++) {
            # yield
            $objStore[$i]
        }

        for ($i = 0; $i -lt $currentIndex; $i++) {
            # yield
            $objStore[$i]
        }
    }
}

function Select-ObjectIndex {
    [Alias('at')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0, Mandatory)]
        [int] $Index
    )
    begin {
        $currentIndex = 0
        $lastPipe = $null
        $isIndexNegative = $Index -lt 0

        if ($isIndexNegative) {
            $lastParams = @{
                Count = $Index * -1
            }

            $lastPipe = { Select-LastObject @lastParams }.GetSteppablePipeline([CommandOrigin]::Internal)
            $lastPipe.Begin($MyInvocation.ExpectingInput)
        }
    }
    process {
        if ($null -eq $InputObject) {
            return
        }

        if (-not $isIndexNegative) {
            if ($currentIndex -eq $Index) {
                # yield
                $InputObject
                [UtilityProfile.CommandStopper]::Stop($PSCmdlet)
            }

            $currentIndex++
            return
        }

        $lastPipe.Process($PSItem)
    }
    end {
        if ($null -ne $lastPipe) {
            # yield
            $lastPipe.End() | Select-Object -First 1
        }
    }
}

function Skip-Object {
    [Alias('skip')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1,

        [switch] $Last
    )
    begin {
        $currentIndex = 0
        if ($Last) {
            $buffer = [List[psobject]]::new()
        }
    }
    process {
        if ($Last) {
            $buffer.Add($InputObject)
            return
        }

        if ($currentIndex -ge $Count) {
            # yield
            $InputObject
        }

        $currentIndex++
    }
    end {
        if (-not $Last) {
            return
        }

        return $buffer[0..($buffer.Count - $Count - 1)]
    }
}

function Skip-LastObject {
    [Alias('skiplast')]
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject] $InputObject,

        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Count = 1
    )
    begin {
        $pipe = { Skip-Object -Last @PSBoundParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $pipe.Begin($MyInvocation.ExpectingInput)
    }
    process {
        $pipe.Process($PSItem)
    }
    end {
        $pipe.End()
    }
}
