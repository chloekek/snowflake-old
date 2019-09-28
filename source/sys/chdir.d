module sys.chdir;

import std.exception : errnoEnforce;
import std.string : toStringz;

import unistd = core.sys.posix.unistd;

@trusted
void chdir(const(char)[] path)
{
    const ok = unistd.chdir(path.toStringz);
    errnoEnforce(ok != -1, "chdir");
}
