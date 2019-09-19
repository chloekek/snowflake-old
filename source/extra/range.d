module extra.range;

import std.typecons : Nullable;

/// Given a function that takes no arguments and returns Nullable!T, return an
/// input range of Ts. The input range will yield values of type T until F
/// returns a null value.
auto iterator(alias F)()
{
    alias Item = typeof(F().get);
    struct Range
    {
        bool empty()    { return ensure.isNull; }
        void popFront() { item.nullify;         }
        Item front()    { return ensure.get;    }

        private
        Nullable!Item ensure()
        {
            if (item.isNull)
                item = F();
            return item;
        }

        private
        Nullable!Item item;
    }
    return Range();
}

///
@safe
unittest
{
    import std.algorithm : equal;
    alias Ni = Nullable!int;
    auto i = 0;
    auto range = iterator!(() => i == 5 ? Ni() : Ni(i++));
    assert(equal(range, [0, 1, 2, 3, 4]));
}
