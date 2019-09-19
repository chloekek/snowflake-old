module sys.fd;

import extra.range : iterator;

import std.exception : errnoEnforce;
import std.string : toStringz;
import std.typecons : Nullable;

import fcntl = core.sys.posix.fcntl;
import sys_stat = core.sys.posix.sys.stat;
import unistd = core.sys.posix.unistd;

alias Mode = sys_stat.mode_t;

alias O_APPEND = fcntl.O_APPEND;
alias O_RDONLY = fcntl.O_RDONLY;
alias O_WRONLY = fcntl.O_WRONLY;

struct Fd
{
    @disable this();
    @disable this(this);

    nothrow pure @nogc @safe
    this(int fd) scope
    {
        this.fd = fd;
    }

    @nogc @trusted
    ~this() scope
    {
        unistd.close(fd);
    }

    private
    int fd;
}

@trusted
Fd open(scope const(char)[] path, int flags, Mode mode)
{
    const fd = fcntl.open(path.toStringz, flags, mode);
    errnoEnforce(fd != -1, "open");
    return Fd(fd);
}

@trusted
size_t read(scope ref Fd fd, scope ubyte[] buf)
{
    const ok = unistd.read(fd.fd, buf.ptr, buf.length);
    errnoEnforce(ok != -1, "read");
    return ok;
}

auto reads(ref Fd fd, ubyte[] buf)
in
{
    assert (buf.length > 0);
}
do
{
    alias Nb = Nullable!(ubyte[]);
    return iterator!({
        auto n = read(fd, buf);
        return n == 0 ? Nb() : Nb(buf[0 .. n]);
    });
}

@trusted
size_t write(scope ref Fd fd, scope const(ubyte)[] buf)
{
    const ok = unistd.write(fd.fd, buf.ptr, buf.length);
    errnoEnforce(ok != -1, "write");
    return ok;
}
