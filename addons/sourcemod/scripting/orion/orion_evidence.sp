char g_OrionEvidenceLogPath[PLATFORM_MAX_PATH];
int g_OrionEvidenceSequence = 0;

void Orion_Evidence_Init()
{
    BuildPath(Path_SM, g_OrionEvidenceLogPath, sizeof(g_OrionEvidenceLogPath), "logs/orion.log");
    RegAdminCmd("sm_orion_session", Orion_Evidence_CommandSession, ADMFLAG_GENERIC, "Set or show the current Project Orion calibration session label.");
    RegAdminCmd("sm_orion_status", Orion_Evidence_CommandStatus, ADMFLAG_GENERIC, "Show Project Orion mode and calibration session.");
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
    char sessionLabel[64];
    Orion_Evidence_GetClientIdentity(client, authId, sizeof(authId), playerName, sizeof(playerName));
    Orion_Evidence_NormalizeQuotedValue(playerName, sizeof(playerName));

    char safeDetails[256];
    strcopy(safeDetails, sizeof(safeDetails), details);
    Orion_Evidence_NormalizeQuotedValue(safeDetails, sizeof(safeDetails));

    GetCurrentMap(mapName, sizeof(mapName));
    Orion_Config_GetModeName(modeName, sizeof(modeName));
    Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));

    g_OrionEvidenceSequence++;
    LogToFileEx(
        g_OrionEvidenceLogPath,
        "seq=%d session=%s type=%s score=%.1f action=%s client=%d steamid=%s name=\"%s\" map=%s mode=%s details=\"%s\"",
        g_OrionEvidenceSequence,
        sessionLabel,
        evidenceType,
        score,
        action,
        client,
        authId,
        playerName,
        mapName,
        modeName,
        safeDetails);

    Orion_Evidence_AlertOrEnforce(client, evidenceType, score, action, safeDetails);
}

public Action Orion_Evidence_CommandSession(int client, int args)
{
    char sessionLabel[64];

    if (args <= 0)
    {
        Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));
        ReplyToCommand(client, "[Orion] session=%s", sessionLabel);
        return Plugin_Handled;
    }

    GetCmdArgString(sessionLabel, sizeof(sessionLabel));
    Orion_Config_SetSessionLabel(sessionLabel);
    Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));
    ReplyToCommand(client, "[Orion] session set to %s", sessionLabel);
    return Plugin_Handled;
}

public Action Orion_Evidence_CommandStatus(int client, int args)
{
    char modeName[32];
    char sessionLabel[64];
    Orion_Config_GetModeName(modeName, sizeof(modeName));
    Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));
    ReplyToCommand(client, "[Orion] enabled=%d mode=%s session=%s", Orion_Config_IsEnabled(), modeName, sessionLabel);
    return Plugin_Handled;
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

void Orion_Evidence_NormalizeQuotedValue(char[] value, int valueLength)
{
    for (int index = 0; index < valueLength && value[index] != '\0'; index++)
    {
        if (value[index] == '"' || value[index] < 32 || value[index] == 127)
        {
            value[index] = '_';
        }
    }
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
