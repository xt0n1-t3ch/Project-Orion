float g_OrionAimLastAngles[MAXPLAYERS + 1][3];
float g_OrionAimLastDelta[MAXPLAYERS + 1];
int g_OrionAimLastButtons[MAXPLAYERS + 1];
int g_OrionAimLastTarget[MAXPLAYERS + 1];
int g_OrionAimTargetTicks[MAXPLAYERS + 1];
int g_OrionAimLastTick[MAXPLAYERS + 1];
int g_OrionAimAttackStartTick[MAXPLAYERS + 1];
int g_OrionAimOneTickShotStreak[MAXPLAYERS + 1];
float g_OrionAimScore[MAXPLAYERS + 1];
bool g_OrionAimHasAngles[MAXPLAYERS + 1];

void Orion_Aim_Init()
{
    HookEvent("weapon_fire", Orion_Aim_OnWeaponFire, EventHookMode_Post);
    HookEvent("player_hurt", Orion_Aim_OnPlayerHurt, EventHookMode_Post);
    HookEvent("player_death", Orion_Aim_OnPlayerDeath, EventHookMode_Post);
}

void Orion_Aim_ResetClient(int client)
{
    g_OrionAimHasAngles[client] = false;
    g_OrionAimLastButtons[client] = 0;
    g_OrionAimLastTarget[client] = 0;
    g_OrionAimTargetTicks[client] = 0;
    g_OrionAimLastTick[client] = 0;
    g_OrionAimAttackStartTick[client] = 0;
    g_OrionAimOneTickShotStreak[client] = 0;
    g_OrionAimScore[client] = 0.0;
    g_OrionAimLastDelta[client] = 0.0;
    g_OrionAimLastAngles[client][0] = 0.0;
    g_OrionAimLastAngles[client][1] = 0.0;
    g_OrionAimLastAngles[client][2] = 0.0;
}

void Orion_Aim_OnPlayerRunCmd(int client, int buttons, float angles[3], int tickcount, int mouse[2])
{
    if (!Orion_IsAliveHumanPlayer(client))
    {
        return;
    }

    float pitchDelta = 0.0;
    float yawDelta = 0.0;
    float totalDelta = 0.0;

    if (g_OrionAimHasAngles[client])
    {
        pitchDelta = Orion_NormalizeAngleDelta(angles[0] - g_OrionAimLastAngles[client][0]);
        yawDelta = Orion_NormalizeAngleDelta(angles[1] - g_OrionAimLastAngles[client][1]);
        totalDelta = pitchDelta + yawDelta;
    }

    Orion_Aim_ScoreInvalidAngles(client, angles, tickcount);

    int target = GetClientAimTarget(client, true);
    if (target == g_OrionAimLastTarget[client] && target > 0)
    {
        g_OrionAimTargetTicks[client]++;
    }
    else
    {
        g_OrionAimTargetTicks[client] = 0;
    }

    bool attackPressed = (buttons & IN_ATTACK) != 0;
    bool attackStarted = attackPressed && ((g_OrionAimLastButtons[client] & IN_ATTACK) == 0);
    bool attackStopped = !attackPressed && ((g_OrionAimLastButtons[client] & IN_ATTACK) != 0);
    int mouseMagnitude = Orion_AbsInt(mouse[0]) + Orion_AbsInt(mouse[1]);

    if (attackStarted)
    {
        g_OrionAimAttackStartTick[client] = tickcount;
        Orion_Aim_ScoreAttackWindow(client, target, totalDelta, mouseMagnitude, tickcount);
    }
    else if (attackStopped)
    {
        Orion_Aim_ScoreAttackRelease(client, tickcount);
    }

    g_OrionAimLastAngles[client][0] = angles[0];
    g_OrionAimLastAngles[client][1] = angles[1];
    g_OrionAimLastAngles[client][2] = angles[2];
    g_OrionAimLastDelta[client] = totalDelta;
    g_OrionAimLastButtons[client] = buttons;
    g_OrionAimLastTarget[client] = target;
    g_OrionAimLastTick[client] = tickcount;
    g_OrionAimHasAngles[client] = true;

    Orion_Aim_Decay(client);
}

void Orion_Aim_ScoreInvalidAngles(int client, float angles[3], int tickcount)
{
    if (!Orion_Config_AngleGuardEnabled())
    {
        return;
    }

    bool hasImpossiblePitch = angles[0] > 89.01 || angles[0] < -89.01;
    bool hasImpossibleRoll = angles[2] > 50.01 || angles[2] < -50.01;

    if (!hasImpossiblePitch && !hasImpossibleRoll)
    {
        return;
    }

    g_OrionAimScore[client] += hasImpossiblePitch && hasImpossibleRoll ? 35.0 : 22.0;

    char details[256];
    Format(details, sizeof(details), "reason=invalid_angles pitch=%.2f yaw=%.2f roll=%.2f tick=%d", angles[0], angles[1], angles[2], tickcount);
    Orion_Evidence_Submit(client, "angle_guard", g_OrionAimScore[client], "observe", details);
}

void Orion_Aim_ScoreAttackWindow(int client, int target, float angleDelta, int mouseMagnitude, int tickcount)
{
    if (target <= 0 || target > MaxClients || !IsClientInGame(target))
    {
        return;
    }

    float scoreDelta = 0.0;

    if (angleDelta >= 45.0)
    {
        scoreDelta += 30.0;
    }
    else if (angleDelta >= 25.0)
    {
        scoreDelta += 18.0;
    }

    if (mouseMagnitude <= 1 && angleDelta >= 20.0)
    {
        scoreDelta += 25.0;
    }

    if (mouseMagnitude == 0 && angleDelta >= 8.0)
    {
        scoreDelta += 18.0;
    }

    if (g_OrionAimTargetTicks[client] <= 1)
    {
        scoreDelta += 15.0;
    }

    if (GetClientTeam(target) == ORION_TEAM_INFECTED)
    {
        scoreDelta += 5.0;
    }

    if (scoreDelta > 0.0)
    {
        g_OrionAimScore[client] += scoreDelta;
        Orion_Aim_ReportIfNeeded(client, "attack_window", target, angleDelta, mouseMagnitude, tickcount);
    }
}

void Orion_Aim_ScoreAttackRelease(int client, int tickcount)
{
    if (g_OrionAimAttackStartTick[client] <= 0)
    {
        return;
    }

    int attackTicks = tickcount - g_OrionAimAttackStartTick[client];
    if (attackTicks >= 0 && attackTicks <= 1)
    {
        g_OrionAimOneTickShotStreak[client]++;
        if (g_OrionAimOneTickShotStreak[client] >= 3)
        {
            g_OrionAimScore[client] += 15.0;
            Orion_Aim_ReportIfNeeded(client, "one_tick_attack_streak", g_OrionAimLastTarget[client], g_OrionAimLastDelta[client], 0, tickcount);
        }
    }
    else if (attackTicks > 4)
    {
        g_OrionAimOneTickShotStreak[client] = 0;
    }

    g_OrionAimAttackStartTick[client] = 0;
}

public void Orion_Aim_OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!Orion_IsAliveHumanPlayer(client))
    {
        return;
    }

    if (g_OrionAimLastDelta[client] >= 30.0)
    {
        g_OrionAimScore[client] += 8.0;
        Orion_Aim_ReportIfNeeded(client, "weapon_fire_delta", g_OrionAimLastTarget[client], g_OrionAimLastDelta[client], 0, g_OrionAimLastTick[client]);
    }
}

public void Orion_Aim_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (!Orion_IsAliveHumanPlayer(attacker) || victim <= 0 || victim > MaxClients)
    {
        return;
    }

    if (g_OrionAimLastTarget[attacker] == victim && g_OrionAimTargetTicks[attacker] <= 2)
    {
        g_OrionAimScore[attacker] += 15.0;
    }

    if (g_OrionAimOneTickShotStreak[attacker] >= 2)
    {
        g_OrionAimScore[attacker] += 12.0;
    }

    if (g_OrionAimLastDelta[attacker] >= 25.0)
    {
        g_OrionAimScore[attacker] += 10.0;
    }

    if (Orion_Aim_PlayerIsAirborneOrFast(attacker))
    {
        g_OrionAimScore[attacker] += 8.0;
    }

    Orion_Aim_ReportIfNeeded(attacker, "hurt_correlation", victim, g_OrionAimLastDelta[attacker], 0, g_OrionAimLastTick[attacker]);
}

public void Orion_Aim_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (!Orion_IsAliveHumanPlayer(attacker) || victim <= 0 || victim > MaxClients)
    {
        return;
    }

    if (g_OrionAimLastTarget[attacker] == victim && g_OrionAimTargetTicks[attacker] <= 2)
    {
        g_OrionAimScore[attacker] += 20.0;
        Orion_Aim_ReportIfNeeded(attacker, "death_correlation", victim, g_OrionAimLastDelta[attacker], 0, g_OrionAimLastTick[attacker]);
    }

    if (g_OrionAimOneTickShotStreak[attacker] >= 2)
    {
        g_OrionAimScore[attacker] += 15.0;
        Orion_Aim_ReportIfNeeded(attacker, "autoshoot_death_correlation", victim, g_OrionAimLastDelta[attacker], 0, g_OrionAimLastTick[attacker]);
    }
}

bool Orion_Aim_PlayerIsAirborneOrFast(int client)
{
    bool isAirborne = (GetEntityFlags(client) & FL_ONGROUND) == 0;
    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    float horizontalSpeed = SquareRoot((velocity[0] * velocity[0]) + (velocity[1] * velocity[1]));
    return isAirborne || horizontalSpeed > 260.0;
}

void Orion_Aim_ReportIfNeeded(int client, const char[] reason, int target, float angleDelta, int mouseMagnitude, int tickcount)
{
    float alertThreshold = Orion_Config_AimThreshold();
    if (g_OrionAimScore[client] < alertThreshold)
    {
        return;
    }

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=%s target=%d angle_delta=%.1f mouse=%d target_ticks=%d tick=%d",
        reason,
        target,
        angleDelta,
        mouseMagnitude,
        g_OrionAimTargetTicks[client],
        tickcount);

    char action[16];
    strcopy(action, sizeof(action), g_OrionAimScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) ? "ban" : "observe");
    Orion_Evidence_Submit(client, "aim", g_OrionAimScore[client], action, details);
}

void Orion_Aim_Decay(int client)
{
    if (g_OrionAimScore[client] > 0.0)
    {
        g_OrionAimScore[client] -= 0.025;
        if (g_OrionAimScore[client] < 0.0)
        {
            g_OrionAimScore[client] = 0.0;
        }
    }
}
