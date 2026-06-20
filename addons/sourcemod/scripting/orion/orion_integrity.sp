float g_OrionIntegrityScore[MAXPLAYERS + 1];
Handle g_OrionIntegrityTimer = null;

void Orion_Integrity_Init()
{
    if (g_OrionIntegrityTimer == null)
    {
        g_OrionIntegrityTimer = CreateTimer(30.0, Orion_Integrity_Timer, _, TIMER_REPEAT);
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
            QueryClientConVar(client, "cl_interp", Orion_Integrity_OnClientConVar);
            QueryClientConVar(client, "cl_interp_ratio", Orion_Integrity_OnClientConVar);
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

    if (result != ConVarQuery_Okay)
    {
        g_OrionIntegrityScore[client] += 10.0;
        Orion_Integrity_ReportIfNeeded(client, "query_failed", cvarName, cvarValue);
        return;
    }

    float floatValue = StringToFloat(cvarValue);

    if (StrEqual(cvarName, "cl_interp", false))
    {
        float lerpMs = floatValue * 1000.0;
        if (lerpMs > Orion_Config_MaxLerpMs())
        {
            g_OrionIntegrityScore[client] += 25.0;
            Orion_Integrity_ReportIfNeeded(client, "lerp_high", cvarName, cvarValue);
        }
    }
    else if (StrEqual(cvarName, "cl_interp_ratio", false))
    {
        if (floatValue > Orion_Config_MaxInterpRatio() || floatValue < Orion_Config_MinInterpRatio())
        {
            g_OrionIntegrityScore[client] += 20.0;
            Orion_Integrity_ReportIfNeeded(client, "interp_ratio_out_of_bounds", cvarName, cvarValue);
        }
    }
}

void Orion_Integrity_ReportIfNeeded(int client, const char[] reason, const char[] cvarName, const char[] cvarValue)
{
    float alertThreshold = Orion_Config_IntegrityThreshold();
    if (g_OrionIntegrityScore[client] < alertThreshold)
    {
        return;
    }

    char details[256];
    Format(details, sizeof(details), "reason=%s cvar=%s value=%s", reason, cvarName, cvarValue);

    char action[16];
    strcopy(action, sizeof(action), g_OrionIntegrityScore[client] >= Orion_Config_EnforceThreshold(alertThreshold) ? "ban" : "observe");
    Orion_Evidence_Submit(client, "integrity", g_OrionIntegrityScore[client], action, details);
}
