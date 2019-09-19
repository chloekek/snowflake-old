module main;

import snowflake.build : Build;
import snowflake.graph : sort;
import snowflake.rule : Rule;
import snowflake.rules.file : file;
import snowflake.rules.script : script;

import std.stdio : writefln;

nothrow pure @safe
immutable(Rule) gcc(immutable(char)[] name, immutable(Rule) source)
{
    return script(name, [source], `
        set -o errexit
        gcc -x c -c "$2" -o "$1"
    `);
}

nothrow pure @safe
immutable(Rule) ld(immutable(char)[] name, immutable(Rule)[] objects)
{
    return script(name, objects, `
        set -o errexit
        gcc "${@:2}" -o "$1"
    `);
}

@safe
void main()
{
    auto greet_c = file("example/greet.c");
    auto main_c = file("example/main.c");

    auto greet_o = gcc("greet.o", greet_c);
    auto main_o = gcc("main.o", main_c);

    auto hello_world = ld("hello-world", [greet_o, main_o]);

    auto bd = Build("snowflake-cache");
    auto sorted = sort([hello_world]);
    foreach (rule; sorted)
        writefln!"%s @ %(%02x%)"(rule.name, bd.build(rule));
}
