/**
 * Project Orion alert audience dispatcher.
 *
 * One module owns who sees each detection type. Audience values come from
 * orion_config.sp accessors: everyone, admins, flag:<flags>, or off.
 */

#define ORION_ALERT_AUDIENCE_MAX_LENGTH 32
#define ORION_ALERT_MESSAGE_MAX_LENGTH 256

void Orion_Alerts_Init()
{
}

void Orion_Alerts_Dispatch(int subject, const char[] evidenceType, float score, const char[] action)
{
    char audience[ORION_ALERT_AUDIENCE_MAX_LENGTH];
    Orion_Config_GetAlertAudience(evidenceType, audience, sizeof(audience));
    TrimString(audience);

    if (audience[0] == '\0')
    {
        strcopy(audience, sizeof(audience), "admins");
    }

    if (StrEqual(audience, "off", false))
    {
        return;
    }

    for (int recipient = 1; recipient <= MaxClients; recipient++)
    {
        if (!Orion_Alerts_CanReceive(recipient, evidenceType, audience))
        {
            continue;
        }

        char message[ORION_ALERT_MESSAGE_MAX_LENGTH];
        Orion_Messages_FormatAlert(recipient, subject, evidenceType, score, action, message, sizeof(message));
        PrintToChat(recipient, "%s", message);
    }
}

bool Orion_Alerts_CanReceive(int recipient, const char[] evidenceType, const char[] audience)
{
    if (recipient <= 0 || recipient > MaxClients || !IsClientInGame(recipient) || IsFakeClient(recipient))
    {
        return false;
    }

    if (StrEqual(audience, "everyone", false))
    {
        return true;
    }

    char overrideName[64];
    Orion_Alerts_FormatOverrideName(evidenceType, overrideName, sizeof(overrideName));

    if (StrEqual(audience, "admins", false))
    {
        if (CheckCommandAccess(recipient, overrideName, ADMFLAG_GENERIC, true))
        {
            return true;
        }

        return CheckCommandAccess(recipient, "orion_alert_admin", ADMFLAG_GENERIC, false);
    }

    if (StrContains(audience, "flag:", false) == 0)
    {
        char flagString[16];
        strcopy(flagString, sizeof(flagString), audience[5]);
        TrimString(flagString);

        int requiredFlags = ReadFlagString(flagString);
        if (requiredFlags == 0)
        {
            return false;
        }

        return CheckCommandAccess(recipient, overrideName, requiredFlags, false);
    }

    return false;
}

void Orion_Alerts_FormatOverrideName(const char[] evidenceType, char[] overrideName, int overrideNameLength)
{
    Format(overrideName, overrideNameLength, "orion_alert_%s", evidenceType);

    for (int index = 0; index < overrideNameLength && overrideName[index] != '\0'; index++)
    {
        bool isLower = overrideName[index] >= 'a' && overrideName[index] <= 'z';
        bool isDigit = overrideName[index] >= '0' && overrideName[index] <= '9';
        if (!isLower && !isDigit && overrideName[index] != '_')
        {
            overrideName[index] = '_';
        }
    }
}
