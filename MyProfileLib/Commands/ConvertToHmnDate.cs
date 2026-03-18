using Humanizer;
using System.Management.Automation;

namespace MyProfileLib.Commands;

[Cmdlet(VerbsData.ConvertTo, "HmnDate", ConfirmImpact = ConfirmImpact.Low)]
[Alias("cthdt")]
[OutputType(typeof(string))]
public class ConvertToHmnDate : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public DateTime Datetime {get; set;}

    protected override void ProcessRecord()
    {
        WriteObject(Datetime.Humanize());
    }
    
}
