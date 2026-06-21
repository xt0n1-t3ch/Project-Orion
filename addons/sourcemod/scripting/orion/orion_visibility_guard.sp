enum
{
    OrionVisibilityReason_InvalidEntity = 0,
    OrionVisibilityReason_Self,
    OrionVisibilityReason_NonHumanObserver,
    OrionVisibilityReason_SpectatorObserver,
    OrionVisibilityReason_AdminObserver,
    OrionVisibilityReason_TeamPolicy,
    OrionVisibilityReason_GhostInfected,
    OrionVisibilityReason_InactiveInfected,
    OrionVisibilityReason_SpawnedInfected,
    OrionVisibilityReason_PvsHiddenEnemy,
    OrionVisibilityReason_InfectedSpawnNearSurvivor,
    OrionVisibilityReason_Count
};

int g_OrionVisibilityBlocked[MAXPLAYERS + 1];
bool g_OrionVisibilityHooked[MAXPLAYERS + 1];
int g_OrionVisibilityAllowedByReason[OrionVisibilityReason_Count];
int g_OrionVisibilitySuppressedByReason[OrionVisibilityReason_Count];
int g_OrionVisibilityPvsHiddenTicks[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_OrionVisibilityLastCheckedTick[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_OrionVisibilityIsVisible[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_OrionVisibilityLastVisibleAt[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_OrionVisibilityLastSpawnReportTick[MAXPLAYERS + 1];
int g_OrionVisibilitySuppressedSinceTelemetry[MAXPLAYERS + 1];
float g_OrionVisibilityLastTelemetryAt[MAXPLAYERS + 1];
int g_OrionVisibilityPrefireCount[MAXPLAYERS + 1];
float g_OrionVisibilityPrefireWindowStartedAt[MAXPLAYERS + 1];
float g_OrionVisibilityLastPrefireEvidenceAt[MAXPLAYERS + 1];
int g_OrionVisibilityTraceTick = -1;
int g_OrionVisibilityTraceCount = 0;

#define ORION_VISIBILITY_TELEMETRY_THROTTLE_SECONDS 30.0

void Orion_Visibility_Init()
{
    RegAdminCmd("sm_orion_visibility_status", Orion_Visibility_CommandStatus, ADMFLAG_GENERIC, "Show Project Orion visibility guard transmit counters.");
    HookEvent("player_spawn", Orion_Visibility_OnPlayerSpawn, EventHookMode_Post);
    HookEvent("weapon_fire", Orion_Visibility_OnWeaponFire, EventHookMode_Post);
    HookEvent("player_hurt", Orion_Visibility_OnPlayerHurt, EventHookMode_Post);
    Orion_Visibility_ResetMapCounters();

    for (int client = 1; client <= MaxClients; client++)
    {
        Orion_Visibility_ResetClient(client);
        if (IsClientInGame(client))
        {
            Orion_Visibility_HookClient(client);
        }
    }
}

void Orion_Visibility_OnMapStart()
{
    Orion_Visibility_ResetMapCounters();
    g_OrionVisibilityTraceTick = -1;
    g_OrionVisibilityTraceCount = 0;

    for (int client = 1; client <= MaxClients; client++)
    {
        Orion_Visibility_ResetPairCache(client);
    }
}

void Orion_Visibility_HookClient(int client)
{
    if (client > 0 && client <= MaxClients && !g_OrionVisibilityHooked[client])
    {
        SDKHook(client, SDKHook_SetTransmit, Orion_Visibility_OnSetTransmit);
        g_OrionVisibilityHooked[client] = true;
    }
}

void Orion_Visibility_ResetClient(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    if (g_OrionVisibilityHooked[client])
    {
        SDKUnhook(client, SDKHook_SetTransmit, Orion_Visibility_OnSetTransmit);
        g_OrionVisibilityHooked[client] = false;
    }

    g_OrionVisibilityBlocked[client] = 0;
    g_OrionVisibilityLastSpawnReportTick[client] = 0;
    g_OrionVisibilitySuppressedSinceTelemetry[client] = 0;
    g_OrionVisibilityLastTelemetryAt[client] = 0.0;
    g_OrionVisibilityPrefireCount[client] = 0;
    g_OrionVisibilityPrefireWindowStartedAt[client] = 0.0;
    g_OrionVisibilityLastPrefireEvidenceAt[client] = 0.0;
    Orion_Visibility_ResetPairCache(client);
}

void Orion_Visibility_ResetPairCache(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    for (int otherClient = 1; otherClient <= MaxClients; otherClient++)
    {
        g_OrionVisibilityPvsHiddenTicks[client][otherClient] = 0;
        g_OrionVisibilityPvsHiddenTicks[otherClient][client] = 0;
        g_OrionVisibilityLastCheckedTick[client][otherClient] = 0;
        g_OrionVisibilityLastCheckedTick[otherClient][client] = 0;
        g_OrionVisibilityIsVisible[client][otherClient] = true;
        g_OrionVisibilityIsVisible[otherClient][client] = true;
        g_OrionVisibilityLastVisibleAt[client][otherClient] = 0.0;
        g_OrionVisibilityLastVisibleAt[otherClient][client] = 0.0;
    }
}

void Orion_Visibility_ResetMapCounters()
{
    for (int reason = 0; reason < view_as<int>(OrionVisibilityReason_Count); reason++)
    {
        g_OrionVisibilityAllowedByReason[reason] = 0;
        g_OrionVisibilitySuppressedByReason[reason] = 0;
    }
}

public Action Orion_Visibility_OnSetTransmit(int entity, int observer)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_VisibilityGuardEnabled())
    {
        return Plugin_Continue;
    }

    int reason = OrionVisibilityReason_InvalidEntity;
    if (Orion_ShouldBlockPlayerTransmit(entity, observer, reason))
    {
        Orion_Visibility_RecordSuppressedEvidence(entity, observer, reason, 55.0, true);
        return Plugin_Handled;
    }

    Orion_Visibility_RecordAllowed(reason);
    if (!Orion_Config_VisibilityPvsEnabled() || !Orion_ShouldEvaluatePvsTransmit(entity, observer))
    {
        return Plugin_Continue;
    }

    if (!Orion_ShouldBlockPvsTransmit(entity, observer))
    {
        return Plugin_Continue;
    }

    Orion_Visibility_RecordSuppressedEvidence(entity, observer, OrionVisibilityReason_PvsHiddenEnemy, 65.0, Orion_Config_VisibilityPvsBlockEnabled());
    return Orion_Config_VisibilityPvsBlockEnabled() ? Plugin_Handled : Plugin_Continue;
}

bool Orion_ShouldBlockPlayerTransmit(int entity, int observer, int& reason)
{
    if (entity <= 0 || entity > MaxClients || observer <= 0 || observer > MaxClients)
    {
        reason = OrionVisibilityReason_InvalidEntity;
        return false;
    }

    if (entity == observer || !IsClientInGame(entity) || !IsClientInGame(observer))
    {
        reason = entity == observer ? OrionVisibilityReason_Self : OrionVisibilityReason_InvalidEntity;
        return false;
    }

    if (IsFakeClient(observer))
    {
        reason = OrionVisibilityReason_NonHumanObserver;
        return false;
    }

    int entityTeam = GetClientTeam(entity);
    int observerTeam = GetClientTeam(observer);

    if (observerTeam == ORION_TEAM_SPECTATOR)
    {
        reason = OrionVisibilityReason_SpectatorObserver;
        return false;
    }

    if (!IsPlayerAlive(observer) && CheckCommandAccess(observer, "orion_visibility_bypass", ADMFLAG_GENERIC, true))
    {
        reason = OrionVisibilityReason_AdminObserver;
        return false;
    }

    if (entityTeam != ORION_TEAM_INFECTED || observerTeam != ORION_TEAM_SURVIVOR)
    {
        reason = OrionVisibilityReason_TeamPolicy;
        return false;
    }

    if (!IsPlayerAlive(entity))
    {
        reason = OrionVisibilityReason_InactiveInfected;
        return true;
    }

    if (GetEntProp(entity, Prop_Send, "m_isGhost") == 1)
    {
        reason = OrionVisibilityReason_GhostInfected;
        return true;
    }

    reason = OrionVisibilityReason_SpawnedInfected;
    return false;
}

bool Orion_ShouldEvaluatePvsTransmit(int entity, int observer)
{
    if (entity <= 0 || entity > MaxClients || observer <= 0 || observer > MaxClients)
    {
        return false;
    }

    if (entity == observer || !IsClientInGame(entity) || !IsClientInGame(observer))
    {
        return false;
    }

    if (IsFakeClient(entity) || IsFakeClient(observer))
    {
        return false;
    }

    int entityTeam = GetClientTeam(entity);
    int observerTeam = GetClientTeam(observer);
    // Default: survivor-facing infected minimization only. The visual-cheat risk is hidden
    // infected data drawn for survivors; keeping the scope narrow avoids breaking infected play.
    if (entityTeam != ORION_TEAM_INFECTED || observerTeam != ORION_TEAM_SURVIVOR)
    {
        return false;
    }

    if (!IsPlayerAlive(entity) || !IsPlayerAlive(observer))
    {
        return false;
    }

    if (entityTeam == ORION_TEAM_INFECTED && GetEntProp(entity, Prop_Send, "m_isGhost") == 1)
    {
        return false;
    }

    return true;
}

public void Orion_Visibility_OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    // Default: observe only. A real weapon_fire gives the prefire signal an attack
    // anchor without trusting client-side renderer state Orion cannot inspect.
    if (!Orion_Visibility_ShouldEvaluatePrefire())
    {
        return;
    }

    int survivor = GetClientOfUserId(event.GetInt("userid"));
    int infected = 0;
    if (Orion_Visibility_FindPrefireTarget(survivor, infected))
    {
        Orion_Visibility_RecordPrefireEvidence(survivor, infected, "weapon_fire");
    }
}

public void Orion_Visibility_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    // Default: observe only. Hurt correlation is stronger than crosshair-only awareness,
    // but it still stays rolling evidence because wallbangs and sound reads can be legal.
    if (!Orion_Visibility_ShouldEvaluatePrefire())
    {
        return;
    }

    int infected = GetClientOfUserId(event.GetInt("userid"));
    int survivor = GetClientOfUserId(event.GetInt("attacker"));
    if (!Orion_Visibility_ShouldEvaluatePrefirePair(survivor, infected))
    {
        return;
    }

    if (!Orion_Visibility_IsAimPreciselyOnTarget(survivor, infected))
    {
        return;
    }

    if (!Orion_Visibility_IsPvsHiddenAndStale(survivor, infected))
    {
        return;
    }

    Orion_Visibility_RecordPrefireEvidence(survivor, infected, "player_hurt");
}

bool Orion_Visibility_ShouldEvaluatePrefire()
{
    return Orion_Config_IsEnabled()
        && Orion_Config_VisibilityGuardEnabled()
        && Orion_Config_VisibilityPvsEnabled()
        && Orion_Config_VisibilityPrefireEnabled();
}

bool Orion_Visibility_ShouldEvaluatePrefirePair(int survivor, int infected)
{
    if (!Orion_IsAliveHumanPlayer(survivor) || !Orion_IsAliveHumanPlayer(infected))
    {
        return false;
    }

    if (GetClientTeam(survivor) != ORION_TEAM_SURVIVOR || GetClientTeam(infected) != ORION_TEAM_INFECTED)
    {
        return false;
    }

    if (GetEntProp(infected, Prop_Send, "m_isGhost") == 1)
    {
        return false;
    }

    return true;
}

bool Orion_Visibility_FindPrefireTarget(int survivor, int& infected)
{
    infected = 0;
    if (!Orion_IsAliveHumanPlayer(survivor) || GetClientTeam(survivor) != ORION_TEAM_SURVIVOR)
    {
        return false;
    }

    float bestAimDot = Orion_Config_VisibilityPrefireAimDotMin();
    for (int candidate = 1; candidate <= MaxClients; candidate++)
    {
        if (!Orion_Visibility_ShouldEvaluatePrefirePair(survivor, candidate))
        {
            continue;
        }

        float aimDot = Orion_Visibility_GetAimDotToTarget(survivor, candidate);
        if (aimDot < bestAimDot)
        {
            continue;
        }

        if (!Orion_Visibility_IsPvsHiddenAndStale(survivor, candidate))
        {
            continue;
        }

        bestAimDot = aimDot;
        infected = candidate;
    }

    return infected != 0;
}

bool Orion_Visibility_IsPvsHiddenAndStale(int survivor, int infected)
{
    if (!Orion_ShouldEvaluatePvsTransmit(infected, survivor))
    {
        return false;
    }

    if (!Orion_ShouldBlockPvsTransmit(infected, survivor))
    {
        return false;
    }

    float lastVisibleAt = g_OrionVisibilityLastVisibleAt[infected][survivor];
    if (lastVisibleAt <= 0.0)
    {
        return false;
    }

    return (GetGameTime() - lastVisibleAt) > Orion_Config_VisibilityPvsGraceSeconds();
}

bool Orion_Visibility_IsAimPreciselyOnTarget(int survivor, int infected)
{
    return Orion_Visibility_GetAimDotToTarget(survivor, infected) >= Orion_Config_VisibilityPrefireAimDotMin();
}

float Orion_Visibility_GetAimDotToTarget(int survivor, int infected)
{
    float survivorEyePosition[3];
    float survivorEyeAngles[3];
    float survivorForward[3];
    float targetCenter[3];
    float directionToTarget[3];

    GetClientEyePosition(survivor, survivorEyePosition);
    GetClientEyeAngles(survivor, survivorEyeAngles);
    GetAngleVectors(survivorEyeAngles, survivorForward, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(survivorForward, survivorForward);

    Orion_Visibility_GetClientCenter(infected, targetCenter);
    SubtractVectors(targetCenter, survivorEyePosition, directionToTarget);
    if (NormalizeVector(directionToTarget, directionToTarget) == 0.0)
    {
        return -1.0;
    }

    return GetVectorDotProduct(survivorForward, directionToTarget);
}

void Orion_Visibility_RecordPrefireEvidence(int survivor, int infected, const char[] triggerName)
{
    float now = GetGameTime();
    float windowSeconds = Orion_Config_VisibilityPrefireWindowSeconds();

    if (g_OrionVisibilityPrefireWindowStartedAt[survivor] <= 0.0
        || (now - g_OrionVisibilityPrefireWindowStartedAt[survivor]) > windowSeconds)
    {
        g_OrionVisibilityPrefireWindowStartedAt[survivor] = now;
        g_OrionVisibilityPrefireCount[survivor] = 0;
    }

    g_OrionVisibilityPrefireCount[survivor]++;
    int minimumEvents = Orion_Config_VisibilityPrefireMinEvents();
    // Default: require a sustained count. One hidden prefire is common in real play;
    // repeated precise attacks after the PVS grace window are the behavioral signal.
    if (g_OrionVisibilityPrefireCount[survivor] < minimumEvents)
    {
        return;
    }

    if (g_OrionVisibilityLastPrefireEvidenceAt[survivor] > 0.0
        && (now - g_OrionVisibilityLastPrefireEvidenceAt[survivor]) < Orion_Config_VisibilityPrefireEvidenceCooldownSeconds())
    {
        return;
    }

    g_OrionVisibilityLastPrefireEvidenceAt[survivor] = now;

    float score = 45.0 + (float(g_OrionVisibilityPrefireCount[survivor] - minimumEvents + 1) * 10.0);
    if (score > 85.0)
    {
        score = 85.0;
    }

    char details[320];
    Format(
        details,
        sizeof(details),
        "reason=prefire_through_wall trigger=%s target=%d hidden_ticks=%d last_visible_age=%.2f count=%d threshold=%d window_seconds=%.1f aim_dot=%.4f trace_count=%d trace_budget=%d",
        triggerName,
        infected,
        g_OrionVisibilityPvsHiddenTicks[infected][survivor],
        now - g_OrionVisibilityLastVisibleAt[infected][survivor],
        g_OrionVisibilityPrefireCount[survivor],
        minimumEvents,
        windowSeconds,
        Orion_Visibility_GetAimDotToTarget(survivor, infected),
        g_OrionVisibilityTraceCount,
        Orion_Config_VisibilityTraceBudgetPerTick());
    Orion_Evidence_Submit(survivor, "visibility_guard", score, "observe", details);
}

public void Orion_Visibility_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_SpawnAbuseGuardEnabled())
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!Orion_IsHumanPlayer(client) || GetClientTeam(client) != ORION_TEAM_INFECTED)
    {
        return;
    }

    CreateTimer(0.15, Orion_Visibility_CheckInfectedSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Orion_Visibility_CheckInfectedSpawn(Handle timer, any userId)
{
    int infected = GetClientOfUserId(userId);
    if (!Orion_Config_IsEnabled() || !Orion_Config_SpawnAbuseGuardEnabled() || !Orion_IsAliveHumanPlayer(infected))
    {
        return Plugin_Stop;
    }

    if (GetClientTeam(infected) != ORION_TEAM_INFECTED || GetEntProp(infected, Prop_Send, "m_isGhost") == 1)
    {
        return Plugin_Stop;
    }

    int nearestSurvivor = 0;
    float nearestDistance = 0.0;
    if (!Orion_Visibility_FindNearestAliveSurvivor(infected, nearestSurvivor, nearestDistance))
    {
        return Plugin_Stop;
    }

    bool hasLineOfSight = Orion_Visibility_IsObserverAbleToSeeTarget(nearestSurvivor, infected);
    bool isNearSpawn = nearestDistance <= Orion_Config_SpawnAbuseNearDistance();
    bool isVisibleSpawn = hasLineOfSight && nearestDistance <= Orion_Config_SpawnAbuseVisibleDistance();
    if (!isNearSpawn && !isVisibleSpawn)
    {
        return Plugin_Stop;
    }

    int currentTick = Orion_Visibility_CurrentTick();
    if (g_OrionVisibilityLastSpawnReportTick[infected] > 0 && currentTick - g_OrionVisibilityLastSpawnReportTick[infected] < 66)
    {
        return Plugin_Stop;
    }

    g_OrionVisibilityLastSpawnReportTick[infected] = currentTick;
    Orion_Visibility_RecordSpawnEvidence(infected, nearestSurvivor, nearestDistance, hasLineOfSight, isNearSpawn, isVisibleSpawn);
    return Plugin_Stop;
}

bool Orion_Visibility_FindNearestAliveSurvivor(int infected, int& nearestSurvivor, float& nearestDistance)
{
    float infectedCenter[3];
    Orion_Visibility_GetClientCenter(infected, infectedCenter);

    nearestSurvivor = 0;
    nearestDistance = 0.0;
    for (int survivor = 1; survivor <= MaxClients; survivor++)
    {
        if (!Orion_IsAliveHumanPlayer(survivor) || GetClientTeam(survivor) != ORION_TEAM_SURVIVOR)
        {
            continue;
        }

        float survivorEyePosition[3];
        GetClientEyePosition(survivor, survivorEyePosition);
        float distance = GetVectorDistance(survivorEyePosition, infectedCenter);
        if (nearestSurvivor == 0 || distance < nearestDistance)
        {
            nearestSurvivor = survivor;
            nearestDistance = distance;
        }
    }

    return nearestSurvivor != 0;
}

bool Orion_ShouldBlockPvsTransmit(int entity, int observer)
{
    int currentTick = Orion_Visibility_CurrentTick();
    if (g_OrionVisibilityLastCheckedTick[entity][observer] == currentTick)
    {
        return !g_OrionVisibilityIsVisible[entity][observer];
    }

    g_OrionVisibilityLastCheckedTick[entity][observer] = currentTick;

    if (Orion_Visibility_IsObserverAbleToSeeTarget(observer, entity))
    {
        g_OrionVisibilityIsVisible[entity][observer] = true;
        g_OrionVisibilityPvsHiddenTicks[entity][observer] = 0;
        g_OrionVisibilityLastVisibleAt[entity][observer] = GetGameTime();
        return false;
    }

    g_OrionVisibilityPvsHiddenTicks[entity][observer]++;
    float lastVisibleAt = g_OrionVisibilityLastVisibleAt[entity][observer];
    if (lastVisibleAt <= 0.0)
    {
        g_OrionVisibilityLastVisibleAt[entity][observer] = GetGameTime();
        return false;
    }

    if ((GetGameTime() - lastVisibleAt) <= Orion_Config_VisibilityPvsGraceSeconds())
    {
        return false;
    }

    if (!Orion_Visibility_IsOutsidePvsBlockDistance(observer, entity))
    {
        return false;
    }

    g_OrionVisibilityIsVisible[entity][observer] = false;
    return true;
}

bool Orion_Visibility_IsObserverAbleToSeeTarget(int observer, int target)
{
    float observerEyePosition[3];
    float observerEyeAngles[3];
    float targetEyePosition[3];
    float targetCenter[3];
    float targetMins[3];
    float targetMaxs[3];

    GetClientEyePosition(observer, observerEyePosition);
    GetClientEyeAngles(observer, observerEyeAngles);
    GetClientEyePosition(target, targetEyePosition);
    GetClientMins(target, targetMins);
    GetClientMaxs(target, targetMaxs);
    Orion_Visibility_GetClientCenter(target, targetCenter);

    if (!Orion_Visibility_IsInFieldOfView(observerEyePosition, observerEyeAngles, targetCenter))
    {
        return false;
    }

    if (Orion_Visibility_IsPointVisible(observerEyePosition, targetCenter))
    {
        return true;
    }

    if (Orion_Visibility_IsForwardVectorVisible(observerEyePosition, observerEyeAngles, targetEyePosition))
    {
        return true;
    }

    if (Orion_Visibility_IsRectangleVisible(observerEyePosition, targetCenter, targetMins, targetMaxs, 1.30))
    {
        return true;
    }

    return Orion_Visibility_IsRectangleVisible(observerEyePosition, targetCenter, targetMins, targetMaxs, 0.65);
}

void Orion_Visibility_GetClientCenter(int client, float center[3])
{
    float maxs[3];
    GetClientMaxs(client, maxs);
    GetClientAbsOrigin(client, center);

    maxs[2] /= 2.0;
    center[2] += maxs[2];
}

bool Orion_Visibility_IsOutsidePvsBlockDistance(int observer, int target)
{
    float observerEyePosition[3];
    float targetCenter[3];
    GetClientEyePosition(observer, observerEyePosition);
    Orion_Visibility_GetClientCenter(target, targetCenter);
    return GetVectorDistance(observerEyePosition, targetCenter) >= Orion_Config_VisibilityPvsMinBlockDistance();
}

bool Orion_Visibility_IsInFieldOfView(const float start[3], const float angles[3], const float end[3])
{
    float normal[3];
    float plane[3];

    GetAngleVectors(angles, normal, NULL_VECTOR, NULL_VECTOR);
    SubtractVectors(end, start, plane);
    NormalizeVector(plane, plane);

    return GetVectorDotProduct(plane, normal) > 0.0;
}

bool Orion_Visibility_IsForwardVectorVisible(const float start[3], const float angles[3], const float end[3])
{
    float forwardVector[3];

    GetAngleVectors(angles, forwardVector, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(forwardVector, 50.0);
    AddVectors(end, forwardVector, forwardVector);

    return Orion_Visibility_IsPointVisible(start, forwardVector);
}

bool Orion_Visibility_IsRectangleVisible(const float start[3], const float end[3], const float mins[3], const float maxs[3], float scale)
{
    float zPositiveOffset = maxs[2] * scale;
    float zNegativeOffset = mins[2] * scale;
    float wideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0 * scale;

    if (zPositiveOffset == 0.0 && zNegativeOffset == 0.0 && wideOffset == 0.0)
    {
        return Orion_Visibility_IsPointVisible(start, end);
    }

    float angles[3];
    float forwardVector[3];
    float right[3];
    float rectangle[4][3];
    float temp[3];

    SubtractVectors(start, end, forwardVector);
    NormalizeVector(forwardVector, forwardVector);
    GetVectorAngles(forwardVector, angles);
    GetAngleVectors(angles, forwardVector, right, NULL_VECTOR);

    if (FloatAbs(forwardVector[2]) <= 0.7071)
    {
        ScaleVector(right, wideOffset);

        temp = end;
        temp[2] += zPositiveOffset;
        AddVectors(temp, right, rectangle[0]);
        SubtractVectors(temp, right, rectangle[1]);

        temp = end;
        temp[2] += zNegativeOffset;
        AddVectors(temp, right, rectangle[2]);
        SubtractVectors(temp, right, rectangle[3]);
    }
    else if (forwardVector[2] > 0.0)
    {
        forwardVector[2] = 0.0;
        NormalizeVector(forwardVector, forwardVector);
        ScaleVector(forwardVector, wideOffset);
        ScaleVector(right, wideOffset);

        temp = end;
        temp[2] += zPositiveOffset;
        AddVectors(temp, right, temp);
        SubtractVectors(temp, forwardVector, rectangle[0]);

        temp = end;
        temp[2] += zPositiveOffset;
        SubtractVectors(temp, right, temp);
        SubtractVectors(temp, forwardVector, rectangle[1]);

        temp = end;
        temp[2] += zNegativeOffset;
        AddVectors(temp, right, temp);
        AddVectors(temp, forwardVector, rectangle[2]);

        temp = end;
        temp[2] += zNegativeOffset;
        SubtractVectors(temp, right, temp);
        AddVectors(temp, forwardVector, rectangle[3]);
    }
    else
    {
        forwardVector[2] = 0.0;
        NormalizeVector(forwardVector, forwardVector);
        ScaleVector(forwardVector, wideOffset);
        ScaleVector(right, wideOffset);

        temp = end;
        temp[2] += zPositiveOffset;
        AddVectors(temp, right, temp);
        AddVectors(temp, forwardVector, rectangle[0]);

        temp = end;
        temp[2] += zPositiveOffset;
        SubtractVectors(temp, right, temp);
        AddVectors(temp, forwardVector, rectangle[1]);

        temp = end;
        temp[2] += zNegativeOffset;
        AddVectors(temp, right, temp);
        SubtractVectors(temp, forwardVector, rectangle[2]);

        temp = end;
        temp[2] += zNegativeOffset;
        SubtractVectors(temp, right, temp);
        SubtractVectors(temp, forwardVector, rectangle[3]);
    }

    for (int cornerIndex = 0; cornerIndex < 4; cornerIndex++)
    {
        if (Orion_Visibility_IsPointVisible(start, rectangle[cornerIndex]))
        {
            return true;
        }
    }

    return false;
}

bool Orion_Visibility_IsPointVisible(const float start[3], const float end[3])
{
    Orion_Visibility_ResetTraceBudgetIfNeeded();
    if (g_OrionVisibilityTraceCount >= Orion_Config_VisibilityTraceBudgetPerTick())
    {
        return true;
    }

    TR_TraceRayFilter(start, end, MASK_VISIBLE, RayType_EndPoint, Orion_Visibility_FilterWorldOnly);
    g_OrionVisibilityTraceCount++;

    return TR_GetFraction() == 1.0;
}

public bool Orion_Visibility_FilterWorldOnly(int entity, int contentsMask)
{
    return false;
}

void Orion_Visibility_ResetTraceBudgetIfNeeded()
{
    int currentTick = Orion_Visibility_CurrentTick();
    if (g_OrionVisibilityTraceTick != currentTick)
    {
        g_OrionVisibilityTraceTick = currentTick;
        g_OrionVisibilityTraceCount = 0;
    }
}

int Orion_Visibility_CurrentTick()
{
    return RoundToFloor(GetGameTime() / GetTickInterval());
}

void Orion_Visibility_RecordAllowed(int reason)
{
    if (reason >= 0 && reason < view_as<int>(OrionVisibilityReason_Count))
    {
        g_OrionVisibilityAllowedByReason[reason]++;
    }
}

void Orion_Visibility_RecordSuppressed(int reason)
{
    if (reason >= 0 && reason < view_as<int>(OrionVisibilityReason_Count))
    {
        g_OrionVisibilitySuppressedByReason[reason]++;
    }
}

void Orion_Visibility_RecordSuppressedEvidence(int entity, int observer, int reason, float score, bool blocked)
{
    score = 0.0;
    g_OrionVisibilityBlocked[observer]++;
    g_OrionVisibilitySuppressedSinceTelemetry[observer]++;
    Orion_Visibility_RecordSuppressed(reason);

    float now = GetGameTime();
    if (g_OrionVisibilityLastTelemetryAt[observer] > 0.0
        && (now - g_OrionVisibilityLastTelemetryAt[observer]) < ORION_VISIBILITY_TELEMETRY_THROTTLE_SECONDS)
    {
        return;
    }

    g_OrionVisibilityLastTelemetryAt[observer] = now;

    char reasonName[32];
    char spawnState[32];
    char details[256];
    Orion_Visibility_GetReasonName(reason, reasonName, sizeof(reasonName));
    Orion_Visibility_GetSpawnState(entity, spawnState, sizeof(spawnState));
    Format(
        details,
        sizeof(details),
        "classification=mitigation_telemetry reason=%s entity=%d team=%d spawn_state=%s blocked=%d suppressed_total=%d observer_blocks_total=%d observer_blocks_window=%d hidden_ticks=%d throttle_seconds=%.1f",
        reasonName,
        entity,
        GetClientTeam(entity),
        spawnState,
        blocked,
        g_OrionVisibilitySuppressedByReason[reason],
        g_OrionVisibilityBlocked[observer],
        g_OrionVisibilitySuppressedSinceTelemetry[observer],
        g_OrionVisibilityPvsHiddenTicks[entity][observer],
        ORION_VISIBILITY_TELEMETRY_THROTTLE_SECONDS);
    g_OrionVisibilitySuppressedSinceTelemetry[observer] = 0;
    Orion_Evidence_Submit(observer, "visibility_guard", score, "telemetry", details);
}

void Orion_Visibility_RecordSpawnEvidence(int infected, int survivor, float distance, bool hasLineOfSight, bool isNearSpawn, bool isVisibleSpawn)
{
    Orion_Visibility_RecordSuppressed(OrionVisibilityReason_InfectedSpawnNearSurvivor);

    char spawnState[32];
    Orion_Visibility_GetSpawnState(infected, spawnState, sizeof(spawnState));
    int zombieClass = HasEntProp(infected, Prop_Send, "m_zombieClass") ? GetEntProp(infected, Prop_Send, "m_zombieClass") : 0;
    float score = isNearSpawn && isVisibleSpawn ? 85.0 : 72.0;

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=infected_spawn_near_survivor entity=%d nearest_survivor=%d distance=%.1f visible=%d near=%d visible_spawn=%d zombie_class=%d spawn_state=%s",
        infected,
        survivor,
        distance,
        hasLineOfSight,
        isNearSpawn,
        isVisibleSpawn,
        zombieClass,
        spawnState);
    Orion_Evidence_Submit(infected, "spawn_guard", score, "observe", details);
}

void Orion_Visibility_GetReasonName(int reason, char[] reasonName, int reasonNameLength)
{
    switch (reason)
    {
        case OrionVisibilityReason_Self:
        {
            strcopy(reasonName, reasonNameLength, "self");
        }
        case OrionVisibilityReason_NonHumanObserver:
        {
            strcopy(reasonName, reasonNameLength, "non_human_observer");
        }
        case OrionVisibilityReason_SpectatorObserver:
        {
            strcopy(reasonName, reasonNameLength, "spectator_observer");
        }
        case OrionVisibilityReason_AdminObserver:
        {
            strcopy(reasonName, reasonNameLength, "admin_observer");
        }
        case OrionVisibilityReason_TeamPolicy:
        {
            strcopy(reasonName, reasonNameLength, "team_policy");
        }
        case OrionVisibilityReason_GhostInfected:
        {
            strcopy(reasonName, reasonNameLength, "ghost_infected");
        }
        case OrionVisibilityReason_InactiveInfected:
        {
            strcopy(reasonName, reasonNameLength, "inactive_infected");
        }
        case OrionVisibilityReason_SpawnedInfected:
        {
            strcopy(reasonName, reasonNameLength, "spawned_infected");
        }
        case OrionVisibilityReason_PvsHiddenEnemy:
        {
            strcopy(reasonName, reasonNameLength, "pvs_hidden_enemy");
        }
        case OrionVisibilityReason_InfectedSpawnNearSurvivor:
        {
            strcopy(reasonName, reasonNameLength, "infected_spawn_near_survivor");
        }
        default:
        {
            strcopy(reasonName, reasonNameLength, "invalid_entity");
        }
    }
}

void Orion_Visibility_GetSpawnState(int entity, char[] spawnState, int spawnStateLength)
{
    if (entity <= 0 || entity > MaxClients || !IsClientInGame(entity))
    {
        strcopy(spawnState, spawnStateLength, "invalid");
        return;
    }

    if (!IsPlayerAlive(entity))
    {
        strcopy(spawnState, spawnStateLength, "inactive");
        return;
    }

    if (GetEntProp(entity, Prop_Send, "m_isGhost") == 1)
    {
        strcopy(spawnState, spawnStateLength, "ghost");
        return;
    }

    strcopy(spawnState, spawnStateLength, "spawned");
}

public Action Orion_Visibility_CommandStatus(int client, int args)
{
    ReplyToCommand(client, "[Orion] visibility guard counters:");

    char reasonName[32];
    for (int reason = 0; reason < view_as<int>(OrionVisibilityReason_Count); reason++)
    {
        Orion_Visibility_GetReasonName(reason, reasonName, sizeof(reasonName));
        ReplyToCommand(
            client,
            "[Orion] reason=%s allowed=%d suppressed=%d",
            reasonName,
            g_OrionVisibilityAllowedByReason[reason],
            g_OrionVisibilitySuppressedByReason[reason]);
    }

    return Plugin_Handled;
}
