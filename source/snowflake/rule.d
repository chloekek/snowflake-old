module snowflake.rule;

import snowflake.digest : Hash;

abstract
class Rule
{
    /// The name of a rule is presented to the user. It is not otherwise used.
    immutable(char[]) name;

    /// The intrinsic hash of a rule is the hash of its configuration.
    immutable(Hash) intrinsicHash;

    /// The inputs of a rule are those rules that must be built prior to building
    /// the rule. The order in which inputs are returned is significant; see the
    /// other methods in this class.
    immutable(Rule[]) inputs;

    nothrow protected pure @nogc @safe
    this(immutable(char)[] name,
         Hash intrinsicHash,
         immutable(Rule)[] inputs) immutable scope
    {
        this.name = name;
        this.intrinsicHash = intrinsicHash;
        this.inputs = inputs;
    }

    abstract @safe
    void build(const(char)[] outputPath,
               const(char[])[] inputPaths)
               const;
}
