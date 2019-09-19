module snowflake.digest;

import std.algorithm : copy, filter, map, sort;
import std.array : array;
import std.conv : octal;
import std.digest.sha : SHA256;
import std.range : chain, put;

import sys.dir : opendir, readdirs;
import sys.fd : O_RDONLY, open, reads;
import sys.readlink : readlink;
import sys.stat : Mode, Off, S_IFDIR, S_IFLNK, S_IFMT, S_IFREG, lstat;

alias Digest = SHA256;
alias Hash   = ubyte[256 / 8];

Hash digest(R...)(R rs)
{
    Digest d;
    copy(chain(rs), &d);
    return d.finish;
}

final class IndigestibleFileException
    : Exception
{
    immutable(char[]) path;

    @safe
    this(immutable(char)[] path) scope
    {
        super("Undigestible file: " ~ path);
        this.path = path;
    }
}

@safe
Hash digestFile(scope const(char)[] path)
{
    Digest d;
    digestFile(d, path);
    return d.finish;
}

@safe
void digestFile(scope ref Digest d, scope const(char)[] path)
{
    const stat = lstat(path);
    const size = stat.st_size;
    const mode = stat.st_mode;
    const perm = mode & octal!777;
    const type = mode & S_IFMT;
    switch (type) {
        case S_IFREG: digestRegularFile (d, perm, size, path); break;
        case S_IFLNK: digestSymbolicLink(d,             path); break;
        case S_IFDIR: digestDirectory   (d, perm,       path); break;
        default: throw new IndigestibleFileException(path.idup);
    }
}

private @safe
void digestRegularFile(scope ref Digest d, Mode perm, Off size, scope const(char)[] path)
{
    // File type.
    put(d, 'F');

    // File permissions.
    putUlong(d, perm);

    // File size in bytes.
    putUlong(d, size);

    // File contents.
    auto fd = open(path, O_RDONLY, 0);
    ubyte[1024] buf;
    copy(reads(fd, buf), &d);
}

private @safe
void digestSymbolicLink(scope ref Digest d, scope const(char)[] path)
{
    // File type.
    put(d, 'S');

    // Symbolic link target.
    const target = readlink(path);
    putString(d, target);
}

private @safe
void digestDirectory(scope ref Digest d, Mode perm, scope const(char)[] path)
{
    // File type.
    put(d, 'D');

    // File permissions.
    putUlong(d, perm);

    // Gather the entries and close the handle ASAP. Sort the entries so that
    // the output of this subroutine is reliable.
    auto entries = {
        auto dir = opendir(path);
        return readdirs(dir)
                   .map!`a.d_name`
                   .filter!`a != "." && a != ".."`
                   .array
                   .sort;
    }();

    // Directory entries.
    foreach (entry; entries) {
        putString(d, entry);
        digestFile(d, path ~ "/" ~ entry);
    }

    // Terminator.
    putString(d, "");
}

nothrow pure @nogc @safe
void putUlong(scope ref Digest d, ulong value)
{
    put(d, cast(ubyte) (value >> 56));
    put(d, cast(ubyte) (value >> 48));
    put(d, cast(ubyte) (value >> 40));
    put(d, cast(ubyte) (value >> 32));
    put(d, cast(ubyte) (value >> 24));
    put(d, cast(ubyte) (value >> 16));
    put(d, cast(ubyte) (value >>  8));
    put(d, cast(ubyte) (value >>  0));
}

nothrow pure @nogc @safe
void putString(scope ref Digest d, scope const(char)[] value)
{
    putUlong(d, value.length);
    put(d, value);
}

@safe
unittest
{
    SHA256 d;
    digestFile(d, "testdata");
    const hash = [0x1D, 0xE6, 0xCB, 0xC5, 0xA4, 0x27, 0x83, 0x0A,
                  0xDF, 0x8A, 0x4B, 0x82, 0x60, 0x47, 0x43, 0x92,
                  0xD8, 0x2B, 0xED, 0x78, 0xA0, 0x78, 0x6D, 0x96,
                  0xDD, 0x0C, 0x77, 0xCC, 0xF9, 0x85, 0x0E, 0x2D];
    assert (d.finish == hash);
}
