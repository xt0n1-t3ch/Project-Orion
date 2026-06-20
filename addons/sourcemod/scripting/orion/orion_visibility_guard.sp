int g_OrionVisibilityBlocked[MAXPLAYERS + 1];

void Orion_Visibility_Init()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        g_OrionVisibilityBlocked[client] = 0;
        if (IsClientInGame(client))
        {
            Orion_Visibility_HookClient(client);
        }
    }
}

void Orion_Visibility_HookClient(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        SDKHook(client, SDKHook_SetTransmit, Orion_Visibility_OnSetTransmit);
    }
}

public Action Orion_Visibility_OnSetTransmit(int entity, int observer)
{
    if (!Orion_Config_IsEnabled() || !Orion_Config_VisibilityGuardEnabled())
    {
        return Plugin_Continue;
    }

    if (!Orion_ShouldBlockPlayerTransmit(entity, observer))
    {
        return Plugin_Continue;
    }

    g_OrionVisibilityBlocked[observer]++;
    if (g_OrionVisibilityBlocked[observer] == 1 || (g_OrionVisibilityBlocked[observer] % 250) == 0)
    {
        Orion_Evidence_Submit(observer, "visibility_guard", 55.0, "observe", "blocked ghost infected transmit to survivor");
    }

    return Plugin_Handled;
}

bool Orion_ShouldBlockPlayerTransmit(int entity, int observer)
{
    if (entity <= 0 || entity > MaxClients || observer <= 0 || observer > MaxClients)
    {
        return false;
    }

    if (entity == observer || !IsClientInGame(entity) || !IsClientInGame(observer))
    {
        return false;
    }

    if (IsFakeClient(observer))
    {
        return false;
    }

    int entityTeam = GetClientTeam(entity);
    int observerTeam = GetClientTeam(observer);

    if (entityTeam != ORION_TEAM_INFECTED || observerTeam != ORION_TEAM_SURVIVOR)
    {
        return false;
    }

    if (!IsPlayerAlive(entity))
    {
        return true;
    }

    if (GetEntProp(entity, Prop_Send, "m_isGhost") == 1)
    {
        return true;
    }

    return false;
}
