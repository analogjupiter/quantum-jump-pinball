module qjp.ui;

import qjp.constants;
import qjp.gametypes;

import raylib;

import std.conv : to;
import Math = std.math;
import qjp.obstacles;

///
void drawFrame(ref GameState state, ref Camera2D camera)
{
    camera.zoom = 1f / state.quantumLevel * 0.95;

    BeginDrawing();
    {
        ClearBackground(CTs.Colors.background);

        if (state.quantumLevel == 0)
        {
            drawGameOver(state);
            EndDrawing();
            return;
        }

        {
            Camera2D cameraSphere = camera;
            cameraSphere.rotation = state.quantumWobbleOffset;

            Camera2D cameraFlippers = camera;
            cameraFlippers.rotation = state.positionFlippers;
            cameraFlippers.zoom = 0.95;

            {
                BeginMode2D(cameraSphere);
                drawSphere(state);
                EndMode2D();
            }

            {
                BeginMode2D(camera);
                drawObstacles(state);
                EndMode2D();
            }

            {
                BeginMode2D(cameraFlippers);
                drawFlippers(state);
                EndMode2D();
            }

            {
                BeginMode2D(camera);
                drawElectrons(state);
                drawPinball(state);
                EndMode2D();
            }
        }

        drawManual();
        drawHandbook();
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
    DrawText("S ... Launch pinball", 10, 100, 16, CTs.Colors.manual);
    DrawText("Q ... Release quantum energy", 10, 120, 16, CTs.Colors.manual);
    DrawText("J ... Left flipper", 10, 160, 16, CTs.Colors.manual);
    DrawText("L ... Right flipper", 10, 180, 16, CTs.Colors.manual);
    DrawText("<- ... Left flipper", 10, 200, 16, CTs.Colors.manual);
    DrawText("-> ... Right flipper", 10, 220, 16, CTs.Colors.manual);
}

void drawHandbook()
{
    enum x = CTs.screenResolution.x - 200;
    DrawText("Tips'n'tricks", x, 30, 16, CTs.Colors.tipsNTricks);
    DrawText("1. Launch a pinball to", x, 60, 16, CTs.Colors.tipsNTricks);
    DrawText("    start the game.", x, 80, 16, CTs.Colors.tipsNTricks);
    DrawText("2. Electrons might spawn", x, 100, 16, CTs.Colors.tipsNTricks);
    DrawText("    when you bump into", x, 120, 16, CTs.Colors.tipsNTricks);
    DrawText("    obstacles.", x, 140, 16, CTs.Colors.tipsNTricks);
    DrawText("3. Collect electrons to", x, 160, 16, CTs.Colors.tipsNTricks);
    DrawText("    make a quantum jump", x, 180, 16, CTs.Colors.tipsNTricks);
    DrawText("    and score points.", x, 200, 16, CTs.Colors.tipsNTricks);
    DrawText("4. Release energy to jump", x, 220, 16, CTs.Colors.tipsNTricks);
    DrawText("    back to a lower", x, 240, 16, CTs.Colors.tipsNTricks);
    DrawText("    quantum.", x, 260, 16, CTs.Colors.tipsNTricks);
    DrawText("    This makes it easier.", x, 280, 16, CTs.Colors.tipsNTricks);
    DrawText("    to navigate through.", x, 300, 16, CTs.Colors.tipsNTricks);
    DrawText("    the sphere.", x, 320, 16, CTs.Colors.tipsNTricks);
    DrawText("5. Make sure not to", x, 340, 16, CTs.Colors.tipsNTricks);
    DrawText("    release all of your", x, 360, 16, CTs.Colors.tipsNTricks);
    DrawText("    quantum energy.", x, 380, 16, CTs.Colors.tipsNTricks);
    DrawText("    You lose by hitting", x, 400, 16, CTs.Colors.tipsNTricks);
    DrawText("    zero quantum.", x, 420, 16, CTs.Colors.tipsNTricks);
}

void drawHUD(const ref GameState state)
{
    import std.format : sformat;

    char[128] buffer;

    {
        sformat(buffer, "Score: %d\0", state.score);
        DrawText(
            buffer.ptr,
            10, 260, 24, CTs.Colors.manual
        );
    }

    {
        sformat(buffer, "Quantum Level: %d\0", state.quantumLevel);
        DrawText(
            buffer.ptr,
            10, 300, 16, CTs.Colors.manual
        );
    }

    {
        sformat(buffer, "Wild Electrons: %d\0", cast(int) state.electrons.length);
        DrawText(
            buffer.ptr,
            10, 320, 16, CTs.Colors.manual
        );
    }

    if (state.positionLauncherSpring > 0)
    {
        sformat(buffer, "Spring: %d%%\0", cast(int) state.positionLauncherSpring);
        DrawText(
            buffer.ptr,
            10, 340, 16, CTs.Colors.flipper
        );
    }

    version (none)
    {
        sformat(buffer, "Now: %.0fs\0", GetTime());
        DrawText(
            buffer.ptr,
            10, 240, 16, CTs.Colors.flipper
        );
    }
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

void drawElectrons(ref GameState state)
{
    foreach (ref Electron electron; state.electrons)
    {
        immutable radius = CTs.radiusElectron * state.quantumLevel;
        immutable radiusAura = CTs.radiusElectronAura * state.quantumLevel;

        DrawCircleV(electron.ball.position, radius, CTs.Colors.electron);

        // glowing aura
        DrawCircleGradient(
            cast(int) electron.ball.position.x,
            cast(int) electron.ball.position.y,
            radiusAura,
            CTs.Colors.electronAura,
            CTs.Colors.electronAura2
        );
    }
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
        enum rooftopY = ceiling - cast(int) CTs.towerRoofHeight;

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
}

void drawObstacles(const ref GameState state)
{
    static void drawQuantumObstacles(const int quantumLevel, const float angleWalls, const float zoom)
    {
        immutable float radiusWall = CTs.wallRadius * zoom;

        getObstacles(quantumLevel, delegate(Obstacle obst) {
            final switch (obst.type) with (Obstacle.Type)
            {
            case defect:
                assert(false, "Defect obstacle");
            case wall:
                DrawCircleSector(
                    Vector2(obst.position.x, obst.position.y),
                    radiusWall,
                    angleWalls - 15,
                    angleWalls + 300,
                    16,
                    CTs.Colors.obstacleWall
                );
                DrawCircleLines(
                    cast(int) obst.position.x, cast(int) obst.position.y,
                    radiusWall,
                    CTs.Colors.obstacleBorder
                );
            }
        });
    }

    foreach (levelMinus1; 0 .. state.quantumLevel)
    {
        immutable qLvl = levelMinus1 + 1;
        drawQuantumObstacles(
            qLvl,
            state.positionWalls,
            (float(qLvl) / float(state.quantumLevel)),
        );
    }
}

void drawGameOver(const ref GameState state)
{
    DrawText("Game Over", 100, 140, 64, CTs.Colors.gameOver);
    DrawText("Press [ESC] to exit", 100, 210, 24, CTs.Colors.manual);
    DrawText("or re-open the app to retry (please).", 100, 240, 24, CTs.Colors.manual);

    import std.format : sformat;

    char[128] buffer;

    {
        sformat(buffer, "Score: %d\0", state.score);
        DrawText(
            buffer.ptr,
            100, 70, 24, CTs.Colors.manual
        );
    }
}
