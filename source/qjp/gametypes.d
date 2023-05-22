module qjp.gametypes;

import qjp.constants;
import qjp.types;
import raylib;

struct GameState
{
    double previousTickAt = 0;

    int quantumLevel = 2;
    int quantumLevelSchedule = 2;
    float quantumWobbleOffset = 0;

    Pinball pinball = Pinball(false, Ball(CTs.pinballVelocity));
    List!Ball balls;

    float positionFlippers = 0;
    float positionFlipperL = 0;
    float positionFlipperR = 0;

    /// %
    float positionLauncherSpring = 0;

    float positionWalls = 0;
}

struct Inputs
{
    enum Direction
    {
        none = 0,
        left,
        right,
    }

    Direction movement = Direction.none;
    bool triggerLeft = false;
    bool triggerRight = false;
    bool triggerLauncher = false;
}

struct Ball
{
    float velocity;
    Vector2 position;
    Vector2 movement = Vector2(0, 0);
}

struct Pinball
{
    bool active = false;
    Ball ball;
}

float calcFieldRadius(const ref GameState state)
{
    return state.quantumLevel * CTs.radiusQuantum;
}
