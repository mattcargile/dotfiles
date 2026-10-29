using namespace Microsoft.CodeAnalysis
using namespace Microsoft.CodeAnalysis.CSharp
using namespace Microsoft.CodeAnalysis.CSharp.Syntax
using namespace System.Collections.Generic
using namespace System.Management.Automation.Language

[CmdletBinding()]
param (
)
end {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    class CmdletAndAliasCollector : CSharpSyntaxWalker {
        CmdletAndAliasCollector() {
            $this.Cmdlet = [SortedSet[string]]::new()
            $this.Alias = [List[string]]::new()
        }
        [SortedSet[string]] $Cmdlet

        [List[string]] $Alias

        [void] VisitClassDeclaration([ClassDeclarationSyntax] $node) {
            if ( [Microsoft.CodeAnalysis.CSharpExtensions]::IsKind( $node.Parent, [SyntaxKind]::FileScopedNamespaceDeclaration) ) {
                foreach ($currentAttrList in $node.AttributeLists) {
                    [SeparatedSyntaxList[AttributeSyntax]] $currentAttr = $currentAttrList.Attributes
                    # Debug.Assert(currentAttr.Count == 1);
                    [AttributeSyntax] $currentAttrFirst = $currentAttr[0]
                    $currentAttrName = [IdentifierNameSyntax]$currentAttrFirst.Name
                    $currentArgList = $currentAttrFirst.ArgumentList
                    # Debug.Assert(currentArgList is not null);
                    if ($currentAttrName.Identifier.ValueText -eq 'Cmdlet') {
                        $currentCmdletVerbExpression = [MemberAccessExpressionSyntax]$currentArgList.Arguments[0].Expression
                        $currentCmdletVerbName = [IdentifierNameSyntax]$currentCmdletVerbExpression.Name
                        $currentCmdletNounExpression = [LiteralExpressionSyntax]$currentArgList.Arguments[1].Expression
                        $currentCmdletNounName = $currentCmdletNounExpression.Token
                        $this.Cmdlet.Add("$($currentCmdletVerbName.Identifier.ValueText)-$($currentCmdletNounName.ValueText)")
                    }
                    if ($currentAttrName.Identifier.ValueText -eq 'Alias') {
                        foreach ( $currentAlias in $currentArgList.Arguments) {
                            $currentAliasExpression = [LiteralExpressionSyntax]$currentAlias.Expression;
                            $this.Alias.Add($currentAliasExpression.Token.ValueText);
                        }
                    }
                }
            }
            ([CSharpSyntaxWalker]$this).VisitClassDeclaration($node);
        }
    }

    $publicFunctionsRootFiles = Get-ChildItem -Path "$PSScriptRoot\..\MyProfile\functions" -Recurse -File -Include *.ps1, *.ps1.tmpl
    $publicCmdletsRootFiles = Get-ChildItem -Path "$PSScriptRoot\..\..\MyProfileLib\Commands" -Recurse -File -Include *.cs
    $publicFunctionOut = @{
        All = @{
            Function = [SortedSet[string]]::new()
            Alias = [SortedSet[string]]::new()
            Cmdlet = [SortedSet[string]]::new()
        }
        Core = @{
            Function = [SortedSet[string]]::new()
            Alias = [SortedSet[string]]::new()
        }
        Desktop = @{
            Function = [SortedSet[string]]::new()
            Alias = [SortedSet[string]]::new()
        }
    }
    [Token[]]$tkns = $null
    [ParseError[]]$err = $null
    $findFunctionDelegate = {
        param([Ast]$ast)
        if ($ast -is [FunctionDefinitionAst]) {
            $true
        }
        else {
            $false
        }
    }
    $currentFile = $null
    foreach ($currentFile in $publicFunctionsRootFiles) {
        $ast = [Parser]::ParseFile( $currentFile, [ref]$tkns, [ref]$err )
        if ($err) {
            Write-Information -MessageData $err -Tags 'ParserError'
            Write-Error "[$($currentFile.Name)] $($err.Message) Start Line $($err.Extent.StartLineNumber) and Start Column $($err.Extent.StartColumnNumber)."
            continue
        }
        if ($ast.BeginBlock -or $ast.CleanBlock -or $ast.DynamicParamBlock -or $ast.ProcessBlock -or $ast.ParamBlock -or $ast.ScriptRequirements) {
            Write-Error -Message "[$($currentFile.Name)] Ast in a form that isn't expected and includes more code blocks than only End Block. Continuing to next item."
            continue
        }
        Write-Information -MessageData $ast -Tags Ast
        $scriptFunctions = $ast.FindAll( $findFunctionDelegate, <# Outer functions and not nested ones #> $false ) 
        foreach ($currentFunc in $scriptFunctions) {
            $currentParentDir = $currentFile | Split-Path -Parent | Split-Path -LeafBase
            $currentEdition = 'All'
            if ($currentParentDir -eq 'core') {
                $currentEdition = 'Core'
            }
            elseif ($currentParentDir -eq 'desktop' ) {
                $currentEdition = 'Desktop'
            }
            $publicFunctionOut.$currentEdition.Function.Add( $currentFunc.Name ) | Out-Null
            $currentFunc |
                ForEach-Object -MemberName Body |
                ForEach-Object -MemberName ParamBlock |
                ForEach-Object -MemberName Attributes |
                Where-Object -FilterScript { $_.TypeName.Name -eq 'Alias' } |
                ForEach-Object -MemberName PositionalArguments |
                ForEach-Object -Process {
                    $publicFunctionOut.$currentEdition.Alias.Add($_.Value) | Out-Null
                }
        }
    }
    $cmdletCollector = [CmdletAndAliasCollector]::new()
    foreach ($currentCmdletFile in $publicCmdletsRootFiles ) {
        $currentCmdletFileText = $currentCmdletFile | Get-Content -Raw
        $currentCsTree = [CSharpSyntaxTree]::ParseText( $currentCmdletFileText )
        $cmdletCollector.Visit( $currentCsTree.GetCompilationUnitRoot() )
    }
    $publicFunctionOut.All.Alias.UnionWith($cmdletCollector.Alias)
    $publicFunctionOut.All.Cmdlet.UnionWith($cmdletCollector.Cmdlet)

    $publicFunctionOut | ConvertTo-Json -Depth 3 -Compress
}

