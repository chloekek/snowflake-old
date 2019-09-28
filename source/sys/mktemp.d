module sys.mktemp;

import stdlib = core.sys.posix.stdlib;

import std.exception : errnoEnforce;
import std.string : fromStringz;
import std.utf : toUTFz;

@trusted
char[] mktemp(const(char)[] template_)
{
    auto ok = stdlib.mktemp(template_.toUTFz!(char*));
    errnoEnforce(ok !is null, "mktemp");
    return ok.fromStringz;
}
