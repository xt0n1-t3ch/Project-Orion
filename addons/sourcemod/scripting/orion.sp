/**
 * Project Orion
 * Server-side evidence anti-cheat for competitive Left 4 Dead 2.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define ORION_PLUGIN_VERSION "0.5.1"
#define ORION_TEAM_SPECTATOR 1
#define ORION_TEAM_SURVIVOR 2
#define ORION_TEAM_INFECTED 3

#if !defined IN_ATTACK
    #define IN_ATTACK (1 << 0)
#endif

#if !defined IN_JUMP
    #define IN_JUMP (1 << 1)
#endif

#if !defined FL_ONGROUND
    #define FL_ONGROUND (1 << 0)
#endif

enum OrionMode
{
    OrionMode_Shadow = 0,
    OrionMode_Alert = 1,
    OrionMode_Enforce = 2
};

#include "orion/orion_config.sp"
#include "orion/orion_evidence.sp"
#include "orion/orion_visibility_guard.sp"
#include "orion/orion_usercmd_guard.sp"
#include "orion/orion_aim_analyzer.sp"
#include "orion/orion_movement_analyzer.sp"
#include "orion/orion_abuse_guard.sp"
#include "orion/orion_cvar_policy.sp"
#include "orion/orion_integrity.sp"
#include "orion/orion_readiness.sp"

public Plugin myinfo =
{
    name = "Project Orion",
    author = "xt0n1-t3ch",
    description = "Server-side evidence anti-cheat for competitive L4D2.",
    version = ORION_PLUGIN_VERSION,
    url = "https://github.com/xt0n1-t3ch/Project-Orion"
};

public void OnPluginStart()
{
    Orion_Config_Init();
    Orion_Readiness_Init();
    Orion_Evidence_Init();
    Orion_Visibility_Init();
    Orion_UserCmdGuard_Init();
    Orion_Aim_Init();
    Orion_Movement_Init();
    Orion_AbuseGuard_Init();
    Orion_CvarPolicy_Init();
    Orion_Integrity_Init();

    AutoExecConfig(true, "orion");
    char modeName[32];
    Orion_Config_GetModeName(modeName, sizeof(modeName));
    PrintToServer("[Orion] Project Orion %s loaded in %s mode.", ORION_PLUGIN_VERSION, modeName);
}

public void OnMapStart()
{
    Orion_Evidence_OnMapStart();
    Orion_Visibility_OnMapStart();
}

public void OnClientPutInServer(int client)
{
    Orion_Aim_ResetClient(client);
    Orion_Movement_ResetClient(client);
    Orion_UserCmdGuard_ResetClient(client);
    Orion_AbuseGuard_ResetClient(client);
    Orion_CvarPolicy_ResetClient(client);
    Orion_Integrity_ResetClient(client);
    Orion_Visibility_HookClient(client);
}

public void OnClientDisconnect(int client)
{
    Orion_Aim_ResetClient(client);
    Orion_Movement_ResetClient(client);
    Orion_UserCmdGuard_ResetClient(client);
    Orion_AbuseGuard_ResetClient(client);
    Orion_CvarPolicy_ResetClient(client);
    Orion_Integrity_ResetClient(client);
    Orion_Visibility_ResetClient(client);
}

public Action OnPlayerRunCmd(
    int client,
    int& buttons,
    int& impulse,
    float vel[3],
    float angles[3],
    int& weapon,
    int& subtype,
    int& cmdnum,
    int& tickcount,
    int& seed,
    int mouse[2])
{
    if (!Orion_Config_IsEnabled() || !Orion_IsHumanPlayer(client))
    {
        return Plugin_Continue;
    }

    float originalAngles[3];
    originalAngles[0] = angles[0];
    originalAngles[1] = angles[1];
    originalAngles[2] = angles[2];
    int originalTickcount = tickcount;
    int originalSeed = seed;

    Orion_UserCmdGuard_OnPlayerRunCmd(client, buttons, angles, cmdnum, tickcount, mouse);
    Orion_Aim_OnPlayerRunCmd(client, buttons, angles, tickcount, mouse);
    Orion_Movement_OnPlayerRunCmd(client, buttons, angles, cmdnum, tickcount, seed);

    if (angles[0] != originalAngles[0] || angles[1] != originalAngles[1] || angles[2] != originalAngles[2] || tickcount != originalTickcount || seed != originalSeed)
    {
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
    if (!Orion_Config_IsEnabled() || !Orion_IsHumanPlayer(client))
    {
        return Plugin_Continue;
    }

    return Orion_Integrity_OnClientSayCommand(client, command, message);
}

public void OnClientSettingsChanged(int client)
{
    if (!Orion_Config_IsEnabled() || !Orion_IsHumanPlayer(client))
    {
        return;
    }

    Orion_Integrity_OnClientSettingsChanged(client);
    Orion_AbuseGuard_OnClientSettingsChanged(client);
}

bool Orion_IsHumanPlayer(int client)
{
    return client > 0
        && client <= MaxClients
        && IsClientInGame(client)
        && !IsFakeClient(client);
}

bool Orion_IsAliveHumanPlayer(int client)
{
    return Orion_IsHumanPlayer(client) && IsPlayerAlive(client);
}

float Orion_NormalizeAngleDelta(float angleDelta)
{
    while (angleDelta > 180.0)
    {
        angleDelta -= 360.0;
    }

    while (angleDelta < -180.0)
    {
        angleDelta += 360.0;
    }

    return FloatAbs(angleDelta);
}

int Orion_AbsInt(int value)
{
    return value < 0 ? -value : value;
}
