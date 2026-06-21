char g_OrionEvidenceLogPath[PLATFORM_MAX_PATH];
int g_OrionEvidenceSequence = 0;

#define ORION_EVIDENCE_DEDUP_BUCKETS 64
#define ORION_EVIDENCE_DEDUP_WINDOW_SECONDS 5.0
#define ORION_EVIDENCE_RECENT_LIMIT 10

bool g_OrionEvidenceDedupActive[ORION_EVIDENCE_DEDUP_BUCKETS];
int g_OrionEvidenceDedupClient[ORION_EVIDENCE_DEDUP_BUCKETS];
char g_OrionEvidenceDedupType[ORION_EVIDENCE_DEDUP_BUCKETS][32];
char g_OrionEvidenceDedupReason[ORION_EVIDENCE_DEDUP_BUCKETS][64];
char g_OrionEvidenceDedupAction[ORION_EVIDENCE_DEDUP_BUCKETS][32];
char g_OrionEvidenceDedupDetails[ORION_EVIDENCE_DEDUP_BUCKETS][256];
char g_OrionEvidenceDedupAuthId[ORION_EVIDENCE_DEDUP_BUCKETS][64];
char g_OrionEvidenceDedupPlayerName[ORION_EVIDENCE_DEDUP_BUCKETS][MAX_NAME_LENGTH];
char g_OrionEvidenceDedupMapName[ORION_EVIDENCE_DEDUP_BUCKETS][64];
char g_OrionEvidenceDedupModeName[ORION_EVIDENCE_DEDUP_BUCKETS][32];
char g_OrionEvidenceDedupSessionLabel[ORION_EVIDENCE_DEDUP_BUCKETS][64];
float g_OrionEvidenceDedupScore[ORION_EVIDENCE_DEDUP_BUCKETS];
float g_OrionEvidenceDedupFirstAt[ORION_EVIDENCE_DEDUP_BUCKETS];
float g_OrionEvidenceDedupLastAt[ORION_EVIDENCE_DEDUP_BUCKETS];
int g_OrionEvidenceDedupRepeatCount[ORION_EVIDENCE_DEDUP_BUCKETS];
Handle g_OrionEvidenceDedupTimer[ORION_EVIDENCE_DEDUP_BUCKETS];

int g_OrionEvidenceRecentSequence[ORION_EVIDENCE_RECENT_LIMIT];
char g_OrionEvidenceRecentPlayerName[ORION_EVIDENCE_RECENT_LIMIT][MAX_NAME_LENGTH];
char g_OrionEvidenceRecentType[ORION_EVIDENCE_RECENT_LIMIT][32];
char g_OrionEvidenceRecentAction[ORION_EVIDENCE_RECENT_LIMIT][32];
char g_OrionEvidenceRecentDetails[ORION_EVIDENCE_RECENT_LIMIT][256];
float g_OrionEvidenceRecentScore[ORION_EVIDENCE_RECENT_LIMIT];
int g_OrionEvidenceRecentRepeatCount[ORION_EVIDENCE_RECENT_LIMIT];
int g_OrionEvidenceRecentWriteIndex = 0;
int g_OrionEvidenceRecentCount = 0;

void Orion_Evidence_Init()
{
    BuildPath(Path_SM, g_OrionEvidenceLogPath, sizeof(g_OrionEvidenceLogPath), "logs/orion.log");
    RegAdminCmd("sm_orion_session", Orion_Evidence_CommandSession, ADMFLAG_GENERIC, "orion.command.session");
    RegAdminCmd("sm_orion_status", Orion_Evidence_CommandStatus, ADMFLAG_GENERIC, "orion.command.status");
    RegAdminCmd("sm_orion_log", Orion_Evidence_CommandLog, ADMFLAG_GENERIC, "orion.command.log");
}

void Orion_Evidence_OnMapStart()
{
    Orion_Evidence_FlushAllDedupBuckets();
    Orion_Evidence_ClearRecentLog();
    g_OrionEvidenceSequence = 0;
}

void Orion_Evidence_ResetClient(int client)
{
    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    Orion_Evidence_FlushDedupBucketsForClient(client);
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

    bool shouldDispatch = Orion_Evidence_RecordDedupedRow(
        client,
        evidenceType,
        score,
        action,
        safeDetails,
        authId,
        playerName,
        mapName,
        modeName,
        sessionLabel);

    if (shouldDispatch)
    {
        Orion_Evidence_AlertOrEnforce(client, evidenceType, score, action);
    }
}

public Action Orion_Evidence_CommandSession(int client, int args)
{
    char sessionLabel[64];

    if (args <= 0)
    {
        Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));
        Orion_Messages_ReplySessionCurrent(client, sessionLabel);
        return Plugin_Handled;
    }

    GetCmdArgString(sessionLabel, sizeof(sessionLabel));
    Orion_Config_SetSessionLabel(sessionLabel);
    Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));
    Orion_Messages_ReplySessionUpdated(client, sessionLabel);
    return Plugin_Handled;
}

public Action Orion_Evidence_CommandStatus(int client, int args)
{
    char modeName[32];
    char sessionLabel[64];
    Orion_Config_GetModeName(modeName, sizeof(modeName));
    Orion_Config_GetSessionLabel(sessionLabel, sizeof(sessionLabel));
    Orion_Messages_ReplyStatus(client, Orion_Config_IsEnabled(), modeName, sessionLabel);
    return Plugin_Handled;
}

public Action Orion_Evidence_CommandLog(int client, int args)
{
    int limit = ORION_EVIDENCE_RECENT_LIMIT;

    if (args > 0)
    {
        char limitText[16];
        GetCmdArg(1, limitText, sizeof(limitText));
        limit = StringToInt(limitText);
    }

    if (limit < 1)
    {
        limit = 1;
    }
    else if (limit > ORION_EVIDENCE_RECENT_LIMIT)
    {
        limit = ORION_EVIDENCE_RECENT_LIMIT;
    }

    Orion_Evidence_FlushAllDedupBuckets();
    Orion_Messages_ReplyLogHeader(client, limit);

    if (g_OrionEvidenceRecentCount <= 0)
    {
        Orion_Messages_ReplyLogEmpty(client);
        return Plugin_Handled;
    }

    int emitted = 0;
    for (int offset = 0; offset < g_OrionEvidenceRecentCount && emitted < limit; offset++)
    {
        int index = g_OrionEvidenceRecentWriteIndex - 1 - offset;
        while (index < 0)
        {
            index += ORION_EVIDENCE_RECENT_LIMIT;
        }

        Orion_Messages_ReplyLogEntry(
            client,
            g_OrionEvidenceRecentSequence[index],
            g_OrionEvidenceRecentPlayerName[index],
            g_OrionEvidenceRecentType[index],
            g_OrionEvidenceRecentScore[index],
            g_OrionEvidenceRecentAction[index],
            g_OrionEvidenceRecentDetails[index],
            g_OrionEvidenceRecentRepeatCount[index]);
        emitted++;
    }

    return Plugin_Handled;
}

void Orion_Evidence_AlertOrEnforce(int client, const char[] evidenceType, float score, const char[] action)
{
    OrionMode mode = Orion_Config_Mode();

    if (mode == OrionMode_Shadow)
    {
        return;
    }

    Orion_Alerts_Dispatch(client, evidenceType, score, action);

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
    Orion_Messages_FormatBanReason(client, evidenceType, score, reason, sizeof(reason));
    BanClient(client, g_OrionBanMinutes.IntValue, BANFLAG_AUTO, reason, reason, "orion");
}

bool Orion_Evidence_RecordDedupedRow(
    int client,
    const char[] evidenceType,
    float score,
    const char[] action,
    const char[] safeDetails,
    const char[] authId,
    const char[] playerName,
    const char[] mapName,
    const char[] modeName,
    const char[] sessionLabel)
{
    float now = GetGameTime();
    char reason[64];
    Orion_Evidence_ExtractReasonToken(safeDetails, reason, sizeof(reason));

    int duplicateBucket = Orion_Evidence_FindDuplicateBucket(client, evidenceType, reason, action, now);
    if (duplicateBucket >= 0)
    {
        g_OrionEvidenceDedupRepeatCount[duplicateBucket]++;
        g_OrionEvidenceDedupLastAt[duplicateBucket] = now;
        if (score > g_OrionEvidenceDedupScore[duplicateBucket])
        {
            g_OrionEvidenceDedupScore[duplicateBucket] = score;
        }

        strcopy(g_OrionEvidenceDedupDetails[duplicateBucket], sizeof(g_OrionEvidenceDedupDetails[]), safeDetails);
        return false;
    }

    int bucket = Orion_Evidence_FindFreeDedupBucket();
    if (bucket < 0)
    {
        bucket = Orion_Evidence_FindOldestDedupBucket();
        Orion_Evidence_FlushDedupBucket(bucket);
    }

    g_OrionEvidenceDedupActive[bucket] = true;
    g_OrionEvidenceDedupClient[bucket] = client;
    strcopy(g_OrionEvidenceDedupType[bucket], sizeof(g_OrionEvidenceDedupType[]), evidenceType);
    strcopy(g_OrionEvidenceDedupReason[bucket], sizeof(g_OrionEvidenceDedupReason[]), reason);
    strcopy(g_OrionEvidenceDedupAction[bucket], sizeof(g_OrionEvidenceDedupAction[]), action);
    strcopy(g_OrionEvidenceDedupDetails[bucket], sizeof(g_OrionEvidenceDedupDetails[]), safeDetails);
    strcopy(g_OrionEvidenceDedupAuthId[bucket], sizeof(g_OrionEvidenceDedupAuthId[]), authId);
    strcopy(g_OrionEvidenceDedupPlayerName[bucket], sizeof(g_OrionEvidenceDedupPlayerName[]), playerName);
    strcopy(g_OrionEvidenceDedupMapName[bucket], sizeof(g_OrionEvidenceDedupMapName[]), mapName);
    strcopy(g_OrionEvidenceDedupModeName[bucket], sizeof(g_OrionEvidenceDedupModeName[]), modeName);
    strcopy(g_OrionEvidenceDedupSessionLabel[bucket], sizeof(g_OrionEvidenceDedupSessionLabel[]), sessionLabel);
    g_OrionEvidenceDedupScore[bucket] = score;
    g_OrionEvidenceDedupFirstAt[bucket] = now;
    g_OrionEvidenceDedupLastAt[bucket] = now;
    g_OrionEvidenceDedupRepeatCount[bucket] = 1;
    g_OrionEvidenceDedupTimer[bucket] = CreateTimer(ORION_EVIDENCE_DEDUP_WINDOW_SECONDS, Orion_Evidence_FlushDedupTimer, bucket, TIMER_FLAG_NO_MAPCHANGE);

    return true;
}

public Action Orion_Evidence_FlushDedupTimer(Handle timer, any bucket)
{
    if (bucket >= 0 && bucket < ORION_EVIDENCE_DEDUP_BUCKETS)
    {
        g_OrionEvidenceDedupTimer[bucket] = null;
        Orion_Evidence_FlushDedupBucket(bucket);
    }

    return Plugin_Stop;
}

int Orion_Evidence_FindDuplicateBucket(int client, const char[] evidenceType, const char[] reason, const char[] action, float now)
{
    for (int bucket = 0; bucket < ORION_EVIDENCE_DEDUP_BUCKETS; bucket++)
    {
        if (!g_OrionEvidenceDedupActive[bucket])
        {
            continue;
        }

        if ((now - g_OrionEvidenceDedupFirstAt[bucket]) > ORION_EVIDENCE_DEDUP_WINDOW_SECONDS)
        {
            Orion_Evidence_FlushDedupBucket(bucket);
            continue;
        }

        if (g_OrionEvidenceDedupClient[bucket] == client
            && StrEqual(g_OrionEvidenceDedupType[bucket], evidenceType, false)
            && StrEqual(g_OrionEvidenceDedupReason[bucket], reason, false)
            && StrEqual(g_OrionEvidenceDedupAction[bucket], action, false))
        {
            return bucket;
        }
    }

    return -1;
}

int Orion_Evidence_FindFreeDedupBucket()
{
    for (int bucket = 0; bucket < ORION_EVIDENCE_DEDUP_BUCKETS; bucket++)
    {
        if (!g_OrionEvidenceDedupActive[bucket])
        {
            return bucket;
        }
    }

    return -1;
}

int Orion_Evidence_FindOldestDedupBucket()
{
    int oldestBucket = 0;
    float oldestFirstAt = g_OrionEvidenceDedupFirstAt[0];

    for (int bucket = 1; bucket < ORION_EVIDENCE_DEDUP_BUCKETS; bucket++)
    {
        if (g_OrionEvidenceDedupFirstAt[bucket] < oldestFirstAt)
        {
            oldestBucket = bucket;
            oldestFirstAt = g_OrionEvidenceDedupFirstAt[bucket];
        }
    }

    return oldestBucket;
}

void Orion_Evidence_FlushAllDedupBuckets()
{
    for (int bucket = 0; bucket < ORION_EVIDENCE_DEDUP_BUCKETS; bucket++)
    {
        Orion_Evidence_FlushDedupBucket(bucket);
    }
}

void Orion_Evidence_FlushDedupBucketsForClient(int client)
{
    for (int bucket = 0; bucket < ORION_EVIDENCE_DEDUP_BUCKETS; bucket++)
    {
        if (g_OrionEvidenceDedupActive[bucket] && g_OrionEvidenceDedupClient[bucket] == client)
        {
            Orion_Evidence_FlushDedupBucket(bucket);
        }
    }
}

void Orion_Evidence_FlushDedupBucket(int bucket)
{
    if (bucket < 0 || bucket >= ORION_EVIDENCE_DEDUP_BUCKETS || !g_OrionEvidenceDedupActive[bucket])
    {
        return;
    }

    if (g_OrionEvidenceDedupTimer[bucket] != null)
    {
        KillTimer(g_OrionEvidenceDedupTimer[bucket]);
        g_OrionEvidenceDedupTimer[bucket] = null;
    }

    g_OrionEvidenceSequence++;
    LogToFileEx(
        g_OrionEvidenceLogPath,
        "seq=%d session=%s type=%s score=%.1f action=%s client=%d steamid=%s name=\"%s\" map=%s mode=%s repeat_count=%d dedup_window=%.1f first_at=%.1f last_at=%.1f details=\"%s\"",
        g_OrionEvidenceSequence,
        g_OrionEvidenceDedupSessionLabel[bucket],
        g_OrionEvidenceDedupType[bucket],
        g_OrionEvidenceDedupScore[bucket],
        g_OrionEvidenceDedupAction[bucket],
        g_OrionEvidenceDedupClient[bucket],
        g_OrionEvidenceDedupAuthId[bucket],
        g_OrionEvidenceDedupPlayerName[bucket],
        g_OrionEvidenceDedupMapName[bucket],
        g_OrionEvidenceDedupModeName[bucket],
        g_OrionEvidenceDedupRepeatCount[bucket],
        ORION_EVIDENCE_DEDUP_WINDOW_SECONDS,
        g_OrionEvidenceDedupFirstAt[bucket],
        g_OrionEvidenceDedupLastAt[bucket],
        g_OrionEvidenceDedupDetails[bucket]);

    Orion_Evidence_AddRecent(
        g_OrionEvidenceSequence,
        g_OrionEvidenceDedupPlayerName[bucket],
        g_OrionEvidenceDedupType[bucket],
        g_OrionEvidenceDedupScore[bucket],
        g_OrionEvidenceDedupAction[bucket],
        g_OrionEvidenceDedupDetails[bucket],
        g_OrionEvidenceDedupRepeatCount[bucket]);

    Orion_Evidence_ClearDedupBucket(bucket);
}

void Orion_Evidence_ClearDedupBucket(int bucket)
{
    g_OrionEvidenceDedupActive[bucket] = false;
    g_OrionEvidenceDedupClient[bucket] = 0;
    g_OrionEvidenceDedupTimer[bucket] = null;
    g_OrionEvidenceDedupRepeatCount[bucket] = 0;
    g_OrionEvidenceDedupFirstAt[bucket] = 0.0;
    g_OrionEvidenceDedupLastAt[bucket] = 0.0;
}

void Orion_Evidence_AddRecent(
    int sequence,
    const char[] playerName,
    const char[] evidenceType,
    float score,
    const char[] action,
    const char[] details,
    int repeatCount)
{
    int index = g_OrionEvidenceRecentWriteIndex;
    g_OrionEvidenceRecentSequence[index] = sequence;
    strcopy(g_OrionEvidenceRecentPlayerName[index], sizeof(g_OrionEvidenceRecentPlayerName[]), playerName);
    strcopy(g_OrionEvidenceRecentType[index], sizeof(g_OrionEvidenceRecentType[]), evidenceType);
    g_OrionEvidenceRecentScore[index] = score;
    strcopy(g_OrionEvidenceRecentAction[index], sizeof(g_OrionEvidenceRecentAction[]), action);
    strcopy(g_OrionEvidenceRecentDetails[index], sizeof(g_OrionEvidenceRecentDetails[]), details);
    g_OrionEvidenceRecentRepeatCount[index] = repeatCount;

    g_OrionEvidenceRecentWriteIndex = (g_OrionEvidenceRecentWriteIndex + 1) % ORION_EVIDENCE_RECENT_LIMIT;
    if (g_OrionEvidenceRecentCount < ORION_EVIDENCE_RECENT_LIMIT)
    {
        g_OrionEvidenceRecentCount++;
    }
}

void Orion_Evidence_ClearRecentLog()
{
    g_OrionEvidenceRecentWriteIndex = 0;
    g_OrionEvidenceRecentCount = 0;
}

void Orion_Evidence_ExtractReasonToken(const char[] details, char[] reason, int reasonLength)
{
    int reasonOffset = StrContains(details, "reason=", false);
    if (reasonOffset < 0)
    {
        strcopy(reason, reasonLength, details);
        return;
    }

    reasonOffset += 7;
    int outputIndex = 0;
    for (int inputIndex = reasonOffset; details[inputIndex] != '\0' && outputIndex < reasonLength - 1; inputIndex++)
    {
        if (details[inputIndex] == ' ')
        {
            break;
        }

        reason[outputIndex] = details[inputIndex];
        outputIndex++;
    }

    reason[outputIndex] = '\0';
    if (reason[0] == '\0')
    {
        strcopy(reason, reasonLength, "none");
    }
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
