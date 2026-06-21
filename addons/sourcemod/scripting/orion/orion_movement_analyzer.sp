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
int g_OrionMoveTickbaseDeviationStreak[MAXPLAYERS + 1];
int g_OrionMoveLastTick[MAXPLAYERS + 1];
int g_OrionMoveLastServerTick[MAXPLAYERS + 1];
int g_OrionMoveLastTickDrift[MAXPLAYERS + 1];
int g_OrionMoveLastTickDriftDeviation[MAXPLAYERS + 1];
int g_OrionMoveLastTickbaseDrift[MAXPLAYERS + 1];
int g_OrionMoveLastTickbaseDriftDeviation[MAXPLAYERS + 1];
int g_OrionMoveAllowedTickbaseDeviation[MAXPLAYERS + 1];
float g_OrionMoveBaselineTickDrift[MAXPLAYERS + 1];
float g_OrionMoveBaselineTickbaseDrift[MAXPLAYERS + 1];
int g_OrionMoveBaselineTickDriftSamples[MAXPLAYERS + 1];
int g_OrionMoveBaselineTickbaseDriftSamples[MAXPLAYERS + 1];
int g_OrionMoveAllowedPastTickDrift[MAXPLAYERS + 1];
int g_OrionMoveAllowedFutureTickDrift[MAXPLAYERS + 1];
int g_OrionMoveBasePastTickDrift[MAXPLAYERS + 1];
int g_OrionMoveBaseFutureTickDrift[MAXPLAYERS + 1];
int g_OrionMoveLastCommandGap[MAXPLAYERS + 1];
int g_OrionMoveAllowedCommandGap[MAXPLAYERS + 1];
int g_OrionMoveLastReportTick[MAXPLAYERS + 1];
int g_OrionMoveLastLagExploitReportTick[MAXPLAYERS + 1];
int g_OrionMoveCommandRateWindowCommands[MAXPLAYERS + 1];
int g_OrionMoveCommandRateWindowStartServerTick[MAXPLAYERS + 1];
int g_OrionMoveCommandRateWindowStartTickbase[MAXPLAYERS + 1];
int g_OrionMoveCommandRateStreak[MAXPLAYERS + 1];
int g_OrionMoveTickbaseRateStreak[MAXPLAYERS + 1];
int g_OrionMoveLastCommandRateAllowed[MAXPLAYERS + 1];
int g_OrionMoveLastCommandRateObserved[MAXPLAYERS + 1];
int g_OrionMoveLastTickbaseAdvance[MAXPLAYERS + 1];
int g_OrionMoveLastAllowedTickbaseAdvance[MAXPLAYERS + 1];
int g_OrionMoveLastPositionTick[MAXPLAYERS + 1];
int g_OrionMoveTeleportJumpStreak[MAXPLAYERS + 1];
int g_OrionMoveLastTriggerTeleportTick[MAXPLAYERS + 1];
int g_OrionMoveFakeAngleStreak[MAXPLAYERS + 1];
bool g_OrionMoveHasLastPosition[MAXPLAYERS + 1];
float g_OrionMoveScore[MAXPLAYERS + 1];
float g_OrionMoveLastSpeed[MAXPLAYERS + 1];
float g_OrionMoveSpeedhackTokens[MAXPLAYERS + 1];
float g_OrionMoveAllowedSpeedhackTokens[MAXPLAYERS + 1];
float g_OrionMoveLatencyMs[MAXPLAYERS + 1];
float g_OrionMoveChokePercent[MAXPLAYERS + 1];
float g_OrionMoveLossPercent[MAXPLAYERS + 1];
float g_OrionMoveCommandRateWindowStartTime[MAXPLAYERS + 1];
float g_OrionMoveLastCommandRatePerSecond[MAXPLAYERS + 1];
float g_OrionMoveLastPosition[MAXPLAYERS + 1][3];
float g_OrionMoveLastTeleportDistance[MAXPLAYERS + 1];
float g_OrionMoveLastAllowedTeleportDistance[MAXPLAYERS + 1];
float g_OrionMoveLastFakeAngleDelta[MAXPLAYERS + 1];

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
#define ORION_MOVE_COMMAND_RATE_SCORE 38.0
#define ORION_MOVE_TICKBASE_RATE_SCORE 28.0
#define ORION_MOVE_TICKBASE_DEVIATION_SCORE 8.0
#define ORION_MOVE_TELEPORT_JUMP_SCORE 80.0
#define ORION_MOVE_FAKE_ANGLE_SCORE 12.0
#define ORION_MOVE_COMMAND_RATE_STREAK_MIN 2
#define ORION_MOVE_TICKBASE_RATE_STREAK_MIN 2
#define ORION_MOVE_TICKBASE_DEVIATION_STREAK_MIN 3
#define ORION_MOVE_TELEPORT_BAN_STREAK_MIN 2

// Tickbase baseline model (kills the #1 false positive).
//
// A legit client's usercmd tickcount is NOT equal to the server tick: it sits
// at a roughly constant offset set by the client clock, latency, and interp.
// Scoring the absolute drift banned honest players (e.g. a steady -23 offset).
// Instead we LEARN each client's natural offset and score only the DEVIATION
// from it. A lag/backtrack/fakeping exploit shows up as a sudden or oscillating
// deviation from the learned baseline; a constant offset converges to baseline
// and scores nothing.
//
// Warmup: number of valid samples folded before the baseline may judge a frame.
#define ORION_MOVE_TICKDRIFT_BASELINE_WARMUP_SAMPLES 64
// EMA weight applied to each in-window sample once warmed up (slow, so a brief
// exploit cannot drag the baseline onto itself; anomalies are never folded).
#define ORION_MOVE_TICKDRIFT_BASELINE_ALPHA 0.05
// |drift| beyond this is a state artifact (just spawned, map change, idle leak),
// never a real exploit: reseed the baseline and never score the frame. ~10s @30t.
#define ORION_MOVE_TICKDRIFT_SANITY_TICKS 300
// Deviation (after baseline) that, with a sustained streak, makes a tick-drift
// finding ban-grade. The baseline absorbs the constant offset, so this is the
// genuine anomaly magnitude, not the raw drift.
#define ORION_MOVE_TICKDRIFT_BAN_DEVIATION_TICKS 12

// Movement buttons are not guaranteed by older include sets, so keep Orion's
// fake-angle projection self-contained and explicit.
#if !defined IN_FORWARD
    #define IN_FORWARD (1 << 3)
#endif

#if !defined IN_BACK
    #define IN_BACK (1 << 4)
#endif

#if !defined IN_MOVELEFT
    #define IN_MOVELEFT (1 << 9)
#endif

#if !defined IN_MOVERIGHT
    #define IN_MOVERIGHT (1 << 10)
#endif

void Orion_Movement_Init()
{
    HookEntityOutput("trigger_teleport", "OnStartTouch", Orion_Movement_OnTriggerTeleportStartTouch);
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
    g_OrionMoveTickbaseDeviationStreak[client] = 0;
    g_OrionMoveLastTick[client] = 0;
    g_OrionMoveLastServerTick[client] = 0;
    g_OrionMoveLastTickDrift[client] = 0;
    g_OrionMoveLastTickDriftDeviation[client] = 0;
    g_OrionMoveLastTickbaseDrift[client] = 0;
    g_OrionMoveLastTickbaseDriftDeviation[client] = 0;
    g_OrionMoveAllowedTickbaseDeviation[client] = 0;
    g_OrionMoveBaselineTickDrift[client] = 0.0;
    g_OrionMoveBaselineTickbaseDrift[client] = 0.0;
    g_OrionMoveBaselineTickDriftSamples[client] = 0;
    g_OrionMoveBaselineTickbaseDriftSamples[client] = 0;
    g_OrionMoveAllowedPastTickDrift[client] = 0;
    g_OrionMoveAllowedFutureTickDrift[client] = 0;
    g_OrionMoveBasePastTickDrift[client] = 0;
    g_OrionMoveBaseFutureTickDrift[client] = 0;
    g_OrionMoveLastCommandGap[client] = 0;
    g_OrionMoveAllowedCommandGap[client] = 0;
    g_OrionMoveLastReportTick[client] = 0;
    g_OrionMoveLastLagExploitReportTick[client] = 0;
    g_OrionMoveCommandRateWindowCommands[client] = 0;
    g_OrionMoveCommandRateWindowStartServerTick[client] = 0;
    g_OrionMoveCommandRateWindowStartTickbase[client] = 0;
    g_OrionMoveCommandRateStreak[client] = 0;
    g_OrionMoveTickbaseRateStreak[client] = 0;
    g_OrionMoveLastCommandRateAllowed[client] = 0;
    g_OrionMoveLastCommandRateObserved[client] = 0;
    g_OrionMoveLastTickbaseAdvance[client] = 0;
    g_OrionMoveLastAllowedTickbaseAdvance[client] = 0;
    g_OrionMoveLastPositionTick[client] = 0;
    g_OrionMoveTeleportJumpStreak[client] = 0;
    g_OrionMoveLastTriggerTeleportTick[client] = 0;
    g_OrionMoveFakeAngleStreak[client] = 0;
    g_OrionMoveHasLastPosition[client] = false;
    g_OrionMoveScore[client] = 0.0;
    g_OrionMoveLastSpeed[client] = 0.0;
    g_OrionMoveSpeedhackTokens[client] = 0.0;
    g_OrionMoveAllowedSpeedhackTokens[client] = 0.0;
    g_OrionMoveLatencyMs[client] = 0.0;
    g_OrionMoveChokePercent[client] = 0.0;
    g_OrionMoveLossPercent[client] = 0.0;
    g_OrionMoveCommandRateWindowStartTime[client] = 0.0;
    g_OrionMoveLastCommandRatePerSecond[client] = 0.0;
    g_OrionMoveLastPosition[client][0] = 0.0;
    g_OrionMoveLastPosition[client][1] = 0.0;
    g_OrionMoveLastPosition[client][2] = 0.0;
    g_OrionMoveLastTeleportDistance[client] = 0.0;
    g_OrionMoveLastAllowedTeleportDistance[client] = 0.0;
    g_OrionMoveLastFakeAngleDelta[client] = 0.0;
}

void Orion_Movement_OnPlayerRunCmd(int client, int buttons, float angles[3], int commandNumber, int& tickcount, int& seed)
{
    if (!Orion_IsAliveHumanPlayer(client))
    {
        Orion_Movement_ResetTransientState(client);
        return;
    }

    if (Orion_Movement_IsExcludedPlayerState(client))
    {
        Orion_Movement_ResetTransientState(client);
        return;
    }

    bool jumpPressed = (buttons & IN_JUMP) != 0;
    bool jumpStarted = jumpPressed && ((g_OrionMoveLastButtons[client] & IN_JUMP) == 0);
    bool jumpReleased = !jumpPressed && ((g_OrionMoveLastButtons[client] & IN_JUMP) != 0);
    bool onGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;
    int previousJumpHeldTicks = g_OrionMoveJumpHeldTicks[client];

    Orion_Movement_UpdateNetworkQuality(client);
    float currentSpeed = Orion_Movement_CurrentSpeed(client);
    int currentTickbase = 0;
    bool hasTickbase = Orion_Movement_TryGetTickbase(client, currentTickbase);

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
    Orion_Movement_ScoreCommandRate(client, commandNumber, tickcount, currentSpeed, currentTickbase, hasTickbase);
    Orion_Movement_ScoreCommandClock(client, buttons, commandNumber, tickcount, seed, currentSpeed);
    Orion_Movement_ScoreSpeedWindow(client, currentSpeed, onGround, angles, tickcount);
    Orion_Movement_ScoreTeleportJump(client, tickcount);
    Orion_Movement_ScoreMoveAngleInconsistency(client, buttons, angles, tickcount, currentSpeed, onGround);

    g_OrionMoveLastButtons[client] = buttons;
    g_OrionMoveLastTick[client] = tickcount;
    g_OrionMoveLastCommandNumber[client] = commandNumber;
    g_OrionMoveLastSpeed[client] = currentSpeed;
    Orion_Movement_Decay(client);
}

void Orion_Movement_ScoreCommandClock(int client, int buttons, int commandNumber, int& tickcount, int& seed, float currentSpeed)
{
    // Synthetic/idle/just-spawned frames (commandNumber or tickcount of 0) carry
    // no real client command. Scoring them is the root of the tick-drift ban
    // storm, so skip all command-clock anomaly scoring here and clear the reuse
    // streak so an idle gap cannot inflate it.
    if (!Orion_IsActiveCommandSample(commandNumber, tickcount))
    {
        g_OrionMoveCommandRepeatStreak[client] = 0;
        return;
    }

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
        Orion_Movement_ScoreTickbaseDrift(client, tickcount, currentSpeed);
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
    g_OrionMoveLastTickDrift[client] = tickDrift;

    // A wildly large drift is a state artifact (just spawned, map change, idle
    // leak), never a real exploit. Reseed the baseline to it and never score
    // the frame; the model relearns the client's offset cleanly from here.
    if (Orion_AbsInt(tickDrift) > ORION_MOVE_TICKDRIFT_SANITY_TICKS)
    {
        g_OrionMoveBaselineTickDrift[client] = float(tickDrift);
        g_OrionMoveBaselineTickDriftSamples[client] = 1;
        g_OrionMoveLastTickDriftDeviation[client] = 0;
        return;
    }

    // Warmup: learn the client's natural, constant offset (clock + latency +
    // interp) before judging any frame against it.
    if (g_OrionMoveBaselineTickDriftSamples[client] < ORION_MOVE_TICKDRIFT_BASELINE_WARMUP_SAMPLES)
    {
        Orion_Movement_FoldTickDriftBaseline(client, tickDrift);
        g_OrionMoveLastTickDriftDeviation[client] = 0;
        return;
    }

    int baselineDrift = RoundToNearest(g_OrionMoveBaselineTickDrift[client]);
    int deviation = tickDrift - baselineDrift;
    g_OrionMoveLastTickDriftDeviation[client] = deviation;

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

    g_OrionMoveAllowedPastTickDrift[client] = allowedPastDriftTicks;
    g_OrionMoveAllowedFutureTickDrift[client] = allowedFutureDriftTicks;
    g_OrionMoveBasePastTickDrift[client] = baseAllowedPastDriftTicks;
    g_OrionMoveBaseFutureTickDrift[client] = baseAllowedFutureDriftTicks;

    // Deviation from the learned baseline is what matters, not the raw drift.
    // Inside the network-aware window this is a normal frame: fold it into the
    // baseline (slow EMA) and only watch for the masked fake-lag pattern.
    if (deviation >= -allowedPastDriftTicks && deviation <= allowedFutureDriftTicks)
    {
        Orion_Movement_FoldTickDriftBaseline(client, tickDrift);

        bool isOutsideBaseWindow = deviation < -baseAllowedPastDriftTicks || deviation > baseAllowedFutureDriftTicks;
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

    // Deviation outside the window: the client clock jumped away from its own
    // learned baseline. This is the genuine lag/backtrack/fakeping signature.
    // Freeze the baseline (do NOT fold this frame) so the exploit cannot train
    // the model onto itself, then score the anomaly magnitude.
    g_OrionMoveLagExploitStreak[client]++;
    int deviationExcessTicks = deviation < 0
        ? (-deviation - allowedPastDriftTicks)
        : (deviation - allowedFutureDriftTicks);
    Orion_Movement_AddScore(client, ORION_MOVE_TICK_DRIFT_SCORE + float(Orion_Movement_MinInt(deviationExcessTicks, 12)));
    if (Orion_Config_HardMitigationEnabled())
    {
        // Clamp back toward the client's learned baseline, not toward raw server
        // tick, so the legit offset is preserved and a clean client never jumps.
        tickcount = deviation < 0
            ? serverTick + baselineDrift - allowedPastDriftTicks
            : serverTick + baselineDrift + allowedFutureDriftTicks;
        if ((buttons & IN_ATTACK) != 0)
        {
            seed = GetRandomInt(1, 2147483647);
        }
    }

    Orion_Movement_ReportIfNeeded(client, "command_tick_drift", tickcount, currentSpeed);
    Orion_Movement_ReportLagExploitIfNeeded(client, "fakeping_tick_drift", tickcount, currentSpeed);
}

void Orion_Movement_ScoreTickbaseDrift(int client, int tickcount, float currentSpeed)
{
    // Lag-exploit / fakeping guard.
    // Default tolerance comes from orion_movement_tickbase_deviation_tolerance_ticks.
    // The cheat mutates m_nTickBase relative to server time; Orion learns each
    // client's normal tickbase offset and scores only sustained deviation.
    int currentTickbase = 0;
    if (!Orion_Movement_TryGetTickbase(client, currentTickbase))
    {
        g_OrionMoveTickbaseDeviationStreak[client] = 0;
        return;
    }

    int serverTick = GetGameTickCount();
    int expectedLatencyAdjustedTickbase = serverTick - Orion_Movement_LatencyAllowanceTicks(client);
    int tickbaseDrift = currentTickbase - expectedLatencyAdjustedTickbase;
    g_OrionMoveLastTickbaseDrift[client] = tickbaseDrift;

    if (Orion_AbsInt(tickbaseDrift) > ORION_MOVE_TICKDRIFT_SANITY_TICKS)
    {
        g_OrionMoveBaselineTickbaseDrift[client] = float(tickbaseDrift);
        g_OrionMoveBaselineTickbaseDriftSamples[client] = 1;
        g_OrionMoveLastTickbaseDriftDeviation[client] = 0;
        g_OrionMoveTickbaseDeviationStreak[client] = 0;
        return;
    }

    if (g_OrionMoveBaselineTickbaseDriftSamples[client] < ORION_MOVE_TICKDRIFT_BASELINE_WARMUP_SAMPLES)
    {
        Orion_Movement_FoldTickbaseDriftBaseline(client, tickbaseDrift);
        g_OrionMoveLastTickbaseDriftDeviation[client] = 0;
        return;
    }

    int baselineDrift = RoundToNearest(g_OrionMoveBaselineTickbaseDrift[client]);
    int deviation = tickbaseDrift - baselineDrift;
    int allowedDeviationTicks = Orion_Config_MovementTickbaseDeviationToleranceTicks()
        + Orion_Movement_MinInt(Orion_Movement_ChokeAllowanceTicks(client), 8)
        + Orion_Movement_MinInt(Orion_Movement_LossAllowanceTicks(client), 4);

    g_OrionMoveLastTickbaseDriftDeviation[client] = deviation;
    g_OrionMoveAllowedTickbaseDeviation[client] = allowedDeviationTicks;

    if (Orion_AbsInt(deviation) <= allowedDeviationTicks)
    {
        Orion_Movement_FoldTickbaseDriftBaseline(client, tickbaseDrift);
        if (g_OrionMoveTickbaseDeviationStreak[client] > 0)
        {
            g_OrionMoveTickbaseDeviationStreak[client]--;
        }
        return;
    }

    g_OrionMoveTickbaseDeviationStreak[client]++;
    g_OrionMoveLagExploitStreak[client]++;

    int excessTicks = Orion_AbsInt(deviation) - allowedDeviationTicks;
    Orion_Movement_AddScore(client, ORION_MOVE_TICKBASE_DEVIATION_SCORE + float(Orion_Movement_MinInt(excessTicks, 12)));
    Orion_Movement_ReportLagExploitIfNeeded(client, "fakeping_tickbase_deviation", tickcount, currentSpeed);
}

void Orion_Movement_FoldTickbaseDriftBaseline(int client, int tickbaseDrift)
{
    int samples = g_OrionMoveBaselineTickbaseDriftSamples[client];
    if (samples < ORION_MOVE_TICKDRIFT_BASELINE_WARMUP_SAMPLES)
    {
        g_OrionMoveBaselineTickbaseDrift[client] =
            (g_OrionMoveBaselineTickbaseDrift[client] * float(samples) + float(tickbaseDrift)) / float(samples + 1);
        g_OrionMoveBaselineTickbaseDriftSamples[client] = samples + 1;
        return;
    }

    g_OrionMoveBaselineTickbaseDrift[client] +=
        ORION_MOVE_TICKDRIFT_BASELINE_ALPHA * (float(tickbaseDrift) - g_OrionMoveBaselineTickbaseDrift[client]);
}

void Orion_Movement_ScoreCommandRate(int client, int commandNumber, int tickcount, float currentSpeed, int currentTickbase, bool hasTickbase)
{
    // Speedhack guard.
    // Default window is orion_movement_command_rate_window_seconds=1.0.
    // Reborn speed modes process too many commands or advance tickbase faster
    // than server ticks; jitter/choke/loss widen the allowance before scoring.
    if (!Orion_IsActiveCommandSample(commandNumber, tickcount))
    {
        return;
    }

    float now = GetGameTime();
    int serverTick = GetGameTickCount();
    if (g_OrionMoveCommandRateWindowStartTime[client] <= 0.0)
    {
        Orion_Movement_ResetCommandRateWindow(client, now, serverTick, currentTickbase, hasTickbase);
        return;
    }

    g_OrionMoveCommandRateWindowCommands[client]++;
    float elapsedSeconds = now - g_OrionMoveCommandRateWindowStartTime[client];
    float commandRateWindowSeconds = Orion_Config_MovementCommandRateWindowSeconds();
    if (elapsedSeconds < commandRateWindowSeconds)
    {
        return;
    }

    float tickInterval = GetTickInterval();
    if (tickInterval <= 0.0)
    {
        Orion_Movement_ResetCommandRateWindow(client, now, serverTick, currentTickbase, hasTickbase);
        return;
    }

    int elapsedServerTicks = serverTick - g_OrionMoveCommandRateWindowStartServerTick[client];
    if (elapsedServerTicks < 0)
    {
        elapsedServerTicks = 0;
    }

    int networkAllowanceTicks = Orion_Config_MovementCommandRateAllowanceTicks()
        + Orion_Movement_MinInt(Orion_Movement_ChokeAllowanceTicks(client), 10)
        + Orion_Movement_MinInt(Orion_Movement_LossAllowanceTicks(client), 6);
    int allowedCommands = RoundToCeil(elapsedSeconds / tickInterval) + networkAllowanceTicks;
    int observedCommands = g_OrionMoveCommandRateWindowCommands[client];

    g_OrionMoveLastCommandRateAllowed[client] = allowedCommands;
    g_OrionMoveLastCommandRateObserved[client] = observedCommands;
    g_OrionMoveLastCommandRatePerSecond[client] = float(observedCommands) / elapsedSeconds;

    if (observedCommands > allowedCommands)
    {
        g_OrionMoveCommandRateStreak[client]++;
        Orion_Movement_AddScore(client, ORION_MOVE_COMMAND_RATE_SCORE + float(Orion_Movement_MinInt(observedCommands - allowedCommands, 16)));
        if (g_OrionMoveCommandRateStreak[client] >= ORION_MOVE_COMMAND_RATE_STREAK_MIN)
        {
            Orion_Movement_ReportIfNeeded(client, "speed_command_rate", tickcount, currentSpeed);
        }
    }
    else if (g_OrionMoveCommandRateStreak[client] > 0)
    {
        g_OrionMoveCommandRateStreak[client]--;
    }

    if (hasTickbase && g_OrionMoveCommandRateWindowStartTickbase[client] > 0)
    {
        int tickbaseAdvance = currentTickbase - g_OrionMoveCommandRateWindowStartTickbase[client];
        int allowedTickbaseAdvance = elapsedServerTicks + Orion_Config_MovementTickbaseRateAllowanceTicks() + networkAllowanceTicks;
        g_OrionMoveLastTickbaseAdvance[client] = tickbaseAdvance;
        g_OrionMoveLastAllowedTickbaseAdvance[client] = allowedTickbaseAdvance;

        if (tickbaseAdvance > allowedTickbaseAdvance)
        {
            g_OrionMoveTickbaseRateStreak[client]++;
            Orion_Movement_AddScore(client, ORION_MOVE_TICKBASE_RATE_SCORE + float(Orion_Movement_MinInt(tickbaseAdvance - allowedTickbaseAdvance, 16)));
            if (g_OrionMoveTickbaseRateStreak[client] >= ORION_MOVE_TICKBASE_RATE_STREAK_MIN)
            {
                Orion_Movement_ReportIfNeeded(client, "speed_command_rate", tickcount, currentSpeed);
            }
        }
        else if (g_OrionMoveTickbaseRateStreak[client] > 0)
        {
            g_OrionMoveTickbaseRateStreak[client]--;
        }
    }

    Orion_Movement_ResetCommandRateWindow(client, now, serverTick, currentTickbase, hasTickbase);
}

void Orion_Movement_ResetCommandRateWindow(int client, float startTime, int startServerTick, int startTickbase, bool hasTickbase)
{
    g_OrionMoveCommandRateWindowStartTime[client] = startTime;
    g_OrionMoveCommandRateWindowStartServerTick[client] = startServerTick;
    g_OrionMoveCommandRateWindowStartTickbase[client] = hasTickbase ? startTickbase : 0;
    g_OrionMoveCommandRateWindowCommands[client] = 1;
}

/**
 * Folds one in-window drift sample into the per-client baseline.
 *
 * During warmup a simple running mean gives a fast, unbiased initial fit; once
 * warmed up a slow EMA tracks gradual clock changes while staying too sluggish
 * for a brief exploit to drag the baseline onto itself. Anomalous frames are
 * never passed here, so the model only ever learns from normal play.
 */
void Orion_Movement_FoldTickDriftBaseline(int client, int tickDrift)
{
    int samples = g_OrionMoveBaselineTickDriftSamples[client];
    if (samples < ORION_MOVE_TICKDRIFT_BASELINE_WARMUP_SAMPLES)
    {
        g_OrionMoveBaselineTickDrift[client] =
            (g_OrionMoveBaselineTickDrift[client] * float(samples) + float(tickDrift)) / float(samples + 1);
        g_OrionMoveBaselineTickDriftSamples[client] = samples + 1;
        return;
    }

    g_OrionMoveBaselineTickDrift[client] +=
        ORION_MOVE_TICKDRIFT_BASELINE_ALPHA * (float(tickDrift) - g_OrionMoveBaselineTickDrift[client]);
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

void Orion_Movement_ScoreTeleportJump(int client, int tickcount)
{
    // Teleport guard.
    // Default floor is orion_movement_teleport_min_horizontal_units=400.
    // Origin cheats create a horizontal jump far beyond max-speed*tickinterval;
    // map trigger_teleport, ladder, noclip, getups, and carry states fail open.
    float currentPosition[3];
    GetClientAbsOrigin(client, currentPosition);

    int serverTick = GetGameTickCount();
    if (!g_OrionMoveHasLastPosition[client])
    {
        Orion_Movement_SavePositionSample(client, currentPosition, serverTick);
        return;
    }

    int elapsedTicks = serverTick - g_OrionMoveLastPositionTick[client];
    if (elapsedTicks <= 0)
    {
        Orion_Movement_SavePositionSample(client, currentPosition, serverTick);
        return;
    }

    float horizontalDelta[3];
    horizontalDelta[0] = currentPosition[0] - g_OrionMoveLastPosition[client][0];
    horizontalDelta[1] = currentPosition[1] - g_OrionMoveLastPosition[client][1];
    horizontalDelta[2] = 0.0;

    float horizontalDistance = SquareRoot((horizontalDelta[0] * horizontalDelta[0]) + (horizontalDelta[1] * horizontalDelta[1]));
    float tickInterval = GetTickInterval();
    float maxLegalDistance = Orion_Config_MovementTeleportMaxSpeedUps()
        * tickInterval
        * float(elapsedTicks)
        * Orion_Config_MovementTeleportAllowanceMultiplier();
    float minTeleportDistance = Orion_Config_MovementTeleportMinHorizontalUnits();
    float allowedDistance = maxLegalDistance > minTeleportDistance ? maxLegalDistance : minTeleportDistance;

    g_OrionMoveLastTeleportDistance[client] = horizontalDistance;
    g_OrionMoveLastAllowedTeleportDistance[client] = allowedDistance;

    if (horizontalDistance <= allowedDistance || Orion_Movement_IsLegitimateTeleportWindow(client, serverTick))
    {
        if (g_OrionMoveTeleportJumpStreak[client] > 0)
        {
            g_OrionMoveTeleportJumpStreak[client]--;
        }
        Orion_Movement_SavePositionSample(client, currentPosition, serverTick);
        return;
    }

    g_OrionMoveTeleportJumpStreak[client]++;
    Orion_Movement_AddScore(client, ORION_MOVE_TELEPORT_JUMP_SCORE);
    Orion_Movement_ReportIfNeeded(client, "teleport_jump", tickcount, Orion_Movement_CurrentSpeed(client));
    Orion_Movement_SavePositionSample(client, currentPosition, serverTick);
}

void Orion_Movement_SavePositionSample(int client, float position[3], int serverTick)
{
    g_OrionMoveHasLastPosition[client] = true;
    g_OrionMoveLastPosition[client][0] = position[0];
    g_OrionMoveLastPosition[client][1] = position[1];
    g_OrionMoveLastPosition[client][2] = position[2];
    g_OrionMoveLastPositionTick[client] = serverTick;
}

void Orion_Movement_ScoreMoveAngleInconsistency(int client, int buttons, float angles[3], int tickcount, float currentSpeed, bool onGround)
{
    // Fake-angle guard.
    // Defaults are orion_movement_fake_angle_min_speed_ups=140 and
    // orion_movement_fake_angle_tolerance_degrees=65. Correct-movement cheats
    // serve one yaw while preserving another world move direction; Orion only
    // scores a persistent ground sample above the speed floor.
    if (!onGround || currentSpeed < Orion_Config_MovementFakeAngleMinSpeedUps())
    {
        if (g_OrionMoveFakeAngleStreak[client] > 0)
        {
            g_OrionMoveFakeAngleStreak[client]--;
        }
        return;
    }

    float intendedForward = 0.0;
    float intendedSide = 0.0;
    if ((buttons & IN_FORWARD) != 0)
    {
        intendedForward += 1.0;
    }
    if ((buttons & IN_BACK) != 0)
    {
        intendedForward -= 1.0;
    }
    if ((buttons & IN_MOVERIGHT) != 0)
    {
        intendedSide += 1.0;
    }
    if ((buttons & IN_MOVELEFT) != 0)
    {
        intendedSide -= 1.0;
    }

    if (intendedForward == 0.0 && intendedSide == 0.0)
    {
        return;
    }

    float servedYawRadians = DegToRad(angles[1]);
    float expectedMove[2];
    expectedMove[0] = (Cosine(servedYawRadians) * intendedForward) + (-Sine(servedYawRadians) * intendedSide);
    expectedMove[1] = (Sine(servedYawRadians) * intendedForward) + (Cosine(servedYawRadians) * intendedSide);

    float velocity[3];
    if (!Orion_Movement_TryGetVelocity(client, velocity))
    {
        return;
    }

    float expectedYaw = RadToDeg(ArcTangent2(expectedMove[1], expectedMove[0]));
    float velocityYaw = RadToDeg(ArcTangent2(velocity[1], velocity[0]));
    float angleDelta = Orion_NormalizeAngleDelta(velocityYaw - expectedYaw);
    g_OrionMoveLastFakeAngleDelta[client] = angleDelta;

    if (angleDelta <= Orion_Config_MovementFakeAngleToleranceDegrees())
    {
        if (g_OrionMoveFakeAngleStreak[client] > 0)
        {
            g_OrionMoveFakeAngleStreak[client]--;
        }
        return;
    }

    g_OrionMoveFakeAngleStreak[client]++;
    if (g_OrionMoveFakeAngleStreak[client] < Orion_Config_MovementFakeAngleStreakTicks())
    {
        return;
    }

    Orion_Movement_AddScore(client, ORION_MOVE_FAKE_ANGLE_SCORE);
    Orion_Movement_ReportIfNeeded(client, "move_angle_inconsistency", tickcount, currentSpeed);
}

float Orion_Movement_CurrentSpeed(int client)
{
    float currentVelocity[3];
    if (!Orion_Movement_TryGetVelocity(client, currentVelocity))
    {
        return 0.0;
    }
    return SquareRoot((currentVelocity[0] * currentVelocity[0]) + (currentVelocity[1] * currentVelocity[1]));
}

bool Orion_Movement_TryGetVelocity(int client, float velocity[3])
{
    if (!HasEntProp(client, Prop_Data, "m_vecVelocity"))
    {
        velocity[0] = 0.0;
        velocity[1] = 0.0;
        velocity[2] = 0.0;
        return false;
    }

    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    return true;
}

bool Orion_Movement_TryGetTickbase(int client, int& tickbase)
{
    if (HasEntProp(client, Prop_Send, "m_nTickBase"))
    {
        tickbase = GetEntProp(client, Prop_Send, "m_nTickBase");
        return true;
    }

    if (HasEntProp(client, Prop_Data, "m_nTickBase"))
    {
        tickbase = GetEntProp(client, Prop_Data, "m_nTickBase");
        return true;
    }

    tickbase = 0;
    return false;
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

public void Orion_Movement_OnTriggerTeleportStartTouch(const char[] output, int caller, int activator, float delay)
{
    if (!Orion_IsHumanPlayer(activator))
    {
        return;
    }

    g_OrionMoveLastTriggerTeleportTick[activator] = GetGameTickCount();
}

void Orion_Movement_ResetTransientState(int client)
{
    g_OrionMoveCommandRepeatStreak[client] = 0;
    g_OrionMoveCommandRegressionStreak[client] = 0;
    g_OrionMoveCommandGapStreak[client] = 0;
    g_OrionMoveNetworkMaskedGapStreak[client] = 0;
    g_OrionMoveNetworkMaskedDriftStreak[client] = 0;
    g_OrionMoveTickbaseDeviationStreak[client] = 0;
    g_OrionMoveCommandRateWindowStartTime[client] = 0.0;
    g_OrionMoveCommandRateWindowCommands[client] = 0;
    g_OrionMoveHasLastPosition[client] = false;
    g_OrionMoveTeleportJumpStreak[client] = 0;
    g_OrionMoveFakeAngleStreak[client] = 0;
}

bool Orion_Movement_IsLegitimateTeleportWindow(int client, int serverTick)
{
    return Orion_Movement_IsExcludedPlayerState(client)
        || (g_OrionMoveLastTriggerTeleportTick[client] > 0 && serverTick - g_OrionMoveLastTriggerTeleportTick[client] <= 3);
}

bool Orion_Movement_IsExcludedPlayerState(int client)
{
    int team = GetClientTeam(client);
    if (team <= ORION_TEAM_SPECTATOR)
    {
        return true;
    }

    MoveType moveType = GetEntityMoveType(client);
    if (moveType == MOVETYPE_LADDER || moveType == MOVETYPE_NOCLIP || moveType == MOVETYPE_OBSERVER)
    {
        return true;
    }

    if (team == ORION_TEAM_INFECTED && Orion_Movement_GetSendPropInt(client, "m_isGhost") > 0)
    {
        return true;
    }

    if (team != ORION_TEAM_SURVIVOR)
    {
        return false;
    }

    return Orion_Movement_GetSendPropInt(client, "m_isIncapacitated") > 0
        || Orion_Movement_GetSendPropInt(client, "m_isHangingFromLedge") > 0
        || Orion_Movement_GetSendPropInt(client, "m_isGettingUp") > 0
        || Orion_Movement_GetSendPropEntity(client, "m_tongueOwner") > 0
        || Orion_Movement_GetSendPropEntity(client, "m_pounceAttacker") > 0
        || Orion_Movement_GetSendPropEntity(client, "m_jockeyAttacker") > 0
        || Orion_Movement_GetSendPropEntity(client, "m_carryAttacker") > 0
        || Orion_Movement_GetSendPropEntity(client, "m_pummelAttacker") > 0;
}

int Orion_Movement_GetSendPropInt(int client, const char[] propertyName)
{
    if (!HasEntProp(client, Prop_Send, propertyName))
    {
        return 0;
    }

    return GetEntProp(client, Prop_Send, propertyName);
}

int Orion_Movement_GetSendPropEntity(int client, const char[] propertyName)
{
    if (!HasEntProp(client, Prop_Send, propertyName))
    {
        return 0;
    }

    return GetEntPropEnt(client, Prop_Send, propertyName);
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

    char details[768];
    Format(
        details,
        sizeof(details),
        "reason=%s tick=%d perfect_jump_streak=%d jump_release_streak=%d repeat_streak=%d command_regression_streak=%d command_gap_streak=%d masked_gap_streak=%d masked_drift_streak=%d lag_exploit_streak=%d tickbase_deviation_streak=%d command_rate_streak=%d tickbase_rate_streak=%d teleport_streak=%d fake_angle_streak=%d command_gap=%d allowed_command_gap=%d tick_drift=%d tick_drift_deviation=%d baseline_drift=%.1f base_past_drift=%d base_future_drift=%d allowed_past_drift=%d allowed_future_drift=%d tickbase_drift=%d tickbase_deviation=%d allowed_tickbase_deviation=%d speed=%.1f speedhack_tokens=%.1f allowed_speedhack_tokens=%.1f command_rate=%.1f observed_commands=%d allowed_commands=%d tickbase_advance=%d allowed_tickbase_advance=%d teleport_distance=%.1f allowed_teleport_distance=%.1f fake_angle_delta=%.1f latency_ms=%.1f choke_pct=%.1f loss_pct=%.1f",
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
        g_OrionMoveTickbaseDeviationStreak[client],
        g_OrionMoveCommandRateStreak[client],
        g_OrionMoveTickbaseRateStreak[client],
        g_OrionMoveTeleportJumpStreak[client],
        g_OrionMoveFakeAngleStreak[client],
        g_OrionMoveLastCommandGap[client],
        g_OrionMoveAllowedCommandGap[client],
        g_OrionMoveLastTickDrift[client],
        g_OrionMoveLastTickDriftDeviation[client],
        g_OrionMoveBaselineTickDrift[client],
        g_OrionMoveBasePastTickDrift[client],
        g_OrionMoveBaseFutureTickDrift[client],
        g_OrionMoveAllowedPastTickDrift[client],
        g_OrionMoveAllowedFutureTickDrift[client],
        g_OrionMoveLastTickbaseDrift[client],
        g_OrionMoveLastTickbaseDriftDeviation[client],
        g_OrionMoveAllowedTickbaseDeviation[client],
        currentSpeed,
        g_OrionMoveSpeedhackTokens[client],
        g_OrionMoveAllowedSpeedhackTokens[client],
        g_OrionMoveLastCommandRatePerSecond[client],
        g_OrionMoveLastCommandRateObserved[client],
        g_OrionMoveLastCommandRateAllowed[client],
        g_OrionMoveLastTickbaseAdvance[client],
        g_OrionMoveLastAllowedTickbaseAdvance[client],
        g_OrionMoveLastTeleportDistance[client],
        g_OrionMoveLastAllowedTeleportDistance[client],
        g_OrionMoveLastFakeAngleDelta[client],
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

    char details[768];
    Format(
        details,
        sizeof(details),
        "source=movement reason=%s tick=%d lag_exploit_streak=%d command_gap_streak=%d masked_gap_streak=%d masked_drift_streak=%d tickbase_deviation_streak=%d repeat_streak=%d command_regression_streak=%d command_gap=%d allowed_command_gap=%d tick_drift=%d tick_drift_deviation=%d base_past_drift=%d base_future_drift=%d allowed_past_drift=%d allowed_future_drift=%d tickbase_drift=%d tickbase_deviation=%d allowed_tickbase_deviation=%d speed=%.1f latency_ms=%.1f choke_pct=%.1f loss_pct=%.1f",
        reason,
        tickcount,
        g_OrionMoveLagExploitStreak[client],
        g_OrionMoveCommandGapStreak[client],
        g_OrionMoveNetworkMaskedGapStreak[client],
        g_OrionMoveNetworkMaskedDriftStreak[client],
        g_OrionMoveTickbaseDeviationStreak[client],
        g_OrionMoveCommandRepeatStreak[client],
        g_OrionMoveCommandRegressionStreak[client],
        g_OrionMoveLastCommandGap[client],
        g_OrionMoveAllowedCommandGap[client],
        g_OrionMoveLastTickDrift[client],
        g_OrionMoveLastTickDriftDeviation[client],
        g_OrionMoveBasePastTickDrift[client],
        g_OrionMoveBaseFutureTickDrift[client],
        g_OrionMoveAllowedPastTickDrift[client],
        g_OrionMoveAllowedFutureTickDrift[client],
        g_OrionMoveLastTickbaseDrift[client],
        g_OrionMoveLastTickbaseDriftDeviation[client],
        g_OrionMoveAllowedTickbaseDeviation[client],
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
        // Ban-grade only when the client clock sustains a real deviation from
        // its own learned baseline. A constant offset converges to baseline and
        // yields deviation 0, so it can never reach this gate (the old absolute
        // `|drift| >= 16` check is what banned honest, high-latency players).
        return g_OrionMoveLagExploitStreak[client] >= ORION_MOVE_LAG_EXPLOIT_STREAK_MIN
            && Orion_AbsInt(g_OrionMoveLastTickDriftDeviation[client]) >= ORION_MOVE_TICKDRIFT_BAN_DEVIATION_TICKS;
    }

    if (StrEqual(reason, "repeated_tickcount", false))
    {
        return g_OrionMoveCommandRepeatStreak[client] >= 16;
    }

    if (StrEqual(reason, "command_number_regression", false))
    {
        return g_OrionMoveCommandRegressionStreak[client] >= 6;
    }

    if (StrEqual(reason, "speed_command_rate", false))
    {
        return g_OrionMoveCommandRateStreak[client] >= ORION_MOVE_COMMAND_RATE_STREAK_MIN
            || g_OrionMoveTickbaseRateStreak[client] >= ORION_MOVE_TICKBASE_RATE_STREAK_MIN;
    }

    if (StrEqual(reason, "teleport_jump", false))
    {
        return g_OrionMoveTeleportJumpStreak[client] >= ORION_MOVE_TELEPORT_BAN_STREAK_MIN;
    }

    if (StrEqual(reason, "move_angle_inconsistency", false))
    {
        return g_OrionMoveFakeAngleStreak[client] >= Orion_Config_MovementFakeAngleStreakTicks() * 2;
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
            || g_OrionMoveNetworkMaskedDriftStreak[client] >= ORION_MOVE_NETWORK_MASKED_STREAK_MIN
            || g_OrionMoveTickbaseDeviationStreak[client] >= ORION_MOVE_TICKBASE_DEVIATION_STREAK_MIN);
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
