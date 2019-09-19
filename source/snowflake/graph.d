module snowflake.graph;

import snowflake.digest : Hash;
import snowflake.rule : Rule;

import std.typecons : Tuple, tuple;

/// Topologically sort a collection of rules, such that inputs come before
/// dependants.
///
/// Inputs do not need to be present in the given range; they will be
/// automatically discovered according to the inputs method.
@safe
immutable(Rule)[] sort(immutable(Rule)[] rules)
{
    immutable(Rule)[] result;

    // Set of intrinsic hashes of rules that have been visited by the go
    // function below. This ensures that the same rule is not added to the
    // result array multiple times.
    Tuple!()[Hash] visited;

    // Recursively add rules to the result array, children first.
    void go(immutable(Rule) rule)
    {
        // Check if already visited, otherwise mark as such.
        const hash = rule.intrinsicHash;
        if (hash in visited) return;
        visited[hash] = tuple;

        // Inputs need to be traversed first; this ensures that we get the
        // correct topological ordering where inputs come before dependants.
        foreach (input; rule.inputs)
            go(input);

        // Then append the rule itself to the result.
        result ~= rule;
    }

    // Call go for every rule given to this function.
    foreach (rule; rules)
        go(rule);

    return result;
}

///
@safe
unittest
{
    import snowflake.rules.file : file;
    import snowflake.rules.script : script;
    import std.algorithm : equal;

    auto rule1 = file("testdata/symlink");
    auto rule2 = script("", [rule1], ``);
    auto rule3 = script("", [rule1, rule2], ``);

    const rules = sort([rule3]);
    assert(equal!`a is b`(rules, [rule1, rule2, rule3]));
}
