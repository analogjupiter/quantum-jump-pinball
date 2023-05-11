module qjp.game;

import qjp.types;
import qjp.gametypes;
import raylib;
import Math = std.math;

public void runPinball()
{
    validateRaylibBinding();

    auto state = GameState();
    runPinball(state);
}

private:

struct GameConstants
{
    enum
    {
        configFlags = ConfigFlags.FLAG_MSAA_4X_HINT,

        screenResolution = Vector2i(1440, 1080),
        cameraOffset = screenResolution / 2,
        center = Vector2i(0, 0),

        title = "Quantum Jump Pinball",
        fps = 60,
    }

    enum
    {
        flipperMovementVelocity = 135,
        flippersVelocity = 800,
        wobbleQuantum = 60f,
    }

    enum
    {
        lineWidth = screenResolution.y / 256,

        radiusCenterCircle = screenResolution.y / 32,

        diameterQuantum = screenResolution.y,
        radiusQuantum = diameterQuantum / 2f,

        diameterPinball = screenResolution.y / 16,
        radiusPinball = diameterPinball / 2,
        radiusPinballAura = radiusPinball * 1.5,

        flipperLength = screenResolution.y / 9,
        flipperMax = screenResolution.y / 12, // must be < flipperLength

        towerHeight = screenResolution.y / 8,
        towerWidth = screenResolution.y / 16,
        towerOffset = screenResolution.y / 8,
    }

    enum ubyte opaque = 0xFF;

    // Colors
    enum Colors : Color
    {
        // dfmt off
        background      = Color(0xFF, 0xFF, 0xFF, opaque),
        manual          = Color(0x00, 0x00, 0x00, opaque),
        layer           = Color(0x99, 0x99, 0x99, opaque),
        layerCenter     = Color(0x00, 0x00, 0x00, 0x22),
        scanner         = Color(0x99, 0xBB, 0x99, opaque),

        pinball         = Color(0x00, 0x00, 0x77, opaque),
        pinballAura     = Color(0x00, 0x00, 0x77, opaque),
        pinballAura2    = Color(0x00, 0x99, 0xFF, 0x00),

        flipper         = Color(0xCC, 0x33, 0x44, opaque),
        tower           = Color(0x44, 0x55, 0x66, opaque),
        outline         = Color(0x00, 0x00, 0x11, opaque),
        // dfmt on
    }
}

enum CTs = GameConstants();

struct GameState
{
    double previousTickAt = 0;
    int quantumLevel = 2;
    Pinball pinball = Pinball(false);
    float quantumWobbleOffset = 0;
    float positionFlippers = 0;
    float positionFlipperL = 0;
    float positionFlipperR = 0;
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
}

void runPinball(ref GameState state)
{
    SetConfigFlags(CTs.configFlags);
    InitWindow(CTs.screenResolution.x, CTs.screenResolution.y, CTs.title.ptr);
    scope (exit)
        CloseWindow();

    SetTargetFPS(CTs.fps);
    rlSetLineWidth(CTs.lineWidth);

    Camera2D camera = Camera2D(cast(Vector2) CTs.cameraOffset, cast(Vector2) CTs.center, 0, 0.95);
    state.pinball.position = Vector2(200, 200);
    state.pinball.active = true;
    state.quantumLevel = 3;

    while (!WindowShouldClose())
    {
        tick(state);

        camera.zoom = 1f / state.quantumLevel * 0.95;

        BeginDrawing();
        {
            ClearBackground(CTs.Colors.background);

            {
                {
                    Camera2D cameraSphere = camera;
                    cameraSphere.rotation = state.quantumWobbleOffset;

                    BeginMode2D(cameraSphere);
                    drawSphere(state);
                    EndMode2D();
                }

                {
                    Camera2D cameraFlippers = camera;
                    cameraFlippers.rotation = state.positionFlippers;
                    cameraFlippers.zoom = 0.95;

                    BeginMode2D(cameraFlippers);
                    drawFlippers(state);
                    EndMode2D();
                }

                BeginMode2D(camera);
                drawPinball(state);
                EndMode2D();

            }

            drawManual();
        }
        EndDrawing();
    }
}

void drawManual()
{
    DrawFPS(10, 10);
    DrawText("ESC ... Exit", 10, 40, 16, CTs.Colors.manual);
    DrawText("A ... Move clockwise", 10, 60, 16, CTs.Colors.manual);
    DrawText("D ... Move counter-clockwise", 10, 80, 16, CTs.Colors.manual);
    DrawText("J ... Left flipper", 10, 100, 16, CTs.Colors.manual);
    DrawText("L ... Right flipper", 10, 120, 16, CTs.Colors.manual);
    DrawText("<- ... Left flipper", 10, 140, 16, CTs.Colors.manual);
    DrawText("-> ... Right flipper", 10, 160, 16, CTs.Colors.manual);
}

void drawSphere(ref GameState state)
{
    foreach (n; 0 .. state.quantumLevel)
    {
        immutable n1 = n + 1;
        immutable radius = CTs.radiusQuantum * n1;
        DrawCircleLines(CTs.center.x, CTs.center.y, radius, CTs.Colors.layer);
    }

    // center circle
    DrawCircle(CTs.center.x, CTs.center.y, CTs.radiusCenterCircle, CTs.Colors.layerCenter);

    // scanner line
    DrawLine(
        CTs.center.x, CTs.center.y,
        CTs.center.x, state.quantumLevel * cast(int) CTs.radiusQuantum,
        CTs.Colors.scanner,
    );
}

void drawPinball(ref GameState state)
{
    if (!state.pinball.active)
        return;

    immutable radius = CTs.radiusPinball * state.quantumLevel;
    immutable radiusAura = CTs.radiusPinballAura * state.quantumLevel;

    // pinball
    DrawCircleV(state.pinball.position, radius, CTs.Colors.pinball);

    // glowing aura
    DrawCircleGradient(
        cast(int) state.pinball.position.x,
        cast(int) state.pinball.position.y,
        radiusAura,
        CTs.Colors.pinballAura,
        CTs.Colors.pinballAura2
    );
}

void drawFlippers(ref GameState state)
{
    static void drawTower(bool left)()
    {
        static if (left)
        {
            enum wallRightX = 0 - CTs.towerOffset;
            enum wallLeftX = wallRightX - CTs.towerWidth;
        }
        else
        {
            enum wallLeftX = CTs.towerOffset;
            enum wallRightX = wallLeftX + CTs.towerWidth;
        }

        enum floor = cast(int) CTs.radiusQuantum;
        enum ceiling = floor - CTs.towerHeight;

        enum centerX = wallLeftX + (CTs.towerWidth / 2);
        enum rooftopY = ceiling - cast(int) Math.sqrt(float(Math.pow(CTs.towerWidth, 2) - Math.pow((CTs.towerWidth / 2), 2)));

        enum crest = Vector2(centerX, rooftopY);
        enum eavesL = Vector2(wallLeftX, ceiling);
        enum eavesR = Vector2(wallRightX, ceiling);

        DrawRectangle(wallLeftX, ceiling, CTs.towerWidth, CTs.towerHeight, CTs.Colors.tower);
        DrawLine(wallLeftX, floor, wallLeftX, ceiling, CTs.Colors.outline);
        DrawLine(wallRightX, floor, wallRightX, ceiling, CTs.Colors.outline);

        static if (left)
            DrawLine(wallRightX + 20, floor, 0 - (CTs.screenResolution.x / 2), floor, CTs
                    .Colors.outline);
        else
            DrawLine(wallLeftX - 20, floor, (CTs.screenResolution.x / 2), floor, CTs.Colors.outline);

        DrawTriangle(crest, eavesL, eavesR, CTs.Colors.tower);
        DrawLine(wallLeftX, ceiling, centerX, rooftopY, CTs.Colors.outline);
        DrawLine(wallRightX, ceiling, centerX, rooftopY, CTs.Colors.outline);
        DrawLine(wallLeftX, ceiling, wallRightX, ceiling, CTs.Colors.outline);
    }

    static void drawFlipper(bool left)(const ref GameState state)
    {
        static if (left)
        {
            enum wallX = 0 - CTs.towerOffset;
            immutable tipPc = state.positionFlipperL;
        }
        else
        {
            enum wallX = CTs.towerOffset;
            immutable tipPc = state.positionFlipperR;
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
            DrawTriangle(tipPos, mount2, mount1, CTs.Colors.flipper);
        else
            DrawTriangle(tipPos, mount1, mount2, CTs.Colors.flipper);
    }

    drawFlipper!true(state);
    drawFlipper!false(state);
    drawTower!true();
    drawTower!false();

    DrawTriangle(
        Vector2(200, -500),
        Vector2(200, -200),
        Vector2(200, -100),
        Colors.GOLD,
    );
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

    return r;
}
