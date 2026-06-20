char g_OrionEvidenceLogPath[PLATFORM_MAX_PATH];
int g_OrionEvidenceSequence = 0;

void Orion_Evidence_Init()
{
    BuildPath(Path_SM, g_OrionEvidenceLogPath, sizeof(g_OrionEvidenceLogPath), "logs/orion.log");
}

void Orion_Evidence_OnMapStart()
{
    g_OrionEvidenceSequence = 0;
}

void Orion_Evidence_Submit(int client, const char[] evidenceType, float score, const char[] action, const char[] details)
{
    if (!Orion_Config_IsEnabled() || g_OrionEvidenceLogLevel.IntValue <= 0)
    {
        return;
    }

    if (g_OrionEvidenceLogLevel.IntValue == 1 && score < 75.0)
    {
        return;
    }

    char authId[64];
    char playerName[MAX_NAME_LENGTH];
    char mapName[64];
    char modeName[32];
    Orion_Evidence_GetClientIdentity(client, authId, sizeof(authId), playerName, sizeof(playerName));
    GetCurrentMap(mapName, sizeof(mapName));
    Orion_Config_GetModeName(modeName, sizeof(modeName));

    g_OrionEvidenceSequence++;
    LogToFileEx(
        g_OrionEvidenceLogPath,
        "seq=%d type=%s score=%.1f action=%s client=%N steamid=%s name=\"%s\" map=%s mode=%s details=\"%s\"",
        g_OrionEvidenceSequence,
        evidenceType,
        score,
        action,
        client,
        authId,
        playerName,
        mapName,
        modeName,
        details);

    Orion_Evidence_AlertOrEnforce(client, evidenceType, score, action, details);
}

void Orion_Evidence_AlertOrEnforce(int client, const char[] evidenceType, float score, const char[] action, const char[] details)
{
    OrionMode mode = Orion_Config_Mode();

    if (mode == OrionMode_Shadow)
    {
        return;
    }

    if (Orion_Config_AdminAlertsEnabled())
    {
        PrintToAdmins("[Orion] %N flagged: %s score %.1f (%s)", client, evidenceType, score, details);
    }

    if (mode == OrionMode_Enforce && StrEqual(action, "ban", false))
    {
        Orion_Evidence_ApplyBan(client, evidenceType, score);
    }
}

void Orion_Evidence_ApplyBan(int client, const char[] evidenceType, float score)
{
    char providerName[32];
    g_OrionBanProvider.GetString(providerName, sizeof(providerName));

    if (StrEqual(providerName, "none", false))
    {
        LogToFileEx(g_OrionEvidenceLogPath, "ban_skipped provider=none client=%N type=%s score=%.1f", client, evidenceType, score);
        return;
    }

    char reason[128];
    Format(reason, sizeof(reason), "Project Orion: %s evidence score %.1f", evidenceType, score);
    BanClient(client, g_OrionBanMinutes.IntValue, BANFLAG_AUTO, reason, reason, "orion");
}

void Orion_Evidence_GetClientIdentity(int client, char[] authId, int authIdLength, char[] playerName, int playerNameLength)
{
    strcopy(authId, authIdLength, "unknown");
    strcopy(playerName, playerNameLength, "unknown");

    if (client <= 0 || client > MaxClients || !IsClientConnected(client))
    {
        return;
    }

    GetClientName(client, playerName, playerNameLength);
    GetClientAuthId(client, AuthId_Steam2, authId, authIdLength, true);
}

void PrintToAdmins(const char[] format, any ...)
{
    char message[256];
    VFormat(message, sizeof(message), format, 2);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && CheckCommandAccess(client, "orion_admin_alert", ADMFLAG_GENERIC, true))
        {
            PrintToChat(client, "%s", message);
        }
    }
}
