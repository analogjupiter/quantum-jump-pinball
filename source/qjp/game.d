module qjp.game;

import qjp.collision;
import qjp.constants;
import qjp.gametypes;
import qjp.random;
import qjp.types;
import qjp.ui;

import raylib;

import Math = qjp.math;

public void runPinball()
{
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

    while (!WindowShouldClose())
    {
        tick(state);
        drawFrame(state, camera);
    }
}

void tick(ref GameState state)
{
    if (state.quantumLevel <= 0)
        return;

    double now = GetTime();
    double delta = now - state.previousTickAt;
    scope (exit)
        state.previousTickAt = now;

    state.quantumWobbleOffset = clampAngle(state.quantumWobbleOffset + delta * CTs.wobbleQuantum);
    state.positionWalls = clampAngle(state.positionWalls - delta * CTs.wallRotationVelocity);
    foreach (ref electron; state.electrons)
        if (!electron.active)
            electron.cooldownLeft -= delta;

    Inputs inputs = queryInput();

    final switch (inputs.movement) with (Inputs.Direction)
    {
    case none:
        break;
    case left:
        state.positionFlippers += (delta * CTs.flipperMovementVelocity);
        state.positionFlippers = clampAngle(state.positionFlippers);
        break;
    case right:
        state.positionFlippers -= (delta * CTs.flipperMovementVelocity);
        state.positionFlippers = clampAngle(state.positionFlippers);
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
    handleElectronLifetimes(state, delta);

    if (inputs.triggerRelease)
    {
        --state.quantumLevelSchedule;
        state.setMessage("Manual Quantum Jump");
    }

    state.quantumLevel = state.quantumLevelSchedule;

    // pull back in oob pinball
    if (checkCollisionOuterBounds(state, state.pinball.ball.position))
        state.pinball.ball.position = state.pinball.ball.position.pullBackInGame(state);

    // remove oob electrons
    foreach (idx, ref electron; state.electrons)
        if (checkCollisionOuterBounds(state, electron.ball.position))
            state.electrons.removeAt(idx);

    if (state.quantumLevel > state.scoreQuantumLevel)
        state.scoreQuantumLevel = state.quantumLevel;

    handleMessageLifetime(state, delta);
}

Inputs queryInput()
{
    Inputs r;

    if (IsKeyDown(KeyboardKey.KEY_A))
        r.movement = Inputs.Direction.left;
    if (IsKeyDown(KeyboardKey.KEY_D))
        r.movement = (r.movement == Inputs.Direction.none)
            ? Inputs.Direction.right : Inputs.Direction.none;

    if (IsKeyDown(KeyboardKey.KEY_J))
        r.triggerLeft = true;
    if (IsKeyDown(KeyboardKey.KEY_L))
        r.triggerRight = true;

    if (IsKeyDown(KeyboardKey.KEY_S))
        r.triggerLauncher = true;

    if (IsKeyPressed(KeyboardKey.KEY_Q))
        r.triggerRelease = true;

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
    static void moveBall(bool isMainPinball)(ref Ball ball, ref GameState state, const double delta)
    {
        import qjp.obstacles;

        float distance = ball.velocity * state.quantumLevel * delta;
        Vector2 nextPos = ball.position + (ball.movement * distance);

        static void reboundBall(bool driftAngle = false)(ref Ball ball)
        {
            ball.movement *= -1;

            static if (driftAngle)
            {
                immutable angleRad = Math.atan2(ball.movement.y, ball.movement.x);

                immutable float turnRad = rand(CTs.reboundAngleMin, CTs.reboundAngleMax).toRadiant();
                immutable angleRadTarget = angleRad + turnRad;

                ball.movement = Vector2(
                    Math.cos(angleRadTarget),
                    Math.sin(angleRadTarget),
                );
            }
        }

        if (checkCollisionOuterBounds(state, nextPos))
            return reboundBall!true(ball);

        static if (isMainPinball)
            if (checkCollisionTowers(state, nextPos))
                return reboundBall!false(ball);

        if (checkCollisionFlippers(state, nextPos))
            return reboundBall!false(ball);

        Obstacle.Type obstacleType;
        if (checkCollisionObstacles!isMainPinball(state, nextPos, obstacleType))
        {
            static if (isMainPinball)
            {
                maybeSpawnElectron(state);

                final switch (obstacleType) with (Obstacle.Type)
                {
                case defect:
                    assert(false, "defect obstacle");
                case wall:
                    break;
                case trap:
                    state.score -= 25;
                    state.quantumLevelSchedule -= (state.quantumLevel < 10)
                        ? 3 : rand(4, state.quantumLevel * 5 / 4);
                    state.setMessage("Trap (-25)");
                    break;
                }
            }
            return reboundBall!true(ball);
        }

        static if (isMainPinball)
        {
            checkCollisionElectrons(state, nextPos, delegate(size_t idx, const ref Electron electron, ref GameState state) {
                state.electrons.removeAt(idx);
                ++state.quantumLevelSchedule;
                state.score += 5;
                state.setMessage("Quantum Jump (+5)");
            });
        }

        ball.position = nextPos;
    }

    if (state.pinball.active)
        moveBall!true(state.pinball.ball, state, delta);

    foreach (ref electron; state.electrons)
        moveBall!false(electron.ball, state, delta);
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

void maybeSpawnElectron(ref GameState state)
{
    if (state.electrons.length >= CTs.maxElectrons)
        return;

    immutable int r = rand(0, 100);
    if (r < CTs.probabilityElectron)
        spawnElectron(state);
}

void spawnElectron(ref GameState state)
{
    state.electrons ~= Electron(Ball(
            CTs.electronVelocity,
            state.pinball.ball.position,
            state.pinball.ball.movement * -1,
    ));
}

Vector2 pullBackInGame(const Vector2 pos, const ref GameState state)
{
    immutable float max = CTs.radiusQuantum * state.quantumLevel - 1;
    immutable float angle = Math.atan2(pos.y, pos.x);

    return Vector2(
        Math.cos(angle) * max,
        Math.sin(angle) * max,
    );
}

void handleElectronLifetimes(ref GameState state, const float delta)
{
    enum f = 100 / CTs.electronLifetime;
    foreach (idx, ref Electron electron; state.electrons)
    {
        electron.life -= delta * f;
        if (electron.life < 0)
            state.electrons.removeAt(idx);
    }
}

void handleMessageLifetime(ref GameState state, const float delta)
{
    if (state.messageLifetime <= 0)
        return;

    state.messageLifetime -= delta;
}
