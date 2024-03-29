module qjp.ui;

import qjp.constants;
import qjp.gametypes;

import raylib;

import Math = qjp.math;
import qjp.obstacles;

///
void drawFrame(ref GameState state, ref Camera2D camera)
{
    camera.zoom = 1f / state.quantumLevel * 0.95;

    BeginDrawing();
    {
        ClearBackground(CTs.Colors.background);

        if (state.quantumLevel <= 0)
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
                BeginMode2D(camera);
                drawElectrons(state);
                drawPinball(state);
                EndMode2D();
            }

            {
                BeginMode2D(cameraFlippers);
                drawFlippers(state);
                EndMode2D();
            }

        }

        drawManual();
        drawHandbook();
        drawHUD(state);
        drawMessage(state);
        drawHint(state);
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
}

void drawHandbook()
{
    enum x = CTs.screenResolution.x - 200;
    DrawText("Tips'n'Tricks", x, 30, 16, CTs.Colors.tipsNTricks);
    DrawText("1. Launch a pinball to", x, 60, 16, CTs.Colors.tipsNTricks);
    DrawText("    start the game.", x, 80, 16, CTs.Colors.tipsNTricks);
    DrawText("2. When you bump into", x, 100, 16, CTs.Colors.tipsNTricks);
    DrawText("    obstacles, electrons", x, 120, 16, CTs.Colors.tipsNTricks);
    DrawText("    might spawn.", x, 140, 16, CTs.Colors.tipsNTricks);
    DrawText("3. Collect electrons to", x, 160, 16, CTs.Colors.tipsNTricks);
    DrawText("    make a quantum jump", x, 180, 16, CTs.Colors.tipsNTricks);
    DrawText("    and score points.", x, 200, 16, CTs.Colors.tipsNTricks);
    DrawText("4. Release energy to jump", x, 220, 16, CTs.Colors.tipsNTricks);
    DrawText("    back to a lower", x, 240, 16, CTs.Colors.tipsNTricks);
    DrawText("    quantum.", x, 260, 16, CTs.Colors.tipsNTricks);
    DrawText("    This makes it easier", x, 280, 16, CTs.Colors.tipsNTricks);
    DrawText("    to navigate through", x, 300, 16, CTs.Colors.tipsNTricks);
    DrawText("    the sphere.", x, 320, 16, CTs.Colors.tipsNTricks);
    DrawText("5. Make sure not to", x, 340, 16, CTs.Colors.tipsNTricks);
    DrawText("    release all of your", x, 360, 16, CTs.Colors.tipsNTricks);
    DrawText("    quantum energy.", x, 380, 16, CTs.Colors.tipsNTricks);
    DrawText("    You lose by hitting", x, 400, 16, CTs.Colors.tipsNTricks);
    DrawText("    zero quantum.", x, 420, 16, CTs.Colors.tipsNTricks);
    DrawText("6. The flippers are", x, 440, 16, CTs.Colors.tipsNTricks);
    DrawText("    nowhere near as", x, 460, 16, CTs.Colors.tipsNTricks);
    DrawText("    useful as they might", x, 480, 16, CTs.Colors.tipsNTricks);
    DrawText("    look.", x, 500, 16, CTs.Colors.tipsNTricks);
    DrawText("7. Jumping down to a lower", x, 520, 16, CTs.Colors.tipsNTricks);
    DrawText("    quantum level will", x, 540, 16, CTs.Colors.tipsNTricks);
    DrawText("    destroy the electrons", x, 560, 16, CTs.Colors.tipsNTricks);
    DrawText("    on higher ones.", x, 580, 16, CTs.Colors.tipsNTricks);
    DrawText("8.  Have fun (...and watch", x, 600, 16, CTs.Colors.tipsNTricks);
    DrawText("    out for -red- traps!)", x, 620, 16, CTs.Colors.tipsNTricks);
}

void drawHUD(const ref GameState state)
{
    import core.stdc.stdio : sprintf;

    char[128] buffer;

    {
        sprintf(buffer.ptr, "Score: %ld\0", state.score);
        DrawText(
            buffer.ptr,
            10, 260, 24, CTs.Colors.manual
        );
    }

    {
        sprintf(buffer.ptr, "Quantum Level: %d\0", state.quantumLevel);
        DrawText(
            buffer.ptr,
            10, 300, 16, CTs.Colors.manual
        );
    }

    {
        sprintf(buffer.ptr, "Wild Electrons: %d\0", cast(int) state.electrons.length);
        DrawText(
            buffer.ptr,
            10, 320, 16, CTs.Colors.manual
        );
    }

    if (state.positionLauncherSpring > 0)
    {
        sprintf(buffer.ptr, "Spring: %d%%\0", cast(int) state.positionLauncherSpring);
        DrawText(
            buffer.ptr,
            10, 340, 16, CTs.Colors.flipper
        );
    }

    version (none)
    {
        sprintf(buffer.ptr, "Now: %.0fs\0", GetTime());
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

        Color c = CTs.Colors.electron;
        Color c2 = CTs.Colors.electronAura;
        Color c3 = CTs.Colors.electronAura2;
        c.a = cast(ubyte)(c.a * electron.life / 100);
        c2.a = cast(ubyte)(c2.a * electron.life / 100);
        c3.a = cast(ubyte)(c3.a * electron.life / 100);
        DrawCircleV(electron.ball.position, radius, c);

        // glowing aura
        DrawCircleGradient(
            cast(int) electron.ball.position.x,
            cast(int) electron.ball.position.y,
            radiusAura,
            c2,
            c3,
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

        enum hyp2 = float(Math.phobosPow(CTs.flipperLength, 2));
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
                break;

            case trap:
                DrawCircleV(
                    Vector2(obst.position.x, obst.position.y),
                    radiusWall,
                    CTs.Colors.obstacleTrap
                );
                break;
            }

            return true;
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
    DrawText("Game Over", 104, 204, 64, CTs.Colors.gameOverShadow);
    DrawText("Game Over", 100, 200, 64, CTs.Colors.gameOver);
    DrawText("Press [ESC] to exit", 100, 280, 24, CTs.Colors.manual);
    DrawText("or re-open the app to retry (please).", 100, 310, 24, CTs.Colors.manual);

    import core.stdc.stdio : sprintf;

    char[128] buffer;

    {
        sprintf(buffer.ptr, "Score: %ld\nHighest quantum level: %d\0",
            state.score,
            state.scoreQuantumLevel
        );
        DrawText(
            buffer.ptr,
            100, 70, 24, CTs.Colors.manual
        );
    }
}

void drawMessage(const ref GameState state)
{
    if (state.messageLifetime <= 0)
        return;

    enum x = 100;
    enum y = cast(int)(CTs.screenResolution.y - (CTs.radiusQuantum / 2));
    enum xShadow = x + 3;
    enum yShadow = y + 3;
    DrawText(state.message.ptr, xShadow, yShadow, CTs.messageSize, CTs.Colors.textShadow);
    DrawText(state.message.ptr, x, y, CTs.messageSize, CTs.Colors.message);
}

void drawHint(const ref GameState state)
{
    if (state.pinball.active)
        return;

    static immutable hint = "Hold & release [S] to launch a pinball...";

    enum y = cast(int)((CTs.screenResolution.y - CTs.messageSize) / 2 + 70);
    DrawText(hint.ptr, 50 + 2, y + 2, CTs.messageSize, CTs.Colors.textShadow);
    DrawText(hint.ptr, 50, y, CTs.messageSize, CTs.Colors.hint);
}
