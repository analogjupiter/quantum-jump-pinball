module qjp.collision;

import qjp.gametypes;
import qjp.types;
import Math = std.math;

struct Collision
{
    enum Location
    {
        outerBounds,
    }

    Location location;
    ptrdiff_t objectIdx;
}

bool checkCollisionOuterBounds(const ref GameState state, const Vector2 pos)
{
    immutable fieldRadius = calcFieldRadius(state);

    // determine distance to center
    immutable distance = Math.sqrt(Math.pow(pos.x, 2) + Math.pow(pos.y, 2));

    // out of bounds?
    return (distance > fieldRadius);
}
