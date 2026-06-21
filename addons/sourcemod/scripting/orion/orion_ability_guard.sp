#define ORION_ABILITY_SPIT 0
#define ORION_ABILITY_VOMIT 1
#define ORION_ABILITY_TANK_PUNCH 2
#define ORION_ABILITY_STUMBLE 3
#define ORION_ABILITY_CHARGE 4
#define ORION_ABILITY_JOCKEY 5
#define ORION_ABILITY_AIR_STUCK 6
#define ORION_ABILITY_COUNT 7

#define ORION_ABILITY_REASON_COOLDOWN 0
#define ORION_ABILITY_REASON_STATE 1
#define ORION_ABILITY_REASON_COUNT 2

#define ORION_ABILITY_SCORE_MAX 100.0
#define ORION_ABILITY_COOLDOWN_SCORE 10.0
#define ORION_ABILITY_STATE_SCORE 18.0
#define ORION_ABILITY_AIR_STUCK_MIN_SPEED 8.0
// L4D2 sendprop value for Tank; kept named so the live RCON pass can confirm
// and patch one owner if this branch exposes a different class map.
#define ORION_ABILITY_ZOMBIECLASS_TANK 8

int g_OrionAbilityLastUseTick[MAXPLAYERS + 1][ORION_ABILITY_COUNT];
int g_OrionAbilityLastReportTick[MAXPLAYERS + 1][ORION_ABILITY_COUNT][ORION_ABILITY_REASON_COUNT];
int g_OrionAbilityLastVomitTick[MAXPLAYERS + 1];
int g_OrionAbilityLastJockeyRideTick[MAXPLAYERS + 1];
int g_OrionAbilityLastJockeyVictim[MAXPLAYERS + 1];
int g_OrionAbilityChargeStartTick[MAXPLAYERS + 1];
int g_OrionAbilityAirStuckTicks[MAXPLAYERS + 1];
float g_OrionAbilityScore[MAXPLAYERS + 1];
float g_OrionAbilityChargeStartYaw[MAXPLAYERS + 1];
bool g_OrionAbilityChargeActive[MAXPLAYERS + 1];
bool g_OrionAbilityChargeRotationReported[MAXPLAYERS + 1];
bool g_OrionAbilityAirStuckReported[MAXPLAYERS + 1];
bool g_OrionAbilityPreThinkHooked[MAXPLAYERS + 1];

void Orion_AbilityGuard_Init()
{
    // HookEventEx keeps Orion load-safe on branches where an optional L4D2 event
    // name differs; the live RCON calibration pass confirms each hook fired.
    HookEventEx("ability_use", Orion_AbilityGuard_OnAbilityUse, EventHookMode_Post);
    HookEventEx("player_hurt", Orion_AbilityGuard_OnPlayerHurt, EventHookMode_Post);
    HookEventEx("player_stagger", Orion_AbilityGuard_OnPlayerStagger, EventHookMode_Post);
    HookEventEx("charger_charge_start", Orion_AbilityGuard_OnChargerChargeStart, EventHookMode_Post);
    HookEventEx("charger_carry_start", Orion_AbilityGuard_OnChargerCarryStart, EventHookMode_Post);
    HookEventEx("jockey_ride", Orion_AbilityGuard_OnJockeyRide, EventHookMode_Post);

    for (int client = 1; client <= MaxClients; client++)
    {
        Orion_AbilityGuard_ResetClient(client);
    }
}

void Orion_AbilityGuard_ResetClient(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    for (int abilityIndex = 0; abilityIndex < ORION_ABILITY_COUNT; abilityIndex++)
    {
        g_OrionAbilityLastUseTick[client][abilityIndex] = 0;
        for (int reasonIndex = 0; reasonIndex < ORION_ABILITY_REASON_COUNT; reasonIndex++)
        {
            g_OrionAbilityLastReportTick[client][abilityIndex][reasonIndex] = 0;
        }
    }

    g_OrionAbilityLastVomitTick[client] = 0;
    g_OrionAbilityLastJockeyRideTick[client] = 0;
    g_OrionAbilityLastJockeyVictim[client] = 0;
    g_OrionAbilityChargeStartTick[client] = 0;
    g_OrionAbilityAirStuckTicks[client] = 0;
    g_OrionAbilityScore[client] = 0.0;
    g_OrionAbilityChargeStartYaw[client] = 0.0;
    g_OrionAbilityChargeActive[client] = false;
    g_OrionAbilityChargeRotationReported[client] = false;
    g_OrionAbilityAirStuckReported[client] = false;

    if (g_OrionAbilityPreThinkHooked[client] && IsClientInGame(client))
    {
        SDKUnhook(client, SDKHook_PreThinkPost, Orion_AbilityGuard_OnPreThinkPost);
        g_OrionAbilityPreThinkHooked[client] = false;
    }
    else
    {
        g_OrionAbilityPreThinkHooked[client] = false;
    }

    if (IsClientInGame(client))
    {
        // PreThink is only used for state transitions that have no reliable
        // single event: charger rotation during charge and air-stuck velocity.
        SDKHook(client, SDKHook_PreThinkPost, Orion_AbilityGuard_OnPreThinkPost);
        g_OrionAbilityPreThinkHooked[client] = true;
    }
}

public void Orion_AbilityGuard_OnAbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_AbilityGuardEnabled())
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid", 0));
    if (!Orion_AbilityGuard_ShouldTrackSpecial(client))
    {
        return;
    }

    char abilityName[64];
    event.GetString("ability", abilityName, sizeof(abilityName), "unknown");

    int abilityIndex = -1;
    if (!Orion_AbilityGuard_TryMapAbilityName(abilityName, abilityIndex))
    {
        return;
    }

    int serverTick = GetGameTickCount();
    Orion_AbilityGuard_RecordAbilityUse(client, abilityIndex, serverTick, "ability_use");

    if (abilityIndex == ORION_ABILITY_VOMIT)
    {
        Orion_AbilityGuard_ScoreDoubleVomit(client, serverTick, "ability_use");
    }
    else if (abilityIndex == ORION_ABILITY_CHARGE)
    {
        Orion_AbilityGuard_StartChargeState(client, serverTick);
    }
}

public void Orion_AbilityGuard_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_AbilityGuardEnabled())
    {
        return;
    }

    int attacker = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("attacker", 0));
    if (!Orion_AbilityGuard_ShouldTrackSpecial(attacker) || !Orion_AbilityGuard_IsTank(attacker))
    {
        return;
    }

    char weaponName[64];
    event.GetString("weapon", weaponName, sizeof(weaponName), "unknown");
    if (!Orion_AbilityGuard_IsTankPunchWeapon(weaponName))
    {
        return;
    }

    Orion_AbilityGuard_RecordAbilityUse(attacker, ORION_ABILITY_TANK_PUNCH, GetGameTickCount(), "player_hurt");
}

public void Orion_AbilityGuard_OnPlayerStagger(Event event, const char[] name, bool dontBroadcast)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_AbilityGuardEnabled())
    {
        return;
    }

    int attacker = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("attacker", 0));
    if (!Orion_AbilityGuard_ShouldTrackSpecial(attacker))
    {
        attacker = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("userid", 0));
    }

    if (!Orion_AbilityGuard_ShouldTrackSpecial(attacker))
    {
        return;
    }

    Orion_AbilityGuard_RecordAbilityUse(attacker, ORION_ABILITY_STUMBLE, GetGameTickCount(), "player_stagger");
}

public void Orion_AbilityGuard_OnChargerChargeStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_AbilityGuardEnabled())
    {
        return;
    }

    int charger = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("userid", 0));
    if (!Orion_AbilityGuard_ShouldTrackSpecial(charger))
    {
        charger = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("attacker", 0));
    }

    if (!Orion_AbilityGuard_ShouldTrackSpecial(charger))
    {
        return;
    }

    int serverTick = GetGameTickCount();
    Orion_AbilityGuard_RecordAbilityUse(charger, ORION_ABILITY_CHARGE, serverTick, "charger_charge_start");
    Orion_AbilityGuard_StartChargeState(charger, serverTick);
}

public void Orion_AbilityGuard_OnChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_AbilityGuardEnabled())
    {
        return;
    }

    int charger = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("userid", 0));
    if (!Orion_AbilityGuard_ShouldTrackSpecial(charger))
    {
        charger = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("attacker", 0));
    }

    if (!Orion_AbilityGuard_ShouldTrackSpecial(charger))
    {
        return;
    }

    Orion_AbilityGuard_ScoreChargeRotation(charger, GetGameTickCount(), "charger_carry_start");
}

public void Orion_AbilityGuard_OnJockeyRide(Event event, const char[] name, bool dontBroadcast)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_AbilityGuardEnabled())
    {
        return;
    }

    int jockey = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("userid", 0));
    if (!Orion_AbilityGuard_ShouldTrackSpecial(jockey))
    {
        jockey = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("attacker", 0));
    }

    if (!Orion_AbilityGuard_ShouldTrackSpecial(jockey))
    {
        return;
    }

    int victim = Orion_AbilityGuard_ClientFromEventUserIdOrIndex(event.GetInt("victim", 0));
    int serverTick = GetGameTickCount();
    Orion_AbilityGuard_RecordAbilityUse(jockey, ORION_ABILITY_JOCKEY, serverTick, "jockey_ride");
    Orion_AbilityGuard_ScoreJockeyState(jockey, victim, serverTick);
}

public void Orion_AbilityGuard_OnPreThinkPost(int client)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_AbilityGuardEnabled() || !Orion_AbilityGuard_ShouldTrackSpecial(client))
    {
        Orion_AbilityGuard_ClearTransientState(client);
        return;
    }

    int serverTick = GetGameTickCount();
    if (g_OrionAbilityChargeActive[client])
    {
        Orion_AbilityGuard_ScoreChargeRotation(client, serverTick, "prethink");
        int chargeAgeTicks = serverTick - g_OrionAbilityChargeStartTick[client];
        if (chargeAgeTicks > Orion_AbilityGuard_CooldownTicks(ORION_ABILITY_CHARGE))
        {
            g_OrionAbilityChargeActive[client] = false;
        }
    }

    Orion_AbilityGuard_ScoreAirStuck(client, serverTick);
    Orion_AbilityGuard_Decay(client);
}

void Orion_AbilityGuard_RecordAbilityUse(int client, int abilityIndex, int serverTick, const char[] source)
{
    int lastUseTick = g_OrionAbilityLastUseTick[client][abilityIndex];
    if (lastUseTick > 0)
    {
        int elapsedTicks = serverTick - lastUseTick;
        int requiredTicks = Orion_AbilityGuard_CooldownTicks(abilityIndex);

        // Same-tick duplicates can be repeated event fan-out, so they are left
        // to state-specific checks and never emit duplicate cooldown evidence.
        if (elapsedTicks > 0 && elapsedTicks < requiredTicks)
        {
            float cooldownSeconds = Orion_AbilityGuard_CooldownSeconds(abilityIndex);
            Orion_AbilityGuard_ReportCooldownAbuse(client, abilityIndex, elapsedTicks, requiredTicks, cooldownSeconds, serverTick, source);
        }
    }

    g_OrionAbilityLastUseTick[client][abilityIndex] = serverTick;
}

void Orion_AbilityGuard_ReportCooldownAbuse(
    int client,
    int abilityIndex,
    int elapsedTicks,
    int requiredTicks,
    float cooldownSeconds,
    int serverTick,
    const char[] source)
{
    if (!Orion_AbilityGuard_CanReport(client, abilityIndex, ORION_ABILITY_REASON_COOLDOWN, serverTick))
    {
        return;
    }

    Orion_AbilityGuard_AddScore(client, ORION_ABILITY_COOLDOWN_SCORE);

    char abilityName[32];
    Orion_AbilityGuard_GetAbilityName(abilityIndex, abilityName, sizeof(abilityName));

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=ability_cooldown_abuse ability=%s elapsed_ticks=%d required_ticks=%d cooldown=%.2f tick=%d source=%s zombie_class=%d",
        abilityName,
        elapsedTicks,
        requiredTicks,
        cooldownSeconds,
        serverTick,
        source,
        Orion_AbilityGuard_ZombieClass(client));

    Orion_Evidence_Submit(client, "ability_guard", g_OrionAbilityScore[client], "observe", details);
}

void Orion_AbilityGuard_ReportImpossibleState(
    int client,
    int abilityIndex,
    const char[] stateName,
    float scoreDelta,
    const char[] metrics,
    int serverTick)
{
    if (!Orion_AbilityGuard_CanReport(client, abilityIndex, ORION_ABILITY_REASON_STATE, serverTick))
    {
        return;
    }

    Orion_AbilityGuard_AddScore(client, scoreDelta);

    char abilityName[32];
    Orion_AbilityGuard_GetAbilityName(abilityIndex, abilityName, sizeof(abilityName));

    char details[384];
    Format(
        details,
        sizeof(details),
        "reason=ability_state_impossible ability=%s state=%s %s tick=%d zombie_class=%d",
        abilityName,
        stateName,
        metrics,
        serverTick,
        Orion_AbilityGuard_ZombieClass(client));

    Orion_Evidence_Submit(client, "ability_guard", g_OrionAbilityScore[client], "observe", details);
}

void Orion_AbilityGuard_ScoreDoubleVomit(int client, int serverTick, const char[] source)
{
    int elapsedTicks = g_OrionAbilityLastVomitTick[client] > 0 ? serverTick - g_OrionAbilityLastVomitTick[client] : -1;
    int windowTicks = Orion_Config_AbilityGuardDoubleVomitWindowTicks();
    g_OrionAbilityLastVomitTick[client] = serverTick;

    if (elapsedTicks < 0 || elapsedTicks > windowTicks)
    {
        return;
    }

    char metrics[128];
    Format(metrics, sizeof(metrics), "elapsed_ticks=%d window_ticks=%d source=%s", elapsedTicks, windowTicks, source);
    Orion_AbilityGuard_ReportImpossibleState(client, ORION_ABILITY_VOMIT, "double_vomit", ORION_ABILITY_STATE_SCORE, metrics, serverTick);
}

void Orion_AbilityGuard_ScoreJockeyState(int client, int victim, int serverTick)
{
    int elapsedTicks = g_OrionAbilityLastJockeyRideTick[client] > 0 ? serverTick - g_OrionAbilityLastJockeyRideTick[client] : -1;
    int previousVictim = g_OrionAbilityLastJockeyVictim[client];
    g_OrionAbilityLastJockeyRideTick[client] = serverTick;
    g_OrionAbilityLastJockeyVictim[client] = victim;

    if (elapsedTicks < 0 || elapsedTicks > Orion_Config_AbilityGuardJockeyStateWindowTicks())
    {
        return;
    }

    char metrics[128];
    Format(metrics, sizeof(metrics), "elapsed_ticks=%d previous_victim=%d victim=%d", elapsedTicks, previousVictim, victim);
    Orion_AbilityGuard_ReportImpossibleState(client, ORION_ABILITY_JOCKEY, "jockey_reentry", ORION_ABILITY_STATE_SCORE, metrics, serverTick);
}

void Orion_AbilityGuard_StartChargeState(int client, int serverTick)
{
    float eyeAngles[3];
    GetClientEyeAngles(client, eyeAngles);

    g_OrionAbilityChargeStartTick[client] = serverTick;
    g_OrionAbilityChargeStartYaw[client] = eyeAngles[1];
    g_OrionAbilityChargeActive[client] = true;
    g_OrionAbilityChargeRotationReported[client] = false;
}

void Orion_AbilityGuard_ScoreChargeRotation(int client, int serverTick, const char[] source)
{
    if (!g_OrionAbilityChargeActive[client] || g_OrionAbilityChargeRotationReported[client])
    {
        return;
    }

    float eyeAngles[3];
    GetClientEyeAngles(client, eyeAngles);
    float yawDelta = Orion_NormalizeAngleDelta(eyeAngles[1] - g_OrionAbilityChargeStartYaw[client]);
    float steerCapDegrees = Orion_Config_AbilityGuardChargerSteerCapDegrees();
    if (yawDelta <= steerCapDegrees)
    {
        return;
    }

    g_OrionAbilityChargeRotationReported[client] = true;

    char metrics[128];
    Format(metrics, sizeof(metrics), "yaw_delta=%.1f steer_cap=%.1f charge_age_ticks=%d source=%s", yawDelta, steerCapDegrees, serverTick - g_OrionAbilityChargeStartTick[client], source);
    Orion_AbilityGuard_ReportImpossibleState(client, ORION_ABILITY_CHARGE, "charger_rotation", ORION_ABILITY_STATE_SCORE + 7.0, metrics, serverTick);
}

void Orion_AbilityGuard_ScoreAirStuck(int client, int serverTick)
{
    bool isAirborne = (GetEntityFlags(client) & FL_ONGROUND) == 0;
    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    float speed = SquareRoot((velocity[0] * velocity[0]) + (velocity[1] * velocity[1]) + (velocity[2] * velocity[2]));

    if (!isAirborne || speed > ORION_ABILITY_AIR_STUCK_MIN_SPEED)
    {
        g_OrionAbilityAirStuckTicks[client] = 0;
        g_OrionAbilityAirStuckReported[client] = false;
        return;
    }

    g_OrionAbilityAirStuckTicks[client]++;
    int windowTicks = Orion_Config_AbilityGuardAirStuckWindowTicks();
    if (g_OrionAbilityAirStuckReported[client] || g_OrionAbilityAirStuckTicks[client] < windowTicks)
    {
        return;
    }

    g_OrionAbilityAirStuckReported[client] = true;
    Orion_AbilityGuard_RecordAbilityUse(client, ORION_ABILITY_AIR_STUCK, serverTick, "prethink");

    char metrics[128];
    Format(metrics, sizeof(metrics), "air_ticks=%d window_ticks=%d speed=%.1f", g_OrionAbilityAirStuckTicks[client], windowTicks, speed);
    Orion_AbilityGuard_ReportImpossibleState(client, ORION_ABILITY_AIR_STUCK, "air_stuck", ORION_ABILITY_STATE_SCORE, metrics, serverTick);
}

bool Orion_AbilityGuard_TryMapAbilityName(const char[] abilityName, int& abilityIndex)
{
    if (StrContains(abilityName, "spit", false) != -1)
    {
        abilityIndex = ORION_ABILITY_SPIT;
        return true;
    }

    if (StrContains(abilityName, "vomit", false) != -1)
    {
        abilityIndex = ORION_ABILITY_VOMIT;
        return true;
    }

    if (StrContains(abilityName, "charge", false) != -1)
    {
        abilityIndex = ORION_ABILITY_CHARGE;
        return true;
    }

    if (StrContains(abilityName, "jockey", false) != -1 || StrContains(abilityName, "leap", false) != -1)
    {
        abilityIndex = ORION_ABILITY_JOCKEY;
        return true;
    }

    if (StrContains(abilityName, "punch", false) != -1 || StrContains(abilityName, "claw", false) != -1)
    {
        abilityIndex = ORION_ABILITY_TANK_PUNCH;
        return true;
    }

    return false;
}

bool Orion_AbilityGuard_ShouldTrackSpecial(int client)
{
    return Orion_IsAliveHumanPlayer(client)
        && GetClientTeam(client) == ORION_TEAM_INFECTED
        && Orion_AbilityGuard_ZombieClass(client) > 0
        && Orion_AbilityGuard_GetSendPropInt(client, "m_isGhost") == 0;
}

bool Orion_AbilityGuard_IsTank(int client)
{
    return Orion_AbilityGuard_ZombieClass(client) == ORION_ABILITY_ZOMBIECLASS_TANK;
}

bool Orion_AbilityGuard_IsTankPunchWeapon(const char[] weaponName)
{
    return StrContains(weaponName, "tank_claw", false) != -1
        || StrContains(weaponName, "claw", false) != -1
        || StrContains(weaponName, "punch", false) != -1;
}

int Orion_AbilityGuard_ClientFromEventUserIdOrIndex(int eventValue)
{
    int client = GetClientOfUserId(eventValue);
    if (client > 0)
    {
        return client;
    }

    if (eventValue > 0 && eventValue <= MaxClients && IsClientInGame(eventValue))
    {
        return eventValue;
    }

    return 0;
}

int Orion_AbilityGuard_ZombieClass(int client)
{
    return Orion_AbilityGuard_GetSendPropInt(client, "m_zombieClass");
}

int Orion_AbilityGuard_GetSendPropInt(int client, const char[] propertyName)
{
    if (client <= 0 || client > MaxClients || !HasEntProp(client, Prop_Send, propertyName))
    {
        return 0;
    }

    return GetEntProp(client, Prop_Send, propertyName);
}

bool Orion_AbilityGuard_CanReport(int client, int abilityIndex, int reasonIndex, int serverTick)
{
    if (g_OrionAbilityLastReportTick[client][abilityIndex][reasonIndex] == serverTick)
    {
        return false;
    }

    g_OrionAbilityLastReportTick[client][abilityIndex][reasonIndex] = serverTick;
    return true;
}

int Orion_AbilityGuard_CooldownTicks(int abilityIndex)
{
    float cooldownSeconds = Orion_AbilityGuard_CooldownSeconds(abilityIndex);
    if (cooldownSeconds <= 0.0)
    {
        return 0;
    }

    float tickInterval = GetTickInterval();
    if (tickInterval <= 0.0)
    {
        return 1;
    }

    return RoundToCeil(cooldownSeconds / tickInterval);
}

float Orion_AbilityGuard_CooldownSeconds(int abilityIndex)
{
    switch (abilityIndex)
    {
        case ORION_ABILITY_SPIT:
        {
            return Orion_Config_AbilityGuardSpitCooldownSeconds();
        }
        case ORION_ABILITY_VOMIT:
        {
            return Orion_Config_AbilityGuardVomitCooldownSeconds();
        }
        case ORION_ABILITY_TANK_PUNCH:
        {
            return Orion_Config_AbilityGuardTankPunchCooldownSeconds();
        }
        case ORION_ABILITY_STUMBLE:
        {
            return Orion_Config_AbilityGuardStumbleCooldownSeconds();
        }
        case ORION_ABILITY_CHARGE:
        {
            return Orion_Config_AbilityGuardChargeCooldownSeconds();
        }
        case ORION_ABILITY_JOCKEY:
        {
            return Orion_Config_AbilityGuardJockeyCooldownSeconds();
        }
        case ORION_ABILITY_AIR_STUCK:
        {
            return Orion_Config_AbilityGuardAirStuckCooldownSeconds();
        }
    }

    return 0.0;
}

void Orion_AbilityGuard_GetAbilityName(int abilityIndex, char[] abilityName, int abilityNameLength)
{
    switch (abilityIndex)
    {
        case ORION_ABILITY_SPIT:
        {
            strcopy(abilityName, abilityNameLength, "spit");
        }
        case ORION_ABILITY_VOMIT:
        {
            strcopy(abilityName, abilityNameLength, "vomit");
        }
        case ORION_ABILITY_TANK_PUNCH:
        {
            strcopy(abilityName, abilityNameLength, "tank_punch");
        }
        case ORION_ABILITY_STUMBLE:
        {
            strcopy(abilityName, abilityNameLength, "stumble");
        }
        case ORION_ABILITY_CHARGE:
        {
            strcopy(abilityName, abilityNameLength, "charge");
        }
        case ORION_ABILITY_JOCKEY:
        {
            strcopy(abilityName, abilityNameLength, "jockey");
        }
        case ORION_ABILITY_AIR_STUCK:
        {
            strcopy(abilityName, abilityNameLength, "air_stuck");
        }
        default:
        {
            strcopy(abilityName, abilityNameLength, "unknown");
        }
    }
}

void Orion_AbilityGuard_ClearTransientState(int client)
{
    g_OrionAbilityChargeActive[client] = false;
    g_OrionAbilityChargeRotationReported[client] = false;
    g_OrionAbilityAirStuckTicks[client] = 0;
    g_OrionAbilityAirStuckReported[client] = false;
}

void Orion_AbilityGuard_AddScore(int client, float scoreDelta)
{
    if (scoreDelta <= 0.0)
    {
        return;
    }

    g_OrionAbilityScore[client] += scoreDelta;
    if (g_OrionAbilityScore[client] > ORION_ABILITY_SCORE_MAX)
    {
        g_OrionAbilityScore[client] = ORION_ABILITY_SCORE_MAX;
    }
}

void Orion_AbilityGuard_Decay(int client)
{
    if (g_OrionAbilityScore[client] > 0.0)
    {
        g_OrionAbilityScore[client] -= 0.02;
        if (g_OrionAbilityScore[client] < 0.0)
        {
            g_OrionAbilityScore[client] = 0.0;
        }
    }
}
