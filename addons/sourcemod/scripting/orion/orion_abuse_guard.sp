#define ORION_ABUSE_COMMAND_WINDOW_SECONDS 1.0
#define ORION_ABUSE_COMMAND_BUDGET 22
#define ORION_ABUSE_COMMAND_LOG_INTERVAL 10
#define ORION_ABUSE_NAME_WINDOW_SECONDS 10.0
#define ORION_ABUSE_NAME_CHANGE_BUDGET 4
#define ORION_ABUSE_CHAT_CLEAR_MAX_LENGTH 190

enum OrionAbuseCommandDecision
{
    OrionAbuseCommandDecision_Allow = 0,
    OrionAbuseCommandDecision_Observe = 1,
    OrionAbuseCommandDecision_Block = 2
};

float g_OrionAbuseScore[MAXPLAYERS + 1];
float g_OrionAbuseCommandWindowStartedAt[MAXPLAYERS + 1];
int g_OrionAbuseCommandsInWindow[MAXPLAYERS + 1];
float g_OrionAbuseNameWindowStartedAt[MAXPLAYERS + 1];
int g_OrionAbuseNameChangesInWindow[MAXPLAYERS + 1];
bool g_OrionAbuseHasLastKnownName[MAXPLAYERS + 1];
char g_OrionAbuseLastKnownName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
int g_OrionVocalizeBurstCount[MAXPLAYERS + 1];
float g_OrionVocalizeLastTime[MAXPLAYERS + 1];
int g_OrionVocalizeSpamAlerts[MAXPLAYERS + 1];

void Orion_AbuseGuard_Init()
{
    AddCommandListener(Orion_AbuseGuard_OnCommand);

    for (int client = 1; client <= MaxClients; client++)
    {
        Orion_AbuseGuard_ResetClient(client);
    }
}

void Orion_AbuseGuard_ResetClient(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    g_OrionAbuseScore[client] = 0.0;
    g_OrionAbuseCommandWindowStartedAt[client] = 0.0;
    g_OrionAbuseCommandsInWindow[client] = 0;
    g_OrionAbuseNameWindowStartedAt[client] = 0.0;
    g_OrionAbuseNameChangesInWindow[client] = 0;
    g_OrionAbuseHasLastKnownName[client] = false;
    g_OrionAbuseLastKnownName[client][0] = '\0';
    g_OrionVocalizeBurstCount[client] = 0;
    g_OrionVocalizeLastTime[client] = 0.0;
    g_OrionVocalizeSpamAlerts[client] = 0;

    if (client <= MaxClients && IsClientInGame(client))
    {
        GetClientName(client, g_OrionAbuseLastKnownName[client], sizeof(g_OrionAbuseLastKnownName[]));
        g_OrionAbuseHasLastKnownName[client] = true;
    }
}

public Action Orion_AbuseGuard_OnCommand(int client, const char[] command, int argc)
{
    if (!Orion_Config_IsEnabled() || !Orion_IsHumanPlayer(client))
    {
        return Plugin_Continue;
    }

    // Vocalize (radial/voice menu) has its own budget + cooldown + kick ladder,
    // so it never touches the generic command-rate path below.
    if (StrEqual(command, "vocalize", false))
    {
        return Orion_AbuseGuard_HandleVocalize(client);
    }

    int commandsInWindow = 0;
    float commandWindowAgeSeconds = 0.0;
    Orion_AbuseGuard_RecordCommandRate(client, commandsInWindow, commandWindowAgeSeconds);

    char reason[48];
    float policyScore = 0.0;
    OrionAbuseCommandDecision decision = Orion_AbuseGuard_CommandPolicy(command, reason, sizeof(reason), policyScore);

    if (commandsInWindow > ORION_ABUSE_COMMAND_BUDGET)
    {
        float rateScore = 12.0 + float(commandsInWindow - ORION_ABUSE_COMMAND_BUDGET);
        if (rateScore > policyScore)
        {
            policyScore = rateScore;
        }

        if (decision == OrionAbuseCommandDecision_Allow)
        {
            decision = OrionAbuseCommandDecision_Observe;
            strcopy(reason, sizeof(reason), "command_rate");
        }
    }

    if (decision == OrionAbuseCommandDecision_Allow)
    {
        return Plugin_Continue;
    }

    bool shouldSubmitRateEvidence = commandsInWindow <= ORION_ABUSE_COMMAND_BUDGET + 1
        || ((commandsInWindow - ORION_ABUSE_COMMAND_BUDGET) % ORION_ABUSE_COMMAND_LOG_INTERVAL) == 0
        || decision == OrionAbuseCommandDecision_Block;

    if (shouldSubmitRateEvidence)
    {
        Orion_AbuseGuard_SubmitCommandEvidence(
            client,
            command,
            argc,
            reason,
            policyScore,
            decision,
            commandsInWindow,
            commandWindowAgeSeconds);
    }

    if (decision == OrionAbuseCommandDecision_Block)
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

Action Orion_AbuseGuard_HandleVocalize(int client)
{
    if (!Orion_Config_VocalizeGuardEnabled())
    {
        return Plugin_Continue;
    }

    float now = GetGameTime();
    float cooldownSeconds = Orion_Config_VocalizeCooldownSeconds();
    int budget = Orion_Config_VocalizeBudget();

    // A full quiet cooldown forgives the burst: fresh budget and the spam tally
    // clears once the player behaves. `now < last` catches the map-change clock
    // reset (GetGameTime restarts at 0) so a stale timestamp never lingers.
    float elapsedSeconds = now - g_OrionVocalizeLastTime[client];
    if (g_OrionVocalizeLastTime[client] > 0.0 && (elapsedSeconds >= cooldownSeconds || now < g_OrionVocalizeLastTime[client]))
    {
        g_OrionVocalizeBurstCount[client] = 0;
        g_OrionVocalizeSpamAlerts[client] = 0;
    }

    g_OrionVocalizeBurstCount[client]++;
    g_OrionVocalizeLastTime[client] = now;

    // Within budget: normal vocalizing, let it through.
    if (g_OrionVocalizeBurstCount[client] <= budget)
    {
        return Plugin_Continue;
    }

    // Over budget without waiting the cooldown: spam. Record an alert, block the
    // vocalize, and kick once the configured alert count is reached.
    g_OrionVocalizeSpamAlerts[client]++;

    char details[192];
    Format(
        details,
        sizeof(details),
        "reason=vocalize_spam count=%d budget=%d alerts=%d cooldown=%.1f",
        g_OrionVocalizeBurstCount[client],
        budget,
        g_OrionVocalizeSpamAlerts[client],
        cooldownSeconds);
    Orion_Evidence_Submit(client, "vocalize_spam", float(g_OrionVocalizeSpamAlerts[client]) * 10.0, "block", details);

    int alertsBeforeKick = Orion_Config_VocalizeAlertsBeforeKick();
    if (alertsBeforeKick > 0 && g_OrionVocalizeSpamAlerts[client] >= alertsBeforeKick)
    {
        // Phase 2 (i18n) replaces this literal with a translated phrase.
        KickClient(client, "Vocalize spam");
        g_OrionVocalizeBurstCount[client] = 0;
        g_OrionVocalizeSpamAlerts[client] = 0;
        g_OrionVocalizeLastTime[client] = 0.0;
    }

    return Plugin_Handled;
}

void Orion_AbuseGuard_OnClientSettingsChanged(int client)
{
    if (!Orion_Config_IsEnabled() || !Orion_IsHumanPlayer(client) || !Orion_Config_NameGuardEnabled())
    {
        return;
    }

    char playerName[MAX_NAME_LENGTH];
    GetClientName(client, playerName, sizeof(playerName));

    int controlCharacters = Orion_AbuseGuard_CountControlCharacters(playerName);
    int changesInWindow = 0;
    float nameWindowAgeSeconds = 0.0;
    bool nameChanged = Orion_AbuseGuard_RecordNameChange(client, playerName, changesInWindow, nameWindowAgeSeconds);

    if (controlCharacters <= 0 && (!nameChanged || changesInWindow <= ORION_ABUSE_NAME_CHANGE_BUDGET))
    {
        return;
    }

    char reason[48];
    float score = 0.0;
    OrionAbuseCommandDecision decision = OrionAbuseCommandDecision_Observe;

    if (controlCharacters > 0)
    {
        strcopy(reason, sizeof(reason), "invalid_name");
        score = controlCharacters > 2 ? 35.0 : 20.0;
        decision = OrionAbuseCommandDecision_Block;
    }
    else
    {
        strcopy(reason, sizeof(reason), "name_rate");
        score = 12.0 + float(changesInWindow - ORION_ABUSE_NAME_CHANGE_BUDGET) * 4.0;
    }

    Orion_AbuseGuard_SubmitNameEvidence(
        client,
        reason,
        score,
        decision,
        controlCharacters,
        changesInWindow,
        nameWindowAgeSeconds);
}

bool Orion_AbuseGuard_RecordNameChange(int client, const char[] playerName, int& changesInWindow, float& windowAgeSeconds)
{
    changesInWindow = 0;
    windowAgeSeconds = 0.0;

    if (client <= 0 || client > MaxClients)
    {
        return false;
    }

    if (!g_OrionAbuseHasLastKnownName[client])
    {
        strcopy(g_OrionAbuseLastKnownName[client], sizeof(g_OrionAbuseLastKnownName[]), playerName);
        g_OrionAbuseHasLastKnownName[client] = true;
        return false;
    }

    if (StrEqual(g_OrionAbuseLastKnownName[client], playerName, false))
    {
        changesInWindow = g_OrionAbuseNameChangesInWindow[client];
        float now = GetGameTime();
        windowAgeSeconds = now - g_OrionAbuseNameWindowStartedAt[client];
        return false;
    }

    float now = GetGameTime();
    windowAgeSeconds = now - g_OrionAbuseNameWindowStartedAt[client];

    if (g_OrionAbuseNameWindowStartedAt[client] <= 0.0 || windowAgeSeconds > ORION_ABUSE_NAME_WINDOW_SECONDS)
    {
        g_OrionAbuseNameWindowStartedAt[client] = now;
        g_OrionAbuseNameChangesInWindow[client] = 0;
        windowAgeSeconds = 0.0;
    }

    g_OrionAbuseNameChangesInWindow[client]++;
    changesInWindow = g_OrionAbuseNameChangesInWindow[client];
    strcopy(g_OrionAbuseLastKnownName[client], sizeof(g_OrionAbuseLastKnownName[]), playerName);
    return true;
}

OrionAbuseCommandDecision Orion_AbuseGuard_CommandPolicy(
    const char[] command,
    char[] reason,
    int reasonLength,
    float& score)
{
    reason[0] = '\0';
    score = 0.0;

    if (Orion_AbuseGuard_IsChatCommand(command))
    {
        char message[256];
        GetCmdArgString(message, sizeof(message));
        int controlCharacters = Orion_AbuseGuard_CountControlCharacters(message);
        int messageLength = strlen(message);

        if (Orion_Config_ChatGuardEnabled() && (controlCharacters > 0 || messageLength > ORION_ABUSE_CHAT_CLEAR_MAX_LENGTH))
        {
            strcopy(reason, reasonLength, "chat_clear");
            score = controlCharacters > 2 ? 35.0 : 22.0;
            return OrionAbuseCommandDecision_Block;
        }

        return OrionAbuseCommandDecision_Allow;
    }

    if (Orion_AbuseGuard_IsNameCommand(command))
    {
        char requestedName[MAX_NAME_LENGTH];
        GetCmdArgString(requestedName, sizeof(requestedName));

        int controlCharacters = Orion_AbuseGuard_CountControlCharacters(requestedName);
        if (Orion_Config_NameGuardEnabled() && controlCharacters > 0)
        {
            strcopy(reason, reasonLength, "invalid_name_command");
            score = controlCharacters > 2 ? 35.0 : 20.0;
            return OrionAbuseCommandDecision_Block;
        }

        return OrionAbuseCommandDecision_Observe;
    }

    if (Orion_AbuseGuard_IsBlockedClientCommand(command))
    {
        strcopy(reason, reasonLength, "blocked_command");
        score = 40.0;
        return OrionAbuseCommandDecision_Block;
    }

    if (Orion_AbuseGuard_IsObservedClientCommand(command))
    {
        strcopy(reason, reasonLength, "observed_command");
        score = 8.0;
        return OrionAbuseCommandDecision_Observe;
    }

    return OrionAbuseCommandDecision_Allow;
}

void Orion_AbuseGuard_RecordCommandRate(int client, int& commandsInWindow, float& windowAgeSeconds)
{
    commandsInWindow = 0;
    windowAgeSeconds = 0.0;

    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    float now = GetGameTime();
    windowAgeSeconds = now - g_OrionAbuseCommandWindowStartedAt[client];

    if (g_OrionAbuseCommandWindowStartedAt[client] <= 0.0 || windowAgeSeconds > ORION_ABUSE_COMMAND_WINDOW_SECONDS)
    {
        g_OrionAbuseCommandWindowStartedAt[client] = now;
        g_OrionAbuseCommandsInWindow[client] = 0;
        windowAgeSeconds = 0.0;
    }

    g_OrionAbuseCommandsInWindow[client]++;
    commandsInWindow = g_OrionAbuseCommandsInWindow[client];
}

void Orion_AbuseGuard_SubmitCommandEvidence(
    int client,
    const char[] command,
    int argc,
    const char[] reason,
    float score,
    OrionAbuseCommandDecision decision,
    int commandsInWindow,
    float windowAgeSeconds)
{
    g_OrionAbuseScore[client] += score;

    char action[16];
    Orion_AbuseGuard_GetEvidenceAction(decision, action, sizeof(action));

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=%s command=%s argc=%d count=%d window=%.2f",
        reason,
        command,
        argc,
        commandsInWindow,
        windowAgeSeconds);

    Orion_Evidence_Submit(client, "abuse_command", g_OrionAbuseScore[client], action, details);
}

void Orion_AbuseGuard_SubmitNameEvidence(
    int client,
    const char[] reason,
    float score,
    OrionAbuseCommandDecision decision,
    int controlCharacters,
    int changesInWindow,
    float windowAgeSeconds)
{
    g_OrionAbuseScore[client] += score;

    char action[16];
    Orion_AbuseGuard_GetEvidenceAction(decision, action, sizeof(action));

    char details[256];
    Format(
        details,
        sizeof(details),
        "reason=%s controls=%d changes=%d window=%.2f",
        reason,
        controlCharacters,
        changesInWindow,
        windowAgeSeconds);

    Orion_Evidence_Submit(client, "abuse_name", g_OrionAbuseScore[client], action, details);
}

void Orion_AbuseGuard_GetEvidenceAction(OrionAbuseCommandDecision decision, char[] action, int actionLength)
{
    if (decision == OrionAbuseCommandDecision_Block)
    {
        strcopy(action, actionLength, "block");
        return;
    }

    strcopy(action, actionLength, "observe");
}

bool Orion_AbuseGuard_IsChatCommand(const char[] command)
{
    return StrEqual(command, "say", false)
        || StrEqual(command, "say_team", false);
}

bool Orion_AbuseGuard_IsNameCommand(const char[] command)
{
    return StrEqual(command, "name", false)
        || StrEqual(command, "setinfo", false);
}

bool Orion_AbuseGuard_IsBlockedClientCommand(const char[] command)
{
    return StrEqual(command, "cl_fullupdate", false)
        || StrEqual(command, "fullupdate", false)
        || StrEqual(command, "send_me_rcon", false)
        || StrEqual(command, "q_sndrcn", false)
        || StrEqual(command, "rcon", false)
        || StrEqual(command, "rcon_password", false)
        || StrEqual(command, "sm_rcon", false)
        || StrEqual(command, "sm_cvar", false)
        || StrEqual(command, "ma_rcon", false)
        || StrEqual(command, "ent_fire", false)
        || StrEqual(command, "ent_create", false)
        || StrEqual(command, "ent_remove", false)
        || StrEqual(command, "ent_remove_all", false)
        || StrEqual(command, "npc_create", false)
        || StrEqual(command, "npc_create_aimed", false)
        || StrEqual(command, "sv_cheats", false)
        || StrEqual(command, "sv_benchmark_force_start", false)
        || StrEqual(command, "sv_soundemitter_filecheck", false)
        || StrEqual(command, "sv_soundemitter_flush", false)
        || StrEqual(command, "sv_soundscape_printdebuginfo", false)
        || StrEqual(command, "rr_reloadresponsesystems", false)
        || StrEqual(command, "snd_restart", false)
        || StrEqual(command, "soundscape_flush", false);
}

bool Orion_AbuseGuard_IsObservedClientCommand(const char[] command)
{
    return StrEqual(command, "kill", false)
        || StrEqual(command, "explode", false)
        || StrEqual(command, "jointeam", false)
        || StrEqual(command, "spectate", false)
        || StrEqual(command, "callvote", false)
        || StrEqual(command, "vote", false)
        || StrEqual(command, "menuselect", false);
}

int Orion_AbuseGuard_CountControlCharacters(const char[] text)
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
