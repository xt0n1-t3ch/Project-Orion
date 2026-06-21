ConVar g_OrionEnable = null;
ConVar g_OrionMode = null;
ConVar g_OrionAimScoreThreshold = null;
ConVar g_OrionMovementScoreThreshold = null;
ConVar g_OrionIntegrityScoreThreshold = null;
ConVar g_OrionVisibilityGuardEnable = null;
ConVar g_OrionVisibilityPvsEnable = null;
ConVar g_OrionVisibilityPvsBlockEnable = null;
ConVar g_OrionVisibilityPvsGraceSeconds = null;
ConVar g_OrionVisibilityPvsMinBlockDistance = null;
ConVar g_OrionVisibilityTraceBudgetPerTick = null;
ConVar g_OrionSpawnAbuseGuardEnable = null;
ConVar g_OrionSpawnAbuseVisibleDistance = null;
ConVar g_OrionSpawnAbuseNearDistance = null;
ConVar g_OrionAdminAlerts = null;
ConVar g_OrionMaxLerpMs = null;
ConVar g_OrionMaxInterpRatio = null;
ConVar g_OrionMinInterpRatio = null;
ConVar g_OrionAngleGuardEnable = null;
ConVar g_OrionChatGuardEnable = null;
ConVar g_OrionNameGuardEnable = null;
ConVar g_OrionVocalizeGuardEnable = null;
ConVar g_OrionVocalizeBudget = null;
ConVar g_OrionVocalizeCooldownSeconds = null;
ConVar g_OrionVocalizeAlertsBeforeKick = null;
ConVar g_OrionAbilityGuardEnable = null;
ConVar g_OrionAbilityGuardSpitCooldownSeconds = null;
ConVar g_OrionAbilityGuardVomitCooldownSeconds = null;
ConVar g_OrionAbilityGuardTankPunchCooldownSeconds = null;
ConVar g_OrionAbilityGuardStumbleCooldownSeconds = null;
ConVar g_OrionAbilityGuardChargeCooldownSeconds = null;
ConVar g_OrionAbilityGuardJockeyCooldownSeconds = null;
ConVar g_OrionAbilityGuardAirStuckCooldownSeconds = null;
ConVar g_OrionAbilityGuardDoubleVomitWindowTicks = null;
ConVar g_OrionAbilityGuardJockeyStateWindowTicks = null;
ConVar g_OrionAbilityGuardChargerSteerCapDegrees = null;
ConVar g_OrionAbilityGuardAirStuckWindowTicks = null;
ConVar g_OrionAlertAudienceDefault = null;
StringMap g_OrionAlertAudienceCvars = null;

// Detection types that get an individually-configurable alert audience cvar.
static const char ORION_ALERT_AUDIENCE_TYPES[][] =
{
    "aim", "movement", "usercmd_guard", "lag_exploit", "visibility_guard",
    "spawn_guard", "abuse_command", "abuse_name", "angle_guard", "integrity",
    "vocalize_spam", "ability_guard"
};
ConVar g_OrionBacktrackPatchEnable = null;
ConVar g_OrionBacktrackToleranceTicks = null;
ConVar g_OrionHardMitigationEnable = null;
ConVar g_OrionMaxPingMs = null;
ConVar g_OrionMaxLossPercent = null;
ConVar g_OrionBanMinutes = null;
ConVar g_OrionBanProvider = null;
ConVar g_OrionEvidenceLogLevel = null;
ConVar g_OrionSessionLabel = null;

void Orion_Config_Init()
{
    g_OrionEnable = CreateConVar("orion_enable", "1", "Enable Project Orion.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_OrionMode = CreateConVar("orion_mode", "shadow", "Project Orion mode: shadow, alert, or enforce.");
    g_OrionAimScoreThreshold = CreateConVar("orion_aim_score_threshold", "75.0", "Aim evidence score required for high-confidence findings.", _, true, 0.0, true, 100.0);
    g_OrionMovementScoreThreshold = CreateConVar("orion_movement_score_threshold", "75.0", "Movement evidence score required for high-confidence findings.", _, true, 0.0, true, 100.0);
    g_OrionIntegrityScoreThreshold = CreateConVar("orion_integrity_score_threshold", "70.0", "Client integrity score required for high-confidence findings.", _, true, 0.0, true, 100.0);
    g_OrionVisibilityGuardEnable = CreateConVar("orion_visibility_guard_enable", "1", "Enable ghost infected transmit suppression.", _, true, 0.0, true, 1.0);
    g_OrionVisibilityPvsEnable = CreateConVar("orion_visibility_pvs_enable", "1", "Enable L4D2 PVS visibility evidence for enemy player transmit decisions.", _, true, 0.0, true, 1.0);
    g_OrionVisibilityPvsBlockEnable = CreateConVar("orion_visibility_pvs_block_enable", "0", "Block enemy player transmit when Orion PVS proves the target is not visible.", _, true, 0.0, true, 1.0);
    g_OrionVisibilityPvsGraceSeconds = CreateConVar("orion_visibility_pvs_grace_seconds", "3.0", "Seconds to keep enemy transmit after last proven visibility.", _, true, 0.0, true, 10.0);
    g_OrionVisibilityPvsMinBlockDistance = CreateConVar("orion_visibility_pvs_min_block_distance", "900.0", "Minimum enemy distance before PVS block mode may suppress transmit.", _, true, 0.0, true, 5000.0);
    g_OrionVisibilityTraceBudgetPerTick = CreateConVar("orion_visibility_trace_budget_per_tick", "512", "Maximum Orion visibility traces per server tick before fail-open.", _, true, 1.0, true, 4096.0);
    g_OrionSpawnAbuseGuardEnable = CreateConVar("orion_spawn_abuse_guard_enable", "1", "Log infected spawn materialization near or visible to survivors.", _, true, 0.0, true, 1.0);
    g_OrionSpawnAbuseVisibleDistance = CreateConVar("orion_spawn_abuse_visible_distance", "650.0", "Maximum visible survivor distance for infected spawn-abuse evidence.", _, true, 0.0, true, 3000.0);
    g_OrionSpawnAbuseNearDistance = CreateConVar("orion_spawn_abuse_near_distance", "250.0", "Maximum proximity distance for infected spawn-abuse evidence even without LOS.", _, true, 0.0, true, 1500.0);
    g_OrionAdminAlerts = CreateConVar("orion_admin_alerts", "1", "Alert admins for high-confidence Orion evidence.", _, true, 0.0, true, 1.0);
    g_OrionMaxLerpMs = CreateConVar("orion_max_lerp_ms", "150.0", "Maximum allowed client interpolation in milliseconds.", _, true, 0.0, true, 500.0);
    g_OrionMaxInterpRatio = CreateConVar("orion_max_interp_ratio", "2.0", "Maximum allowed cl_interp_ratio.", _, true, 0.0, true, 10.0);
    g_OrionMinInterpRatio = CreateConVar("orion_min_interp_ratio", "0.0", "Minimum allowed cl_interp_ratio.", _, true, 0.0, true, 10.0);
    g_OrionAngleGuardEnable = CreateConVar("orion_angle_guard_enable", "1", "Score and patch impossible client view angles.", _, true, 0.0, true, 1.0);
    g_OrionChatGuardEnable = CreateConVar("orion_chat_guard_enable", "1", "Block chat-clear/control-character abuse.", _, true, 0.0, true, 1.0);
    g_OrionNameGuardEnable = CreateConVar("orion_name_guard_enable", "1", "Score newline/control-character names.", _, true, 0.0, true, 1.0);
    g_OrionVocalizeGuardEnable = CreateConVar("orion_vocalize_guard_enable", "1", "Detect and punish vocalize spam (radial-menu/voice command flooding).", _, true, 0.0, true, 1.0);
    g_OrionVocalizeBudget = CreateConVar("orion_vocalize_budget", "5", "Vocalizes a player may use in a burst before spam alerts begin.", _, true, 1.0, true, 50.0);
    g_OrionVocalizeCooldownSeconds = CreateConVar("orion_vocalize_cooldown_seconds", "3.0", "Quiet seconds after the budget that forgive the burst; vocalizing before it elapses counts as spam.", _, true, 0.5, true, 30.0);
    g_OrionVocalizeAlertsBeforeKick = CreateConVar("orion_vocalize_alerts_before_kick", "3", "Spam alerts a player accumulates before Orion kicks them; 0 disables the kick.", _, true, 0.0, true, 20.0);

    g_OrionAbilityGuardEnable = CreateConVar("orion_ability_guard_enable", "1", "Detect special-infected ability glitches (infinite spit, double vomit, infinite tank punch, infinite stumble, charger rotation, jockey re-entry, air stuck).", _, true, 0.0, true, 1.0);
    g_OrionAbilityGuardSpitCooldownSeconds = CreateConVar("orion_ability_guard_spit_cooldown_seconds", "14.0", "Minimum legal seconds between Spitter spits; faster is cooldown abuse. CONFIRM ON LIVE.", _, true, 0.0, true, 60.0);
    g_OrionAbilityGuardVomitCooldownSeconds = CreateConVar("orion_ability_guard_vomit_cooldown_seconds", "1.0", "Minimum legal seconds between Boomer vomits. CONFIRM ON LIVE.", _, true, 0.0, true, 60.0);
    g_OrionAbilityGuardTankPunchCooldownSeconds = CreateConVar("orion_ability_guard_tank_punch_cooldown_seconds", "1.5", "Minimum legal seconds between Tank punches. CONFIRM ON LIVE.", _, true, 0.0, true, 60.0);
    g_OrionAbilityGuardStumbleCooldownSeconds = CreateConVar("orion_ability_guard_stumble_cooldown_seconds", "1.0", "Minimum legal seconds between stumbles a special infected inflicts. CONFIRM ON LIVE.", _, true, 0.0, true, 60.0);
    g_OrionAbilityGuardChargeCooldownSeconds = CreateConVar("orion_ability_guard_charge_cooldown_seconds", "12.0", "Minimum legal seconds between Charger charges. CONFIRM ON LIVE.", _, true, 0.0, true, 60.0);
    g_OrionAbilityGuardJockeyCooldownSeconds = CreateConVar("orion_ability_guard_jockey_cooldown_seconds", "5.0", "Minimum legal seconds between Jockey leaps. CONFIRM ON LIVE.", _, true, 0.0, true, 60.0);
    g_OrionAbilityGuardAirStuckCooldownSeconds = CreateConVar("orion_ability_guard_air_stuck_cooldown_seconds", "2.0", "Cooldown between air-stuck reports for one client. CONFIRM ON LIVE.", _, true, 0.0, true, 60.0);
    g_OrionAbilityGuardDoubleVomitWindowTicks = CreateConVar("orion_ability_guard_double_vomit_window_ticks", "10", "Ticks within which a second vomit counts as a double-vomit glitch. CONFIRM ON LIVE.", _, true, 1.0, true, 200.0);
    g_OrionAbilityGuardJockeyStateWindowTicks = CreateConVar("orion_ability_guard_jockey_state_window_ticks", "32", "Ticks within which a re-ride counts as a jockey state glitch. CONFIRM ON LIVE.", _, true, 1.0, true, 200.0);
    g_OrionAbilityGuardChargerSteerCapDegrees = CreateConVar("orion_ability_guard_charger_steer_cap_degrees", "30.0", "Maximum legal yaw a Charger may turn during a charge; more is charger-rotation. CONFIRM ON LIVE.", _, true, 0.0, true, 180.0);
    g_OrionAbilityGuardAirStuckWindowTicks = CreateConVar("orion_ability_guard_air_stuck_window_ticks", "33", "Consecutive airborne near-zero-speed ticks before air-stuck is reported. CONFIRM ON LIVE.", _, true, 1.0, true, 400.0);

    g_OrionAlertAudienceDefault = CreateConVar("orion_alert_audience_default", "admins", "Default alert audience for detections without a specific override. Values: everyone, admins, flag:<flags>, off.");
    g_OrionAlertAudienceCvars = new StringMap();
    for (int audienceIndex = 0; audienceIndex < sizeof(ORION_ALERT_AUDIENCE_TYPES); audienceIndex++)
    {
        char audienceCvarName[64];
        Format(audienceCvarName, sizeof(audienceCvarName), "orion_alert_audience_%s", ORION_ALERT_AUDIENCE_TYPES[audienceIndex]);
        char audienceCvarDesc[160];
        Format(audienceCvarDesc, sizeof(audienceCvarDesc), "Who sees %s alerts. Values: everyone, admins, flag:<flags>, off.", ORION_ALERT_AUDIENCE_TYPES[audienceIndex]);
        ConVar audienceCvar = CreateConVar(audienceCvarName, "admins", audienceCvarDesc);
        g_OrionAlertAudienceCvars.SetValue(ORION_ALERT_AUDIENCE_TYPES[audienceIndex], audienceCvar);
    }
    g_OrionBacktrackPatchEnable = CreateConVar("orion_backtrack_patch_enable", "1", "Score suspicious command tick drift/backtrack windows.", _, true, 0.0, true, 1.0);
    g_OrionBacktrackToleranceTicks = CreateConVar("orion_backtrack_tolerance_ticks", "2", "Allowed command tick drift before backtrack evidence is scored.", _, true, 0.0, true, 16.0);
    g_OrionHardMitigationEnable = CreateConVar("orion_hard_mitigation_enable", "1", "Allow Orion to patch unsafe usercmd values outside shadow mode.", _, true, 0.0, true, 1.0);
    g_OrionMaxPingMs = CreateConVar("orion_max_ping_ms", "0", "Maximum allowed ping in milliseconds; 0 disables ping enforcement evidence.", _, true, 0.0, true, 1000.0);
    g_OrionMaxLossPercent = CreateConVar("orion_max_loss_percent", "0.0", "Maximum allowed packet loss percent; 0 disables packet-loss evidence.", _, true, 0.0, true, 100.0);
    g_OrionBanMinutes = CreateConVar("orion_ban_minutes", "0", "Ban length in minutes for enforce mode; 0 is permanent.", _, true, 0.0);
    g_OrionBanProvider = CreateConVar("orion_ban_provider", "basebans", "Ban provider label: none, basebans, or sourcebans.");
    g_OrionEvidenceLogLevel = CreateConVar("orion_evidence_log_level", "2", "Evidence verbosity: 0 off, 1 high-confidence, 2 suspicious.", _, true, 0.0, true, 2.0);
    g_OrionSessionLabel = CreateConVar("orion_session_label", "default", "Current Project Orion calibration session label.");
}

bool Orion_Config_IsEnabled()
{
    return g_OrionEnable != null && g_OrionEnable.BoolValue;
}

bool Orion_Config_VisibilityGuardEnabled()
{
    return g_OrionVisibilityGuardEnable != null && g_OrionVisibilityGuardEnable.BoolValue;
}

bool Orion_Config_VisibilityPvsEnabled()
{
    return g_OrionVisibilityPvsEnable != null && g_OrionVisibilityPvsEnable.BoolValue;
}

bool Orion_Config_VisibilityPvsBlockEnabled()
{
    return g_OrionVisibilityPvsBlockEnable != null && g_OrionVisibilityPvsBlockEnable.BoolValue;
}

float Orion_Config_VisibilityPvsGraceSeconds()
{
    return g_OrionVisibilityPvsGraceSeconds.FloatValue;
}

float Orion_Config_VisibilityPvsMinBlockDistance()
{
    return g_OrionVisibilityPvsMinBlockDistance.FloatValue;
}

int Orion_Config_VisibilityTraceBudgetPerTick()
{
    return g_OrionVisibilityTraceBudgetPerTick.IntValue;
}

bool Orion_Config_SpawnAbuseGuardEnabled()
{
    return g_OrionSpawnAbuseGuardEnable != null && g_OrionSpawnAbuseGuardEnable.BoolValue;
}

float Orion_Config_SpawnAbuseVisibleDistance()
{
    return g_OrionSpawnAbuseVisibleDistance.FloatValue;
}

float Orion_Config_SpawnAbuseNearDistance()
{
    return g_OrionSpawnAbuseNearDistance.FloatValue;
}

bool Orion_Config_AdminAlertsEnabled()
{
    return g_OrionAdminAlerts != null && g_OrionAdminAlerts.BoolValue;
}

OrionMode Orion_Config_Mode()
{
    char modeName[32];
    g_OrionMode.GetString(modeName, sizeof(modeName));

    if (StrEqual(modeName, "enforce", false))
    {
        return OrionMode_Enforce;
    }

    if (StrEqual(modeName, "alert", false))
    {
        return OrionMode_Alert;
    }

    return OrionMode_Shadow;
}

void Orion_Config_GetModeName(char[] modeName, int modeNameLength)
{
    g_OrionMode.GetString(modeName, modeNameLength);
}

float Orion_Config_AimThreshold()
{
    return g_OrionAimScoreThreshold.FloatValue;
}

float Orion_Config_MovementThreshold()
{
    return g_OrionMovementScoreThreshold.FloatValue;
}

float Orion_Config_IntegrityThreshold()
{
    return g_OrionIntegrityScoreThreshold.FloatValue;
}

float Orion_Config_EnforceThreshold(float alertThreshold)
{
    float enforceThreshold = alertThreshold + 15.0;
    if (enforceThreshold > 95.0)
    {
        enforceThreshold = 95.0;
    }

    return enforceThreshold;
}

float Orion_Config_MaxLerpMs()
{
    return g_OrionMaxLerpMs.FloatValue;
}

float Orion_Config_MaxInterpRatio()
{
    return g_OrionMaxInterpRatio.FloatValue;
}

float Orion_Config_MinInterpRatio()
{
    return g_OrionMinInterpRatio.FloatValue;
}

bool Orion_Config_AngleGuardEnabled()
{
    return g_OrionAngleGuardEnable != null && g_OrionAngleGuardEnable.BoolValue;
}

bool Orion_Config_ChatGuardEnabled()
{
    return g_OrionChatGuardEnable != null && g_OrionChatGuardEnable.BoolValue;
}

bool Orion_Config_NameGuardEnabled()
{
    return g_OrionNameGuardEnable != null && g_OrionNameGuardEnable.BoolValue;
}

bool Orion_Config_VocalizeGuardEnabled()
{
    return g_OrionVocalizeGuardEnable != null && g_OrionVocalizeGuardEnable.BoolValue;
}

int Orion_Config_VocalizeBudget()
{
    return g_OrionVocalizeBudget.IntValue;
}

float Orion_Config_VocalizeCooldownSeconds()
{
    return g_OrionVocalizeCooldownSeconds.FloatValue;
}

int Orion_Config_VocalizeAlertsBeforeKick()
{
    return g_OrionVocalizeAlertsBeforeKick.IntValue;
}

bool Orion_Config_AbilityGuardEnabled()
{
    return g_OrionAbilityGuardEnable != null && g_OrionAbilityGuardEnable.BoolValue;
}

float Orion_Config_AbilityGuardSpitCooldownSeconds()
{
    return g_OrionAbilityGuardSpitCooldownSeconds.FloatValue;
}

float Orion_Config_AbilityGuardVomitCooldownSeconds()
{
    return g_OrionAbilityGuardVomitCooldownSeconds.FloatValue;
}

float Orion_Config_AbilityGuardTankPunchCooldownSeconds()
{
    return g_OrionAbilityGuardTankPunchCooldownSeconds.FloatValue;
}

float Orion_Config_AbilityGuardStumbleCooldownSeconds()
{
    return g_OrionAbilityGuardStumbleCooldownSeconds.FloatValue;
}

float Orion_Config_AbilityGuardChargeCooldownSeconds()
{
    return g_OrionAbilityGuardChargeCooldownSeconds.FloatValue;
}

float Orion_Config_AbilityGuardJockeyCooldownSeconds()
{
    return g_OrionAbilityGuardJockeyCooldownSeconds.FloatValue;
}

float Orion_Config_AbilityGuardAirStuckCooldownSeconds()
{
    return g_OrionAbilityGuardAirStuckCooldownSeconds.FloatValue;
}

int Orion_Config_AbilityGuardDoubleVomitWindowTicks()
{
    return g_OrionAbilityGuardDoubleVomitWindowTicks.IntValue;
}

int Orion_Config_AbilityGuardJockeyStateWindowTicks()
{
    return g_OrionAbilityGuardJockeyStateWindowTicks.IntValue;
}

float Orion_Config_AbilityGuardChargerSteerCapDegrees()
{
    return g_OrionAbilityGuardChargerSteerCapDegrees.FloatValue;
}

int Orion_Config_AbilityGuardAirStuckWindowTicks()
{
    return g_OrionAbilityGuardAirStuckWindowTicks.IntValue;
}

void Orion_Config_GetAlertAudience(const char[] evidenceType, char[] buffer, int bufferLength)
{
    ConVar audienceCvar;
    if (g_OrionAlertAudienceCvars != null
        && g_OrionAlertAudienceCvars.GetValue(evidenceType, audienceCvar)
        && audienceCvar != null)
    {
        audienceCvar.GetString(buffer, bufferLength);
        return;
    }

    if (g_OrionAlertAudienceDefault != null)
    {
        g_OrionAlertAudienceDefault.GetString(buffer, bufferLength);
        return;
    }

    strcopy(buffer, bufferLength, "admins");
}

bool Orion_Config_BacktrackPatchEnabled()
{
    return g_OrionBacktrackPatchEnable != null && g_OrionBacktrackPatchEnable.BoolValue;
}

int Orion_Config_BacktrackToleranceTicks()
{
    return g_OrionBacktrackToleranceTicks.IntValue;
}

bool Orion_Config_HardMitigationEnabled()
{
    return g_OrionHardMitigationEnable != null && g_OrionHardMitigationEnable.BoolValue && Orion_Config_Mode() != OrionMode_Shadow;
}

float Orion_Config_MaxPingMs()
{
    return g_OrionMaxPingMs.FloatValue;
}

float Orion_Config_MaxLossPercent()
{
    return g_OrionMaxLossPercent.FloatValue;
}

void Orion_Config_GetSessionLabel(char[] sessionLabel, int sessionLabelLength)
{
    g_OrionSessionLabel.GetString(sessionLabel, sessionLabelLength);
    Orion_Config_NormalizeLabel(sessionLabel, sessionLabelLength);
}

void Orion_Config_SetSessionLabel(const char[] sessionLabel)
{
    char normalizedLabel[64];
    strcopy(normalizedLabel, sizeof(normalizedLabel), sessionLabel);
    Orion_Config_NormalizeLabel(normalizedLabel, sizeof(normalizedLabel));
    g_OrionSessionLabel.SetString(normalizedLabel);
}

void Orion_Config_NormalizeLabel(char[] sessionLabel, int sessionLabelLength)
{
    bool hasVisibleCharacter = false;

    for (int index = 0; index < sessionLabelLength && sessionLabel[index] != '\0'; index++)
    {
        if (sessionLabel[index] <= 32 || sessionLabel[index] == '"' || sessionLabel[index] == '\'' || sessionLabel[index] == '=')
        {
            sessionLabel[index] = '_';
        }
        else
        {
            hasVisibleCharacter = true;
        }
    }

    if (!hasVisibleCharacter)
    {
        strcopy(sessionLabel, sessionLabelLength, "default");
    }
}
