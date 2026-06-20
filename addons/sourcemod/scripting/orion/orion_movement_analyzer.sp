int g_OrionMoveLastButtons[MAXPLAYERS + 1];
int g_OrionMoveLastJumpTick[MAXPLAYERS + 1];
int g_OrionMoveLastJumpReleaseTick[MAXPLAYERS + 1];
int g_OrionMoveJumpHeldTicks[MAXPLAYERS + 1];
int g_OrionMovePerfectJumpStreak[MAXPLAYERS + 1];
int g_OrionMoveJumpReleaseCadenceStreak[MAXPLAYERS + 1];
int g_OrionMoveCommandRepeatStreak[MAXPLAYERS + 1];
int g_OrionMoveLastCommandNumber[MAXPLAYERS + 1];
int g_OrionMoveCommandRegressionStreak[MAXPLAYERS + 1];
int g_OrionMoveCommandGapStreak[MAXPLAYERS + 1];
int g_OrionMoveNetworkMaskedGapStreak[MAXPLAYERS + 1];
int g_OrionMoveNetworkMaskedDriftStreak[MAXPLAYERS + 1];
int g_OrionMoveLagExploitStreak[MAXPLAYERS + 1];
int g_OrionMoveLastTick[MAXPLAYERS + 1];
int g_OrionMoveLastServerTick[MAXPLAYERS + 1];
int g_OrionMoveLastTickDrift[MAXPLAYERS + 1];
int g_OrionMoveAllowedPastTickDrift[MAXPLAYERS + 1];
int g_OrionMoveAllowedFutureTickDrift[MAXPLAYERS + 1];
int g_OrionMoveBasePastTickDrift[MAXPLAYERS + 1];
int g_OrionMoveBaseFutureTickDrift[MAXPLAYERS + 1];
int g_OrionMoveLastCommandGap[MAXPLAYERS + 1];
int g_OrionMoveAllowedCommandGap[MAXPLAYERS + 1];
int g_OrionMoveLastReportTick[MAXPLAYERS + 1];
int g_OrionMoveLastLagExploitReportTick[MAXPLAYERS + 1];
float g_OrionMoveScore[MAXPLAYERS + 1];
float g_OrionMoveLastSpeed[MAXPLAYERS + 1];
float g_OrionMoveSpeedhackTokens[MAXPLAYERS + 1];
float g_OrionMoveAllowedSpeedhackTokens[MAXPLAYERS + 1];
float g_OrionMoveLatencyMs[MAXPLAYERS + 1];
float g_OrionMoveChokePercent[MAXPLAYERS + 1];
float g_OrionMoveLossPercent[MAXPLAYERS + 1];

#define ORION_MOVE_SPEEDHACK_BUCKET_BASE_TOKENS 8
#define ORION_MOVE_SPEEDHACK_BUCKET_DECAY_PER_TICK 1.0
#define ORION_MOVE_SPEEDHACK_BUCKET_SCORE 4.0
#define ORION_MOVE_SPEEDHACK_BUCKET_MIN_SPEED 300.0
#define ORION_MOVE_SCORE_MAX 150.0
#define ORION_MOVE_REPORT_COOLDOWN_TICKS 66
#define ORION_MOVE_COMMAND_GAP_BASE_TICKS 2
#define ORION_MOVE_COMMAND_GAP_SCORE 5.0
#define ORION_MOVE_FAKE_LAG_CHOKE_PERCENT 35.0
#define ORION_MOVE_FAKE_LAG_LOW_LOSS_PERCENT 3.0
#define ORION_MOVE_NETWORK_MASKED_STREAK_MIN 3
#define ORION_MOVE_LAG_EXPLOIT_STREAK_MIN 3
#define ORION_MOVE_LAG_EXPLOIT_REPORT_COOLDOWN_TICKS 32
#define ORION_MOVE_JUMP_RELEASE_CADENCE_TICKS 4
#define ORION_MOVE_JUMP_RELEASE_RESET_TICKS 16
#define ORION_MOVE_AUTOTRIGGER_RELEASE_TICKS 2
#define ORION_MOVE_AUTOTRIGGER_SCORE 5.5
#define ORION_MOVE_TICK_DRIFT_SCORE 8.0

void Orion_Movement_Init()
{
}

void Orion_Movement_ResetClient(int client)
{
    g_OrionMoveLastButtons[client] = 0;
    g_OrionMoveLastJumpTick[client] = 0;
    g_OrionMoveLastJumpReleaseTick[client] = 0;
    g_OrionMoveJumpHeldTicks[client] = 0;
    g_OrionMovePerfectJumpStreak[client] = 0;
    g_OrionMoveJumpReleaseCadenceStreak[client] = 0;
    g_OrionMoveCommandRepeatStreak[client] = 0;
    g_OrionMoveLastCommandNumber[client] = 0;
    g_OrionMoveCommandRegressionStreak[client] = 0;
    g_OrionMoveCommandGapStreak[client] = 0;
    g_OrionMoveNetworkMaskedGapStreak[client] = 0;
    g_OrionMoveNetworkMaskedDriftStreak[client] = 0;
    g_OrionMoveLagExploitStreak[client] = 0;
    g_OrionMoveLastTick[client] = 0;
    g_OrionMoveLastServerTick[client] = 0;
    g_OrionMoveLastTickDrift[client] = 0;
    g_OrionMoveAllowedPastTickDrift[client] = 0;
    g_OrionMoveAllowedFutureTickDrift[client] = 0;
    g_OrionMoveBasePastTickDrift[client] = 0;
    g_OrionMoveBaseFutureTickDrift[client] = 0;
    g_OrionMoveLastCommandGap[client] = 0;
    g_OrionMoveAllowedCommandGap[client] = 0;
    g_OrionMoveLastReportTick[client] = 0;
    g_OrionMoveLastLagExploitReportTick[client] = 0;
    g_OrionMoveScore[client] = 0.0;
    g_OrionMoveLastSpeed[client] = 0.0;
    g_OrionMoveSpeedhackTokens[client] = 0.0;
    g_OrionMoveAllowedSpeedhackTokens[client] = 0.0;
    g_OrionMoveLatencyMs[client] = 0.0;
    g_OrionMoveChokePercent[client] = 0.0;
    g_OrionMoveLossPercent[client] = 0.0;
}

void Orion_Movement_OnPlayerRunCmd(int client, int buttons, float angles[3], int commandNumber, int& tickcount, int& seed)
{
    if (!Orion_IsAliveHumanPlayer(client))
    {
        return;
    }

    bool jumpPressed = (buttons & IN_JUMP) != 0;
    bool jumpStarted = jumpPressed && ((g_OrionMoveLastButtons[client] & IN_JUMP) == 0);
    bool jumpReleased = !jumpPressed && ((g_OrionMoveLastButtons[client] & IN_JUMP) != 0);
    bool onGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;
    int previousJumpHeldTicks = g_OrionMoveJumpHeldTicks[client];

    Orion_Movement_UpdateNetworkQuality(client);
    float currentSpeed = Orion_Movement_CurrentSpeed(client);

    if (jumpReleased)
    {
        Orion_Movement_ScoreJumpRelease(client, tickcount, currentSpeed, previousJumpHeldTicks);
    }

    g_OrionMoveJumpHeldTicks[client] = jumpPressed ? previousJumpHeldTicks + 1 : 0;

    if (jumpStarted)
    {
        Orion_Movement_ScoreJump(client, tickcount, onGround, currentSpeed);
    }

    Orion_Movement_ScoreSpeedhackBucket(client, tickcount, currentSpeed);
    Orion_Movement_ScoreCommandClock(client, buttons, commandNumber, tickcount, seed, currentSpeed);
    Orion_Movement_ScoreSpeedWindow(client, currentSpeed, onGround, angles, tickcount);

    g_OrionMoveLastButtons[client] = buttons;
    g_OrionMoveLastTick[client] = tickcount;
    g_OrionMoveLastCommandNumber[client] = commandNumber;
    g_OrionMoveLastSpeed[client] = currentSpeed;
    Orion_Movement_Decay(client);
}

void Orion_Movement_ScoreCommandClock(int client, int buttons, int commandNumber, int& tickcount, int& seed, float currentSpeed)
{
    int commandGap = 0;
    if (g_OrionMoveLastCommandNumber[client] > 0)
    {
        commandGap = commandNumber - g_OrionMoveLastCommandNumber[client];
        g_OrionMoveLastCommandGap[client] = commandGap;
        if (commandGap > 1)
        {
            Orion_Movement_ScoreCommandGap(client, commandGap, tickcount, currentSpeed);
        }
    }

    if (tickcount == g_OrionMoveLastTick[client] || seed == 0)
    {
        g_OrionMoveCommandRepeatStreak[client]++;
        if (g_OrionMoveCommandRepeatStreak[client] > 8)
        {
            Orion_Movement_AddScore(client, 10.0);
            if (Orion_Config_HardMitigationEnabled() && (buttons & IN_ATTACK) != 0)
            {
                seed = GetRandomInt(1, 2147483647);
            }
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
        Orion_Movement_AddScore(client, 6.0);
    }
    else if (g_OrionMoveCommandRegressionStreak[client] > 0)
    {
        g_OrionMoveCommandRegressionStreak[client]--;
    }

    if (Orion_Config_BacktrackPatchEnabled())
    {
        Orion_Movement_ScoreTickDrift(client, buttons, tickcount, seed, currentSpeed);
    }

    if (g_OrionMoveCommandRegressionStreak[client] >= 3)
    {
        Orion_Movement_ReportIfNeeded(client, "command_number_regression", tickcount, currentSpeed);
    }
}

void Orion_Movement_ScoreCommandGap(int client, int commandGap, int tickcount, float currentSpeed)
{
    int latencyAllowanceTicks = Orion_Movement_LatencyAllowanceTicks(client);
    int chokeAllowanceTicks = Orion_Movement_ChokeAllowanceTicks(client);
    int lossAllowanceTicks = Orion_Movement_LossAllowanceTicks(client);
    int allowedCommandGap = ORION_MOVE_COMMAND_GAP_BASE_TICKS
        + Orion_Movement_MinInt(latencyAllowanceTicks / 2, 4)
        + Orion_Movement_MinInt(chokeAllowanceTicks, 10)
        + Orion_Movement_MinInt(lossAllowanceTicks, 6);

    g_OrionMoveAllowedCommandGap[client] = allowedCommandGap;

    if (commandGap <= allowedCommandGap)
    {
        if (commandGap > ORION_MOVE_COMMAND_GAP_BASE_TICKS + 4
            && g_OrionMoveChokePercent[client] >= ORION_MOVE_FAKE_LAG_CHOKE_PERCENT
            && g_OrionMoveLossPercent[client] <= ORION_MOVE_FAKE_LAG_LOW_LOSS_PERCENT)
        {
            g_OrionMoveNetworkMaskedGapStreak[client]++;
            if (g_OrionMoveNetworkMaskedGapStreak[client] >= ORION_MOVE_NETWORK_MASKED_STREAK_MIN)
            {
                g_OrionMoveLagExploitStreak[client]++;
                Orion_Movement_AddScore(client, 4.0);
                Orion_Movement_ReportLagExploitIfNeeded(client, "network_masked_command_gap", tickcount, currentSpeed);
            }
        }
        else if (g_OrionMoveNetworkMaskedGapStreak[client] > 0)
        {
            g_OrionMoveNetworkMaskedGapStreak[client]--;
        }

        if (g_OrionMoveCommandGapStreak[client] > 0)
        {
            g_OrionMoveCommandGapStreak[client]--;
        }
        return;
    }

    g_OrionMoveCommandGapStreak[client]++;
    float gapScore = ORION_MOVE_COMMAND_GAP_SCORE + float(commandGap - allowedCommandGap);
    if (g_OrionMoveChokePercent[client] >= ORION_MOVE_FAKE_LAG_CHOKE_PERCENT && g_OrionMoveLossPercent[client] <= ORION_MOVE_FAKE_LAG_LOW_LOSS_PERCENT)
    {
        gapScore += 6.0;
        g_OrionMoveLagExploitStreak[client]++;
        Orion_Movement_ReportLagExploitIfNeeded(client, "fake_lag_command_gap", tickcount, currentSpeed);
    }

    Orion_Movement_AddScore(client, gapScore);
    if (g_OrionMoveCommandGapStreak[client] >= 2 || commandGap >= allowedCommandGap + 6)
    {
        Orion_Movement_ReportIfNeeded(client, "command_gap_choke", tickcount, currentSpeed);
    }
}

void Orion_Movement_ScoreTickDrift(int client, int buttons, int& tickcount, int& seed, float currentSpeed)
{
    int serverTick = GetGameTickCount();
    int tickDrift = tickcount - serverTick;
    int configuredToleranceTicks = Orion_Config_BacktrackToleranceTicks();
    int baseAllowedPastDriftTicks = configuredToleranceTicks;
    int baseAllowedFutureDriftTicks = configuredToleranceTicks + 4;
    int latencyAllowanceTicks = Orion_Movement_LatencyAllowanceTicks(client);
    int chokeAllowanceTicks = Orion_Movement_ChokeAllowanceTicks(client);
    int lossAllowanceTicks = Orion_Movement_LossAllowanceTicks(client);
    int allowedPastDriftTicks = configuredToleranceTicks
        + latencyAllowanceTicks
        + Orion_Movement_MinInt(chokeAllowanceTicks, 10)
        + Orion_Movement_MinInt(lossAllowanceTicks, 6);
    int allowedFutureDriftTicks = configuredToleranceTicks
        + Orion_Movement_MinInt(latencyAllowanceTicks / 2, 6)
        + 4;

    g_OrionMoveLastTickDrift[client] = tickDrift;
    g_OrionMoveAllowedPastTickDrift[client] = allowedPastDriftTicks;
    g_OrionMoveAllowedFutureTickDrift[client] = allowedFutureDriftTicks;
    g_OrionMoveBasePastTickDrift[client] = baseAllowedPastDriftTicks;
    g_OrionMoveBaseFutureTickDrift[client] = baseAllowedFutureDriftTicks;

    if (tickDrift >= -allowedPastDriftTicks && tickDrift <= allowedFutureDriftTicks)
    {
        bool isOutsideBaseWindow = tickDrift < -baseAllowedPastDriftTicks || tickDrift > baseAllowedFutureDriftTicks;
        if (isOutsideBaseWindow
            && g_OrionMoveChokePercent[client] >= ORION_MOVE_FAKE_LAG_CHOKE_PERCENT
            && g_OrionMoveLossPercent[client] <= ORION_MOVE_FAKE_LAG_LOW_LOSS_PERCENT)
        {
            g_OrionMoveNetworkMaskedDriftStreak[client]++;
            if (g_OrionMoveNetworkMaskedDriftStreak[client] >= ORION_MOVE_NETWORK_MASKED_STREAK_MIN)
            {
                g_OrionMoveLagExploitStreak[client]++;
                Orion_Movement_AddScore(client, 4.0);
                Orion_Movement_ReportLagExploitIfNeeded(client, "network_masked_tick_drift", tickcount, currentSpeed);
            }
        }
        else if (g_OrionMoveNetworkMaskedDriftStreak[client] > 0)
        {
            g_OrionMoveNetworkMaskedDriftStreak[client]--;
        }

        return;
    }

    g_OrionMoveLagExploitStreak[client]++;
    int driftExcessTicks = tickDrift < 0 ? (-tickDrift - allowedPastDriftTicks) : (tickDrift - allowedFutureDriftTicks);
    Orion_Movement_AddScore(client, ORION_MOVE_TICK_DRIFT_SCORE + float(Orion_Movement_MinInt(driftExcessTicks, 12)));
    if (Orion_Config_HardMitigationEnabled())
    {
        tickcount = tickDrift < 0 ? serverTick - allowedPastDriftTicks : serverTick + allowedFutureDriftTicks;
        if ((buttons & IN_ATTACK) != 0)
        {
            seed = GetRandomInt(1, 2147483647);
        }
    }

    Orion_Movement_ReportIfNeeded(client, "command_tick_drift", tickcount, currentSpeed);
    Orion_Movement_ReportLagExploitIfNeeded(client, "fakeping_tick_drift", tickcount, currentSpeed);
}

void Orion_Movement_ScoreSpeedhackBucket(int client, int tickcount, float currentSpeed)
{
    int serverTick = GetGameTickCount();
    if (g_OrionMoveLastServerTick[client] <= 0)
    {
        g_OrionMoveLastServerTick[client] = serverTick;
        g_OrionMoveAllowedSpeedhackTokens[client] = float(ORION_MOVE_SPEEDHACK_BUCKET_BASE_TOKENS);
        return;
    }

    int elapsedServerTicks = serverTick - g_OrionMoveLastServerTick[client];
    if (elapsedServerTicks < 0)
    {
        elapsedServerTicks = 0;
    }

    float remainingTokens = g_OrionMoveSpeedhackTokens[client] - (float(elapsedServerTicks) * ORION_MOVE_SPEEDHACK_BUCKET_DECAY_PER_TICK);
    if (remainingTokens < 0.0)
    {
        remainingTokens = 0.0;
    }

    if (currentSpeed < ORION_MOVE_SPEEDHACK_BUCKET_MIN_SPEED)
    {
        g_OrionMoveSpeedhackTokens[client] = remainingTokens;
        g_OrionMoveLastServerTick[client] = serverTick;
        return;
    }

    remainingTokens += 1.0;
    g_OrionMoveSpeedhackTokens[client] = remainingTokens;
    g_OrionMoveLastServerTick[client] = serverTick;

    int allowedTokens = ORION_MOVE_SPEEDHACK_BUCKET_BASE_TOKENS
        + Orion_Movement_MinInt(Orion_Movement_LatencyAllowanceTicks(client), 8)
        + Orion_Movement_MinInt(Orion_Movement_ChokeAllowanceTicks(client), 12)
        + Orion_Movement_MinInt(Orion_Movement_LossAllowanceTicks(client), 6);
    g_OrionMoveAllowedSpeedhackTokens[client] = float(allowedTokens);

    if (remainingTokens <= g_OrionMoveAllowedSpeedhackTokens[client])
    {
        return;
    }

    Orion_Movement_AddScore(client, ORION_MOVE_SPEEDHACK_BUCKET_SCORE + (remainingTokens - g_OrionMoveAllowedSpeedhackTokens[client]));
    Orion_Movement_ReportIfNeeded(client, "speedhack_token_bucket", tickcount, currentSpeed);
}

void Orion_Movement_ScoreJumpRelease(int client, int tickcount, float currentSpeed, int heldTicksBeforeRelease)
{
    int releaseIntervalTicks = tickcount - g_OrionMoveLastJumpReleaseTick[client];
    if (g_OrionMoveLastJumpReleaseTick[client] > 0 && releaseIntervalTicks > 0 && releaseIntervalTicks <= ORION_MOVE_JUMP_RELEASE_CADENCE_TICKS)
    {
        g_OrionMoveJumpReleaseCadenceStreak[client]++;
        Orion_Movement_AddScore(client, 2.5);
    }
    else if (releaseIntervalTicks > ORION_MOVE_JUMP_RELEASE_RESET_TICKS)
    {
        g_OrionMoveJumpReleaseCadenceStreak[client] = 0;
    }

    if (heldTicksBeforeRelease > 0 && heldTicksBeforeRelease <= ORION_MOVE_AUTOTRIGGER_RELEASE_TICKS && g_OrionMoveLastJumpTick[client] > 0)
    {
        Orion_Movement_AddScore(client, ORION_MOVE_AUTOTRIGGER_SCORE);
    }

    g_OrionMoveLastJumpReleaseTick[client] = tickcount;
    if (g_OrionMoveJumpReleaseCadenceStreak[client] >= 6)
    {
        Orion_Movement_ReportIfNeeded(client, "jump_release_cadence", tickcount, currentSpeed);
    }
}

void Orion_Movement_ScoreJump(int client, int tickcount, bool onGround, float currentSpeed)
{
    int tickDistance = tickcount - g_OrionMoveLastJumpTick[client];
    int releaseToPressTicks = tickcount - g_OrionMoveLastJumpReleaseTick[client];

    if (g_OrionMoveLastJumpTick[client] > 0 && tickDistance > 0 && tickDistance <= 3 && onGround)
    {
        g_OrionMovePerfectJumpStreak[client]++;
        Orion_Movement_AddScore(client, 7.5);
    }
    else if (tickDistance > 12)
    {
        g_OrionMovePerfectJumpStreak[client] = 0;
    }

    if (g_OrionMovePerfectJumpStreak[client] >= 8)
    {
        Orion_Movement_AddScore(client, 15.0);
    }

    if (onGround && g_OrionMoveLastJumpReleaseTick[client] > 0 && releaseToPressTicks > 0 && releaseToPressTicks <= ORION_MOVE_AUTOTRIGGER_RELEASE_TICKS)
    {
        Orion_Movement_AddScore(client, ORION_MOVE_AUTOTRIGGER_SCORE);
        if (g_OrionMoveJumpReleaseCadenceStreak[client] >= 4)
        {
            Orion_Movement_AddScore(client, 7.0);
        }
    }

    if (currentSpeed > 310.0 && currentSpeed >= g_OrionMoveLastSpeed[client])
    {
        Orion_Movement_AddScore(client, 5.0);
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

    Orion_Movement_AddScore(client, hasSuspiciousSpeed && hasAirControlBurst ? 16.0 : 8.0);
    Orion_Movement_ReportIfNeeded(client, hasAirControlBurst ? "air_strafe_burst" : "speed_gain", tickcount, currentSpeed);
}

float Orion_Movement_CurrentSpeed(int client)
{
    float currentVelocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", currentVelocity);
    return SquareRoot((currentVelocity[0] * currentVelocity[0]) + (currentVelocity[1] * currentVelocity[1]));
}

void Orion_Movement_UpdateNetworkQuality(int client)
{
    g_OrionMoveLatencyMs[client] = GetClientAvgLatency(client, NetFlow_Both) * 1000.0;
    g_OrionMoveChokePercent[client] = GetClientAvgChoke(client, NetFlow_Both) * 100.0;
    g_OrionMoveLossPercent[client] = GetClientAvgLoss(client, NetFlow_Both) * 100.0;
}

int Orion_Movement_LatencyAllowanceTicks(int client)
{
    float tickInterval = GetTickInterval();
    if (tickInterval <= 0.0)
    {
        return 0;
    }

    return Orion_Movement_ClampInt(RoundToCeil((g_OrionMoveLatencyMs[client] / 1000.0) / tickInterval), 0, 16);
}

int Orion_Movement_ChokeAllowanceTicks(int client)
{
    return Orion_Movement_ClampInt(RoundToCeil(g_OrionMoveChokePercent[client] / 5.0), 0, 16);
}

int Orion_Movement_LossAllowanceTicks(int client)
{
    return Orion_Movement_ClampInt(RoundToCeil(g_OrionMoveLossPercent[client] / 5.0), 0, 12);
}

int Orion_Movement_ClampInt(int value, int minimumValue, int maximumValue)
{
    if (value < minimumValue)
    {
        return minimumValue;
    }

    if (value > maximumValue)
    {
        return maximumValue;
    }

    return value;
}

int Orion_Movement_MinInt(int leftValue, int rightValue)
{
    return leftValue < rightValue ? leftValue : rightValue;
}

void Orion_Movement_ReportIfNeeded(int client, const char[] reason, int tickcount, float currentSpeed)
{
    float alertThreshold = Orion_Config_MovementThreshold();
    if (g_OrionMoveScore[client] < alertThreshold)
    {
        return;
    }

    int serverTick = GetGameTickCount();
    if (g_OrionMoveLastReportTick[client] > 0 && serverTick - g_OrionMoveLastReportTick[client] < ORION_MOVE_REPORT_COOLDOWN_TICKS)
    {
        return;
    }

    g_OrionMoveLastReportTick[client] = serverTick;

    char details[512];
    Format(
        details,
        sizeof(details),
        "reason=%s tick=%d perfect_jump_streak=%d jump_release_streak=%d repeat_streak=%d command_regression_streak=%d command_gap_streak=%d masked_gap_streak=%d masked_drift_streak=%d lag_exploit_streak=%d command_gap=%d allowed_command_gap=%d tick_drift=%d base_past_drift=%d base_future_drift=%d allowed_past_drift=%d allowed_future_drift=%d speed=%.1f speedhack_tokens=%.1f allowed_speedhack_tokens=%.1f latency_ms=%.1f choke_pct=%.1f loss_pct=%.1f",
        reason,
        tickcount,
        g_OrionMovePerfectJumpStreak[client],
        g_OrionMoveJumpReleaseCadenceStreak[client],
        g_OrionMoveCommandRepeatStreak[client],
        g_OrionMoveCommandRegressionStreak[client],
        g_OrionMoveCommandGapStreak[client],
        g_OrionMoveNetworkMaskedGapStreak[client],
        g_OrionMoveNetworkMaskedDriftStreak[client],
        g_OrionMoveLagExploitStreak[client],
        g_OrionMoveLastCommandGap[client],
        g_OrionMoveAllowedCommandGap[client],
        g_OrionMoveLastTickDrift[client],
        g_OrionMoveBasePastTickDrift[client],
        g_OrionMoveBaseFutureTickDrift[client],
        g_OrionMoveAllowedPastTickDrift[client],
        g_OrionMoveAllowedFutureTickDrift[client],
        currentSpeed,
        g_OrionMoveSpeedhackTokens[client],
        g_OrionMoveAllowedSpeedhackTokens[client],
        g_OrionMoveLatencyMs[client],
        g_OrionMoveChokePercent[client],
        g_OrionMoveLossPercent[client]);

    char action[16];
    strcopy(action, sizeof(action), g_OrionMoveScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) && Orion_Movement_IsBanEligible(client, reason) ? "ban" : "observe");
    Orion_Evidence_Submit(client, "movement", g_OrionMoveScore[client], action, details);
}

void Orion_Movement_ReportLagExploitIfNeeded(int client, const char[] reason, int tickcount, float currentSpeed)
{
    float alertThreshold = Orion_Config_IntegrityThreshold();
    if (g_OrionMoveScore[client] < alertThreshold && g_OrionMoveLagExploitStreak[client] < ORION_MOVE_LAG_EXPLOIT_STREAK_MIN)
    {
        return;
    }

    int serverTick = GetGameTickCount();
    if (g_OrionMoveLastLagExploitReportTick[client] > 0 && serverTick - g_OrionMoveLastLagExploitReportTick[client] < ORION_MOVE_LAG_EXPLOIT_REPORT_COOLDOWN_TICKS)
    {
        return;
    }

    g_OrionMoveLastLagExploitReportTick[client] = serverTick;

    char details[512];
    Format(
        details,
        sizeof(details),
        "source=movement reason=%s tick=%d lag_exploit_streak=%d command_gap_streak=%d masked_gap_streak=%d masked_drift_streak=%d repeat_streak=%d command_regression_streak=%d command_gap=%d allowed_command_gap=%d tick_drift=%d base_past_drift=%d base_future_drift=%d allowed_past_drift=%d allowed_future_drift=%d speed=%.1f latency_ms=%.1f choke_pct=%.1f loss_pct=%.1f",
        reason,
        tickcount,
        g_OrionMoveLagExploitStreak[client],
        g_OrionMoveCommandGapStreak[client],
        g_OrionMoveNetworkMaskedGapStreak[client],
        g_OrionMoveNetworkMaskedDriftStreak[client],
        g_OrionMoveCommandRepeatStreak[client],
        g_OrionMoveCommandRegressionStreak[client],
        g_OrionMoveLastCommandGap[client],
        g_OrionMoveAllowedCommandGap[client],
        g_OrionMoveLastTickDrift[client],
        g_OrionMoveBasePastTickDrift[client],
        g_OrionMoveBaseFutureTickDrift[client],
        g_OrionMoveAllowedPastTickDrift[client],
        g_OrionMoveAllowedFutureTickDrift[client],
        currentSpeed,
        g_OrionMoveLatencyMs[client],
        g_OrionMoveChokePercent[client],
        g_OrionMoveLossPercent[client]);

    char action[16];
    strcopy(action, sizeof(action), g_OrionMoveScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) && Orion_Movement_IsLagExploitBanEligible(client) ? "ban" : "observe");
    Orion_Evidence_Submit(client, "lag_exploit", g_OrionMoveScore[client], action, details);
}

bool Orion_Movement_IsBanEligible(int client, const char[] reason)
{
    if (StrEqual(reason, "command_gap_choke", false))
    {
        return g_OrionMoveCommandGapStreak[client] >= 2 || g_OrionMoveLagExploitStreak[client] >= ORION_MOVE_LAG_EXPLOIT_STREAK_MIN;
    }

    if (StrEqual(reason, "command_tick_drift", false))
    {
        return g_OrionMoveLagExploitStreak[client] >= ORION_MOVE_LAG_EXPLOIT_STREAK_MIN || Orion_AbsInt(g_OrionMoveLastTickDrift[client]) >= 16;
    }

    if (StrEqual(reason, "repeated_tickcount", false))
    {
        return g_OrionMoveCommandRepeatStreak[client] >= 16;
    }

    if (StrEqual(reason, "command_number_regression", false))
    {
        return g_OrionMoveCommandRegressionStreak[client] >= 6;
    }

    return true;
}

bool Orion_Movement_IsLagExploitBanEligible(int client)
{
    return g_OrionMoveLagExploitStreak[client] >= ORION_MOVE_LAG_EXPLOIT_STREAK_MIN
        && (g_OrionMoveCommandGapStreak[client] >= 2
            || g_OrionMoveCommandRepeatStreak[client] >= 12
            || g_OrionMoveCommandRegressionStreak[client] >= 6
            || g_OrionMoveNetworkMaskedGapStreak[client] >= ORION_MOVE_NETWORK_MASKED_STREAK_MIN
            || g_OrionMoveNetworkMaskedDriftStreak[client] >= ORION_MOVE_NETWORK_MASKED_STREAK_MIN);
}

void Orion_Movement_AddScore(int client, float scoreDelta)
{
    g_OrionMoveScore[client] += scoreDelta;
    if (g_OrionMoveScore[client] > ORION_MOVE_SCORE_MAX)
    {
        g_OrionMoveScore[client] = ORION_MOVE_SCORE_MAX;
    }
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
