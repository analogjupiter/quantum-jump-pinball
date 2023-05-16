module qjp.game;

import qjp.collision;
import qjp.constants;
import qjp.gametypes;
import qjp.random;
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

        launchNewPinball(state);
        state.positionLauncherSpring = 0;
    }
}

void launchNewPinball(ref GameState state)
{
    spawnPinball(state);
    state.pinball.active = true;
}

void moveBalls(ref GameState state, const double delta)
{
    static void moveBall(bool isMainPinball)(ref Ball ball, const ref GameState state, const double delta)
    {
        float distance = ball.velocity * state.quantumLevel * delta;
        Vector2 nextPos = ball.position + (ball.movement * distance);

        static if (isMainPinball)
        {
        }

        if (checkCollisionOuterBounds(state, nextPos))
        {
            ball.movement *= -1;
            immutable angleRad = Math.atan2(ball.movement.y, ball.movement.x);
            
            immutable float turnRad = rand(CTs.reboundAngleMin, CTs.reboundAngleMax);
            immutable angleRadTarget = angleRad + turnRad;
            
            ball.movement = Vector2(
                Math.cos(angleRadTarget),
                Math.sin(angleRadTarget),
            );

            return;
        }

        ball.position = nextPos;
    }

    if (state.pinball.active)
        moveBall!true(state.pinball.ball, state, delta);

    foreach (ball; state.balls)
        moveBall!false(ball, state, delta);
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
    immutable float angleRad = (state.positionFlippers + 90).toRadiant();
    immutable float fieldRadius = calcFieldRadius(state);

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
