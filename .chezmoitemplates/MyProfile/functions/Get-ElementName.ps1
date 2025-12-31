<#
.SYNOPSIS
    Gets the element/object name
.DESCRIPTION
    Recreates C# nameof to get name of the object
.EXAMPLE
    $x = 1
    Get-ElementName {$x}
    Returns the name of the variable $x as x
#>
function Get-ElementName {
    [Alias('nameof')]
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory)]
        [ValidateNotNull()]
        [ScriptBlock] $Expression
    )
    end {
        if ($Expression.Ast.EndBlock.Statements.Count -eq 0) {
            return
        }

        $firstElement = $Expression.Ast.EndBlock.Statements[0].PipelineElements[0]
        if ($firstElement.Expression.VariablePath.UserPath) {
            return $firstElement.Expression.VariablePath.UserPath
        }

        if ($firstElement.Expression.Member) {
            return $firstElement.Expression.Member.SafeGetValue()
        }

        if ($firstElement.GetCommandName) {
            return $firstElement.GetCommandName()
        }

        if ($firstElement.Expression.TypeName.FullName) {
            return $firstElement.Expression.TypeName.FullName
        }
    }
}
