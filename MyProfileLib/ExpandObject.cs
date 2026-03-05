using System.Management.Automation;

namespace MyProfileLib;

public class ExpandObject
{
    public ExpandObject() { }
    public string? Name {get; set; }
    public string? TypeName {get; set;}
    public PSObject? Value {get; set;}
    public int Index {get; set;}
}
