float g_OrionIntegrityScore[MAXPLAYERS + 1];
Handle g_OrionIntegrityTimer = null;
Handle g_OrionNetworkTimer = null;

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
}

void Orion_Integrity_ResetClient(int client)
{
    g_OrionIntegrityScore[client] = 0.0;
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
