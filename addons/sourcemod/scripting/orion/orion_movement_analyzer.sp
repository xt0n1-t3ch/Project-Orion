int g_OrionMoveLastButtons[MAXPLAYERS + 1];
int g_OrionMoveLastJumpTick[MAXPLAYERS + 1];
int g_OrionMovePerfectJumpStreak[MAXPLAYERS + 1];
int g_OrionMoveCommandRepeatStreak[MAXPLAYERS + 1];
int g_OrionMoveLastCommandNumber[MAXPLAYERS + 1];
int g_OrionMoveCommandRegressionStreak[MAXPLAYERS + 1];
int g_OrionMoveLastTick[MAXPLAYERS + 1];
float g_OrionMoveScore[MAXPLAYERS + 1];
float g_OrionMoveLastSpeed[MAXPLAYERS + 1];

void Orion_Movement_Init()
{
}

void Orion_Movement_ResetClient(int client)
{
    g_OrionMoveLastButtons[client] = 0;
    g_OrionMoveLastJumpTick[client] = 0;
    g_OrionMovePerfectJumpStreak[client] = 0;
    g_OrionMoveCommandRepeatStreak[client] = 0;
    g_OrionMoveLastCommandNumber[client] = 0;
    g_OrionMoveCommandRegressionStreak[client] = 0;
    g_OrionMoveLastTick[client] = 0;
    g_OrionMoveScore[client] = 0.0;
    g_OrionMoveLastSpeed[client] = 0.0;
}

void Orion_Movement_OnPlayerRunCmd(int client, int buttons, float angles[3], int commandNumber, int tickcount, int seed)
{
    if (!Orion_IsAliveHumanPlayer(client))
    {
        return;
    }

    bool jumpPressed = (buttons & IN_JUMP) != 0;
    bool jumpStarted = jumpPressed && ((g_OrionMoveLastButtons[client] & IN_JUMP) == 0);
    bool onGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;

    float currentSpeed = Orion_Movement_CurrentSpeed(client);

    if (jumpStarted)
    {
        Orion_Movement_ScoreJump(client, tickcount, onGround, currentSpeed);
    }

    Orion_Movement_ScoreCommandClock(client, commandNumber, tickcount, seed, currentSpeed);
    Orion_Movement_ScoreSpeedWindow(client, currentSpeed, onGround, angles, tickcount);

    g_OrionMoveLastButtons[client] = buttons;
    g_OrionMoveLastTick[client] = tickcount;
    g_OrionMoveLastCommandNumber[client] = commandNumber;
    g_OrionMoveLastSpeed[client] = currentSpeed;
    Orion_Movement_Decay(client);
}

void Orion_Movement_ScoreCommandClock(int client, int commandNumber, int tickcount, int seed, float currentSpeed)
{
    if (tickcount == g_OrionMoveLastTick[client] || seed == 0)
    {
        g_OrionMoveCommandRepeatStreak[client]++;
        if (g_OrionMoveCommandRepeatStreak[client] > 8)
        {
            g_OrionMoveScore[client] += 10.0;
            Orion_Movement_ReportIfNeeded(client, "repeated_tickcount", tickcount, currentSpeed);
        }
    }
    else
    {
        g_OrionMoveCommandRepeatStreak[client] = 0;
    }

    if (g_OrionMoveLastCommandNumber[client] > 0 && commandNumber <= g_OrionMoveLastCommandNumber[client])
    {
        g_OrionMoveCommandRegressionStreak[client]++;
        g_OrionMoveScore[client] += 6.0;
    }
    else if (g_OrionMoveCommandRegressionStreak[client] > 0)
    {
        g_OrionMoveCommandRegressionStreak[client]--;
    }

    if (Orion_Config_BacktrackPatchEnabled())
    {
        int serverTick = GetGameTickCount();
        int tickDrift = tickcount - serverTick;
        int allowedDriftTicks = Orion_Config_BacktrackToleranceTicks();
        if (tickDrift < -allowedDriftTicks || tickDrift > (allowedDriftTicks + 12))
        {
            g_OrionMoveScore[client] += 8.0;
            Orion_Movement_ReportIfNeeded(client, "command_tick_drift", tickcount, currentSpeed);
        }
    }

    if (g_OrionMoveCommandRegressionStreak[client] >= 3)
    {
        Orion_Movement_ReportIfNeeded(client, "command_number_regression", tickcount, currentSpeed);
    }
}

void Orion_Movement_ScoreJump(int client, int tickcount, bool onGround, float currentSpeed)
{
    int tickDistance = tickcount - g_OrionMoveLastJumpTick[client];

    if (g_OrionMoveLastJumpTick[client] > 0 && tickDistance > 0 && tickDistance <= 3 && onGround)
    {
        g_OrionMovePerfectJumpStreak[client]++;
        g_OrionMoveScore[client] += 7.5;
    }
    else if (tickDistance > 12)
    {
        g_OrionMovePerfectJumpStreak[client] = 0;
    }

    if (g_OrionMovePerfectJumpStreak[client] >= 8)
    {
        g_OrionMoveScore[client] += 15.0;
    }

    if (currentSpeed > 310.0 && currentSpeed >= g_OrionMoveLastSpeed[client])
    {
        g_OrionMoveScore[client] += 5.0;
    }

    g_OrionMoveLastJumpTick[client] = tickcount;
    Orion_Movement_ReportIfNeeded(client, "jump_window", tickcount, currentSpeed);
}

void Orion_Movement_ScoreSpeedWindow(int client, float currentSpeed, bool onGround, float angles[3], int tickcount)
{
    float speedGain = currentSpeed - g_OrionMoveLastSpeed[client];
    bool hasSuspiciousSpeed = currentSpeed > 340.0 && speedGain > 20.0;
    bool hasAirControlBurst = !onGround && currentSpeed > 320.0 && FloatAbs(angles[2]) > 20.0;

    if (!hasSuspiciousSpeed && !hasAirControlBurst)
    {
        return;
    }

    g_OrionMoveScore[client] += hasSuspiciousSpeed && hasAirControlBurst ? 16.0 : 8.0;
    Orion_Movement_ReportIfNeeded(client, hasAirControlBurst ? "air_strafe_burst" : "speed_gain", tickcount, currentSpeed);
}

float Orion_Movement_CurrentSpeed(int client)
{
    float currentVelocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", currentVelocity);
    return SquareRoot((currentVelocity[0] * currentVelocity[0]) + (currentVelocity[1] * currentVelocity[1]));
}

void Orion_Movement_ReportIfNeeded(int client, const char[] reason, int tickcount, float currentSpeed)
{
    float alertThreshold = Orion_Config_MovementThreshold();
    if (g_OrionMoveScore[client] < alertThreshold)
    {
        return;
    }

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=%s tick=%d perfect_jump_streak=%d repeat_streak=%d command_regression_streak=%d speed=%.1f",
        reason,
        tickcount,
        g_OrionMovePerfectJumpStreak[client],
        g_OrionMoveCommandRepeatStreak[client],
        g_OrionMoveCommandRegressionStreak[client],
        currentSpeed);

    char action[16];
    strcopy(action, sizeof(action), g_OrionMoveScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) ? "ban" : "observe");
    Orion_Evidence_Submit(client, "movement", g_OrionMoveScore[client], action, details);
}

void Orion_Movement_Decay(int client)
{
    if (g_OrionMoveScore[client] > 0.0)
    {
        g_OrionMoveScore[client] -= 0.015;
        if (g_OrionMoveScore[client] < 0.0)
        {
            g_OrionMoveScore[client] = 0.0;
        }
    }
}
