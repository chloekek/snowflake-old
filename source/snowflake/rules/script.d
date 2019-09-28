module snowflake.rules.script;

import snowflake.digest : Digest, Hash, putString;
import snowflake.rule : Rule;

import std.algorithm : copy, map;
import std.exception : enforce;

import sys.chdir : chdir;
import sys.mkdtemp : mkdtemp;
import sys.pid : Pid, WEXITSTATUS, WIFEXITED, execp, fork, waitpid;

immutable(Rule) script(Args...)(Args args)
{
    return new immutable(Script)(args);
}

final
class Script
    : Rule
{
    immutable(char[]) script;

    nothrow pure @nogc @safe
    this(immutable(char)[] name,
         immutable(Rule)[] inputs,
         immutable(char)[] script)
         immutable scope
    {
        super(name, hash(name, inputs, script), inputs);
        this.script = script;
    }

    nothrow private pure static @nogc @safe
    Hash hash(immutable(char)[] name,
              immutable(Rule)[] inputs,
              immutable(char)[] script)
    {
        Digest d;

        putString(d, __MODULE__);
        putString(d, script);

        // The name and inputs are passed to the script, so they must be
        // part of the intrinsic hash.
        putString(d, name);
        copy(inputs.map!"a.intrinsicHash", &d);

        return d.finish;
    }

    override @safe
    void build(const(char)[] outputPath,
               const(char[])[] inputPaths)
               const scope
    {
        const pid = fork();
        if (pid.isNull)
            childProcess(outputPath, inputPaths);
        else
            parentProcess(pid.get);
    }

    private @safe
    void childProcess(const(char)[] outputPath,
                      const(char[])[] inputPaths)
                      const scope
    {
        const bash = "bash";
        const argv = [bash, "-c", script, name, outputPath] ~ inputPaths;

        // TODO: Delete up working directory after build.
        const workingDirectory = mkdtemp("/tmp/snowflake.XXXXXX");
        chdir(workingDirectory);

        // TODO: Forward stdout to stderr.
        // TODO: Clean up environment.
        // TODO: Set up namespaces?

        execp(bash, argv);
    }

    private @safe
    void parentProcess(Pid child) const scope
    {
        const wait = waitpid(child, 0);
        const ok = WIFEXITED(wait.wstatus) && WEXITSTATUS(wait.wstatus) == 0;
        // TODO: Report more informative error.
        enforce(ok, "waitpid");
    }
}
