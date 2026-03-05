using System.ComponentModel;
using System.Linq.Expressions;
using System.Reflection;
using System.Management.Automation;
using System.Management.Automation.Internal;

namespace MyProfileLib;

[EditorBrowsable(EditorBrowsableState.Never)]
[Cmdlet(VerbsLifecycle.Stop, "UpstreamCommand")]
public class CommandStopper : PSCmdlet
{
    private static readonly Func<PSCmdlet, Exception> s_creator;

    static CommandStopper()
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
        var exception = s_creator(cmdlet);
        cmdlet.SessionState.PSVariable.Set("__exceptionToThrow", exception);
        var variable = GetOrCreateVariable(cmdlet, "__exceptionToThrow");
        object oldValue = variable.Value;
        try
        {
            variable.Value = exception;
            ScriptBlock.Create("& $ExecutionContext.InvokeCommand.GetCmdletByTypeName([MyProfileLib.CommandStopper]) $__exceptionToThrow")
                .GetSteppablePipeline(CommandOrigin.Internal)
                .Begin(false);
        }
        finally
        {
            variable.Value = oldValue;
        }
    }

    private static PSVariable GetOrCreateVariable(PSCmdlet cmdlet, string name)
    {
        PSVariable result = cmdlet.SessionState.PSVariable.Get(name);
        if (result != null)
        {
            return result;
        }

        result = new PSVariable(name, null);
        cmdlet.SessionState.PSVariable.Set(result);
        return result;
    }

    protected override void BeginProcessing()
    {
        throw BeginException;
    }
}
