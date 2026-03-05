using System.Collections.ObjectModel;
namespace MyProfileLib;

public class CommandParameterInfo
{
    public CommandParameterInfo(){}
    public string? Set {get; set;}
    public ReadOnlyCollection<string>? Aliases {get; set;}
    public int Position {get; set;}
    public bool IsDynamic {get; set;}
    public bool IsMandatory {get; set;}
    public bool ValueFromPipeline {get; set;}
    public bool ValueFromPipelineByPropertyName {get; set;}
    public bool ValueFromRemainingArguments {get; set;}
    public Type? Type {get; set;}
    public string? Name {get; set;}
    public ReadOnlyCollection<Attribute>? Attributes {get; set;}
    public bool IsDefaultSet {get; set;}
}
