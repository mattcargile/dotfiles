using Humanizer;
using System.Management.Automation;

namespace MyProfileLib.Commands;

[CmdletBinding(ConfirmImpact = ConfirmImpact.Low)]
[Cmdlet(VerbsData.ConvertTo, "HumanDate")]
[Alias("cthdt")]
[OutputType(typeof(string))]
public class ConvertToHumanDate : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public DateTime Datetime {get; set;}

    protected override void ProcessRecord()
    {
        WriteObject(Datetime.Humanize());
    }
    
}
