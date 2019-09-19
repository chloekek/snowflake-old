module sys.readlink;

import std.exception : enforce, errnoEnforce;
import std.string : toStringz;

import unistd = core.sys.posix.unistd;

@trusted
immutable(char)[] readlink(scope const(char)[] path)
{
    char[1024] buf;
    const ok = unistd.readlink(path.toStringz, buf.ptr, buf.length);
    errnoEnforce(ok != -1, "readlink");
    enforce(ok != buf.length, "readlink");
    return buf[0 .. ok].idup;
}

@safe
unittest
{
    const path = "testdata/symlink";
    const target = readlink(path);
    assert (target == "example");
}
