module qjp.obstacles;

import qjp.types;
import qjp.constants;
import Math = std.math;

struct Obstacle
{
    enum Type
    {
        defect,
        wall,
    }

    Type type;
    Vector2 position;
}

void getObstacles(const int quantumLevel, const void delegate(Obstacle) callback)
{
    immutable nObstacles =
        cast(int)(
            (quantumLevel * 2.4)
                + (quantumLevel % 3)
                + Math.cos(float(quantumLevel))
        );
    immutable indivShift = (CTs.radiusQuantum * 0.9) / nObstacles;
    immutable minShift =
        (CTs.radiusQuantum * (quantumLevel - 1))
        + (CTs.radiusQuantum * 0.05)
        + (indivShift / 2);

    float angle = 15;
    immutable float nObst3 = (nObstacles / 3) + 1;

    foreach (n; 0 .. nObstacles)
    {
        Obstacle.Type type;
        if (quantumLevel <= 3)
        {
            type = Obstacle.Type.wall;
        }
        else
        {
            // TODO
            type = Obstacle.Type.wall;
        }

        angle += 300 * n / nObst3;

        immutable float shift = minShift + n * indivShift;

        immutable pos = Vector2(
            Math.cos(angle.toRadiant),
            Math.sin(angle.toRadiant)
        ) * shift;

        callback(Obstacle(type, pos));
    }
}
