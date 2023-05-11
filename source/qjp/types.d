module qjp.types;

import raylib;

struct Vector2i
{
    int x;
    int y;

    T opCast(T : Vector2)() const @safe pure nothrow @nogc
    {
        return Vector2(this.x, this.y);
    }

    Vector2i opBinary(string op)(inout int rhs)
            if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        return Vector2i(
            mixin("this.x " ~ op ~ " rhs"),
            mixin("this.y " ~ op ~ " rhs"),
        );
    }
}
