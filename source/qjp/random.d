module qjp.random;

import std.random;

private static Xorshift64 _rng = Xorshift64(0x1234);

Xorshift64 RNG() @safe nothrow @nogc
{
    return _rng;
}

Num rand(Num)(Num min, Num max)
{
    return uniform(min, max, _rng);
}
