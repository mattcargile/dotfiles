using System.ComponentModel;
using System.Linq.Expressions;
using System.Reflection;
using System.Management.Automation;
using System.Management.Automation.Internal;

namespace MyProfileLib;

[EditorBrowsable(EditorBrowsableState.Never)]
[Cmdlet(VerbsLifecycle.Stop, "UpstreamCommand")]
public class StopUpstreamCommand : PSCmdlet
{
    private static readonly Func<PSCmdlet, Exception> s_creator;

    static StopUpstreamCommand()
    {
        ParameterExpression cmdlet = Expression.Parameter(typeof(PSCmdlet), "cmdlet");
        Type? stopUpStreamType = typeof(PSObject).Assembly.GetType("System.Management.Automation.StopUpstreamCommandsException");
        ConstructorInfo? ctorStop = stopUpStreamType?.GetConstructor(
            BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance,
            null,
            [typeof(InternalCommand)],
            null
        );
        if (ctorStop is not null)
        {
            s_creator = Expression.Lambda<Func<PSCmdlet, Exception>>(
                Expression.New( ctorStop, cmdlet),
                "NewStopUpstreamCommandsException",
                [cmdlet]
            )
            .Compile();
        }
        else
        {
            throw new InvalidDataException();
        }
    }

    [Parameter(Position = 0, Mandatory = true)]
    [ValidateNotNull]
    public Exception BeginException { get; set; } = new NotSupportedException();

    [Hidden, EditorBrowsable(EditorBrowsableState.Never)]
    public static void Stop(PSCmdlet cmdlet)
    {
        var command = new CmdletInfo("Stop-UpstreamCommand", typeof(StopUpstreamCommand));
        ScriptBlock.Create("param($command, $exception) & $command $exception")
            .GetSteppablePipeline(
                CommandOrigin.Internal,
                new object[] { command, s_creator(cmdlet) } )
            .Begin(false);
    }

    protected override void BeginProcessing()
    {
        throw BeginException;
    }
}
