module snowflake.cache;

import snowflake.digest : Hash, digestFile;

import std.algorithm : joiner, map;
import std.array : array;
import std.format : format;
import std.range : chunks;

import sys.fd : O_APPEND, O_RDONLY, O_WRONLY, open, reads, write;

/// Mapping from description hashes to output hashes, also stored on disk
/// alongside the outputs.
struct Cache
{
    @disable this();
    @disable this(this);

    private
    immutable(char[]) path;

    private
    Hash[Hash] outputHashes;

    invariant
    {
        assert (outputHashes == cast(const(Hash[Hash])) readOutputHashes(path));
    }

    @safe
    this(immutable(char)[] path) scope
    {
        this.path = path;
        this.outputHashes = readOutputHashes(path);
    }

    private static @trusted
    Hash[Hash] readOutputHashes(immutable(char)[] path)
    {
        Hash[Hash] result;

        ubyte[1024] buf;
        auto fd = open(path ~ "/.output-hashes", O_RDONLY, 0);
        foreach (entry; reads(fd, buf).joiner.chunks(64).map!array) {
            Hash descriptionHash = entry[ 0 .. 32];
            Hash outputHash      = entry[32 .. 64];
            result[descriptionHash] = outputHash;
        }

        return result;
    }

    private @safe
    void writeOutputHash(Hash descriptionHash, Hash outputHash) const scope
    {
        auto fd = open(path ~ "/.output-hashes", O_APPEND | O_WRONLY, 0);
        write(fd, descriptionHash);
        write(fd, outputHash);
    }

    /// Require that an entry is in the cache. If it is not, insert it by
    /// building with the given thunk, which must return a path to a file that
    /// will be moved into the cache by this method.
    @safe
    Hash require(Hash descriptionHash, lazy immutable(char)[] build) scope
    out (outputHash)
    {
        assert (outputHashes[descriptionHash] == outputHash);
    }
    do
    {
        if (const outputHash = descriptionHash in outputHashes)
            return *outputHash;
        else
            return doBuild(descriptionHash, build);
    }

    /// Find the output hash for a description hash. It must already be in the
    /// cache.
    pure @safe
    Hash opIndex(Hash descriptionHash) const scope
    {
        return outputHashes[descriptionHash];
    }

    /// Check whether the description hash is in the cache, and if so, return the
    /// corresponding output hash.
    nothrow pure @nogc @safe
    const(Hash)* opBinaryRight(string op : "in")
                              (Hash descriptionHash)
                               const return scope
    {
        return descriptionHash in outputHashes;
    }

    private @safe
    Hash doBuild(Hash descriptionHash, immutable(char)[] build) scope
    out (outputHash)
    {
        assert (outputHashes[descriptionHash] == outputHash);
    }
    do
    {
        const tempOutputPath = build;
        const outputHash = digestFile(tempOutputPath);

        // TODO: Use POSIX API directly.
        import std.file : rename;
        rename(tempOutputPath, outputPath(outputHash));

        writeOutputHash(descriptionHash, outputHash);
        outputHashes[descriptionHash] = outputHash;

        return outputHash;
    }

    /// Find the path to a cache entry by its output hash. The entry does not
    /// have to be present in the cache.
    pure @safe
    immutable(char)[] outputPath(Hash outputHash) const scope
    {
        return format!"%s/%(%02x%)"(path, outputHash);
    }
}
