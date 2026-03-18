using Humanizer;
using System.Diagnostics;
using System.Management.Automation;

namespace MyProfileLib.Commands;

[Cmdlet(VerbsData.ConvertTo, "HmnByteSize", ConfirmImpact = ConfirmImpact.Low)]
[Alias("cthbs")]
[OutputType(typeof(string))]
public class ConvertToHmnByteSize : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 1, ValueFromPipeline = true)]
    [Alias("ByteSize", "bs")]
    public long Size {get; set;}

    [Parameter(Mandatory = true, Position = 0)]
    public string? Format {get; set;}

    protected override void ProcessRecord()
    {
        Debug.Assert(Format is not null);
        WriteObject(Size.Bits().Humanize(Format));
    }
    
}