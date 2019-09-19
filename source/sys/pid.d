module sys.pid;

import std.algorithm : map;
import std.array : array;
import std.exception : errnoEnforce;
import std.range : chain, only;
import std.string : toStringz;
import std.typecons : Nullable;

import sys_types = core.sys.posix.sys.types;
import sys_wait = core.sys.posix.sys.wait;
import unistd = core.sys.posix.unistd;

alias Pid = sys_types.pid_t;

@trusted bool WIFEXITED  (int a) { return sys_wait.WIFEXITED(a); }
@trusted int  WEXITSTATUS(int a) { return sys_wait.WEXITSTATUS(a); }

@trusted
Nullable!Pid fork()
{
    alias NP = typeof(return);
    const pid = unistd.fork();
    errnoEnforce(pid != -1, "fork");
    return pid == 0 ? NP() : NP(pid);
}

@trusted
void execp(scope const(char)[] file,
           scope const(char[])[] argv)
{
    const filez = file.toStringz;
    const argvz = chain(argv.map!toStringz, only(null)).array.ptr;
    unistd.execvp(filez, argvz);
    errnoEnforce(false, "execvp");
}

struct Waitpid
{
    Pid pid;
    int wstatus;
}

@trusted
Waitpid waitpid(Pid pid, int options)
{
    int wstatus;
    const rpid = sys_wait.waitpid(pid, &wstatus, options);
    errnoEnforce(rpid != -1, "waitpid");
    return Waitpid(rpid, wstatus);
}
