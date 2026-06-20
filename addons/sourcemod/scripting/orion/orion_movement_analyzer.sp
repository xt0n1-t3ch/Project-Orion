int g_OrionMoveLastButtons[MAXPLAYERS + 1];
int g_OrionMoveLastJumpTick[MAXPLAYERS + 1];
int g_OrionMovePerfectJumpStreak[MAXPLAYERS + 1];
int g_OrionMoveCommandRepeatStreak[MAXPLAYERS + 1];
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
    g_OrionMoveLastTick[client] = 0;
    g_OrionMoveScore[client] = 0.0;
    g_OrionMoveLastSpeed[client] = 0.0;
}

void Orion_Movement_OnPlayerRunCmd(int client, int buttons, int tickcount)
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

    if (tickcount == g_OrionMoveLastTick[client])
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

    g_OrionMoveLastButtons[client] = buttons;
    g_OrionMoveLastTick[client] = tickcount;
    g_OrionMoveLastSpeed[client] = currentSpeed;
    Orion_Movement_Decay(client);
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

float Orion_Movement_CurrentSpeed(int client)
{
    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    return SquareRoot((velocity[0] * velocity[0]) + (velocity[1] * velocity[1]));
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
        "reason=%s tick=%d perfect_jump_streak=%d repeat_streak=%d speed=%.1f",
        reason,
        tickcount,
        g_OrionMovePerfectJumpStreak[client],
        g_OrionMoveCommandRepeatStreak[client],
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
