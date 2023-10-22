module qjp.obstacles;

import qjp.types;
import qjp.constants;
import Math = qjp.math;

struct Obstacle
{
    enum Type
    {
        defect,
        wall,
        trap,
    }

    Type type;
    Vector2 position;
}

void getObstacles(const int quantumLevel, scope const bool delegate(Obstacle) callback)
{
    immutable nObstacles =
        cast(int)(
            (quantumLevel % 3)
                + (quantumLevel % 14)
                - (quantumLevel % 7)
                + ((quantumLevel % 17) % 11)
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
        if ((quantumLevel == 4) && (n == 2))
            type = Obstacle.Type.trap;
        else if ((quantumLevel % 7 == 6) && (n) % 11 == 9)
        {
            type = Obstacle.Type.trap;
        }
        else
            type = Obstacle.Type.wall;

        angle += 300 * n / nObst3 + (quantumLevel * 2);

        immutable float shift = minShift + n * indivShift;

        immutable pos = Vector2(
            Math.cos(angle.toRadiant),
            Math.sin(angle.toRadiant)
        ) * shift;

        if (!callback(Obstacle(type, pos)))
            break;
    }
}
