ConVar g_OrionEnable = null;
ConVar g_OrionMode = null;
ConVar g_OrionAimScoreThreshold = null;
ConVar g_OrionMovementScoreThreshold = null;
ConVar g_OrionIntegrityScoreThreshold = null;
ConVar g_OrionVisibilityGuardEnable = null;
ConVar g_OrionAdminAlerts = null;
ConVar g_OrionMaxLerpMs = null;
ConVar g_OrionMaxInterpRatio = null;
ConVar g_OrionMinInterpRatio = null;
ConVar g_OrionBanMinutes = null;
ConVar g_OrionBanProvider = null;
ConVar g_OrionEvidenceLogLevel = null;

void Orion_Config_Init()
{
    g_OrionEnable = CreateConVar("orion_enable", "1", "Enable Project Orion.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_OrionMode = CreateConVar("orion_mode", "shadow", "Project Orion mode: shadow, alert, or enforce.");
    g_OrionAimScoreThreshold = CreateConVar("orion_aim_score_threshold", "75.0", "Aim evidence score required for high-confidence findings.", _, true, 0.0, true, 100.0);
    g_OrionMovementScoreThreshold = CreateConVar("orion_movement_score_threshold", "75.0", "Movement evidence score required for high-confidence findings.", _, true, 0.0, true, 100.0);
    g_OrionIntegrityScoreThreshold = CreateConVar("orion_integrity_score_threshold", "70.0", "Client integrity score required for high-confidence findings.", _, true, 0.0, true, 100.0);
    g_OrionVisibilityGuardEnable = CreateConVar("orion_visibility_guard_enable", "1", "Enable ghost infected transmit suppression.", _, true, 0.0, true, 1.0);
    g_OrionAdminAlerts = CreateConVar("orion_admin_alerts", "1", "Alert admins for high-confidence Orion evidence.", _, true, 0.0, true, 1.0);
    g_OrionMaxLerpMs = CreateConVar("orion_max_lerp_ms", "150.0", "Maximum allowed client interpolation in milliseconds.", _, true, 0.0, true, 500.0);
    g_OrionMaxInterpRatio = CreateConVar("orion_max_interp_ratio", "2.0", "Maximum allowed cl_interp_ratio.", _, true, 0.0, true, 10.0);
    g_OrionMinInterpRatio = CreateConVar("orion_min_interp_ratio", "0.0", "Minimum allowed cl_interp_ratio.", _, true, 0.0, true, 10.0);
    g_OrionBanMinutes = CreateConVar("orion_ban_minutes", "0", "Ban length in minutes for enforce mode; 0 is permanent.", _, true, 0.0);
    g_OrionBanProvider = CreateConVar("orion_ban_provider", "basebans", "Ban provider label: none, basebans, or sourcebans.");
    g_OrionEvidenceLogLevel = CreateConVar("orion_evidence_log_level", "2", "Evidence verbosity: 0 off, 1 high-confidence, 2 suspicious.", _, true, 0.0, true, 2.0);
}

bool Orion_Config_IsEnabled()
{
    return g_OrionEnable != null && g_OrionEnable.BoolValue;
}

bool Orion_Config_VisibilityGuardEnabled()
{
    return g_OrionVisibilityGuardEnable != null && g_OrionVisibilityGuardEnable.BoolValue;
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
