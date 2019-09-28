module sys.mkdtemp;

import stdlib = core.sys.posix.stdlib;

import std.exception : errnoEnforce;
import std.string : fromStringz;
import std.utf : toUTFz;

@trusted
char[] mkdtemp(const(char)[] template_)
{
    auto ok = stdlib.mkdtemp(template_.toUTFz!(char*));
    errnoEnforce(ok !is null, "mkdtemp");
    return ok.fromStringz;
}
