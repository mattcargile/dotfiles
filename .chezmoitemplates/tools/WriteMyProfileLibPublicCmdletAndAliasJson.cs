#:package Microsoft.CodeAnalysis.CSharp@*
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

static string GetSourceFilePath([CallerFilePath] string path = "") => path;
string sourceFilePath = GetSourceFilePath();
Debug.Assert(sourceFilePath != "");
string? sourceFileParentPath = Directory.GetParent(sourceFilePath)?.FullName;
Debug.Assert(sourceFileParentPath is not null);
string commandsDir = Path.Join( sourceFileParentPath, "..", "..", "MyProfileLib", "Commands" );
var files = Directory.EnumerateFiles(commandsDir);
var collector = new CmdletAndAliasCollector();
foreach (string file in files)
{
    string currentFileContent = File.ReadAllText(file);
    var csTree = CSharpSyntaxTree.ParseText(currentFileContent);
    var csRoot = csTree.GetCompilationUnitRoot();
    collector.Visit(csRoot);
}
string outJson = JsonSerializer.Serialize(collector, CmdletAndAliasCollectorJsonContext.Default.CmdletAndAliasCollector);
Console.WriteLine(outJson);

[JsonSerializable(typeof(CmdletAndAliasCollector))]
internal partial class CmdletAndAliasCollectorJsonContext : JsonSerializerContext { }

class CmdletAndAliasCollector : CSharpSyntaxWalker
{
    public ICollection<string> CmdletNames {get; } = [ ];
    public ICollection<string> AliasNames {get; } = [ ];
    public override void VisitClassDeclaration(ClassDeclarationSyntax node)
    {
        if (node.Parent.IsKind(SyntaxKind.FileScopedNamespaceDeclaration))
        {
            foreach (AttributeListSyntax currentAttrList in node.AttributeLists)
            {
                SeparatedSyntaxList<AttributeSyntax> currentAttr = currentAttrList.Attributes;
                Debug.Assert(currentAttr.Count == 1);
                AttributeSyntax currentAttrFirst = currentAttr[0];
                var currentAttrName = (IdentifierNameSyntax)currentAttrFirst.Name;
                var currentArgList = currentAttrFirst.ArgumentList;
                Debug.Assert(currentArgList is not null);
                if (currentAttrName.Identifier.ValueText == "Cmdlet")
                {
                    var currentCmdletVerbExpression = (MemberAccessExpressionSyntax)currentArgList.Arguments[0].Expression;
                    var currentCmdletVerbName = (IdentifierNameSyntax)currentCmdletVerbExpression.Name;
                    var currentCmdletNounExpression = (LiteralExpressionSyntax)currentArgList.Arguments[1].Expression;
                    var currentCmdletNounName = currentCmdletNounExpression.Token;
                    CmdletNames.Add($"{currentCmdletVerbName.Identifier.ValueText}-{currentCmdletNounName.ValueText}");
                }
                if (currentAttrName.Identifier.ValueText == "Alias")
                {
                    foreach (var currentAlias in currentArgList.Arguments)
                    {
                        var currentAliasExpression = (LiteralExpressionSyntax)currentAlias.Expression;
                        AliasNames.Add(currentAliasExpression.Token.ValueText);
                    }
                    
                }
            }
        }
        base.VisitClassDeclaration(node);
    }
    
}