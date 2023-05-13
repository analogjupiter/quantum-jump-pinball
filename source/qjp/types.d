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

struct List(T)
{
    private
    {
        T[] _data;
        size_t _length;
    }

    size_t capacity() const @safe pure nothrow @nogc
    {
        return _data.length;
    }

    size_t length() const @safe pure nothrow @nogc
    {
        return _length;
    }

    auto opOpAssign(string op : "~")(T value)
    {
        this.reserveIfNecessary();
        _data[_length] = value;
        ++_length;
        return this;
    }

    int opApply(scope int delegate(ref T) dg)
    {
        int result = 0;

        foreach (item; _data)
        {
            result = dg(item);
            if (result)
                break;
        }

        return result;
    }

    private void reserveIfNecessary()
    {
        if (capacity > _length)
            return;

        _data.length += (_data.length / 2);
    }
}
