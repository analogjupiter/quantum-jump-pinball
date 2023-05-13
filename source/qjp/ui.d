module qjp.ui;

import qjp.constants;
import qjp.gametypes;

import raylib;

import std.conv : to;
import Math = std.math;

///
void drawFrame(const ref GameState state, ref Camera2D camera)
{
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
        drawHUD(state);
    }
    EndDrawing();
}

private:

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
    DrawText("S ... Launch pinball", 10, 180, 16, CTs.Colors.manual);
}

void drawHUD(const ref GameState state)
{
    DrawText(
        ("Spring: " ~ (cast(int) state.positionLauncherSpring)
            .to!string ~ "%\0").ptr,
        10, 400, 16, CTs.Colors.flipper
    );
    DrawText(
        ("Now: " ~ (cast(int) GetTime()).to!string ~ "s\0").ptr,
        10, 420, 16, CTs.Colors.flipper
    );
}

void drawSphere(const ref GameState state)
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

void drawPinball(const ref GameState state)
{
    if (!state.pinball.active)
        return;

    immutable radius = CTs.radiusPinball * state.quantumLevel;
    immutable radiusAura = CTs.radiusPinballAura * state.quantumLevel;

    // pinball
    DrawCircleV(state.pinball.ball.position, radius, CTs.Colors.pinball);

    // glowing aura
    DrawCircleGradient(
        cast(int) state.pinball.ball.position.x,
        cast(int) state.pinball.ball.position.y,
        radiusAura,
        CTs.Colors.pinballAura,
        CTs.Colors.pinballAura2
    );
}

void drawFlippers(const ref GameState state)
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