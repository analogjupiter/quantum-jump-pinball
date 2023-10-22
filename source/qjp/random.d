module qjp.random;

import core.stdc.stdlib : rand;

Num rand(Num)(Num min, Num max)
{
    return (rand() + min) % max;
}
