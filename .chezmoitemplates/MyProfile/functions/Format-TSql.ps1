<#  
.SYNOPSIS  
    Format-TSQL will format tsql script supplied per options set
.DESCRIPTION  
    This script will strip supplied code of comments format per options
.NOTES  
    Author     : Mala Mahadevan (malathi.mahadevan@gmail.com)
  
.PARAMETERS
-InputScript: text file containing T-SQL
    -OutputScript: name of text file to be generated as output

.LIMITATIONS
Strips code of comments
.LINK  
    

.HISTORY
2021.08.08First version for sqlservercentral.com
#>
function Format-TSQL
{
   
    #Defining parameter for scriptname
    [CmdletBinding()]
    [Alias('ftsql')]
    param(
        [Parameter(ValueFromPipeline,Mandatory)]
        [string]
        $InputObject
    )

    if (-not (Get-Module -Name dbatools)) {
        Import-Module -Name dbatools -Global
    }
    #This may need to be modified to wherever the dll resides on your machine
    # TODO: Fix this to find the right dll. Probably should be a C# cmdlet in the MyProfileLib and have a hard pull of this library to avoid dependency on `dbatools`
    # Add-Type -Path "C:\Program Files\Microsoft SQL Server\150\DAC\bin\Microsoft.SqlServer.TransactSql.ScriptDom.dll"

    $generator = [Microsoft.SqlServer.TransactSql.ScriptDom.Sql150ScriptGenerator]::New();
    $generator.Options.IncludeSemicolons = $true
    $generator.Options.AlignClauseBodies = $false
    $generator.Options.AlignColumnDefinitionFields = $false
    $generator.Options.AlignSetClauseItem = $true
    $generator.Options.AsKeywordOnOwnLine = $true
    $generator.Options.IndentationSize = 4
    $generator.Options.IndentSetClause = $true
    $generator.Options.IndentViewBody = $true
    $generator.Options.KeywordCasing =  [Microsoft.SqlServer.TransactSql.ScriptDom.KeywordCasing]::Uppercase
    $generator.Options.MultilineInsertSourcesList = $true
    $generator.Options.MultilineInsertTargetsList = $true
    $generator.Options.MultilineSelectElementsList = $true
    $generator.Options.MultilineSetClauseItems = $true
    $generator.Options.MultilineViewColumnsList = $true
    $generator.Options.MultilineWherePredicatesList = $true
    $generator.Options.NewLineBeforeCloseParenthesisInMultilineList = $true
    $generator.Options.NewLineBeforeFromClause = $true
    $generator.Options.NewLineBeforeGroupByClause = $true
    $generator.Options.NewLineBeforeHavingClause = $true
    $generator.Options.NewLineBeforeJoinClause = $true
    $generator.Options.NewLineBeforeOffsetClause = $true
    $generator.Options.NewLineBeforeOpenParenthesisInMultilineList = $true
    $generator.Options.NewLineBeforeOrderByClause = $true
    $generator.Options.NewLineBeforeOutputClause = $true
    $generator.Options.NewLineBeforeWhereClause = $true
    $generator.Options.NewLineBeforeWindowClause = $true
    $generator.Options.NumNewlinesAfterStatement = 1
    $generator.Options.SqlEngineType = [Microsoft.SqlServer.TransactSql.ScriptDom.SqlEngineType]::Standalone
    $generator.Options.SqlVersion = [Microsoft.SqlServer.TransactSql.ScriptDom.SqlVersion]::Sql150

    $stringreader = New-Object -TypeName System.IO.StreamReader -ArgumentList ([MemoryStream]::new([Encoding]::UTF8.GetBytes($InputObject)))
   
    $generate = [Microsoft.SqlServer.TransactSql.ScriptDom.Sql150ScriptGenerator]($generator)
    $parser = [Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser]($true)::New();
    if($null -eq $parser ){
        throw 'ScriptDOM not installed or not accessible'
    }

    $parseerrors = $null
    $fragment = $parser.Parse($stringreader,([ref]$parseerrors))
    if($parseerrors.Count -gt 0) {
        throw "$($parseErrors.Count) parsing error(s): $(($parseErrors | ConvertTo-Json))"
    } 

    $formattedoutput = [string]::Empty
    $generate.GenerateScript($fragment,([ref]$formattedoutput)) 
    $formattedoutput.ToString()
}
