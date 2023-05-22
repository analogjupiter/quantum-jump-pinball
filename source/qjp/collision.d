module qjp.collision;

import qjp.constants;
import qjp.gametypes;
import qjp.types;
import raylib;
import Math = std.math;
import qjp.obstacles;

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
    immutable distance = pythagoras(pos.x, pos.y);

    // out of bounds?
    return (distance > fieldRadius);
}

bool checkCollisionTowers(const ref GameState state, const Vector2 pos)
{
    immutable float angleTowersRad = state.positionFlippers.toRadiant();

    immutable float anglePosOrig = Math.atan2(pos.y, pos.x);
    immutable float radiusPosOrig = pythagoras(pos.y, pos.x);

    immutable float radiusTranslated = radiusPosOrig / state.quantumLevel;
    immutable float anglePosTranslatedRad = anglePosOrig - angleTowersRad;

    immutable posTranslated = Vector2(
        Math.cos(anglePosTranslatedRad),
        Math.sin(anglePosTranslatedRad),
    ) * radiusTranslated;

    static bool checkTower(bool left)(const Vector2 pos)
    {
        static if (left)
        {
            enum wallRightX = 0 - CTs.towerOffset;
            enum wallLeftX = wallRightX - CTs.towerWidth;
        }
        else
        {
            enum wallLeftX = CTs.towerOffset;
        }

        enum floor = cast(int) CTs.radiusQuantum;
        enum ceiling = floor - CTs.towerHeight;

        enum rooftopY = ceiling - CTs.towerRoofHeight;

        return CheckCollisionPointRec(
            pos,
            Rectangle(wallLeftX, rooftopY, CTs.towerWidth, CTs.towerHeightTotal),
        );
    }

    return checkTower!true(posTranslated)
        || checkTower!false(posTranslated);
}

bool checkCollisionFlippers(const ref GameState state, const Vector2 pos)
{
    immutable float angleTowersRad = state.positionFlippers.toRadiant();

    immutable float anglePosOrig = Math.atan2(pos.y, pos.x);
    immutable float radiusPosOrig = pythagoras(pos.y, pos.x);

    immutable float radiusTranslated = radiusPosOrig / state.quantumLevel;
    immutable float anglePosTranslatedRad = anglePosOrig - angleTowersRad;

    immutable posTranslated = Vector2(
        Math.cos(anglePosTranslatedRad),
        Math.sin(anglePosTranslatedRad),
    ) * radiusTranslated;

    static bool checkFlipper(bool left)(const float posFlipper, const Vector2 pos)
    {
        static if (left)
        {
            enum wallX = 0 - CTs.towerOffset;
            immutable tipPc = posFlipper;
        }
        else
        {
            enum wallX = CTs.towerOffset;
            immutable tipPc = posFlipper;
        }

        enum floor = CTs.radiusQuantum;
        enum mount1Y = floor - (CTs.towerHeight / 3);
        enum mount2Y = floor - (CTs.towerHeight / 3 * 2);

        enum mount1 = Vector2(wallX, mount1Y);
        enum mount2 = Vector2(wallX, mount2Y);

        enum hyp2 = float(Math.pow(CTs.flipperLength, 2));
        immutable tipOffY = CTs.flipperMax * tipPc / 100f;
        immutable tipOffY2 = Math.pow(tipOffY, 2);
        immutable tipOffX = Math.sqrt(hyp2 - tipOffY2);

        static if (left)
            immutable tipX = wallX + tipOffX;
        else
            immutable tipX = wallX - tipOffX;

        immutable tipY = mount1Y - tipOffY;
        immutable tipPos = Vector2(tipX, tipY);

        static if (left)
            return CheckCollisionPointTriangle(pos, tipPos, mount2, mount1);
        else
            return CheckCollisionPointTriangle(pos, tipPos, mount1, mount2);
    }

    return checkFlipper!true(state.positionFlipperL, posTranslated)
        || checkFlipper!false(state.positionFlipperR, posTranslated);
}

bool checkCollisionObstacles(const ref GameState state, const Vector2 pos)
{
    static class CollisionException : Exception
    {
        public this()
        {
            super(null);
        }
    }

    foreach (lvlMin1; 0 .. state.quantumLevel)
        try
            getObstacles(lvlMin1 + 1, delegate(Obstacle obst) {
                final switch (obst.type) with (Obstacle.Type)
                {
                case defect:
                    assert(false, "Defect obstacle");
                case wall:
                    if (distance(obst.position, pos) < CTs.wallRadius)
                        throw new CollisionException();
                    break;
                }
            });
        catch (CollisionException)
            return true;

    return false;
}

void checkCollisionElectrons(ref GameState state, const Vector2 pos, void delegate(size_t, const ref Electron) onCollision)
{
    immutable float maxDistance = (CTs.radiusPinballAura * state.quantumLevel);
    foreach (idx, const ref Electron electron; state.electrons)
        if (distance(electron.ball.position, pos) < maxDistance)
            onCollision(idx, electron);
}
