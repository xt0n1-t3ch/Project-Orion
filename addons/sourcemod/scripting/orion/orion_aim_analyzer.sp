#define ORION_AIM_HISTORY_SIZE 12
#define ORION_AIM_DELTA_WINDOW_SIZE 6
#define ORION_AIM_REPEAT_MIN_DELTA 6.0
#define ORION_AIM_REPEAT_EPSILON 0.025
#define ORION_AIM_SNAP2_HIGH_DELTA 70.0
#define ORION_AIM_WINDOW_HIGH_DELTA 155.0
#define ORION_AIM_JOIN_GRACE_SECONDS 12.0
#define ORION_AIM_RECENT_CONTEXT_TICKS 10
#define ORION_AIM_MAX_SCORE 100.0
#define ORION_AIM_PLAYER_CENTER_Z 36.0
#define ORION_AIM_RAPIDFIRE_NEXT_ATTACK_GRACE 0.01
#define ORION_AIM_TIGHT_HIT_RECENT_TICKS 24

float g_OrionAimLastAngles[MAXPLAYERS + 1][3];
float g_OrionAimLastDelta[MAXPLAYERS + 1];
float g_OrionAimLastPitchDelta[MAXPLAYERS + 1];
float g_OrionAimLastYawDelta[MAXPLAYERS + 1];
float g_OrionAimRecentSnap2Delta[MAXPLAYERS + 1];
float g_OrionAimRecentWindowDelta[MAXPLAYERS + 1];
float g_OrionAimHistoryAngles[MAXPLAYERS + 1][ORION_AIM_HISTORY_SIZE][3];
float g_OrionAimHistoryDelta[MAXPLAYERS + 1][ORION_AIM_HISTORY_SIZE];
int g_OrionAimHistoryTarget[MAXPLAYERS + 1][ORION_AIM_HISTORY_SIZE];
int g_OrionAimHistoryMouse[MAXPLAYERS + 1][ORION_AIM_HISTORY_SIZE];
int g_OrionAimHistoryButtons[MAXPLAYERS + 1][ORION_AIM_HISTORY_SIZE];
int g_OrionAimHistoryTick[MAXPLAYERS + 1][ORION_AIM_HISTORY_SIZE];
int g_OrionAimHistoryIndex[MAXPLAYERS + 1];
int g_OrionAimHistoryCount[MAXPLAYERS + 1];
int g_OrionAimLastButtons[MAXPLAYERS + 1];
int g_OrionAimLastTarget[MAXPLAYERS + 1];
int g_OrionAimTargetTicks[MAXPLAYERS + 1];
int g_OrionAimLastTick[MAXPLAYERS + 1];
int g_OrionAimLastMouseMagnitude[MAXPLAYERS + 1];
int g_OrionAimAttackStartTick[MAXPLAYERS + 1];
int g_OrionAimOneTickShotStreak[MAXPLAYERS + 1];
int g_OrionAimAngleRepeatStreak[MAXPLAYERS + 1];
int g_OrionAimTriggerSupportSignal[MAXPLAYERS + 1];
int g_OrionAimLastFireTick[MAXPLAYERS + 1];
int g_OrionAimLastFireWeaponId[MAXPLAYERS + 1];
int g_OrionAimBurstFireTicks[MAXPLAYERS + 1];
int g_OrionAimLastOutcomeTick[MAXPLAYERS + 1];
int g_OrionAimLastOutcomeDamage[MAXPLAYERS + 1];
int g_OrionAimLastOutcomeHitGroup[MAXPLAYERS + 1];
int g_OrionAimAttackToggleStreak[MAXPLAYERS + 1];
int g_OrionAimRapidfireCadenceStreak[MAXPLAYERS + 1];
int g_OrionAimRapidfireNextAttackStreak[MAXPLAYERS + 1];
int g_OrionAimRapidfireHitStreak[MAXPLAYERS + 1];
int g_OrionAimSilentMismatchHits[MAXPLAYERS + 1];
int g_OrionAimNorecoilHitStreak[MAXPLAYERS + 1];
int g_OrionAimLaserTightHitStreak[MAXPLAYERS + 1];
int g_OrionAimLastTightHitTick[MAXPLAYERS + 1];
float g_OrionAimLastSilentMismatchDegrees[MAXPLAYERS + 1];
float g_OrionAimBurstStartPitch[MAXPLAYERS + 1];
float g_OrionAimBurstMinPitch[MAXPLAYERS + 1];
float g_OrionAimBurstMaxPitch[MAXPLAYERS + 1];
float g_OrionAimBurstPitchMotion[MAXPLAYERS + 1];
float g_OrionAimScore[MAXPLAYERS + 1];
float g_OrionAimReadyAt[MAXPLAYERS + 1];
bool g_OrionAimHasAngles[MAXPLAYERS + 1];
bool g_OrionAimLastOutcomeHeadshot[MAXPLAYERS + 1];
bool g_OrionAimLastOutcomeNoSpreadSignal[MAXPLAYERS + 1];
char g_OrionAimLastFireWeapon[MAXPLAYERS + 1][32];
char g_OrionAimLastOutcomeWeapon[MAXPLAYERS + 1][32];

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
    g_OrionAimLastMouseMagnitude[client] = 0;
    g_OrionAimAttackStartTick[client] = 0;
    g_OrionAimOneTickShotStreak[client] = 0;
    g_OrionAimAngleRepeatStreak[client] = 0;
    g_OrionAimTriggerSupportSignal[client] = 0;
    g_OrionAimLastFireTick[client] = 0;
    g_OrionAimLastFireWeaponId[client] = 0;
    g_OrionAimBurstFireTicks[client] = 0;
    g_OrionAimLastOutcomeTick[client] = 0;
    g_OrionAimLastOutcomeDamage[client] = 0;
    g_OrionAimLastOutcomeHitGroup[client] = 0;
    g_OrionAimAttackToggleStreak[client] = 0;
    g_OrionAimRapidfireCadenceStreak[client] = 0;
    g_OrionAimRapidfireNextAttackStreak[client] = 0;
    g_OrionAimRapidfireHitStreak[client] = 0;
    g_OrionAimSilentMismatchHits[client] = 0;
    g_OrionAimNorecoilHitStreak[client] = 0;
    g_OrionAimLaserTightHitStreak[client] = 0;
    g_OrionAimLastTightHitTick[client] = 0;
    g_OrionAimLastOutcomeHeadshot[client] = false;
    g_OrionAimLastOutcomeNoSpreadSignal[client] = false;
    g_OrionAimLastSilentMismatchDegrees[client] = 0.0;
    g_OrionAimBurstStartPitch[client] = 0.0;
    g_OrionAimBurstMinPitch[client] = 0.0;
    g_OrionAimBurstMaxPitch[client] = 0.0;
    g_OrionAimBurstPitchMotion[client] = 0.0;
    g_OrionAimScore[client] = 0.0;
    g_OrionAimReadyAt[client] = GetGameTime() + ORION_AIM_JOIN_GRACE_SECONDS;
    g_OrionAimLastDelta[client] = 0.0;
    g_OrionAimLastPitchDelta[client] = 0.0;
    g_OrionAimLastYawDelta[client] = 0.0;
    g_OrionAimRecentSnap2Delta[client] = 0.0;
    g_OrionAimRecentWindowDelta[client] = 0.0;
    g_OrionAimLastAngles[client][0] = 0.0;
    g_OrionAimLastAngles[client][1] = 0.0;
    g_OrionAimLastAngles[client][2] = 0.0;
    g_OrionAimHistoryIndex[client] = 0;
    g_OrionAimHistoryCount[client] = 0;
    strcopy(g_OrionAimLastFireWeapon[client], sizeof(g_OrionAimLastFireWeapon[]), "unknown");
    strcopy(g_OrionAimLastOutcomeWeapon[client], sizeof(g_OrionAimLastOutcomeWeapon[]), "unknown");

    for (int sample = 0; sample < ORION_AIM_HISTORY_SIZE; sample++)
    {
        g_OrionAimHistoryAngles[client][sample][0] = 0.0;
        g_OrionAimHistoryAngles[client][sample][1] = 0.0;
        g_OrionAimHistoryAngles[client][sample][2] = 0.0;
        g_OrionAimHistoryDelta[client][sample] = 0.0;
        g_OrionAimHistoryTarget[client][sample] = 0;
        g_OrionAimHistoryMouse[client][sample] = 0;
        g_OrionAimHistoryButtons[client][sample] = 0;
        g_OrionAimHistoryTick[client][sample] = 0;
    }
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
    Orion_Aim_RecordAttackCadence(client, attackPressed, attackStarted, attackStopped);
    Orion_Aim_RecordBurstPitch(client, attackPressed, pitchDelta, angles[0]);

    if (Orion_Aim_IsInJoinGrace(client))
    {
        Orion_Aim_RecordHistory(client, angles, target, 0.0, mouseMagnitude, buttons, tickcount);
        Orion_Aim_StoreCommandSnapshot(client, angles, target, 0.0, 0.0, 0.0, buttons, tickcount, mouseMagnitude);
        return;
    }

    Orion_Aim_ScoreAngleHistory(client, target, pitchDelta, yawDelta, totalDelta, mouseMagnitude, tickcount);

    if (attackStarted)
    {
        g_OrionAimAttackStartTick[client] = tickcount;
        Orion_Aim_ScoreAttackWindow(client, target, totalDelta, mouseMagnitude, tickcount);
    }
    else if (attackStopped)
    {
        Orion_Aim_ScoreAttackRelease(client, tickcount);
    }

    Orion_Aim_RecordHistory(client, angles, target, totalDelta, mouseMagnitude, buttons, tickcount);

    Orion_Aim_StoreCommandSnapshot(client, angles, target, totalDelta, pitchDelta, yawDelta, buttons, tickcount, mouseMagnitude);

    Orion_Aim_Decay(client);
}

// Tracks the one-tick attack toggles rapidfire/autoshoot uses to manufacture
// fire events. It is only scored later when weapon_fire/player_hurt confirms
// the toggle cadence produced real offensive output.
void Orion_Aim_RecordAttackCadence(int client, bool attackPressed, bool attackStarted, bool attackStopped)
{
    if (attackStarted || attackStopped)
    {
        g_OrionAimAttackToggleStreak[client]++;
        return;
    }

    if (!attackPressed && g_OrionAimAttackToggleStreak[client] > 0)
    {
        g_OrionAimAttackToggleStreak[client]--;
    }
}

// A no-recoil compensator keeps the served pitch almost flat across a sustained
// burst. This records the pitch span and total pitch motion; scoring waits for
// hits so normal aim practice is not punished by view-angle shape alone.
void Orion_Aim_RecordBurstPitch(int client, bool attackPressed, float pitchDelta, float currentPitch)
{
    if (!attackPressed)
    {
        return;
    }

    if (g_OrionAimBurstFireTicks[client] <= 1)
    {
        g_OrionAimBurstStartPitch[client] = currentPitch;
        g_OrionAimBurstMinPitch[client] = currentPitch;
        g_OrionAimBurstMaxPitch[client] = currentPitch;
        g_OrionAimBurstPitchMotion[client] = 0.0;
        return;
    }

    if (currentPitch < g_OrionAimBurstMinPitch[client])
    {
        g_OrionAimBurstMinPitch[client] = currentPitch;
    }
    else if (currentPitch > g_OrionAimBurstMaxPitch[client])
    {
        g_OrionAimBurstMaxPitch[client] = currentPitch;
    }

    g_OrionAimBurstPitchMotion[client] += pitchDelta;
}

void Orion_Aim_StoreCommandSnapshot(int client, float angles[3], int target, float totalDelta, float pitchDelta, float yawDelta, int buttons, int tickcount, int mouseMagnitude)
{
    g_OrionAimLastAngles[client][0] = angles[0];
    g_OrionAimLastAngles[client][1] = angles[1];
    g_OrionAimLastAngles[client][2] = angles[2];
    g_OrionAimLastDelta[client] = totalDelta;
    g_OrionAimLastPitchDelta[client] = pitchDelta;
    g_OrionAimLastYawDelta[client] = yawDelta;
    g_OrionAimLastButtons[client] = buttons;
    g_OrionAimLastTarget[client] = target;
    g_OrionAimLastTick[client] = tickcount;
    g_OrionAimLastMouseMagnitude[client] = mouseMagnitude;
    g_OrionAimHasAngles[client] = true;
}

void Orion_Aim_RecordHistory(int client, float angles[3], int target, float totalDelta, int mouseMagnitude, int buttons, int tickcount)
{
    int historyIndex = g_OrionAimHistoryIndex[client];
    g_OrionAimHistoryAngles[client][historyIndex][0] = angles[0];
    g_OrionAimHistoryAngles[client][historyIndex][1] = angles[1];
    g_OrionAimHistoryAngles[client][historyIndex][2] = angles[2];
    g_OrionAimHistoryDelta[client][historyIndex] = totalDelta;
    g_OrionAimHistoryTarget[client][historyIndex] = target;
    g_OrionAimHistoryMouse[client][historyIndex] = mouseMagnitude;
    g_OrionAimHistoryButtons[client][historyIndex] = buttons;
    g_OrionAimHistoryTick[client][historyIndex] = tickcount;

    g_OrionAimHistoryIndex[client] = (historyIndex + 1) % ORION_AIM_HISTORY_SIZE;
    if (g_OrionAimHistoryCount[client] < ORION_AIM_HISTORY_SIZE)
    {
        g_OrionAimHistoryCount[client]++;
    }
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

    Orion_Aim_AddScore(client, hasImpossiblePitch && hasImpossibleRoll ? 35.0 : 22.0);

    char details[256];
    Format(details, sizeof(details), "reason=invalid_angles pitch=%.2f yaw=%.2f roll=%.2f tick=%d patched=%d", angles[0], angles[1], angles[2], tickcount, Orion_Config_HardMitigationEnabled());
    Orion_Evidence_Submit(client, "angle_guard", g_OrionAimScore[client], "observe", details);

    if (Orion_Config_HardMitigationEnabled())
    {
        if (angles[0] > 89.0)
        {
            angles[0] = 89.0;
        }
        else if (angles[0] < -89.0)
        {
            angles[0] = -89.0;
        }

        if (angles[2] > 50.0 || angles[2] < -50.0)
        {
            angles[2] = 0.0;
        }
    }
}

void Orion_Aim_ScoreAngleHistory(int client, int target, float pitchDelta, float yawDelta, float totalDelta, int mouseMagnitude, int tickcount)
{
    if (!g_OrionAimHasAngles[client])
    {
        return;
    }

    bool hasValidTarget = Orion_Aim_IsValidTarget(target);
    bool hasRecentOffensiveContext = Orion_Aim_HasRecentOffensiveContext(client, tickcount);
    if (!hasValidTarget && !hasRecentOffensiveContext)
    {
        g_OrionAimAngleRepeatStreak[client] = 0;
        if (g_OrionAimTriggerSupportSignal[client] > 0 && mouseMagnitude > 4)
        {
            g_OrionAimTriggerSupportSignal[client]--;
        }
        return;
    }

    float snap2Delta = totalDelta + g_OrionAimLastDelta[client];
    float windowDelta = totalDelta + Orion_Aim_GetWindowTotalDelta(client, ORION_AIM_DELTA_WINDOW_SIZE);
    g_OrionAimRecentSnap2Delta[client] = snap2Delta;
    g_OrionAimRecentWindowDelta[client] = windowDelta;

    if (totalDelta >= ORION_AIM_REPEAT_MIN_DELTA
        && FloatAbs(pitchDelta - g_OrionAimLastPitchDelta[client]) <= ORION_AIM_REPEAT_EPSILON
        && FloatAbs(yawDelta - g_OrionAimLastYawDelta[client]) <= ORION_AIM_REPEAT_EPSILON)
    {
        g_OrionAimAngleRepeatStreak[client]++;
    }
    else
    {
        g_OrionAimAngleRepeatStreak[client] = 0;
    }

    float scoreDelta = 0.0;

    // A sharp 2-tick snap is only suspicious when it lands ON a valid target the
    // player just acquired (target_ticks<=1). Raw turn magnitude with no target
    // under the crosshair is a normal human flick and must NOT score — that, plus
    // treating mouse==0 as proof, was the 180-degree false positive that banned
    // legit players. mouse==0 is unreliable in L4D2 (controllers/configs report
    // it legitimately), so here it only nudges the weight; it never carries a ban
    // on its own. The bare accumulated-window-delta path is removed entirely; the
    // real silent-aim signal is the served-angle-vs-hit mismatch (aim integrity
    // phase) and the fire-tick attack window, not how far the view swept.
    if (hasValidTarget && g_OrionAimTargetTicks[client] <= 1 && snap2Delta >= ORION_AIM_SNAP2_HIGH_DELTA)
    {
        scoreDelta += mouseMagnitude <= 2 ? 12.0 : 8.0;
    }

    if (g_OrionAimAngleRepeatStreak[client] >= 5)
    {
        scoreDelta += 20.0;
    }
    else if (g_OrionAimAngleRepeatStreak[client] >= 3)
    {
        scoreDelta += 12.0;
    }

    if (hasValidTarget && g_OrionAimTargetTicks[client] <= 1 && totalDelta >= 18.0 && mouseMagnitude <= 1)
    {
        g_OrionAimTriggerSupportSignal[client]++;
        scoreDelta += g_OrionAimTriggerSupportSignal[client] >= 2 ? 12.0 : 6.0;
    }
    else if (g_OrionAimTriggerSupportSignal[client] > 0 && mouseMagnitude > 4)
    {
        g_OrionAimTriggerSupportSignal[client]--;
    }

    if (scoreDelta > 0.0)
    {
        Orion_Aim_AddScore(client, scoreDelta);
        Orion_Aim_ReportIfNeeded(client, "angle_history", target, totalDelta, mouseMagnitude, tickcount);
    }
}

float Orion_Aim_GetWindowTotalDelta(int client, int requestedSampleCount)
{
    int sampleCount = requestedSampleCount;
    if (sampleCount > g_OrionAimHistoryCount[client])
    {
        sampleCount = g_OrionAimHistoryCount[client];
    }

    float windowDelta = 0.0;
    for (int sampleAge = 0; sampleAge < sampleCount; sampleAge++)
    {
        int historySlot = Orion_Aim_GetHistorySlot(client, sampleAge);
        if (historySlot >= 0)
        {
            windowDelta += g_OrionAimHistoryDelta[client][historySlot];
        }
    }

    return windowDelta;
}

int Orion_Aim_GetHistorySlot(int client, int sampleAge)
{
    if (sampleAge < 0 || sampleAge >= g_OrionAimHistoryCount[client])
    {
        return -1;
    }

    int historySlot = g_OrionAimHistoryIndex[client] - 1 - sampleAge;
    while (historySlot < 0)
    {
        historySlot += ORION_AIM_HISTORY_SIZE;
    }

    return historySlot;
}

void Orion_Aim_ScoreAttackWindow(int client, int target, float angleDelta, int mouseMagnitude, int tickcount)
{
    if (!Orion_Aim_IsValidTarget(target))
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

    if (mouseMagnitude <= 1 && g_OrionAimTargetTicks[client] <= 1)
    {
        g_OrionAimTriggerSupportSignal[client]++;
        if (g_OrionAimTriggerSupportSignal[client] >= 3)
        {
            scoreDelta += 15.0;
        }
    }

    if (GetClientTeam(target) == ORION_TEAM_INFECTED)
    {
        scoreDelta += 5.0;
    }

    if (scoreDelta > 0.0)
    {
        Orion_Aim_AddScore(client, scoreDelta);
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
            Orion_Aim_AddScore(client, 15.0);
            Orion_Aim_ReportIfNeeded(client, "one_tick_attack_streak", g_OrionAimLastTarget[client], g_OrionAimLastDelta[client], 0, tickcount);
        }
    }
    else if (attackTicks > 4)
    {
        g_OrionAimOneTickShotStreak[client] = 0;
        if (g_OrionAimTriggerSupportSignal[client] > 0)
        {
            g_OrionAimTriggerSupportSignal[client]--;
        }
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

    char weaponName[32];
    event.GetString("weapon", weaponName, sizeof(weaponName), "unknown");
    int weaponId = event.GetInt("weaponid", 0);
    Orion_Aim_ScoreRapidfireFireSupport(client, weaponName, g_OrionAimLastTick[client]);
    Orion_Aim_RecordWeaponFire(client, weaponName, weaponId, g_OrionAimLastTick[client]);

    if (g_OrionAimLastDelta[client] >= 30.0)
    {
        Orion_Aim_AddScore(client, 8.0);
        Orion_Aim_ReportIfNeeded(client, "weapon_fire_delta", g_OrionAimLastTarget[client], g_OrionAimLastDelta[client], 0, g_OrionAimLastTick[client]);
    }

    if (g_OrionAimTriggerSupportSignal[client] >= 3 && g_OrionAimLastMouseMagnitude[client] <= 1)
    {
        Orion_Aim_AddScore(client, 10.0);
        Orion_Aim_ReportIfNeeded(client, "trigger_autoshoot_fire", g_OrionAimLastTarget[client], g_OrionAimLastDelta[client], g_OrionAimLastMouseMagnitude[client], g_OrionAimLastTick[client]);
    }
}

void Orion_Aim_RecordWeaponFire(int client, const char[] weaponName, int weaponId, int tickcount)
{
    int fireIntervalTicks = g_OrionAimLastFireTick[client] > 0 ? tickcount - g_OrionAimLastFireTick[client] : -1;
    if (fireIntervalTicks > 0 && fireIntervalTicks <= 2)
    {
        g_OrionAimBurstFireTicks[client]++;
    }
    else
    {
        g_OrionAimBurstFireTicks[client] = 1;
        g_OrionAimNorecoilHitStreak[client] = 0;
        g_OrionAimBurstStartPitch[client] = g_OrionAimLastAngles[client][0];
        g_OrionAimBurstMinPitch[client] = g_OrionAimLastAngles[client][0];
        g_OrionAimBurstMaxPitch[client] = g_OrionAimLastAngles[client][0];
        g_OrionAimBurstPitchMotion[client] = 0.0;
    }

    g_OrionAimLastFireTick[client] = tickcount;
    g_OrionAimLastFireWeaponId[client] = weaponId;
    strcopy(g_OrionAimLastFireWeapon[client], sizeof(g_OrionAimLastFireWeapon[]), weaponName);
}

// Scores only support signals for rapidfire here. The finding is emitted from a
// later hit/death correlation path so a dry weapon_fire spam cannot ban alone.
void Orion_Aim_ScoreRapidfireFireSupport(int client, const char[] weaponName, int tickcount)
{
    if (!Orion_Config_AimIntegrityEnabled())
    {
        return;
    }

    int legalIntervalTicks = Orion_Aim_GetLegalFireIntervalTicks(weaponName);
    int previousFireIntervalTicks = g_OrionAimLastFireTick[client] > 0 ? tickcount - g_OrionAimLastFireTick[client] : -1;
    if (previousFireIntervalTicks > 0 && previousFireIntervalTicks < legalIntervalTicks)
    {
        g_OrionAimRapidfireCadenceStreak[client]++;
    }
    else if (g_OrionAimRapidfireCadenceStreak[client] > 0)
    {
        g_OrionAimRapidfireCadenceStreak[client]--;
    }

    float nextPrimaryAttackAt = 0.0;
    if (Orion_Aim_TryGetNextPrimaryAttack(client, nextPrimaryAttackAt) && nextPrimaryAttackAt <= GetGameTime() + ORION_AIM_RAPIDFIRE_NEXT_ATTACK_GRACE)
    {
        g_OrionAimRapidfireNextAttackStreak[client]++;
    }
    else if (g_OrionAimRapidfireNextAttackStreak[client] > 0)
    {
        g_OrionAimRapidfireNextAttackStreak[client]--;
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

    int damage = event.GetInt("dmg_health", 0);
    int hitGroup = event.GetInt("hitgroup", 0);
    Orion_Aim_RecordWeaponOutcome(attacker, "hurt", damage, hitGroup, false, g_OrionAimLastFireWeapon[attacker], g_OrionAimLastTick[attacker]);

    if (g_OrionAimLastTarget[attacker] == victim && g_OrionAimTargetTicks[attacker] <= 2)
    {
        Orion_Aim_AddScore(attacker, 15.0);
    }

    if (g_OrionAimOneTickShotStreak[attacker] >= 2)
    {
        Orion_Aim_AddScore(attacker, 12.0);
    }

    if (g_OrionAimLastDelta[attacker] >= 25.0)
    {
        Orion_Aim_AddScore(attacker, 10.0);
    }

    if (Orion_Aim_PlayerIsAirborneOrFast(attacker))
    {
        Orion_Aim_AddScore(attacker, 8.0);
    }

    Orion_Aim_ScoreSilentAngleMismatch(attacker, victim, g_OrionAimLastTick[attacker]);
    Orion_Aim_ScoreRapidfireHit(attacker, victim, g_OrionAimLastTick[attacker]);
    Orion_Aim_ScoreNorecoilHit(attacker, victim, g_OrionAimLastTick[attacker]);
    Orion_Aim_RecordLaserTightHit(attacker, victim, hitGroup, false, g_OrionAimLastTick[attacker]);

    Orion_Aim_ScoreWeaponOutcome(attacker, hitGroup, false);
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

    char weaponName[32];
    event.GetString("weapon", weaponName, sizeof(weaponName), "unknown");
    bool isHeadshot = event.GetBool("headshot", false);
    Orion_Aim_RecordWeaponOutcome(attacker, "death", 0, 0, isHeadshot, weaponName, g_OrionAimLastTick[attacker]);

    if (g_OrionAimLastTarget[attacker] == victim && g_OrionAimTargetTicks[attacker] <= 2)
    {
        Orion_Aim_AddScore(attacker, 20.0);
        Orion_Aim_ReportIfNeeded(attacker, "death_correlation", victim, g_OrionAimLastDelta[attacker], 0, g_OrionAimLastTick[attacker]);
    }

    if (g_OrionAimOneTickShotStreak[attacker] >= 2)
    {
        Orion_Aim_AddScore(attacker, 15.0);
        Orion_Aim_ReportIfNeeded(attacker, "autoshoot_death_correlation", victim, g_OrionAimLastDelta[attacker], 0, g_OrionAimLastTick[attacker]);
    }

    Orion_Aim_ScoreSilentAngleMismatch(attacker, victim, g_OrionAimLastTick[attacker]);
    Orion_Aim_ScoreRapidfireHit(attacker, victim, g_OrionAimLastTick[attacker]);
    Orion_Aim_ScoreNorecoilHit(attacker, victim, g_OrionAimLastTick[attacker]);
    Orion_Aim_RecordLaserTightHit(attacker, victim, 0, isHeadshot, g_OrionAimLastTick[attacker]);

    Orion_Aim_ScoreWeaponOutcome(attacker, 0, isHeadshot);
}

void Orion_Aim_RecordWeaponOutcome(int client, const char[] outcomeName, int damage, int hitGroup, bool isHeadshot, const char[] weaponName, int tickcount)
{
    g_OrionAimLastOutcomeTick[client] = tickcount;
    g_OrionAimLastOutcomeDamage[client] = damage;
    g_OrionAimLastOutcomeHitGroup[client] = hitGroup;
    g_OrionAimLastOutcomeHeadshot[client] = isHeadshot;
    g_OrionAimLastOutcomeNoSpreadSignal[client] = false;
    strcopy(g_OrionAimLastOutcomeWeapon[client], sizeof(g_OrionAimLastOutcomeWeapon[]), weaponName);

    if (StrEqual(outcomeName, "hurt", false) && hitGroup == 1 && g_OrionAimLastDelta[client] >= 18.0 && g_OrionAimLastMouseMagnitude[client] <= 1)
    {
        g_OrionAimLastOutcomeNoSpreadSignal[client] = true;
    }
    else if (StrEqual(outcomeName, "death", false) && isHeadshot && g_OrionAimLastDelta[client] >= 18.0 && g_OrionAimLastMouseMagnitude[client] <= 1)
    {
        g_OrionAimLastOutcomeNoSpreadSignal[client] = true;
    }
}

void Orion_Aim_ScoreWeaponOutcome(int client, int hitGroup, bool isHeadshot)
{
    float scoreDelta = 0.0;

    if (g_OrionAimLastOutcomeNoSpreadSignal[client])
    {
        scoreDelta += 12.0;
    }

    if ((hitGroup == 1 || isHeadshot) && g_OrionAimRecentSnap2Delta[client] >= 45.0)
    {
        scoreDelta += 8.0;
    }

    if (g_OrionAimBurstFireTicks[client] >= 3 && g_OrionAimLastMouseMagnitude[client] <= 1 && g_OrionAimLastDelta[client] >= 12.0)
    {
        scoreDelta += 8.0;
    }

    if (scoreDelta > 0.0)
    {
        Orion_Aim_AddScore(client, scoreDelta);
    }
}

// Silent/perfect-silent serves a fake angle to the server while firing on the
// real client angle. A hit with the served crosshair far off the victim is the
// server-observable signal, but it must repeat before enforcement is eligible.
void Orion_Aim_ScoreSilentAngleMismatch(int attacker, int victim, int tickcount)
{
    if (!Orion_Config_AimIntegrityEnabled() || !Orion_Aim_IsScorableVictim(attacker, victim))
    {
        return;
    }

    float mismatchDegrees = 0.0;
    if (!Orion_Aim_TryGetServedAngleToVictimDegrees(attacker, victim, mismatchDegrees))
    {
        return;
    }

    g_OrionAimLastSilentMismatchDegrees[attacker] = mismatchDegrees;

    int fireAge = g_OrionAimLastFireTick[attacker] > 0 ? tickcount - g_OrionAimLastFireTick[attacker] : -1;
    if (fireAge < 0 || fireAge > 2 || mismatchDegrees < Orion_Config_AimSilentMismatchDegrees())
    {
        if (g_OrionAimSilentMismatchHits[attacker] > 0)
        {
            g_OrionAimSilentMismatchHits[attacker]--;
        }
        return;
    }

    g_OrionAimSilentMismatchHits[attacker]++;
    if (g_OrionAimSilentMismatchHits[attacker] < Orion_Config_AimSilentMismatchMinHits())
    {
        Orion_Aim_AddScore(attacker, 12.0);
        return;
    }

    Orion_Aim_AddScore(attacker, 22.0);
    Orion_Aim_ReportIfNeeded(attacker, "silent_angle_mismatch", victim, mismatchDegrees, g_OrionAimLastMouseMagnitude[attacker], tickcount);
}

// Rapidfire/autoshoot needs both abnormal fire cadence and a hit. This combines
// sub-cycle weapon_fire intervals, one-tick IN_ATTACK toggles, and suspicious
// next-primary-attack state before emitting a hit-correlated finding.
void Orion_Aim_ScoreRapidfireHit(int attacker, int victim, int tickcount)
{
    if (!Orion_Config_AimIntegrityEnabled() || !Orion_Aim_IsScorableVictim(attacker, victim))
    {
        return;
    }

    int minSignalCount = Orion_Config_AimRapidfireMinSignals();
    bool hasCadenceSignal = g_OrionAimRapidfireCadenceStreak[attacker] >= minSignalCount;
    bool hasNextAttackSignal = g_OrionAimRapidfireNextAttackStreak[attacker] >= minSignalCount;
    bool hasToggleSignal = g_OrionAimAttackToggleStreak[attacker] >= minSignalCount + 1;
    if (!hasCadenceSignal && !hasNextAttackSignal && !hasToggleSignal)
    {
        if (g_OrionAimRapidfireHitStreak[attacker] > 0)
        {
            g_OrionAimRapidfireHitStreak[attacker]--;
        }
        return;
    }

    g_OrionAimRapidfireHitStreak[attacker]++;
    if (g_OrionAimRapidfireHitStreak[attacker] < 2)
    {
        Orion_Aim_AddScore(attacker, 10.0);
        return;
    }

    Orion_Aim_AddScore(attacker, 20.0);
    Orion_Aim_ReportIfNeeded(attacker, "rapidfire_cadence", victim, float(g_OrionAimRapidfireCadenceStreak[attacker]), g_OrionAimLastMouseMagnitude[attacker], tickcount);
}

// No-recoil keeps view pitch almost unchanged during a long burst. Requiring a
// sustained burst plus repeated hits keeps ordinary short sprays and recoil
// control practice out of enforcement scope.
void Orion_Aim_ScoreNorecoilHit(int attacker, int victim, int tickcount)
{
    if (!Orion_Config_AimIntegrityEnabled() || !Orion_Aim_IsScorableVictim(attacker, victim))
    {
        return;
    }

    int minBurstShots = Orion_Config_AimNorecoilMinBurstShots();
    float pitchSpan = g_OrionAimBurstMaxPitch[attacker] - g_OrionAimBurstMinPitch[attacker];
    float flatPitchDegrees = Orion_Config_AimNorecoilFlatPitchDegrees();
    if (g_OrionAimBurstFireTicks[attacker] < minBurstShots || pitchSpan > flatPitchDegrees || g_OrionAimBurstPitchMotion[attacker] > flatPitchDegrees * 2.0)
    {
        if (g_OrionAimNorecoilHitStreak[attacker] > 0)
        {
            g_OrionAimNorecoilHitStreak[attacker]--;
        }
        return;
    }

    g_OrionAimNorecoilHitStreak[attacker]++;
    if (g_OrionAimNorecoilHitStreak[attacker] < Orion_Config_AimNorecoilMinHits())
    {
        Orion_Aim_AddScore(attacker, 10.0);
        return;
    }

    Orion_Aim_AddScore(attacker, 20.0);
    Orion_Aim_ReportIfNeeded(attacker, "norecoil_flat", victim, pitchSpan, g_OrionAimLastMouseMagnitude[attacker], tickcount);
}

// Laser-tight aim is a support signal for fake-upgrade nospread. The integrity
// module cross-checks it against the weapon upgrade netprops; this function only
// records repeated tight, hit-correlated accuracy.
void Orion_Aim_RecordLaserTightHit(int attacker, int victim, int hitGroup, bool isHeadshot, int tickcount)
{
    if (!Orion_Config_AimIntegrityEnabled() || !Orion_Aim_IsScorableVictim(attacker, victim))
    {
        return;
    }

    float mismatchDegrees = 0.0;
    if (!Orion_Aim_TryGetServedAngleToVictimDegrees(attacker, victim, mismatchDegrees))
    {
        return;
    }

    bool hitVitalGroup = isHeadshot || hitGroup == 1 || hitGroup == 2;
    int fireAge = g_OrionAimLastFireTick[attacker] > 0 ? tickcount - g_OrionAimLastFireTick[attacker] : -1;
    if (hitVitalGroup && fireAge >= 0 && fireAge <= 2 && mismatchDegrees <= Orion_Config_AimLaserTightDegrees() && g_OrionAimLastDelta[attacker] <= Orion_Config_AimLaserTightDegrees())
    {
        g_OrionAimLaserTightHitStreak[attacker]++;
        g_OrionAimLastTightHitTick[attacker] = tickcount;
        return;
    }

    if (g_OrionAimLaserTightHitStreak[attacker] > 0)
    {
        g_OrionAimLaserTightHitStreak[attacker]--;
    }
}

int Orion_Aim_GetLaserTightHitStreak(int client)
{
    return g_OrionAimLaserTightHitStreak[client];
}

bool Orion_Aim_HasRecentLaserTightHits(int client, int tickcount)
{
    int ageTicks = g_OrionAimLastTightHitTick[client] > 0 ? tickcount - g_OrionAimLastTightHitTick[client] : -1;
    return ageTicks >= 0 && ageTicks <= ORION_AIM_TIGHT_HIT_RECENT_TICKS;
}

int Orion_Aim_GetLastObservedTick(int client)
{
    return g_OrionAimLastTick[client];
}

bool Orion_Aim_PlayerIsAirborneOrFast(int client)
{
    bool isAirborne = (GetEntityFlags(client) & FL_ONGROUND) == 0;
    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    float horizontalSpeed = SquareRoot((velocity[0] * velocity[0]) + (velocity[1] * velocity[1]));
    return isAirborne || horizontalSpeed > 260.0;
}

bool Orion_Aim_IsValidTarget(int target)
{
    return target > 0 && target <= MaxClients && IsClientInGame(target);
}

bool Orion_Aim_IsScorableVictim(int attacker, int victim)
{
    return victim > 0
        && victim <= MaxClients
        && victim != attacker
        && IsClientInGame(victim)
        && IsPlayerAlive(victim)
        && !IsFakeClient(victim)
        && GetClientTeam(attacker) != GetClientTeam(victim);
}

bool Orion_Aim_TryGetServedAngleToVictimDegrees(int attacker, int victim, float &mismatchDegrees)
{
    float attackerEye[3];
    float victimCenter[3];
    GetClientEyePosition(attacker, attackerEye);
    GetClientAbsOrigin(victim, victimCenter);
    victimCenter[2] += ORION_AIM_PLAYER_CENTER_Z;

    float toVictim[3];
    MakeVectorFromPoints(attackerEye, victimCenter, toVictim);
    if (GetVectorLength(toVictim) <= 0.01)
    {
        return false;
    }

    NormalizeVector(toVictim, toVictim);

    float servedForward[3];
    float servedRight[3];
    float servedUp[3];
    GetAngleVectors(g_OrionAimLastAngles[attacker], servedForward, servedRight, servedUp);
    NormalizeVector(servedForward, servedForward);

    float dotProduct = GetVectorDotProduct(servedForward, toVictim);
    if (dotProduct > 1.0)
    {
        dotProduct = 1.0;
    }
    else if (dotProduct < -1.0)
    {
        dotProduct = -1.0;
    }

    mismatchDegrees = RadToDeg(ArcCosine(dotProduct));
    return true;
}

int Orion_Aim_GetLegalFireIntervalTicks(const char[] weaponName)
{
    int configuredMinimumTicks = Orion_Config_AimRapidfireMinCycleTicks();
    if (configuredMinimumTicks < 1)
    {
        configuredMinimumTicks = 1;
    }

    int legalMinimumTicks = configuredMinimumTicks;
    if (StrContains(weaponName, "shotgun", false) != -1)
    {
        legalMinimumTicks = Orion_Aim_MaxInt(legalMinimumTicks, 10);
    }
    else if (StrContains(weaponName, "sniper", false) != -1 || StrContains(weaponName, "hunting_rifle", false) != -1)
    {
        legalMinimumTicks = Orion_Aim_MaxInt(legalMinimumTicks, 6);
    }
    else if (StrContains(weaponName, "pistol", false) != -1)
    {
        legalMinimumTicks = Orion_Aim_MaxInt(legalMinimumTicks, 3);
    }
    else if (StrContains(weaponName, "grenade_launcher", false) != -1)
    {
        legalMinimumTicks = Orion_Aim_MaxInt(legalMinimumTicks, 24);
    }
    else
    {
        legalMinimumTicks = Orion_Aim_MaxInt(legalMinimumTicks, 2);
    }

    return legalMinimumTicks;
}

bool Orion_Aim_TryGetNextPrimaryAttack(int client, float &nextPrimaryAttackAt)
{
    if (!HasEntProp(client, Prop_Send, "m_hActiveWeapon"))
    {
        return false;
    }

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (activeWeapon <= MaxClients || !IsValidEntity(activeWeapon) || !HasEntProp(activeWeapon, Prop_Send, "m_flNextPrimaryAttack"))
    {
        return false;
    }

    nextPrimaryAttackAt = GetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack");
    return true;
}

int Orion_Aim_MaxInt(int left, int right)
{
    return left > right ? left : right;
}

bool Orion_Aim_IsInJoinGrace(int client)
{
    return GetGameTime() < g_OrionAimReadyAt[client];
}

bool Orion_Aim_HasMatureTelemetry(int client)
{
    return !Orion_Aim_IsInJoinGrace(client) && g_OrionAimHistoryCount[client] >= ORION_AIM_HISTORY_SIZE;
}

bool Orion_Aim_HasRecentOffensiveContext(int client, int tickcount)
{
    int fireAge = g_OrionAimLastFireTick[client] > 0 ? tickcount - g_OrionAimLastFireTick[client] : -1;
    int outcomeAge = g_OrionAimLastOutcomeTick[client] > 0 ? tickcount - g_OrionAimLastOutcomeTick[client] : -1;
    return (fireAge >= 0 && fireAge <= ORION_AIM_RECENT_CONTEXT_TICKS)
        || (outcomeAge >= 0 && outcomeAge <= ORION_AIM_RECENT_CONTEXT_TICKS);
}

bool Orion_Aim_IsBanEligible(int client, const char[] reason, int target, int tickcount)
{
    bool hasValidTarget = Orion_Aim_IsValidTarget(target);
    bool hasRecentOffensiveContext = Orion_Aim_HasRecentOffensiveContext(client, tickcount);

    if (!Orion_Aim_HasMatureTelemetry(client))
    {
        return false;
    }

    if (StrEqual(reason, "angle_history", false))
    {
        return hasValidTarget && hasRecentOffensiveContext;
    }

    if (StrEqual(reason, "attack_window", false)
        || StrEqual(reason, "hurt_correlation", false)
        || StrEqual(reason, "death_correlation", false)
        || StrEqual(reason, "autoshoot_death_correlation", false)
        || StrEqual(reason, "silent_angle_mismatch", false)
        || StrEqual(reason, "norecoil_flat", false)
        || StrEqual(reason, "rapidfire_cadence", false))
    {
        return hasValidTarget;
    }

    if (StrEqual(reason, "weapon_fire_delta", false)
        || StrEqual(reason, "trigger_autoshoot_fire", false)
        || StrEqual(reason, "one_tick_attack_streak", false))
    {
        return hasValidTarget && hasRecentOffensiveContext;
    }

    return false;
}

void Orion_Aim_AddScore(int client, float scoreDelta)
{
    if (scoreDelta <= 0.0)
    {
        return;
    }

    g_OrionAimScore[client] += scoreDelta;
    if (g_OrionAimScore[client] > ORION_AIM_MAX_SCORE)
    {
        g_OrionAimScore[client] = ORION_AIM_MAX_SCORE;
    }
}

void Orion_Aim_ReportIfNeeded(int client, const char[] reason, int target, float angleDelta, int mouseMagnitude, int tickcount)
{
    float alertThreshold = Orion_Config_AimThreshold();
    if (g_OrionAimScore[client] < alertThreshold)
    {
        return;
    }

    int fireAge = g_OrionAimLastFireTick[client] > 0 ? tickcount - g_OrionAimLastFireTick[client] : -1;
    int outcomeAge = g_OrionAimLastOutcomeTick[client] > 0 ? tickcount - g_OrionAimLastOutcomeTick[client] : -1;

    char details[768];
    bool isBanEligible = Orion_Aim_IsBanEligible(client, reason, target, tickcount);
    float graceRemainingSeconds = g_OrionAimReadyAt[client] - GetGameTime();
    if (graceRemainingSeconds < 0.0)
    {
        graceRemainingSeconds = 0.0;
    }

    Format(
        details,
        sizeof(details),
        "reason=%s target=%d angle_delta=%.1f snap2=%.1f total_delta=%.1f repeat=%d mouse=%d last_mouse=%d target_ticks=%d trigger=%d one_tick=%d hist=%d tick=%d weapon=%s weaponid=%d fire_age=%d burst=%d outcome_weapon=%s hitgroup=%d damage=%d headshot=%d nospread=%d outcome_age=%d silent_gap=%.1f silent_hits=%d rapidfire_cadence=%d rapidfire_next=%d rapidfire_hits=%d toggle=%d norecoil_hits=%d burst_pitch_span=%.2f burst_pitch_motion=%.2f tight_hits=%d ban_eligible=%d grace_left=%.1f",
        reason,
        target,
        angleDelta,
        g_OrionAimRecentSnap2Delta[client],
        g_OrionAimRecentWindowDelta[client],
        g_OrionAimAngleRepeatStreak[client],
        mouseMagnitude,
        g_OrionAimLastMouseMagnitude[client],
        g_OrionAimTargetTicks[client],
        g_OrionAimTriggerSupportSignal[client],
        g_OrionAimOneTickShotStreak[client],
        g_OrionAimHistoryCount[client],
        tickcount,
        g_OrionAimLastFireWeapon[client],
        g_OrionAimLastFireWeaponId[client],
        fireAge,
        g_OrionAimBurstFireTicks[client],
        g_OrionAimLastOutcomeWeapon[client],
        g_OrionAimLastOutcomeHitGroup[client],
        g_OrionAimLastOutcomeDamage[client],
        g_OrionAimLastOutcomeHeadshot[client],
        g_OrionAimLastOutcomeNoSpreadSignal[client],
        outcomeAge,
        g_OrionAimLastSilentMismatchDegrees[client],
        g_OrionAimSilentMismatchHits[client],
        g_OrionAimRapidfireCadenceStreak[client],
        g_OrionAimRapidfireNextAttackStreak[client],
        g_OrionAimRapidfireHitStreak[client],
        g_OrionAimAttackToggleStreak[client],
        g_OrionAimNorecoilHitStreak[client],
        g_OrionAimBurstMaxPitch[client] - g_OrionAimBurstMinPitch[client],
        g_OrionAimBurstPitchMotion[client],
        g_OrionAimLaserTightHitStreak[client],
        isBanEligible,
        graceRemainingSeconds);

    char action[16];
    strcopy(action, sizeof(action), g_OrionAimScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) && isBanEligible ? "ban" : "observe");
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

    int tickcount = g_OrionAimLastTick[client];
    if (g_OrionAimLastOutcomeTick[client] > 0 && tickcount - g_OrionAimLastOutcomeTick[client] > ORION_AIM_RECENT_CONTEXT_TICKS * 3)
    {
        if (g_OrionAimSilentMismatchHits[client] > 0)
        {
            g_OrionAimSilentMismatchHits[client]--;
        }
        if (g_OrionAimRapidfireHitStreak[client] > 0)
        {
            g_OrionAimRapidfireHitStreak[client]--;
        }
        if (g_OrionAimNorecoilHitStreak[client] > 0)
        {
            g_OrionAimNorecoilHitStreak[client]--;
        }
        if (g_OrionAimLaserTightHitStreak[client] > 0)
        {
            g_OrionAimLaserTightHitStreak[client]--;
        }
    }

    if (g_OrionAimLastFireTick[client] > 0 && tickcount - g_OrionAimLastFireTick[client] > ORION_AIM_RECENT_CONTEXT_TICKS * 2)
    {
        if (g_OrionAimRapidfireCadenceStreak[client] > 0)
        {
            g_OrionAimRapidfireCadenceStreak[client]--;
        }
        if (g_OrionAimRapidfireNextAttackStreak[client] > 0)
        {
            g_OrionAimRapidfireNextAttackStreak[client]--;
        }
        if (g_OrionAimAttackToggleStreak[client] > 0)
        {
            g_OrionAimAttackToggleStreak[client]--;
        }
    }
}
