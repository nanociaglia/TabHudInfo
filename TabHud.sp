#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <store>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define MAX_BUTTONS 	25
#define RGBSpecs 	255, 255, 255, 255
#define IN_SCORE 	(1 << 16)

Handle g_hSyncHud, g_hCTabHud;

bool	g_bEnableTabHud[MAXPLAYERS + 1], g_bStoreCredits = false;

public Plugin myinfo 		= 
{
	name 				= "Tab Hud Info",
	author 				= "Nano",
	description 			= "Show info when you press TAB",
	version 				= "1.4",
	url 					= "https://steamcommunity.com/id/marianzet1/"
};

public void OnPluginStart() 
{
	g_hCTabHud 		= RegClientCookie("toggle_tabhud", "TabHud", CookieAccess_Protected);
	g_hSyncHud 		= CreateHudSynchronizer();

	RegConsoleCmd("sm_tabhud", OnToggleTabHud);
}

public void OnClientPutInServer(int client)
{
	g_bEnableTabHud[client] = true;
	char sBuffer[64];
	GetClientCookie(client, g_hCTabHud, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer,"0"))
	{
		g_bEnableTabHud[client] = false;
	}
}

public void OnAllPluginsLoaded()
{
	g_bStoreCredits = LibraryExists("store");
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "store"))
	{
		g_bStoreCredits = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "store"))
	{
		g_bStoreCredits = false;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("Store_GetClientCredits");
	return APLRes_Success;
}

public Action OnToggleTabHud(int client, int args)
{
	if(!client) return Plugin_Continue;
	
	if(g_bEnableTabHud[client])
	{
		CPrintToChat(client, "{green}[TAB-HUD]{default} You have {darkred}disabled {default}scoreboard information.");
		g_bEnableTabHud[client] = false;
		SetClientCookie(client, g_hCTabHud, "0");
	}
	else 
	{
		CPrintToChat(client, "{green}[TAB-HUD]{default} You have {lightblue}enabled {default}scoreboard information.");
		g_bEnableTabHud[client] = true;
		SetClientCookie(client, g_hCTabHud, "1");
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsValidClient(client) && g_bEnableTabHud[client])
	{
		if (buttons & IN_SCORE)
		{
			static float flDelay[MAXPLAYERS+1];
			float flCurrentTime = GetEngineTime();

			if (flCurrentTime - flDelay[client] < 1.0)
			{
				return Plugin_Continue;
			}

			flDelay[client] = flCurrentTime;

			int iTimeLeft;
			char sPrint[270], sMinutes[5], sSeconds[5], sHour[30], sMap[PLATFORM_MAX_PATH];

			GetMapTimeLeft(iTimeLeft);
			GetNextMap(sMap, sizeof(sMap));
			GetMapDisplayName(sMap, sMap, sizeof(sMap));

			FormatTime(sHour, sizeof(sHour), "%H:%M", GetTime());
			FormatEx(sMinutes, sizeof(sMinutes), "%s%i", ((iTimeLeft / 60) < 10) ? "0" : "", iTimeLeft / 60);
			FormatEx(sSeconds, sizeof(sSeconds), "%s%i", ((iTimeLeft % 60) < 10) ? "0" : "", iTimeLeft % 60);

			int iPlayersCountAlive = 0, iPlayersCountSpec = 0, iPlayersCountTotal = 0;

			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
				{
					++iPlayersCountAlive;
				}
			}
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_SPECTATOR)
				{
					++iPlayersCountSpec;
				}
			}
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i))
				{
					++iPlayersCountTotal;
				}
			}

			if(IsValidClient(client)) 
			{
				if(g_bStoreCredits)
				{
					if(iTimeLeft >= 0) 
					{
						Format(sPrint, sizeof(sPrint), "-|Credits: %i\n-|TimeLeft: %s:%s\n-|Hour: %s\n-|People connected: %d/%d\n-|People playing: %d\n-|Specs: %d", Store_GetClientCredits(client), sMinutes, sSeconds, sHour, iPlayersCountTotal, GetMaxHumanPlayers(), iPlayersCountAlive, iPlayersCountSpec);
						SetHudTextParams(0.0, 0.4, 1.0, RGBSpecs, 0, 0.00, 0.3, 0.4);
						ShowSyncHudText(client, g_hSyncHud, sPrint);
					}
					else if(iTimeLeft < 0) 
					{
						Format(sPrint, sizeof(sPrint), "-|Credits: %i\n-|Nextmap: %s\n-|Hour: %s\n-|People connected: %d/%d\n-|People playing: %d\n-|Specs: %d", Store_GetClientCredits(client), sMap, sHour, iPlayersCountTotal, GetMaxHumanPlayers(), iPlayersCountAlive, iPlayersCountSpec);
						SetHudTextParams(0.0, 0.4, 1.0, RGBSpecs, 0, 0.00, 0.3, 0.4);
						ShowSyncHudText(client, g_hSyncHud, sPrint);
					}
				}
				else
				{
					if(iTimeLeft >= 0) 
					{
						Format(sPrint, sizeof(sPrint), "-|TimeLeft: %s:%s\n-|Hour: %s\n-|People connected: %d/%d\n-|People playing: %d\n-|Specs: %d", sMinutes, sSeconds, sHour, iPlayersCountTotal, GetMaxHumanPlayers(), iPlayersCountAlive, iPlayersCountSpec);
						SetHudTextParams(0.0, 0.4, 1.0, RGBSpecs, 0, 0.00, 0.3, 0.4);
						ShowSyncHudText(client, g_hSyncHud, sPrint);
					}
					else if(iTimeLeft < 0) 
					{
						Format(sPrint, sizeof(sPrint), "-|Nextmap: %s\n-|Hour: %s\n-|People connected: %d/%d\n-|People playing: %d\n-|Specs: %d", sMap, sHour, iPlayersCountTotal, GetMaxHumanPlayers(), iPlayersCountAlive, iPlayersCountSpec);
						SetHudTextParams(0.0, 0.4, 1.0, RGBSpecs, 0, 0.00, 0.3, 0.4);
						ShowSyncHudText(client, g_hSyncHud, sPrint);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}