module sys.stat;

import std.exception : errnoEnforce;
import std.string : toStringz;

import sys_stat = core.sys.posix.sys.stat;

alias Mode = sys_stat.mode_t;
alias Off  = sys_stat.off_t;
alias Stat = sys_stat.stat_t;

alias S_IFMT = sys_stat.S_IFMT;

alias S_IFREG = sys_stat.S_IFREG;
alias S_IFLNK = sys_stat.S_IFLNK;
alias S_IFDIR = sys_stat.S_IFDIR;

@trusted
Stat lstat(scope const(char)[] path)
{
    sys_stat.stat_t buf;
    const ok = sys_stat.lstat(path.toStringz, &buf);
    errnoEnforce(ok != -1, "lstat");
    return buf;
}

@safe
unittest
{
    const path = "testdata/hello";
    const stat = lstat(path);
    assert((stat.st_mode & S_IFMT) == S_IFREG);
}
