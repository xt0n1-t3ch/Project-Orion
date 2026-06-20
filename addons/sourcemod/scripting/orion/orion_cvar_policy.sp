enum OrionCvarComparisonKind
{
    OrionCvarComparison_Equal = 0,
    OrionCvarComparison_NotEqual,
    OrionCvarComparison_LessThanOrEqual,
    OrionCvarComparison_GreaterThanOrEqual,
    OrionCvarComparison_BetweenInclusive
};

#define ORION_CVAR_POLICY_INVALID_INDEX -1
#define ORION_CVAR_POLICY_VALUE_EPSILON 0.001

int g_OrionCvarPolicyNextIndex[MAXPLAYERS + 1];
int g_OrionCvarPolicyPendingIndex[MAXPLAYERS + 1];
int g_OrionCvarPolicyConsecutiveFailures[MAXPLAYERS + 1];

char g_OrionCvarPolicyNames[][] =
{
    "cl_interp",
    "cl_interp_ratio",
    "cl_lagcompensation",
    "cl_predict",
    "sv_cheats",
    "mat_wireframe",
    "mat_proxy",
    "mat_fullbright",
    "mat_fillrate",
    "mat_measurefillrate",
    "mat_showlowresimage",
    "r_drawothermodels",
    "r_drawmodelstatsoverlay",
    "r_drawrenderboxes",
    "r_drawentities",
    "snd_visualize",
    "snd_show",
    "r_shadowwireframe",
    "r_showenvcubemap",
    "r_modelwireframedecal",
    "cl_leveloverview",
    "cl_overdraw_test",
    "cl_showevents",
    "fog_enable",
    "r_aspectratio",
    "r_colorstaticprops",
    "r_dispwalkable",
    "r_drawbeams",
    "r_drawbrushmodels",
    "r_drawclipbrushes",
    "r_drawdecals",
    "r_drawopaqueworld",
    "r_drawparticles",
    "r_drawskybox",
    "r_drawtranslucentworld",
    "r_skybox",
    "r_visocclusion",
    "vcollide_wireframe"
};

float g_OrionCvarPolicyExpectedValues[] =
{
    0.0,
    0.0,
    1.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    0.0,
    0.0
};

float g_OrionCvarPolicyMinimumValues[] =
{
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    0.0,
    0.0
};

float g_OrionCvarPolicyMaximumValues[] =
{
    0.150,
    2.0,
    1.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    1.0,
    0.0,
    0.0
};

OrionCvarComparisonKind g_OrionCvarPolicyComparisonKinds[] =
{
    OrionCvarComparison_LessThanOrEqual,
    OrionCvarComparison_BetweenInclusive,
    OrionCvarComparison_BetweenInclusive,
    OrionCvarComparison_BetweenInclusive,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal,
    OrionCvarComparison_Equal
};

float g_OrionCvarPolicyScores[] =
{
    25.0,
    20.0,
    15.0,
    15.0,
    30.0,
    30.0,
    30.0,
    30.0,
    25.0,
    25.0,
    25.0,
    30.0,
    30.0,
    30.0,
    30.0,
    30.0,
    30.0,
    30.0,
    30.0,
    30.0,
    25.0,
    25.0,
    25.0,
    25.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    20.0,
    25.0
};

char g_OrionCvarPolicyActionLabels[][] =
{
    "observe",
    "observe",
    "observe",
    "observe",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "ban",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "observe",
    "ban"
};

char g_OrionCvarPolicyExpectedLabels[][] =
{
    "max=0.150",
    "min=0.0 max=2.0",
    "min=0.0 max=1.0",
    "min=0.0 max=1.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=1.0",
    "expected=0.0",
    "expected=0.0",
    "expected=1.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=1.0",
    "expected=0.0",
    "expected=0.0",
    "expected=0.0",
    "expected=1.0",
    "expected=1.0",
    "expected=0.0",
    "expected=1.0",
    "expected=1.0",
    "expected=1.0",
    "expected=1.0",
    "expected=1.0",
    "expected=1.0",
    "expected=0.0",
    "expected=0.0"
};

void Orion_CvarPolicy_Init()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        Orion_CvarPolicy_ResetClient(client);
    }
}

void Orion_CvarPolicy_ResetClient(int client)
{
    if (!Orion_CvarPolicy_IsValidClientSlot(client))
    {
        return;
    }

    g_OrionCvarPolicyNextIndex[client] = 0;
    g_OrionCvarPolicyPendingIndex[client] = ORION_CVAR_POLICY_INVALID_INDEX;
    g_OrionCvarPolicyConsecutiveFailures[client] = 0;
}

bool Orion_CvarPolicy_QueryNext(int client, char[] cvarName, int cvarNameLength)
{
    if (!Orion_CvarPolicy_IsValidClientSlot(client) || cvarNameLength <= 0 || g_OrionCvarPolicyPendingIndex[client] != ORION_CVAR_POLICY_INVALID_INDEX)
    {
        return false;
    }

    int policyIndex = g_OrionCvarPolicyNextIndex[client];
    if (policyIndex < 0 || policyIndex >= Orion_CvarPolicy_Count())
    {
        policyIndex = 0;
    }

    strcopy(cvarName, cvarNameLength, g_OrionCvarPolicyNames[policyIndex]);
    g_OrionCvarPolicyPendingIndex[client] = policyIndex;
    g_OrionCvarPolicyNextIndex[client] = (policyIndex + 1) % Orion_CvarPolicy_Count();
    return true;
}

bool Orion_CvarPolicy_HandleResult(
    int client,
    ConVarQueryResult result,
    const char[] cvarName,
    const char[] cvarValue,
    float& scoreDelta,
    char[] reason,
    int reasonLength,
    char[] actionLabel,
    int actionLabelLength,
    char[] expectedLabel,
    int expectedLabelLength)
{
    scoreDelta = 0.0;
    Orion_CvarPolicy_CopyString(reason, reasonLength, "");
    Orion_CvarPolicy_CopyString(actionLabel, actionLabelLength, "");
    Orion_CvarPolicy_CopyString(expectedLabel, expectedLabelLength, "");

    if (!Orion_CvarPolicy_IsValidClientSlot(client))
    {
        return false;
    }

    int policyIndex = Orion_CvarPolicy_FindPolicy(cvarName);
    if (policyIndex == ORION_CVAR_POLICY_INVALID_INDEX)
    {
        return false;
    }

    Orion_CvarPolicy_ClearPendingQuery(client, policyIndex);

    if (result != ConVarQuery_Okay)
    {
        g_OrionCvarPolicyConsecutiveFailures[client]++;
        scoreDelta = g_OrionCvarPolicyConsecutiveFailures[client] >= 3 ? 8.0 : 2.0;
        Orion_CvarPolicy_CopyString(reason, reasonLength, "query_failed");
        Orion_CvarPolicy_CopyString(actionLabel, actionLabelLength, "observe");
        Orion_CvarPolicy_CopyString(expectedLabel, expectedLabelLength, "query_ok");
        return true;
    }

    g_OrionCvarPolicyConsecutiveFailures[client] = 0;
    float actualValue = StringToFloat(cvarValue);
    if (!Orion_CvarPolicy_IsViolation(policyIndex, actualValue))
    {
        return false;
    }

    scoreDelta = g_OrionCvarPolicyScores[policyIndex];
    Orion_CvarPolicy_CopyString(reason, reasonLength, "cvar_policy_mismatch");
    Orion_CvarPolicy_CopyString(actionLabel, actionLabelLength, g_OrionCvarPolicyActionLabels[policyIndex]);
    Orion_CvarPolicy_CopyString(expectedLabel, expectedLabelLength, g_OrionCvarPolicyExpectedLabels[policyIndex]);
    return true;
}

int Orion_CvarPolicy_Count()
{
    return sizeof(g_OrionCvarPolicyNames);
}

int Orion_CvarPolicy_FindPolicy(const char[] cvarName)
{
    for (int policyIndex = 0; policyIndex < Orion_CvarPolicy_Count(); policyIndex++)
    {
        if (StrEqual(cvarName, g_OrionCvarPolicyNames[policyIndex], false))
        {
            return policyIndex;
        }
    }

    return ORION_CVAR_POLICY_INVALID_INDEX;
}

bool Orion_CvarPolicy_IsViolation(int policyIndex, float actualValue)
{
    if (StrEqual(g_OrionCvarPolicyNames[policyIndex], "cl_interp", false))
    {
        return actualValue > (Orion_Config_MaxLerpMs() / 1000.0) + ORION_CVAR_POLICY_VALUE_EPSILON;
    }

    if (StrEqual(g_OrionCvarPolicyNames[policyIndex], "cl_interp_ratio", false))
    {
        return actualValue < Orion_Config_MinInterpRatio() - ORION_CVAR_POLICY_VALUE_EPSILON
            || actualValue > Orion_Config_MaxInterpRatio() + ORION_CVAR_POLICY_VALUE_EPSILON;
    }

    switch (g_OrionCvarPolicyComparisonKinds[policyIndex])
    {
        case OrionCvarComparison_Equal:
        {
            return FloatAbs(actualValue - g_OrionCvarPolicyExpectedValues[policyIndex]) > ORION_CVAR_POLICY_VALUE_EPSILON;
        }
        case OrionCvarComparison_NotEqual:
        {
            return FloatAbs(actualValue - g_OrionCvarPolicyExpectedValues[policyIndex]) <= ORION_CVAR_POLICY_VALUE_EPSILON;
        }
        case OrionCvarComparison_LessThanOrEqual:
        {
            return actualValue > g_OrionCvarPolicyMaximumValues[policyIndex] + ORION_CVAR_POLICY_VALUE_EPSILON;
        }
        case OrionCvarComparison_GreaterThanOrEqual:
        {
            return actualValue < g_OrionCvarPolicyMinimumValues[policyIndex] - ORION_CVAR_POLICY_VALUE_EPSILON;
        }
        case OrionCvarComparison_BetweenInclusive:
        {
            return actualValue < g_OrionCvarPolicyMinimumValues[policyIndex] - ORION_CVAR_POLICY_VALUE_EPSILON
                || actualValue > g_OrionCvarPolicyMaximumValues[policyIndex] + ORION_CVAR_POLICY_VALUE_EPSILON;
        }
    }

    return false;
}

bool Orion_CvarPolicy_IsValidClientSlot(int client)
{
    return client > 0 && client <= MaxClients;
}

void Orion_CvarPolicy_ClearPendingQuery(int client, int policyIndex)
{
    if (g_OrionCvarPolicyPendingIndex[client] == policyIndex)
    {
        g_OrionCvarPolicyPendingIndex[client] = ORION_CVAR_POLICY_INVALID_INDEX;
    }
}

void Orion_CvarPolicy_CopyString(char[] destination, int destinationLength, const char[] source)
{
    if (destinationLength <= 0)
    {
        return;
    }

    strcopy(destination, destinationLength, source);
}
