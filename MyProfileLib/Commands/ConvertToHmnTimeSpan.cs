using Humanizer;
using System.Management.Automation;

namespace MyProfileLib.Commands;

[Cmdlet(VerbsData.ConvertTo, "HmnTimeSpan", ConfirmImpact = ConfirmImpact.Low)]
[Alias("cthts")]
[OutputType(typeof(string))]
public class ConvertToHmnTimeSpan : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 1, ValueFromPipeline = true)]
    public TimeSpan TimeSpan {get; set;}
    [Parameter(Mandatory = true, Position = 0)]
    public int Precision {get; set;}

    protected override void ProcessRecord()
    {
        WriteObject(TimeSpan.Humanize(Precision));
    }
}
