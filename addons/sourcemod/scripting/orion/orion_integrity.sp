// L4D2 laser sight lives in the upgrade bit-vector. Fake-upgrade nospread tries
// to get the laser accuracy effect without this server-visible bit being set.
#define ORION_INTEGRITY_LASER_SIGHT_BIT (1 << 2)

float g_OrionIntegrityScore[MAXPLAYERS + 1];
Handle g_OrionIntegrityTimer = null;
Handle g_OrionNetworkTimer = null;
int g_OrionIntegrityFakeUpgradeStreak[MAXPLAYERS + 1];

void Orion_Integrity_Init()
{
    if (g_OrionIntegrityTimer == null)
    {
        g_OrionIntegrityTimer = CreateTimer(30.0, Orion_Integrity_Timer, _, TIMER_REPEAT);
    }

    if (g_OrionNetworkTimer == null)
    {
        g_OrionNetworkTimer = CreateTimer(5.0, Orion_Integrity_NetworkTimer, _, TIMER_REPEAT);
    }

    HookEvent("player_hurt", Orion_Integrity_OnPlayerHurt, EventHookMode_Post);
}

void Orion_Integrity_ResetClient(int client)
{
    g_OrionIntegrityScore[client] = 0.0;
    g_OrionIntegrityFakeUpgradeStreak[client] = 0;
}

public Action Orion_Integrity_Timer(Handle timer)
{
    if (!Orion_Config_IsEnabled())
    {
        return Plugin_Continue;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (Orion_IsHumanPlayer(client))
        {
            char cvarName[64];
            for (int queryIndex = 0; queryIndex < 8; queryIndex++)
            {
                if (Orion_CvarPolicy_QueryNext(client, cvarName, sizeof(cvarName)))
                {
                    QueryClientConVar(client, cvarName, Orion_Integrity_OnClientConVar);
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action Orion_Integrity_NetworkTimer(Handle timer)
{
    if (!Orion_Config_IsEnabled())
    {
        return Plugin_Continue;
    }

    float maxPingMs = Orion_Config_MaxPingMs();
    float maxLossPercent = Orion_Config_MaxLossPercent();

    if (maxPingMs <= 0.0 && maxLossPercent <= 0.0)
    {
        return Plugin_Continue;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!Orion_IsHumanPlayer(client))
        {
            continue;
        }

        float pingMs = GetClientAvgLatency(client, NetFlow_Both) * 1000.0;
        float lossPercent = GetClientAvgLoss(client, NetFlow_Both) * 100.0;

        if (maxPingMs > 0.0 && pingMs > maxPingMs)
        {
            g_OrionIntegrityScore[client] += 6.0;
            Orion_Integrity_ReportNetworkIfNeeded(client, "ping_high", pingMs, lossPercent);
        }

        if (maxLossPercent > 0.0 && lossPercent > maxLossPercent)
        {
            g_OrionIntegrityScore[client] += 6.0;
            Orion_Integrity_ReportNetworkIfNeeded(client, "loss_high", pingMs, lossPercent);
        }
    }

    return Plugin_Continue;
}

public void Orion_Integrity_OnClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    if (!Orion_IsHumanPlayer(client))
    {
        return;
    }

    float scoreDelta = 0.0;
    char reason[64];
    char actionLabel[16];
    char expectedLabel[64];
    if (Orion_CvarPolicy_HandleResult(client, result, cvarName, cvarValue, scoreDelta, reason, sizeof(reason), actionLabel, sizeof(actionLabel), expectedLabel, sizeof(expectedLabel)))
    {
        g_OrionIntegrityScore[client] += scoreDelta;
        Orion_Integrity_ReportIfNeeded(client, reason, cvarName, cvarValue, expectedLabel);
    }
}

public void Orion_Integrity_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (!Orion_Config_AimIntegrityEnabled() || !Orion_Integrity_IsScorableHit(attacker, victim))
    {
        return;
    }

    int lastAimTick = Orion_Aim_GetLastObservedTick(attacker);
    int tightHitStreak = Orion_Aim_GetLaserTightHitStreak(attacker);
    if (tightHitStreak < Orion_Config_AimLaserTightMinHits() || !Orion_Aim_HasRecentLaserTightHits(attacker, lastAimTick))
    {
        if (g_OrionIntegrityFakeUpgradeStreak[attacker] > 0)
        {
            g_OrionIntegrityFakeUpgradeStreak[attacker]--;
        }
        return;
    }

    int upgradeBitVec = 0;
    int upgradedPrimaryAmmoLoaded = 0;
    bool hasUpgradeBits = Orion_Integrity_TryGetUpgradeInt(attacker, "m_upgradeBitVec", upgradeBitVec);
    bool hasUpgradedAmmo = Orion_Integrity_TryGetUpgradeInt(attacker, "m_nUpgradedPrimaryAmmoLoaded", upgradedPrimaryAmmoLoaded);
    if (!hasUpgradeBits)
    {
        return;
    }

    bool hasLaserUpgrade = (upgradeBitVec & ORION_INTEGRITY_LASER_SIGHT_BIT) != 0;
    if (hasLaserUpgrade)
    {
        g_OrionIntegrityFakeUpgradeStreak[attacker] = 0;
        return;
    }

    g_OrionIntegrityFakeUpgradeStreak[attacker]++;
    g_OrionIntegrityScore[attacker] += g_OrionIntegrityFakeUpgradeStreak[attacker] >= 2 ? 24.0 : 12.0;
    Orion_Integrity_ReportFakeUpgradeIfNeeded(attacker, upgradeBitVec, hasUpgradedAmmo ? upgradedPrimaryAmmoLoaded : -1, tightHitStreak);
}

public Action Orion_Integrity_OnClientSayCommand(int client, const char[] command, const char[] message)
{
    if (!Orion_Config_ChatGuardEnabled())
    {
        return Plugin_Continue;
    }

    int controlCharacters = Orion_Integrity_CountControlCharacters(message);
    int messageLength = strlen(message);
    bool hasChatClearPattern = controlCharacters > 0 || messageLength > 190;

    if (!hasChatClearPattern)
    {
        return Plugin_Continue;
    }

    g_OrionIntegrityScore[client] += controlCharacters > 2 ? 30.0 : 18.0;

    char details[256];
    Format(details, sizeof(details), "reason=chat_clear command=%s length=%d controls=%d", command, messageLength, controlCharacters);
    Orion_Evidence_Submit(client, "chat_guard", g_OrionIntegrityScore[client], "observe", details);
    return Plugin_Handled;
}

void Orion_Integrity_OnClientSettingsChanged(int client)
{
    if (!Orion_Config_NameGuardEnabled())
    {
        return;
    }

    char playerName[MAX_NAME_LENGTH];
    GetClientName(client, playerName, sizeof(playerName));
    int controlCharacters = Orion_Integrity_CountControlCharacters(playerName);

    if (controlCharacters <= 0)
    {
        return;
    }

    g_OrionIntegrityScore[client] += 20.0;

    char details[256];
    Format(details, sizeof(details), "reason=invalid_name controls=%d", controlCharacters);
    Orion_Evidence_Submit(client, "name_guard", g_OrionIntegrityScore[client], "observe", details);
}

bool Orion_Integrity_IsScorableHit(int attacker, int victim)
{
    return Orion_IsAliveHumanPlayer(attacker)
        && victim > 0
        && victim <= MaxClients
        && victim != attacker
        && IsClientInGame(victim)
        && IsPlayerAlive(victim)
        && !IsFakeClient(victim)
        && GetClientTeam(attacker) != GetClientTeam(victim);
}

// The upgrade fields can live on the active weapon or on the player depending
// on the L4D2 item path. Every read is guarded so missing netprops fail closed
// instead of turning calibration servers into crash reproducers.
bool Orion_Integrity_TryGetUpgradeInt(int client, const char[] propName, int &propValue)
{
    if (HasEntProp(client, Prop_Send, "m_hActiveWeapon"))
    {
        int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (activeWeapon > MaxClients && IsValidEntity(activeWeapon) && HasEntProp(activeWeapon, Prop_Send, propName))
        {
            propValue = GetEntProp(activeWeapon, Prop_Send, propName);
            return true;
        }
    }

    if (HasEntProp(client, Prop_Send, propName))
    {
        propValue = GetEntProp(client, Prop_Send, propName);
        return true;
    }

    return false;
}

void Orion_Integrity_ReportFakeUpgradeIfNeeded(int client, int upgradeBitVec, int upgradedPrimaryAmmoLoaded, int tightHitStreak)
{
    float alertThreshold = Orion_Config_IntegrityThreshold();
    if (g_OrionIntegrityScore[client] < alertThreshold)
    {
        return;
    }

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=fake_upgrade_nospread upgrade_bits=%d upgraded_ammo=%d laser_bit=%d tight_hits=%d fake_upgrade_streak=%d",
        upgradeBitVec,
        upgradedPrimaryAmmoLoaded,
        ORION_INTEGRITY_LASER_SIGHT_BIT,
        tightHitStreak,
        g_OrionIntegrityFakeUpgradeStreak[client]);

    char action[16];
    strcopy(action, sizeof(action), g_OrionIntegrityScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) && g_OrionIntegrityFakeUpgradeStreak[client] >= 2 ? "ban" : "observe");
    Orion_Evidence_Submit(client, "integrity", g_OrionIntegrityScore[client], action, details);
}

int Orion_Integrity_CountControlCharacters(const char[] text)
{
    int count = 0;
    int textLength = strlen(text);

    for (int index = 0; index < textLength; index++)
    {
        int character = text[index];
        if ((character >= 0 && character < 32) || character == 127)
        {
            count++;
        }
    }

    return count;
}

void Orion_Integrity_ReportIfNeeded(int client, const char[] reason, const char[] cvarName, const char[] cvarValue, const char[] expectedLabel)
{
    float alertThreshold = Orion_Config_IntegrityThreshold();
    if (g_OrionIntegrityScore[client] < alertThreshold)
    {
        return;
    }

    char details[256];
    Format(details, sizeof(details), "reason=%s cvar=%s value=%s expected=%s", reason, cvarName, cvarValue, expectedLabel);

    char action[16];
    strcopy(action, sizeof(action), g_OrionIntegrityScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) ? "ban" : "observe");
    Orion_Evidence_Submit(client, "integrity", g_OrionIntegrityScore[client], action, details);
}

void Orion_Integrity_ReportNetworkIfNeeded(int client, const char[] reason, float pingMs, float lossPercent)
{
    float alertThreshold = Orion_Config_IntegrityThreshold();
    if (g_OrionIntegrityScore[client] < alertThreshold)
    {
        return;
    }

    char details[256];
    Format(details, sizeof(details), "reason=%s ping_ms=%.1f loss_percent=%.2f", reason, pingMs, lossPercent);

    char action[16];
    strcopy(action, sizeof(action), g_OrionIntegrityScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) ? "ban" : "observe");
    Orion_Evidence_Submit(client, "network", g_OrionIntegrityScore[client], action, details);
}
