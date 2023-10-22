module qjp.types;

import raylib;
import Math = qjp.math;

public import raylib : Vector2;

float toRadiant(const float degree)
{
    return degree * Math.PI / 180;
}

float toDegree(const float radiant)
{
    return radiant * 180 / Math.PI;
}

float clampAngle(const float angle)
{
    if (angle >= 360)
        return angle % 360;

    if (angle < 0)
        return (angle % 360 + 360);

    return angle;
}

F pythagoras(F)(const F a, const F b)
{
    return Math.sqrt(Math.pow(a, 2) + Math.pow(b, 2));
}

struct Vector2i
{
    int x;
    int y;

    this(int x, int y)
    {
        this.x = x;
        this.y = y;
    }

    this(Vector2 v)
    {
        this.x = cast(int) v.x;
        this.y = cast(int) v.y;
    }

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
    import core.stdc.stdlib : malloc, realloc;

    private
    {
        T* _data = null;
        size_t _capacity = 0;
        size_t _length = 0;
    }

    size_t capacity() const @safe pure nothrow @nogc
    {
        return _capacity;
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

        foreach (ref item; _data[0 .. _length])
        {
            result = dg(item);
            if (result)
                break;
        }

        return result;
    }

    int opApply(scope int delegate(size_t, const ref T) dg)
    {
        int result = 0;

        foreach (idx, ref item; _data[0 .. _length])
        {
            result = dg(idx, item);
            if (result)
                break;
        }

        return result;
    }

    int opApply(scope int delegate(size_t, ref T) dg)
    {
        int result = 0;

        foreach (idx, ref item; _data[0 .. _length])
        {
            result = dg(idx, item);
            if (result)
                break;
        }

        return result;
    }

    void removeAt(size_t idx)
    {
        if (idx < _length)
            foreach (i, ref val; _data[idx .. (_length - 1)])
                val = _data[i + 1];
        --_length;
    }

    private void reserveIfNecessary()
    {
        if (capacity > _length)
            return;

        _capacity += ((_capacity / 2) + 1);
        _data = cast(T*) realloc(_data, T.sizeof * _capacity);
    }
}
