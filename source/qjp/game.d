module qjp.game;

import qjp.constants;
import qjp.gametypes;
import qjp.types;
import qjp.ui;

import raylib;

import Math = std.math;

public void runPinball()
{
    validateRaylibBinding();

    auto state = GameState();
    runPinball(state);
}

private:

void runPinball(ref GameState state)
{
    SetConfigFlags(CTs.configFlags);
    InitWindow(CTs.screenResolution.x, CTs.screenResolution.y, CTs.title.ptr);
    scope (exit)
        CloseWindow();

    SetTargetFPS(CTs.fps);
    rlSetLineWidth(CTs.lineWidth);

    Camera2D camera = Camera2D(cast(Vector2) CTs.cameraOffset, cast(Vector2) CTs.center, 0, 0.95);
    state.quantumLevel = 1;

    while (!WindowShouldClose())
    {
        tick(state);
        drawFrame(state, camera);
    }
}

void tick(ref GameState state)
{
    double now = GetTime();
    double delta = now - state.previousTickAt;
    scope (exit)
        state.previousTickAt = now;

    state.quantumWobbleOffset += delta * CTs.wobbleQuantum;

    Inputs inputs = queryInput();

    final switch (inputs.movement) with (Inputs.Direction)
    {
    case none:
        break;
    case left:
        state.positionFlippers += (delta * CTs.flipperMovementVelocity);
        break;
    case right:
        state.positionFlippers -= (delta * CTs.flipperMovementVelocity);
        break;
    }

    if (state.positionFlipperL > 0)
    {
        state.positionFlipperL -= delta * CTs.flippersVelocity;
        if (state.positionFlipperL < 0)
            state.positionFlipperL = 0;
    }
    if (state.positionFlipperR > 0)
    {
        state.positionFlipperR -= delta * CTs.flippersVelocity;
        if (state.positionFlipperR < 0)
            state.positionFlipperR = 0;
    }

    if (inputs.triggerLeft)
        state.positionFlipperL = 100;

    if (inputs.triggerRight)
        state.positionFlipperR = 100;

    handlePinballLauncher(state, delta, inputs);

    moveBalls(state, delta);
}

Inputs queryInput()
{
    Inputs r;

    if (IsKeyDown(KeyboardKey.KEY_A))
        r.movement = Inputs.Direction.left;
    if (IsKeyDown(KeyboardKey.KEY_D))
        r.movement = (r.movement == Inputs.Direction.none)
            ? Inputs.Direction.right : Inputs.Direction.none;

    if (IsKeyDown(KeyboardKey.KEY_J) || IsKeyDown(KeyboardKey.KEY_LEFT))
        r.triggerLeft = true;
    if (IsKeyDown(KeyboardKey.KEY_L) || IsKeyDown(KeyboardKey.KEY_RIGHT))
        r.triggerRight = true;

    if (IsKeyDown(KeyboardKey.KEY_S))
        r.triggerLauncher = true;

    return r;
}

void handlePinballLauncher(ref GameState state, const double delta, const ref Inputs inputs)
{
    // still held?
    if (inputs.triggerLauncher)
    {
        state.positionLauncherSpring += (CTs.launcherSpringVelocity * delta);

        // cap at max length
        if (state.positionLauncherSpring > 100)
            state.positionLauncherSpring = 100;
    }
    else
    {
        // no release?
        if (state.positionLauncherSpring == 0)
            return;

        // too short, false start?
        if (state.positionLauncherSpring < 30)
        {
            state.positionLauncherSpring = 0;
            return;
        }

        launchNewPinball(state, cast(int) state.positionLauncherSpring);
        state.positionLauncherSpring = 0;
    }
}

void launchNewPinball(ref GameState state, const int velocityPct)
in (velocityPct >= 0)
in (velocityPct <= 100)
{
    state.pinball.active = true;
    auto movement = Vector2(Math.cos(state.positionFlippers), Math.sin(state.positionFlippers));
    spawnPinball(state);
}

void moveBalls(ref GameState state, const double delta)
{
    static void moveBall(ref Ball ball, const double delta)
    {
        float distance = ball.velocity * delta;
        ball.position += ball.movement * distance;
    }

    if (state.pinball.active)
        moveBall(state.pinball.ball, delta);

    foreach (ball; state.balls)
        moveBall(ball, delta);
}

Vector2 calcOuterCirclePos(const ref GameState state, float angle)
{
    immutable float radius = state.quantumLevel * CTs.radiusQuantum;
    immutable float angleRad = angle.toRadiant();
    return Vector2(
        Math.cos(angleRad) * radius,
        Math.sin(angleRad) * radius,
    );
}

void spawnPinball(ref GameState state)
{
    immutable float fieldRadius = state.quantumLevel * CTs.radiusQuantum;
    immutable float angleRad = (state.positionFlippers + 90).toRadiant();
    immutable pos = Vector2(
        Math.cos(angleRad),
        Math.sin(angleRad),
    );

    state.pinball.ball = Ball(
        CTs.pinballVelocity * state.positionLauncherSpring / 100,
        pos * fieldRadius,
        pos * -1,
    );
}

float toRadiant(const float degree)
{
    return degree * Math.PI / 180;
}

float toDegree(const float radiant)
{
    return radiant * 180 / Math.PI;
}
