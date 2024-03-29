module qjp.gametypes;

import qjp.constants;
import qjp.types;
import raylib;

struct GameState
{
    double previousTickAt = 0;

    long score = 0;
    int scoreQuantumLevel = 0;
    int quantumLevel = 2;
    int quantumLevelSchedule = 2;
    float quantumWobbleOffset = 0;

    Pinball pinball = Pinball(false, Ball(CTs.pinballVelocity));
    List!Electron electrons;

    float positionFlippers = 0;
    float positionFlipperL = 0;
    float positionFlipperR = 0;

    /// %
    float positionLauncherSpring = 0;

    float positionWalls = 0;

    float messageLifetime = 0;
    char[128] message;
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
    bool triggerRelease = false;
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

struct Electron
{
    Ball ball;
    float cooldownLeft = CTs.electronCooldown;
    float life = 100;

    bool active() inout
    {
        return cooldownLeft < 0;
    }
}

float calcFieldRadius(const ref GameState state)
{
    return state.quantumLevel * CTs.radiusQuantum;
}

void setMessage(ref GameState state, string message)
{
    state.message[0 .. message.length] = message;
    state.message[message.length] = '\0';
    state.messageLifetime = CTs.messageLifetime;
}
