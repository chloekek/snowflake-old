module snowflake.rules.file;

import snowflake.digest : Digest, Hash, digestFile, putString;
import snowflake.rule : Rule;

import std.exception : enforce;

import sys.pid : Pid, WEXITSTATUS, WIFEXITED, execp, fork, waitpid;

immutable(Rule) file(Args...)(Args args)
{
    return new immutable(File)(args);
}

final
class File
    : Rule
{
    immutable(char[]) path;

    @safe
    this(immutable(char)[] path) immutable scope
    {
        super(path, hash(path), []);
        this.path = path;
    }

    private static @safe
    Hash hash(immutable(char)[] path)
    {
        Digest d;
        putString(d, __MODULE__);
        digestFile(d, path);
        return d.finish;
    }

    override @safe
    void build(const(char)[] outputPath,
               const(char[])[] inputPaths)
               const scope
    {
        // TODO: Implement this in D.
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
        const cp = "cp";
        const argv = [cp, "--recursive", path, outputPath];
        execp(cp, argv);
    }

    private @safe
    void parentProcess(Pid child) const scope
    {
        const wait = waitpid(child, 0);
        const ok = WIFEXITED(wait.wstatus) && WEXITSTATUS(wait.wstatus) == 0;
        enforce(ok, "waitpid");
    }
}
