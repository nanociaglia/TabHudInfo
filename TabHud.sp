#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>
#include <clientprefs>

#define MAX_BUTTONS 25
#define RGB 255, 255, 255, 255
#define IN_SCORE        (1 << 16)

#pragma semicolon 1
#pragma newdecls required

Handle g_hCookie_TabHud;
bool g_bEnableTabHud[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Tab Hud Info",
	author = "Nano",
	description = "Show info about timeleft, players and spectators when you press TAB",
	version = "1.1",
	url = "https://steamcommunity.com/id/marianzet1/"
};

public void OnPluginStart(){
	g_hCookie_TabHud = RegClientCookie("toggle_tabhud", "TabHud", CookieAccess_Protected);

	RegConsoleCmd("sm_tabhud", OnToggleTabHud);
}

public void OnClientPutInServer(int client){
	g_bEnableTabHud[client] = true;
	char buffer[64];
	GetClientCookie(client, g_hCookie_TabHud, buffer, sizeof(buffer));
	if(StrEqual(buffer,"0")){
		g_bEnableTabHud[client] = false;
	}
}

public Action OnToggleTabHud(int client, int args){
	if(!client) return Plugin_Continue;
	
	if(g_bEnableTabHud[client]){
		CPrintToChat(client, "{green}[TAB-HUD] {darkred}Desactivaste {default}la información del scoreboard.");
		g_bEnableTabHud[client] = false;
		SetClientCookie(client, g_hCookie_TabHud, "0");
	}
	else {
		CPrintToChat(client, "{green}[TAB-HUD] {lightblue}Activaste {default}la información del scoreboard.");
		g_bEnableTabHud[client] = true;
		SetClientCookie(client, g_hCookie_TabHud, "1");
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bEnableTabHud[client]){
		if (buttons & IN_SCORE){
			static float flDelay[MAXPLAYERS+1];
			float flCurrentTime = GetEngineTime();

			if (flCurrentTime - flDelay[client] < 1.0){
				return Plugin_Continue;
			}

			flDelay[client] = flCurrentTime;

			int iPlayersCount = 0;
			int iSpecCount = 0;
			for (int i = 1; i <= MaxClients; i++){
				if (IsValidClient(i)){
					++iPlayersCount;
				}
			}
			for (int i = 1; i <= MaxClients; i++){
				if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_SPECTATOR){
					++iSpecCount;
				}
			}

			int iTimeleft;
			char sTime[60];
			char ShowInfo[60];
			GetMapTimeLeft(iTimeleft);
			if(iTimeleft > 0)
			{
				FormatTime(sTime, sizeof(sTime), "%M:%S", iTimeleft);

				Format(ShowInfo, sizeof(ShowInfo), "Tiempo restante: %s\nEspectadores: %d\nJugadores: %d/%d", sTime, iSpecCount, iPlayersCount, GetMaxHumanPlayers());
				SetHudTextParams(0.0, 0.4, 1.0, RGB, 0, 0.00, 0.3, 0.4);
				ShowHudText(client, 0, ShowInfo);
			}
			if(iTimeleft <= 0)
			{
				char sMap[PLATFORM_MAX_PATH];
				GetNextMap(sMap, sizeof(sMap));

				GetMapDisplayName(sMap, sMap, sizeof(sMap));
				Format(ShowInfo, sizeof(ShowInfo), "Nextmap: %s\nEspectadores: %d\nJugadores: %d/%d", sMap, iSpecCount, iPlayersCount, GetMaxHumanPlayers());
				SetHudTextParams(0.0, 0.4, 1.0, RGB, 0, 0.00, 0.3, 0.4);
				ShowHudText(client, 0, ShowInfo);
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