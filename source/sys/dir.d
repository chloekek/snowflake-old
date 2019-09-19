module sys.dir;

import extra.range : iterator;

import std.exception : errnoEnforce;
import std.string : fromStringz, toStringz;
import std.typecons : Nullable;

import dirent = core.sys.posix.dirent;
import errno = core.stdc.errno;

struct Dir
{
    @disable this();
    @disable this(this);

    nothrow private pure @nogc @safe
    this(dirent.DIR* dir) scope
    {
        this.dir = dir;
    }

    @nogc @trusted
    ~this() scope
    {
        dirent.closedir(dir);
    }

    private
    dirent.DIR* dir;
}

struct Dirent
{
    nothrow pure @nogc @system
    this(scope inout(dirent.dirent)* entry) inout scope
    {
        d_name = entry.d_name.ptr.fromStringz;
    }

    char[] d_name;
}

@trusted
Dir opendir(scope const(char)[] path)
{
    auto dir = dirent.opendir(path.toStringz);
    errnoEnforce(dir !is null, "opendir");
    return Dir(dir);
}

@trusted
Nullable!Dirent readdir(scope ref Dir dir)
{
    errno.errno = 0;
    auto entry = dirent.readdir(dir.dir);
    if (entry is null && errno.errno != 0)
        errnoEnforce(false, "readdir");

    if (entry is null)
        return typeof(return).init;
    else
        return typeof(return)(Dirent(entry));
}

/// Return an input range over the directory entries, by lazily calling readdir.
/// The special entries . and .. are not excluded from the range.
auto readdirs(scope ref Dir dir)
{
    return iterator!(() => readdir(dir));
}

///
@safe
unittest
{
    import std.algorithm : equal, map, sort;
    import std.array : array;
    auto dir = opendir("testdata");
    auto range = readdirs(dir).map!`a.d_name`.array.sort;
    assert(equal(range, [".", "..", "hello", "symlink"]));
}
