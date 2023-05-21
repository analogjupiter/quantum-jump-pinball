module qjp.constants;

import qjp.types;
import raylib;
import Math = std.math : PI;

enum TAU = 2 * Math.PI;
enum float SQRT_3 = Math.sqrt(3f);
enum float SQRT_3_2 = SQRT_3 / 2;

struct GameConstants
{
    enum
    {
        configFlags = ConfigFlags.FLAG_MSAA_4X_HINT,

        //screenResolution = Vector2i(1440, 1080),
        screenResolution = Vector2i(1024, 720),
        cameraOffset = screenResolution / 2,
        center = Vector2i(0, 0),

        title = "Quantum Jump Pinball",
        fps = 60,
    }

    enum
    {
        flipperMovementVelocity = 135,
        flippersVelocity = 800,
        wobbleQuantum = 60.0f,
        pinballVelocity = screenResolution.y / 0.75f,
        launcherSpringVelocity = 50.0f,
        reboundAngleMin = 40.toRadiant(),
        reboundAngleMax = 50.toRadiant(),
        wallRotationVelocity = 45.0f,
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
        towerRoofHeight = towerWidth * SQRT_3_2,
        towerHeightTotal = CTs.towerHeight + towerRoofHeight,

        wallRadius = screenResolution.y / 20,
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
        tower           = Color(0x99, 0xAA, 0xCC, opaque),
        outline         = Color(0x00, 0x00, 0x11, opaque),

        obstacleBorder  = Color(0x11, 0x11, 0x11, opaque),
        obstacleWall    = Color(0xAA, 0x77, 0x77, opaque),
        // dfmt on
    }
}

enum CTs = GameConstants();
