#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors_csgo>
#include <smlib>
#include <roleplay>
#include <smjansson>
#include <SteamWorks>
#include <basecomm>

#pragma newdecls required

public Plugin myinfo =  {
	name = "Sanction manager", author = "KoSSoLaX`",
	description = "Aide pour les admins", version = "2.0", url = "http://www.ts-x.eu/"
}


enum banCause {
	bc_irrespect,
	bc_spam,
	bc_event,
	bc_usebug,
	bc_cheat,
	bc_double,
	bc_refus,
	bc_freekill,
	bc_other,
	bc_max
};

int g_iUserData[65][bc_max];
int g_iPunition[bc_max][16] = {
	{ -5, -15, -60, 15, 60, 24*60, 2*24*60, 5*24*60, 7*24*60, 14*24*60, 21*24*60, 31*24*60, 40*24*60, 60*24*60, 90*24*60, 120*24*60 },
	{ -5, -15, -60, 15, 60, 24*60, 2*24*60, 5*24*60, 7*24*60, 14*24*60, 21*24*60, 31*24*60, 40*24*60, 60*24*60, 90*24*60, 120*24*60 },
	{ 60, 24*60, 2*24*60, 5*24*60, 7*24*60, 14*24*60, 31*24*60},
	{ 7*24*60, 365*24*60},
	{ 365*24*60 },
	{ 10*365*24*60 },
	{ 60, 24*60, 2*24*60, 5*24*60, 7*24*60, 14*24*60, 31*24*60},
	{ 24*60 },
	{ 24*60 }
};
char g_szPunition[bc_max][] = {"Irrespect", "Spam", "Perturbation d'event", "Utilisation de bug", "CHEAT", "Double compte", "Refus de vente", "FREEKILL", "Autre, préciser:"};


public void OnPluginStart() {	
	
	RegAdminCmd("sm_sanction", Cmd_Sanction, ADMFLAG_KICK);
	for(int i=1; i<=MaxClients; i++) {
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
	}
}
public Action Cmd_Sanction(int client, int args) {
	Draw_SanctionMenu(client, -1, 0);
	return Plugin_Handled;
}
public void OnClientPostAdminCheck(int client) {
	char URL[128], szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	Format(URL, sizeof(URL), "https://www.ts-x.eu/api/user/pilori/%s/next", szSteamID);
	
	Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, URL);
	SteamWorks_SetHTTPCallbacks(req, OnSteamWorksHTTPComplete);
	SteamWorks_SetHTTPRequestContextValue(req, client);
	SteamWorks_SendHTTPRequest(req);
}
public int OnSteamWorksHTTPComplete(Handle HTTPRequest, bool fail, bool success, EHTTPStatusCode statusCode, any client) {
	
	if (success && statusCode == k_EHTTPStatusCode200OK )  { 
		int size;
		SteamWorks_GetHTTPResponseBodySize(HTTPRequest, size);
		char[] tmp = new char[size + 1];
		SteamWorks_GetHTTPResponseBodyData(HTTPRequest, tmp, size);
		
		Handle json = json_object_get(json_load(tmp), "count");
		g_iUserData[client][bc_irrespect] = json_object_get_int(json, "irrespect");
		g_iUserData[client][bc_spam] = json_object_get_int(json, "spam");
		g_iUserData[client][bc_event] = json_object_get_int(json, "event");
		g_iUserData[client][bc_usebug] = json_object_get_int(json, "usebug");
		g_iUserData[client][bc_cheat] = json_object_get_int(json, "cheat");
		g_iUserData[client][bc_double] = json_object_get_int(json, "double");
		g_iUserData[client][bc_refus] = json_object_get_int(json, "refus");
		g_iUserData[client][bc_freekill] = json_object_get_int(json, "freekill");
		g_iUserData[client][bc_other] = json_object_get_int(json, "autres");
	}
	
	delete HTTPRequest;
}
// ----------------------------------------------------------------------------
void Draw_SanctionMenu(int client, int target, int sanction) {
	char tmp[64], tmp2[64];
	
	if( target == 0 ) {
		Menu menu = new Menu(Handle_SanctionMenu);
		menu.SetTitle("Sanctionner un joueur\n ");
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( i == client || IsFakeClient(i) )
				continue;
			
			Format(tmp, sizeof(tmp), "%d -1", i);
			Format(tmp2, sizeof(tmp2), "%N%s", i, rp_IsClientNew(i) ? " - NOUVEAU" : "");
			menu.AddItem(tmp, tmp2);
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if( sanction == -1 ) {
		Menu menu = new Menu(Handle_SanctionMenu);
		menu.SetTitle("Sanctionner %N\n ", target);
		
		for (int i = 0; i < view_as<int>(bc_max); i++) {
			
			if( !(GetUserFlagBits(i) & ADMFLAG_BAN) && i >= 3 )
				break;
			
			Format(tmp, sizeof(tmp), "%d %d", target, i);
			Format(tmp2, sizeof(tmp2), "%s%s", g_szPunition[i], i == view_as<int>(bc_irrespect) ? "(micro)" : (i == view_as<int>(bc_spam) ? "(chat)" : ""));
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		banCause c = view_as<banCause>(sanction);
		g_iUserData[client][c]++;
		int dur = getSanctionDuration(target, c);
		
		switch(c) {
			case bc_irrespect: {
				if( dur < 0 ) {
					SQL_Insert(client, target, -dur, g_szPunition[c], "rp-vocal");
					rp_SetClientBool(target, b_IsMuteVocal, true);
					CreateTimer((-dur) * 60.0, MUTE_TIMER2, target);
					CPrintToChat(target, "[{red}MUTE{default}] A titre {green}préventif{default}, vous avez été {red}interdit d'utiliser votre micro pour %d minutes{default} en raison de votre comportement.", dur);
				}
				else {
					SQL_Insert(client, target, dur, g_szPunition[c], "csgo");
					KickClient(target, g_szPunition[c]);
				}
			}
			case bc_spam: {
				if( dur < 0 ) {
					SQL_Insert(client, target, -dur, g_szPunition[c], "rp-global");
					rp_SetClientBool(target, b_IsMuteGlobal, true);
					CreateTimer((-dur) * 60.0, GAG_TIMER2, target);
					CPrintToChat(client, "[{red}GAG{default}] A titre {green}préventif{default}, vous avez été {red}interdit du chat général pour %d minutes{default} en raison de votre comportement.", -dur);
				}
				else {
					SQL_Insert(client, target, dur, g_szPunition[c], "csgo");
					KickClient(target, g_szPunition[c]);
				}
			}
			case bc_event: {
				SQL_Insert(client, target, dur, g_szPunition[c], "rp-event");
				rp_SetClientBool(target, b_IsMuteEvent, true);
			}
			case bc_usebug: {
				SQL_Insert(client, target, dur, g_szPunition[c], "csgo");
				KickClient(target, g_szPunition[c]);
			}
			case bc_cheat: {
				SQL_Insert(client, target, dur, g_szPunition[c], "rp-pvp");
				rp_SetClientBool(target, b_IsMutePvP, true);
			}
			case bc_double: {
				SQL_Insert(client, target, dur, g_szPunition[c], "csgo");
				KickClient(target, g_szPunition[c]);
			}
			case bc_refus: {
				SQL_Insert(client, target, dur, g_szPunition[c], "csgo");
				KickClient(target, g_szPunition[c]);
			}
			case bc_freekill: {
				SQL_Insert(client, target, dur, g_szPunition[c], "rp-kill");
				rp_SetClientBool(target, b_IsMuteKILL, true);
			}
			case bc_other: {
				SQL_Insert(client, target, dur, g_szPunition[c], "csgo");
				KickClient(target, g_szPunition[c]);
				
				rp_GetClientNextMessage(client, target, fwdMessage);
			}
		}
	}
}
public void fwdMessage(int client, any target, char[] message) {
	SQL_Insert(client, target, getSanctionDuration(target, bc_other), message, "csgo");
	KickClient(client, g_szPunition[bc_other]);
}
public int Handle_SanctionMenu(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("Handle_SanctionMenu");
	#endif
	if (action == MenuAction_Select) {
		char options[64], explo[2][32];
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, " ", explo, sizeof(explo), sizeof(explo[]));
		
		int a = StringToInt(explo[0]);
		int b = StringToInt(explo[1]);
		Draw_SanctionMenu(client, a, b);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
public void BaseComm_OnClientGag(int client, bool gag) {
	if( !gag )
		return;
	
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_EVENT )
		rp_HookEvent(client, RP_OnPlayerZoneChange, GAG_fwdOnZoneChange);
	else {
		CreateTimer(5.0 * 60.0, GAG_TIMER, client);
		CPrintToChat(client, "[{red}GAG{default}] A titre {green}préventif{default}, vous avez été {red}interdit du chat général pour 5 minutes{default} en raison de votre comportement.");
	}
}
public Action GAG_TIMER(Handle timer, any client) {
	BaseComm_SetClientGag(client, false);
	CPrintToChat(client, "[{red}GAG{default}] Vous pouvez à nouveau utiliser le chat général.");
}
public Action GAG_TIMER2(Handle timer, any client) {
	rp_SetClientBool(client, b_IsMuteGlobal, false);
	CPrintToChat(client, "[{red}GAG{default}] Vous pouvez à nouveau utiliser le chat général.");
}
public Action GAG_fwdOnZoneChange(int client, int newZone, int oldZone) {
	if( !(rp_GetZoneBit( newZone ) & BITZONE_EVENT) )
		BaseComm_SetClientGag(client, false);
}
// ----------------------------------------------------------------------------
public void BaseComm_OnClientMute(int client, bool gag) {
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_EVENT )
		rp_HookEvent(client, RP_OnPlayerZoneChange, MUTE_fwdOnZoneChange);
	else {
		CreateTimer(5.0 * 60.0, MUTE_TIMER, client);
		CPrintToChat(client, "[{red}MUTE{default}] A titre {green}préventif{default}, vous avez été {red}interdit d'utiliser votre micro pour 5 minutes{default} en raison de votre comportement.");
	}
}
public Action MUTE_TIMER(Handle timer, any client) {
	BaseComm_SetClientMute(client, false);
	CPrintToChat(client, "[{red}MUTE{default}] Vous pouvez à nouveau utiliser votre micro.");
}
public Action MUTE_TIMER2(Handle timer, any client) {
	rp_SetClientBool(client, b_IsMuteVocal, false);
	CPrintToChat(client, "[{red}MUTE{default}] Vous pouvez à nouveau utiliser votre micro.");
}
public Action MUTE_fwdOnZoneChange(int client, int newZone, int oldZone) {
	if( !(rp_GetZoneBit( newZone ) & BITZONE_EVENT) )
		BaseComm_SetClientMute(client, false);
}
// ----------------------------------------------------------------------------
int getSanctionDuration(int client, banCause cause) {
	int time = g_iUserData[client][cause];
	
	if( time >= sizeof(g_iPunition[]) )
		time = sizeof(g_iPunition[]) - 1;
	
	while( g_iPunition[cause][time] == 0 ) {
		time--;
	}
	
	return g_iPunition[cause][time];
}
void SQL_Insert(int client, int target, int duration, const char[] reason, const char[] type) {
	char query[1024], szClient[32], szTarget[32];
	
	GetClientAuthId(client, AuthId_Engine, szClient, sizeof(szClient));
	GetClientAuthId(target, AuthId_Engine, szTarget, sizeof(szTarget));
	
	int size = strlen(reason) * 2 + 1;
	char[] eReason = new char[size];
	SQL_EscapeString(rp_GetDatabase(), reason, eReason, size);
	
	Format(query, sizeof(query), "INSERT INTO `ts-x`.`srv_bans` (`id`, `SteamID`, `StartTime`, `EndTime`, `Length`, `adminSteamID`, `BanReason`, `game`) ");
	Format(query, sizeof(query), "%s VALUES(NULL, '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+%d, '%d', '%s', '%s', '%s'); ", query, szClient, duration*60, duration*60, szTarget, eReason, type);
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
}
