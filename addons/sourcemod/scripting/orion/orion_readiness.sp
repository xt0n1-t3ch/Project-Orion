void Orion_Readiness_Init()
{
    RegAdminCmd("sm_orion_readiness", Orion_Readiness_Command, ADMFLAG_GENERIC, "Show Project Orion live readiness diagnostics.");
    RegAdminCmd("sm_orion_ready", Orion_Readiness_Command, ADMFLAG_GENERIC, "Alias for sm_orion_readiness.");
}

public Action Orion_Readiness_Command(int client, int args)
{
    char statusName[32];
    char modeName[32];
    char sessionLabel[64];
    char mapName[64];
    char banProvider[32];

    Orion_Readiness_GetStatusName(statusName, sizeof(statusName));
    Orion_Config_GetModeName(modeName, sizeof(modeName));
    Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));
    GetCurrentMap(mapName, sizeof(mapName));
    g_OrionBanProvider.GetString(banProvider, sizeof(banProvider));

    int humanCount = 0;
    int botCount = 0;
    int spectatorCount = 0;
    int survivorCount = 0;
    int infectedCount = 0;
    Orion_Readiness_CountClients(humanCount, botCount, spectatorCount, survivorCount, infectedCount);

    float aimAlertThreshold = Orion_Config_AimThreshold();
    float movementAlertThreshold = Orion_Config_MovementThreshold();
    float integrityAlertThreshold = Orion_Config_IntegrityThreshold();

    ReplyToCommand(client, "[Orion] readiness=%s version=%s map=%s", statusName, ORION_PLUGIN_VERSION, mapName);
    ReplyToCommand(
        client,
        "[Orion] enabled=%d mode=%s session=%s evidence_log_level=%d admin_alerts=%d",
        Orion_Config_IsEnabled(),
        modeName,
        sessionLabel,
        g_OrionEvidenceLogLevel.IntValue,
        Orion_Config_AdminAlertsEnabled());
    ReplyToCommand(
        client,
        "[Orion] players humans=%d bots=%d spectators=%d survivors=%d infected=%d",
        humanCount,
        botCount,
        spectatorCount,
        survivorCount,
        infectedCount);
    ReplyToCommand(
        client,
        "[Orion] thresholds aim=%.1f/%.1f movement=%.1f/%.1f integrity=%.1f/%.1f",
        aimAlertThreshold,
        Orion_Config_EnforceThreshold(aimAlertThreshold),
        movementAlertThreshold,
        Orion_Config_EnforceThreshold(movementAlertThreshold),
        integrityAlertThreshold,
        Orion_Config_EnforceThreshold(integrityAlertThreshold));
    ReplyToCommand(
        client,
        "[Orion] guards visibility=%d pvs=%d pvs_block=%d spawn_guard=%d angle=%d chat=%d name=%d backtrack=%d hard_mitigation=%d",
        Orion_Config_VisibilityGuardEnabled(),
        Orion_Config_VisibilityPvsEnabled(),
        Orion_Config_VisibilityPvsBlockEnabled(),
        Orion_Config_SpawnAbuseGuardEnabled(),
        Orion_Config_AngleGuardEnabled(),
        Orion_Config_ChatGuardEnabled(),
        Orion_Config_NameGuardEnabled(),
        Orion_Config_BacktrackPatchEnabled(),
        Orion_Config_HardMitigationEnabled());
    ReplyToCommand(
        client,
        "[Orion] network max_lerp_ms=%.1f interp_ratio=%.1f..%.1f max_ping_ms=%.1f max_loss_percent=%.1f ban_provider=%s ban_minutes=%d",
        Orion_Config_MaxLerpMs(),
        Orion_Config_MinInterpRatio(),
        Orion_Config_MaxInterpRatio(),
        Orion_Config_MaxPingMs(),
        Orion_Config_MaxLossPercent(),
        banProvider,
        g_OrionBanMinutes.IntValue);
    ReplyToCommand(
        client,
        "[Orion] cvar_policy policies=%d max_pending_queries=%d",
        Orion_CvarPolicy_Count(),
        ORION_CVAR_POLICY_MAX_PENDING_QUERIES);

    return Plugin_Handled;
}

void Orion_Readiness_GetStatusName(char[] statusName, int statusNameLength)
{
    if (!Orion_Config_IsEnabled())
    {
        strcopy(statusName, statusNameLength, "disabled");
        return;
    }

    if (g_OrionEvidenceLogLevel.IntValue <= 0)
    {
        strcopy(statusName, statusNameLength, "evidence_off");
        return;
    }

    if (Orion_Config_Mode() == OrionMode_Enforce || Orion_Config_VisibilityPvsBlockEnabled() || Orion_Config_HardMitigationEnabled())
    {
        strcopy(statusName, statusNameLength, "enforcement_active");
        return;
    }

    if (Orion_Config_Mode() == OrionMode_Alert)
    {
        strcopy(statusName, statusNameLength, "alert_ready");
        return;
    }

    strcopy(statusName, statusNameLength, "shadow_ready");
}

void Orion_Readiness_CountClients(
    int& humanCount,
    int& botCount,
    int& spectatorCount,
    int& survivorCount,
    int& infectedCount)
{
    for (int player = 1; player <= MaxClients; player++)
    {
        if (!IsClientInGame(player))
        {
            continue;
        }

        if (IsFakeClient(player))
        {
            botCount++;
        }
        else
        {
            humanCount++;
        }

        int team = GetClientTeam(player);
        switch (team)
        {
            case ORION_TEAM_SPECTATOR:
            {
                spectatorCount++;
            }
            case ORION_TEAM_SURVIVOR:
            {
                survivorCount++;
            }
            case ORION_TEAM_INFECTED:
            {
                infectedCount++;
            }
        }
    }
}
