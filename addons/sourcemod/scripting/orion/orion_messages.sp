/**
 * Project Orion translated message owner.
 *
 * User-facing text lives in addons/sourcemod/translations/orion.phrases.txt.
 * Code in this module only chooses phrase keys, colors, and recipient language.
 */

#define ORION_MESSAGE_MAX_PREFIX_LENGTH 64
#define ORION_MESSAGE_MAX_DISPLAY_LENGTH 96

void Orion_Messages_Init()
{
    LoadTranslations("orion.phrases");
}

void Orion_Messages_FormatAlert(int recipient, int subject, const char[] evidenceType, float score, const char[] action, char[] message, int messageLength)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);

    char prefix[ORION_MESSAGE_MAX_PREFIX_LENGTH];
    char playerName[MAX_NAME_LENGTH];
    char evidenceName[ORION_MESSAGE_MAX_DISPLAY_LENGTH];
    char confidenceName[ORION_MESSAGE_MAX_DISPLAY_LENGTH];
    char coloredPlayerName[MAX_NAME_LENGTH + 8];
    char coloredEvidenceName[ORION_MESSAGE_MAX_DISPLAY_LENGTH + 8];
    char coloredConfidenceName[ORION_MESSAGE_MAX_DISPLAY_LENGTH + 8];

    Format(prefix, sizeof(prefix), "%T", "orion.prefix", translationTarget);
    Orion_Messages_FormatPlayerName(translationTarget, subject, playerName, sizeof(playerName));
    Orion_Messages_FormatEvidenceName(translationTarget, evidenceType, evidenceName, sizeof(evidenceName));
    Orion_Messages_FormatConfidenceName(translationTarget, score, confidenceName, sizeof(confidenceName));

    Format(coloredPlayerName, sizeof(coloredPlayerName), "\x03%s\x01", playerName);
    Format(coloredEvidenceName, sizeof(coloredEvidenceName), "\x05%s\x01", evidenceName);
    Format(coloredConfidenceName, sizeof(coloredConfidenceName), "\x04%s\x01", confidenceName);

    if (StrEqual(action, "telemetry", false))
    {
        Format(
            message,
            messageLength,
            "\x04%s\x01 %T",
            prefix,
            "orion.alert.telemetry",
            translationTarget,
            coloredPlayerName,
            coloredEvidenceName,
            coloredConfidenceName);
        return;
    }

    Format(
        message,
        messageLength,
        "\x04%s\x01 %T",
        prefix,
        "orion.alert.detected",
        translationTarget,
        coloredPlayerName,
        coloredEvidenceName,
        coloredConfidenceName);
}

void Orion_Messages_FormatBanReason(int recipient, const char[] evidenceType, float score, char[] reason, int reasonLength)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);

    char evidenceName[ORION_MESSAGE_MAX_DISPLAY_LENGTH];
    char scoreText[16];
    Orion_Messages_FormatEvidenceName(translationTarget, evidenceType, evidenceName, sizeof(evidenceName));
    Format(scoreText, sizeof(scoreText), "%.1f", score);

    Format(reason, reasonLength, "%T", "orion.enforcement.ban_reason", translationTarget, evidenceName, scoreText);
}

void Orion_Messages_FormatKickReason(int recipient, const char[] evidenceType, char[] reason, int reasonLength)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);

    char evidenceName[ORION_MESSAGE_MAX_DISPLAY_LENGTH];
    Orion_Messages_FormatEvidenceName(translationTarget, evidenceType, evidenceName, sizeof(evidenceName));

    Format(reason, reasonLength, "%T", "orion.enforcement.kick_reason", translationTarget, evidenceName);
}

void Orion_Messages_ReplySessionCurrent(int recipient, const char[] sessionLabel)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);
    ReplyToCommand(recipient, "%T", "orion.command.session.current", translationTarget, sessionLabel);
}

void Orion_Messages_ReplySessionUpdated(int recipient, const char[] sessionLabel)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);
    ReplyToCommand(recipient, "%T", "orion.command.session.updated", translationTarget, sessionLabel);
}

void Orion_Messages_ReplyStatus(int recipient, bool enabled, const char[] modeName, const char[] sessionLabel)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);
    ReplyToCommand(recipient, "%T", "orion.command.status", translationTarget, enabled ? 1 : 0, modeName, sessionLabel);
}

void Orion_Messages_ReplyLogHeader(int recipient, int limit)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);
    ReplyToCommand(recipient, "%T", "orion.command.log.header", translationTarget, limit);
}

void Orion_Messages_ReplyLogEmpty(int recipient)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);
    ReplyToCommand(recipient, "%T", "orion.command.log.empty", translationTarget);
}

void Orion_Messages_ReplyLogEntry(
    int recipient,
    int sequence,
    const char[] playerName,
    const char[] evidenceType,
    float score,
    const char[] action,
    const char[] details,
    int repeatCount)
{
    int translationTarget = Orion_Messages_TranslationTarget(recipient);

    char evidenceName[ORION_MESSAGE_MAX_DISPLAY_LENGTH];
    char actionName[ORION_MESSAGE_MAX_DISPLAY_LENGTH];
    char scoreText[16];
    Orion_Messages_FormatEvidenceName(translationTarget, evidenceType, evidenceName, sizeof(evidenceName));
    Orion_Messages_FormatActionName(translationTarget, action, actionName, sizeof(actionName));
    Format(scoreText, sizeof(scoreText), "%.1f", score);

    ReplyToCommand(
        recipient,
        "%T",
        "orion.command.log.entry",
        translationTarget,
        sequence,
        playerName,
        evidenceName,
        scoreText,
        actionName,
        details,
        repeatCount);
}

void Orion_Messages_FormatPlayerName(int translationTarget, int subject, char[] playerName, int playerNameLength)
{
    if (subject > 0 && subject <= MaxClients && IsClientConnected(subject))
    {
        GetClientName(subject, playerName, playerNameLength);
        return;
    }

    Format(playerName, playerNameLength, "%T", "orion.player.unknown", translationTarget, subject);
}

void Orion_Messages_FormatEvidenceName(int translationTarget, const char[] evidenceType, char[] evidenceName, int evidenceNameLength)
{
    char phraseKey[64];
    Orion_Messages_GetEvidencePhraseKey(evidenceType, phraseKey, sizeof(phraseKey));
    Format(evidenceName, evidenceNameLength, "%T", phraseKey, translationTarget);
}

void Orion_Messages_FormatConfidenceName(int translationTarget, float score, char[] confidenceName, int confidenceNameLength)
{
    char phraseKey[64];
    Orion_Messages_GetConfidencePhraseKey(score, phraseKey, sizeof(phraseKey));
    Format(confidenceName, confidenceNameLength, "%T", phraseKey, translationTarget);
}

void Orion_Messages_FormatActionName(int translationTarget, const char[] action, char[] actionName, int actionNameLength)
{
    char phraseKey[64];
    Orion_Messages_GetActionPhraseKey(action, phraseKey, sizeof(phraseKey));
    Format(actionName, actionNameLength, "%T", phraseKey, translationTarget);
}

void Orion_Messages_GetEvidencePhraseKey(const char[] evidenceType, char[] phraseKey, int phraseKeyLength)
{
    if (StrEqual(evidenceType, "aim", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.aim");
    }
    else if (StrEqual(evidenceType, "movement", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.movement");
    }
    else if (StrEqual(evidenceType, "usercmd_guard", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.usercmd_guard");
    }
    else if (StrEqual(evidenceType, "lag_exploit", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.lag_exploit");
    }
    else if (StrEqual(evidenceType, "visibility_guard", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.visibility_guard");
    }
    else if (StrEqual(evidenceType, "spawn_guard", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.spawn_guard");
    }
    else if (StrEqual(evidenceType, "abuse_command", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.abuse_command");
    }
    else if (StrEqual(evidenceType, "abuse_name", false) || StrEqual(evidenceType, "name_guard", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.abuse_name");
    }
    else if (StrEqual(evidenceType, "angle_guard", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.angle_guard");
    }
    else if (StrEqual(evidenceType, "integrity", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.integrity");
    }
    else if (StrEqual(evidenceType, "vocalize_spam", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.vocalize_spam");
    }
    else if (StrEqual(evidenceType, "chat_guard", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.chat_guard");
    }
    else if (StrEqual(evidenceType, "network", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.network");
    }
    else
    {
        strcopy(phraseKey, phraseKeyLength, "orion.evidence.unknown");
    }
}

void Orion_Messages_GetConfidencePhraseKey(float score, char[] phraseKey, int phraseKeyLength)
{
    if (score >= 75.0)
    {
        strcopy(phraseKey, phraseKeyLength, "orion.confidence.high");
    }
    else if (score >= 50.0)
    {
        strcopy(phraseKey, phraseKeyLength, "orion.confidence.medium");
    }
    else
    {
        strcopy(phraseKey, phraseKeyLength, "orion.confidence.low");
    }
}

void Orion_Messages_GetActionPhraseKey(const char[] action, char[] phraseKey, int phraseKeyLength)
{
    if (StrEqual(action, "ban", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.action.ban");
    }
    else if (StrEqual(action, "kick", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.action.kick");
    }
    else if (StrEqual(action, "block", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.action.block");
    }
    else if (StrEqual(action, "telemetry", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.action.telemetry");
    }
    else if (StrEqual(action, "quarantine", false))
    {
        strcopy(phraseKey, phraseKeyLength, "orion.action.quarantine");
    }
    else
    {
        strcopy(phraseKey, phraseKeyLength, "orion.action.observe");
    }
}

int Orion_Messages_TranslationTarget(int recipient)
{
    if (recipient > 0 && recipient <= MaxClients && IsClientInGame(recipient))
    {
        int language = GetClientLanguage(recipient);
        if (language >= 0)
        {
            return recipient;
        }
    }

    return LANG_SERVER;
}
