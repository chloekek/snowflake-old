module snowflake.build;

import snowflake.cache : Cache;
import snowflake.digest : Hash, digest;
import snowflake.rule : Rule;

import std.algorithm : map;
import std.array : array;
import std.range : only;
import std.typecons : Tuple, tuple;

struct Build
{
    @disable this();
    @disable this(this);

    private
    Cache cache;

    /// Mapping from intrinsic hashes to description hashes.
    private
    Hash[Hash] descriptionHashes;

    @safe
    this(immutable(char)[] cachePath)
    {
        this.cache = Cache(cachePath);
    }

    /// Whether a rule was already built.
    @safe
    bool built(immutable(Rule) rule) const scope
    {
        return built(rule.intrinsicHash);
    }

    /// ditto
    nothrow pure @nogc @safe
    bool built(Hash intrinsicHash) const scope
    {
        const descriptionHash = intrinsicHash in descriptionHashes;
        return descriptionHash !is null && *descriptionHash in cache;
    }

    /// Build a rule and return the output hash. The inputs of the rule must
    /// already have been built using the same [Build] object.
    @safe
    Hash build(immutable(Rule) rule) scope
    in
    {
        foreach (input; rule.inputs)
            assert (built(input));
    }
    out
    {
        assert (built(rule));
    }
    do
    {
        const inputs = analyzeInputs(rule.inputs);

        const intrinsicHash =
            rule.intrinsicHash;

        const descriptionHash =
            descriptionHashes.require(
                intrinsicHash,
                digest(only(intrinsicHash), inputs[0]),
            );

        const outputHash =
            cache.require(
                descriptionHash,
                doBuild(rule, inputs[1]),
            );

        return outputHash;
    }

    private @safe
    immutable(char)[] doBuild(immutable(Rule) rule,
                              immutable(char[])[] inputPaths)
                              const scope
    {
        // TODO: Generate unique path.
        // TODO: Delete partial output if build fails.
        const tempOutputPath = "/tmp/snowflake-build";
        rule.build(tempOutputPath, inputPaths);
        return tempOutputPath;
    }

    /// Find the output hashes and output paths for the inputs of a rule. The
    /// inputs must have already been built.
    private @safe
    Tuple!(Hash[], immutable(char[])[])
    analyzeInputs(immutable(Rule)[] inputs) scope
    in
    {
        foreach (input; inputs)
            assert (built(input));
    }
    out (result)
    {
        assert (result[0].length == inputs.length);
        assert (result[1].length == inputs.length);
    }
    do
    {
        auto hashes =
            inputs
            .map!(i => cache[descriptionHashes[i.intrinsicHash]])
            .array;

        auto paths =
            hashes
            .map!(h => cast(immutable(char[])) cache.outputPath(h))
            .array;

        return tuple(hashes, paths);
    }
}
