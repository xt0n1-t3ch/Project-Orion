static const float ORION_USERCMD_MAX_SAFE_PITCH = 89.01;
static const float ORION_USERCMD_MAX_SAFE_ROLL = 50.01;
static const float ORION_USERCMD_SCORE_COMMAND_REUSE = 18.0;
static const float ORION_USERCMD_SCORE_COMMAND_REGRESSION = 30.0;
static const float ORION_USERCMD_SCORE_TICK_REUSE = 12.0;
static const float ORION_USERCMD_SCORE_TICK_MUTATION = 22.0;
static const float ORION_USERCMD_SCORE_BUTTON_MUTATION = 20.0;
static const float ORION_USERCMD_SCORE_IMPOSSIBLE_ANGLE = 28.0;
static const int ORION_USERCMD_REUSE_STREAK_REPORT_MIN = 3;
static const int ORION_USERCMD_REPORT_COOLDOWN_TICKS = 32;

bool g_OrionUserCmdHasSnapshot[MAXPLAYERS + 1];
int g_OrionUserCmdLastCommandNumber[MAXPLAYERS + 1];
int g_OrionUserCmdLastTickCount[MAXPLAYERS + 1];
int g_OrionUserCmdLastButtons[MAXPLAYERS + 1];
int g_OrionUserCmdLastMouseX[MAXPLAYERS + 1];
int g_OrionUserCmdLastMouseY[MAXPLAYERS + 1];
int g_OrionUserCmdLastReportGameTick[MAXPLAYERS + 1];
int g_OrionUserCmdCommandReuseStreak[MAXPLAYERS + 1];
int g_OrionUserCmdCommandRegressionStreak[MAXPLAYERS + 1];
int g_OrionUserCmdTickReuseStreak[MAXPLAYERS + 1];
int g_OrionUserCmdTickRegressionStreak[MAXPLAYERS + 1];
int g_OrionUserCmdButtonMutationStreak[MAXPLAYERS + 1];
int g_OrionUserCmdImpossibleAngleStreak[MAXPLAYERS + 1];
float g_OrionUserCmdScore[MAXPLAYERS + 1];
float g_OrionUserCmdLastAngles[MAXPLAYERS + 1][3];

void Orion_UserCmdGuard_Init()
{
}

void Orion_UserCmdGuard_ResetClient(int client)
{
    g_OrionUserCmdHasSnapshot[client] = false;
    g_OrionUserCmdLastCommandNumber[client] = 0;
    g_OrionUserCmdLastTickCount[client] = 0;
    g_OrionUserCmdLastButtons[client] = 0;
    g_OrionUserCmdLastMouseX[client] = 0;
    g_OrionUserCmdLastMouseY[client] = 0;
    g_OrionUserCmdLastReportGameTick[client] = 0;
    g_OrionUserCmdCommandReuseStreak[client] = 0;
    g_OrionUserCmdCommandRegressionStreak[client] = 0;
    g_OrionUserCmdTickReuseStreak[client] = 0;
    g_OrionUserCmdTickRegressionStreak[client] = 0;
    g_OrionUserCmdButtonMutationStreak[client] = 0;
    g_OrionUserCmdImpossibleAngleStreak[client] = 0;
    g_OrionUserCmdScore[client] = 0.0;
    g_OrionUserCmdLastAngles[client][0] = 0.0;
    g_OrionUserCmdLastAngles[client][1] = 0.0;
    g_OrionUserCmdLastAngles[client][2] = 0.0;
}

bool Orion_UserCmdGuard_OnPlayerRunCmd(
    int client,
    int buttons,
    float angles[3],
    int commandNumber,
    int tickcount,
    int mouse[2])
{
    if (!Orion_IsAliveHumanPlayer(client))
    {
        Orion_UserCmdGuard_ResetClient(client);
        return false;
    }

    bool wasCommandMutated = false;

    if (g_OrionUserCmdHasSnapshot[client])
    {
        wasCommandMutated = Orion_UserCmdGuard_CheckCommandNumber(client, commandNumber, tickcount, buttons, angles, mouse) || wasCommandMutated;
        wasCommandMutated = Orion_UserCmdGuard_CheckTickCount(client, commandNumber, tickcount, buttons, angles, mouse) || wasCommandMutated;
        wasCommandMutated = Orion_UserCmdGuard_CheckButtons(client, commandNumber, tickcount, buttons, angles, mouse) || wasCommandMutated;
    }

    wasCommandMutated = Orion_UserCmdGuard_CheckImpossibleAngles(client, commandNumber, tickcount, buttons, angles, mouse) || wasCommandMutated;
    Orion_UserCmdGuard_SaveSnapshot(client, commandNumber, tickcount, buttons, angles, mouse);
    Orion_UserCmdGuard_Decay(client);
    return wasCommandMutated;
}

bool Orion_UserCmdGuard_CheckCommandNumber(int client, int commandNumber, int tickcount, int buttons, float angles[3], int mouse[2])
{
    if (commandNumber < g_OrionUserCmdLastCommandNumber[client])
    {
        g_OrionUserCmdCommandRegressionStreak[client]++;
        g_OrionUserCmdScore[client] += ORION_USERCMD_SCORE_COMMAND_REGRESSION;
        Orion_UserCmdGuard_ReportEvidence(client, "cmdnum_regression", commandNumber, tickcount, buttons, angles, mouse);
        return true;
    }

    if (commandNumber == g_OrionUserCmdLastCommandNumber[client])
    {
        g_OrionUserCmdCommandReuseStreak[client]++;
        g_OrionUserCmdScore[client] += ORION_USERCMD_SCORE_COMMAND_REUSE;

        if (g_OrionUserCmdCommandReuseStreak[client] >= ORION_USERCMD_REUSE_STREAK_REPORT_MIN)
        {
            Orion_UserCmdGuard_ReportEvidence(client, "cmdnum_reuse", commandNumber, tickcount, buttons, angles, mouse);
        }

        return true;
    }

    g_OrionUserCmdCommandReuseStreak[client] = 0;
    if (g_OrionUserCmdCommandRegressionStreak[client] > 0)
    {
        g_OrionUserCmdCommandRegressionStreak[client]--;
    }

    return false;
}

bool Orion_UserCmdGuard_CheckTickCount(int client, int commandNumber, int tickcount, int buttons, float angles[3], int mouse[2])
{
    if (commandNumber == g_OrionUserCmdLastCommandNumber[client] && tickcount != g_OrionUserCmdLastTickCount[client])
    {
        g_OrionUserCmdScore[client] += ORION_USERCMD_SCORE_TICK_MUTATION;
        Orion_UserCmdGuard_ReportEvidence(client, "tickcount_mutated_reused_cmd", commandNumber, tickcount, buttons, angles, mouse);
        return true;
    }

    if (tickcount < g_OrionUserCmdLastTickCount[client])
    {
        g_OrionUserCmdTickRegressionStreak[client]++;
        g_OrionUserCmdScore[client] += ORION_USERCMD_SCORE_TICK_MUTATION;
        Orion_UserCmdGuard_ReportEvidence(client, "tickcount_regression", commandNumber, tickcount, buttons, angles, mouse);
        return true;
    }

    if (tickcount == g_OrionUserCmdLastTickCount[client])
    {
        g_OrionUserCmdTickReuseStreak[client]++;
        g_OrionUserCmdScore[client] += ORION_USERCMD_SCORE_TICK_REUSE;

        if (g_OrionUserCmdTickReuseStreak[client] >= ORION_USERCMD_REUSE_STREAK_REPORT_MIN)
        {
            Orion_UserCmdGuard_ReportEvidence(client, "tickcount_reuse", commandNumber, tickcount, buttons, angles, mouse);
        }

        return true;
    }

    g_OrionUserCmdTickReuseStreak[client] = 0;
    if (g_OrionUserCmdTickRegressionStreak[client] > 0)
    {
        g_OrionUserCmdTickRegressionStreak[client]--;
    }

    return false;
}

bool Orion_UserCmdGuard_CheckButtons(int client, int commandNumber, int tickcount, int buttons, float angles[3], int mouse[2])
{
    if (commandNumber != g_OrionUserCmdLastCommandNumber[client])
    {
        g_OrionUserCmdButtonMutationStreak[client] = 0;
        return false;
    }

    if (buttons == g_OrionUserCmdLastButtons[client])
    {
        return false;
    }

    g_OrionUserCmdButtonMutationStreak[client]++;
    g_OrionUserCmdScore[client] += ORION_USERCMD_SCORE_BUTTON_MUTATION;
    Orion_UserCmdGuard_ReportEvidence(client, "buttons_mutated_reused_cmd", commandNumber, tickcount, buttons, angles, mouse);
    return true;
}

bool Orion_UserCmdGuard_CheckImpossibleAngles(int client, int commandNumber, int tickcount, int buttons, float angles[3], int mouse[2])
{
    bool hasImpossiblePitch = angles[0] > ORION_USERCMD_MAX_SAFE_PITCH || angles[0] < -ORION_USERCMD_MAX_SAFE_PITCH;
    bool hasImpossibleRoll = angles[2] > ORION_USERCMD_MAX_SAFE_ROLL || angles[2] < -ORION_USERCMD_MAX_SAFE_ROLL;

    if (!hasImpossiblePitch && !hasImpossibleRoll)
    {
        g_OrionUserCmdImpossibleAngleStreak[client] = 0;
        return false;
    }

    if (Orion_UserCmdGuard_IsL4D2ViewControlException(client))
    {
        return false;
    }

    g_OrionUserCmdImpossibleAngleStreak[client]++;
    g_OrionUserCmdScore[client] += hasImpossiblePitch && hasImpossibleRoll
        ? ORION_USERCMD_SCORE_IMPOSSIBLE_ANGLE * 1.5
        : ORION_USERCMD_SCORE_IMPOSSIBLE_ANGLE;
    Orion_UserCmdGuard_ReportEvidence(client, "impossible_angles", commandNumber, tickcount, buttons, angles, mouse);
    return true;
}

bool Orion_UserCmdGuard_IsL4D2ViewControlException(int client)
{
    int team = GetClientTeam(client);

    if (team <= ORION_TEAM_SPECTATOR)
    {
        return true;
    }

    if (team == ORION_TEAM_INFECTED && Orion_UserCmdGuard_GetSendPropInt(client, "m_isGhost") > 0)
    {
        return true;
    }

    if (team == ORION_TEAM_SURVIVOR)
    {
        return Orion_UserCmdGuard_GetSendPropInt(client, "m_isIncapacitated") > 0
            || Orion_UserCmdGuard_GetSendPropInt(client, "m_isHangingFromLedge") > 0
            || Orion_UserCmdGuard_GetSendPropEntity(client, "m_tongueOwner") > 0
            || Orion_UserCmdGuard_GetSendPropEntity(client, "m_pounceAttacker") > 0
            || Orion_UserCmdGuard_GetSendPropEntity(client, "m_jockeyAttacker") > 0
            || Orion_UserCmdGuard_GetSendPropEntity(client, "m_carryAttacker") > 0
            || Orion_UserCmdGuard_GetSendPropEntity(client, "m_pummelAttacker") > 0;
    }

    return false;
}

int Orion_UserCmdGuard_GetSendPropInt(int client, const char[] propertyName)
{
    if (!HasEntProp(client, Prop_Send, propertyName))
    {
        return 0;
    }

    return GetEntProp(client, Prop_Send, propertyName);
}

int Orion_UserCmdGuard_GetSendPropEntity(int client, const char[] propertyName)
{
    if (!HasEntProp(client, Prop_Send, propertyName))
    {
        return 0;
    }

    return GetEntPropEnt(client, Prop_Send, propertyName);
}

void Orion_UserCmdGuard_SaveSnapshot(int client, int commandNumber, int tickcount, int buttons, float angles[3], int mouse[2])
{
    g_OrionUserCmdHasSnapshot[client] = true;
    g_OrionUserCmdLastCommandNumber[client] = commandNumber;
    g_OrionUserCmdLastTickCount[client] = tickcount;
    g_OrionUserCmdLastButtons[client] = buttons;
    g_OrionUserCmdLastMouseX[client] = mouse[0];
    g_OrionUserCmdLastMouseY[client] = mouse[1];
    g_OrionUserCmdLastAngles[client][0] = angles[0];
    g_OrionUserCmdLastAngles[client][1] = angles[1];
    g_OrionUserCmdLastAngles[client][2] = angles[2];
}

void Orion_UserCmdGuard_ReportEvidence(int client, const char[] reason, int commandNumber, int tickcount, int buttons, float angles[3], int mouse[2])
{
    int gameTick = GetGameTickCount();
    if (g_OrionUserCmdLastReportGameTick[client] > 0 && gameTick - g_OrionUserCmdLastReportGameTick[client] < ORION_USERCMD_REPORT_COOLDOWN_TICKS)
    {
        return;
    }

    g_OrionUserCmdLastReportGameTick[client] = gameTick;

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=%s cmd=%d/%d tick=%d/%d btn=%d/%d ang=%.2f,%.2f,%.2f last_ang=%.2f,%.2f,%.2f mouse=%d,%d/%d,%d streaks=%d,%d,%d,%d,%d,%d",
        reason,
        commandNumber,
        g_OrionUserCmdLastCommandNumber[client],
        tickcount,
        g_OrionUserCmdLastTickCount[client],
        buttons,
        g_OrionUserCmdLastButtons[client],
        angles[0],
        angles[1],
        angles[2],
        g_OrionUserCmdLastAngles[client][0],
        g_OrionUserCmdLastAngles[client][1],
        g_OrionUserCmdLastAngles[client][2],
        mouse[0],
        mouse[1],
        g_OrionUserCmdLastMouseX[client],
        g_OrionUserCmdLastMouseY[client],
        g_OrionUserCmdCommandReuseStreak[client],
        g_OrionUserCmdCommandRegressionStreak[client],
        g_OrionUserCmdTickReuseStreak[client],
        g_OrionUserCmdTickRegressionStreak[client],
        g_OrionUserCmdButtonMutationStreak[client],
        g_OrionUserCmdImpossibleAngleStreak[client]);

    Orion_Evidence_Submit(client, "usercmd_guard", g_OrionUserCmdScore[client], "observe", details);
}

void Orion_UserCmdGuard_Decay(int client)
{
    if (g_OrionUserCmdScore[client] <= 0.0)
    {
        return;
    }

    g_OrionUserCmdScore[client] -= 0.02;
    if (g_OrionUserCmdScore[client] < 0.0)
    {
        g_OrionUserCmdScore[client] = 0.0;
    }
}
