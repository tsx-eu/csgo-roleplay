/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.2.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MENU_TIME_DURATION 60

// TODO: Trouver astuce pour bypass menu vente et définir les types de contrat ici.

public Plugin myinfo = {
	name = "Jobs: Mercenaire", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Mercenaire",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

enum competance {
	competance_left = 0,
	competance_cut,
	competance_tir,
	competance_usp,
	competance_awp,
	competance_pompe,
	competance_invis,
	competance_hp,
	competance_vitesse,
	competance_type,
	
	competance_max
};

int g_iKillerPoint[65][competance_max];
int g_iKillerPoint_stored[65][competance_max];
int g_bShouldOpen[65];
Handle g_vCapture = INVALID_HANDLE;
Handle g_vConfigTueur = INVALID_HANDLE;
Handle g_hTimer[65];

// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_item_contrat",		Cmd_ItemContrat,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_conprotect",	Cmd_ItemConProtect,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_enquete_menu",Cmd_ItemEnqueteMenu,	"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_enquete",		Cmd_ItemEnquete,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cryptage",	Cmd_ItemCryptage,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_map",			Cmd_ItemMaps,			"RP-ITEM",	FCVAR_UNREGISTERED);
	
	g_vConfigTueur = CreateConVar("rp_config_kidnapping", "171,172,173,174,182,183-184");
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnConfigsExecuted() {
	g_vCapture =  FindConVar("rp_capture");
	HookConVarChange(g_vCapture, OnCvarChange);
}
public void OnCvarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	#if defined DEBUG
	PrintToServer("OnCvarChange");
	#endif
	
	if( cvar == g_vCapture ) {
		if( StrEqual(oldVal, "none") && StrEqual(newVal, "active") ) {
			for (int i = 1; i <= MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				if( rp_GetClientInt(i, i_ToKill) > 0 ) {
					SetContratFail(i, true);
				}
			}
		}
	}
}
// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwfCommand);
	rp_HookEvent(client, RP_PostTakeDamageWeapon, fwdWeapon);
}
public void OnClientDisconnect(int client) {
	if( rp_GetClientInt(client, i_ToKill) > 0 && rp_GetClientJobID(client) == 41 ) {
		SetContratFail(client);
	}
	
	g_bShouldOpen[client] = false;
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
			
		if( rp_GetClientInt(i, i_ToKill) == client  ) {
			if( rp_GetClientInt(client, i_KidnappedBy) == i ) {
				CPrintToChat(i, "{lightblue}[TSX-RP]{default} Votre cible s'est déconnectée.");
				RestoreAssassinNormal(i);
			}
			else {
				CPrintToChat(i, "{lightblue}[TSX-RP]{default} Votre cible s'est déconnectée.");
				SetContratFail(i, true);
			}
		}
	}
	
	clearKidnapping(client);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemContrat(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemContrat");
	#endif
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(2);
	int target = GetCmdArgInt(3);
	int vendeur = GetCmdArgInt(4);
	int item_id = GetCmdArgInt(args);
	
	if( StrContains(arg1, "justice") == 0 ) {
		if( rp_GetClientJobID(client) != 101 && client != vendeur) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
	}
	
	rp_SetClientInt(target, i_ContratTotal, rp_GetClientInt(target, i_ContratTotal) + 1);
	if( rp_GetClientJobID(client) == 41 && rp_GetClientJobID(vendeur) )
		rp_SetClientInt(target, i_ContratTotal, rp_GetClientInt(target, i_ContratTotal) + 1);
	
	switch( rp_GetClientInt(vendeur, i_Job) ) {
		case 41: g_iKillerPoint[vendeur][competance_left] = 6;
		case 42: g_iKillerPoint[vendeur][competance_left] = 6;
		case 43: g_iKillerPoint[vendeur][competance_left] = 5;
		case 44: g_iKillerPoint[vendeur][competance_left] = 5;
		case 45: g_iKillerPoint[vendeur][competance_left] = 4;
		case 46: g_iKillerPoint[vendeur][competance_left] = 4;
		case 47: g_iKillerPoint[vendeur][competance_left] = 3;					
		default: g_iKillerPoint[vendeur][competance_left] = 0;
	}
	OpenSelectSkill(vendeur);
	
	rp_SetClientInt(vendeur, i_ToKill, target);
	rp_SetClientInt(vendeur, i_ContratFor, client);
	if(item_id != 0)
		rp_SetClientInt(vendeur, i_ContratPay, rp_GetItemInt(item_id, item_type_prix) );
	else
		rp_SetClientInt(vendeur, i_ContratPay, 0);

	rp_HookEvent(vendeur, RP_OnPlayerDead, fwdTueurDead);
	rp_HookEvent(target, RP_OnPlayerDead, fwdTueurKill);
	rp_HookEvent(vendeur, RP_OnFrameSeconde, fwdFrame);
	
	rp_HookEvent(vendeur, RP_PreGiveDamage, fwdDamage);

	rp_SetClientStat(vendeur, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);

	
	SDKHook(vendeur, SDKHook_WeaponDrop, OnWeaponDrop);
	
	
	if( StrContains(arg1, "classic") == 0 ) {
		g_iKillerPoint[vendeur][competance_type] = 1001;
	}
	else if( StrContains(arg1, "police") == 0 ) {
		g_iKillerPoint[vendeur][competance_type] = 1002;
	}
	else if( StrContains(arg1, "pvp") == 0 ) {
		g_iKillerPoint[vendeur][competance_type] = 1003;
	}
	else if( StrContains(arg1, "justice") == 0 ) {
		g_iKillerPoint[vendeur][competance_type] = 1004;
	}
	else if( StrContains(arg1, "kidnapping") == 0 ) {
		g_iKillerPoint[vendeur][competance_type] = 1005;
		rp_SetClientInt(target, i_ContratTotal, rp_GetClientInt(target, i_ContratTotal) + 10);
	}
	else if( StrContains(arg1, "lupin") == 0 ) {
		g_iKillerPoint[vendeur][competance_type] = 1006;
	}
	
	
	if( !IsValidClient(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible s'est déconnectée.");
		SetContratFail(client);
	}
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action fwdFrame(int client) {
	int target = rp_GetClientInt(client, i_ToKill);
	
	if( !IsValidClient(target) ) {
		SetContratFail(client);
	}
	else if(rp_GetClientJobID(client) != 41) {
		SetContratFail(client);
	}
	else {
		rp_Effect_BeamBox(client, target, NULL_VECTOR, 255, 0, 0);
	}
	
	return Plugin_Continue;
}
public Action fwdTueurKill(int client, int attacker, float& respawn) {
	if( rp_GetClientInt(attacker, i_ToKill) == client && rp_GetClientInt(client, i_KidnappedBy) != attacker ) {
		rp_SetClientStat(attacker, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
		rp_SetClientStat(attacker, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
		CPrintToChat(attacker, "{lightblue}[TSX-RP]{default} Vous avez rempli votre contrat pour avoir tué %N.", client);
		rp_SetClientInt(attacker, i_AddToPay, rp_GetClientInt(attacker, i_AddToPay) + 100);
		
		int from = rp_GetClientInt(attacker, i_ContratFor);
		bool kidnapping = false;
		
		if( IsValidClient(from) ) {
			CPrintToChat(from, "{lightblue}[TSX-RP]{default} %N a rempli son contrat en tuant %N.", attacker, client);
			rp_IncrementSuccess(from, success_list_tueur);
			
			if( g_iKillerPoint[attacker][competance_type] == 1003 ) {
				int gFrom = rp_GetClientGroupID(from);
				int gVictim = rp_GetClientGroupID(client);
				
				if( gFrom != 0 && gVictim != 0 && gVictim != gFrom ) {
					char query[1024], szSteamID[32], szSteamID2[32];

					GetClientAuthId(from, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
					GetClientAuthId(client, AuthId_Engine, szSteamID2, sizeof(szSteamID2), false);

					Format(query, sizeof(query), "INSERT INTO `rp_pvp` (`id`, `group_id`, `steamid`, `steamid2`, `time`, `time2`) VALUES (NULL, '%i', '%s', '%s', '%i', '%i');",
						gFrom, szSteamID, szSteamID2, 1, 1 );

					SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query, 0, DBPrio_Low);

					rp_IncrementSuccess(from, success_list_in_gang);
				}
			}
			else if( g_iKillerPoint[attacker][competance_type] == 1004 ) {
				respawn = 0.05;
				if( rp_GetClientBool(client, b_IsSearchByTribunal) ) {
					rp_SetClientBool(client, b_SpawnToTribunal, true);
					rp_HookEvent(client, RP_OnPlayerSpawn, fwdOnRespawn);
				}
			}
			else if( g_iKillerPoint[attacker][competance_type] == 1005 ) {
				rp_SetClientInt(client, i_ToPay, from);
				rp_SetClientInt(client, i_KidnappedBy, attacker);
				rp_SetClientBool(client, b_SpawnToTueur, true);
				rp_HookEvent(client, RP_OnPlayerSpawn, fwdOnRespawn);
				respawn = 0.05;				
				kidnapping = true;
				
				rp_ClientFloodIncrement(0, client, fd_kidnapping, 6.0*60.0);
			}
			else if( g_iKillerPoint[attacker][competance_type] == 1006 ) {
				if((rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank)) > 1000){
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - 100);
					rp_SetClientInt(from, i_Money, rp_GetClientInt(from, i_Money) + 100);
				}
				respawn *= 1.25;			
			}
			else if( g_iKillerPoint[attacker][competance_type] == 1007 ) {
				int mnt;
				
				for(int i=0; i<MAX_ITEMS; i++) {
					mnt = rp_GetClientItem(client, i);
					
					if( mnt ) {
						rp_ClientGiveItem(client, i, mnt, true);
						rp_ClientGiveItem(client, i, -mnt, false);
					}
				}
				respawn *= 4.0;			
			}
			else {
				respawn *= 1.25;
			}
		}
		
		if( !kidnapping )
			RestoreAssassinNormal(attacker);
		
		return Plugin_Handled; // On retire des logs
	}
	return Plugin_Continue;
}
public Action fwdOnRespawn(int client) {
	if( rp_GetClientBool(client, b_SpawnToTueur) ) {
		rp_SetClientBool(client, b_SpawnToTueur, false);
		CreateTimer(0.01, SendToTueur, client);
	}
	if( rp_GetClientBool(client, b_SpawnToTribunal) ) {
		rp_SetClientBool(client, b_SpawnToTribunal, false);
		CreateTimer(0.01, SendToTribunal, client);
	}
}
public Action fwdTueurDead(int client, int attacker, float& respawn) {
	int target = rp_GetClientInt(client, i_ToKill);
	if( target > 0  && attacker == target) { // Double check.
		SetContratFail(client);
	}
	
	return Plugin_Continue;
}
public Action OnWeaponDrop(int client, int weapon) {
	
	if( rp_GetClientJobID(client) == 41 && (g_iKillerPoint[client][competance_usp] || g_iKillerPoint[client][competance_awp] || g_iKillerPoint[client][competance_pompe]) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas lâcher vos armes pendant un contrat.");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
public Action fwdDamage(int client, int victim, float& damage) {
	
	int target = rp_GetClientInt(client, i_ToKill);
	
	if( target > 0 && target == victim ) {
		if( !rp_IsTargetSeen(victim, client) )
			damage *= 2.0;
		if( rp_IsClientNew(victim) )
			damage *= 2.0;
			
		damage *= 2.0;
		return Plugin_Changed;
	}
	else if( target > 0 && target != victim ) {
		damage /= 3.0;
		return Plugin_Changed;
	}
		
	return Plugin_Continue;
}
public Action fwdSpeed(int client, float& speed, float& gravity) {
	speed += 0.5;
	return Plugin_Changed;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemConProtect(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemConProtect");
	#endif
	
	int client = GetCmdArgInt(1);
	int vendeur = GetCmdArgInt(2);
	
	rp_SetClientInt(client, i_Protect_From, vendeur);
	rp_SetClientInt(vendeur, i_Protect_Him, client);
	
	GivePlayerItem(client, "weapon_taser");
	GivePlayerItem(vendeur, "weapon_taser");
	
	CreateTimer(6*60.0, TimerEndProtect, client);
}
public Action TimerEndProtect(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("TimerEndProtect");
	#endif
	
	int vendeur = rp_GetClientInt(client, i_Protect_From);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le contrat de protection est terminé."); // Félicitations si réussi ? Votre client est mort,dommage. si raté ?
	CPrintToChat(vendeur, "{lightblue}[TSX-RP]{default} Le contrat de protection est terminé.");
	
	rp_SetClientInt(client, i_Protect_From, 0);
	rp_SetClientInt(vendeur, i_Protect_Him, 0);
	
}
// ----------------------------------------------------------------------------
public Action fwfCommand(int client, char[] command, char[] arg) {	
	if( StrEqual(command, "tueur") || StrEqual(command, "skill") ) { // C'est pour nous !
		if( rp_GetClientJobID(client) == 41 ) {
			OpenSelectSkill(client);
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
void OpenSelectSkill(int client) {
	#if defined DEBUG
	PrintToServer("OpenSelectSkill");
	#endif
	
	char tmp[255];
	Format(tmp, 254, "Sélectionner les compétences à utiliser (%i)", g_iKillerPoint[client][competance_left]);
	
	Handle menu = CreateMenu(AddCompetanceToAssassin);
	SetMenuTitle(menu, tmp);
	
	AddMenuItem(menu, "annule", "Annuler mon contrat");
	
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_cut] ) {
		AddMenuItem(menu, "cut", "Cut Maximum");
	}
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_tir] ) {
		AddMenuItem(menu, "tir", "Precision Maximum");
	}
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_usp] && ( !g_iKillerPoint[client][competance_awp] && !g_iKillerPoint[client][competance_pompe] )) { //On ne peut pas selectionner une arme si on en déjà choisi une auparavant
		AddMenuItem(menu, "usp", "M4 / Usp");
	}
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_awp] && ( !g_iKillerPoint[client][competance_usp] && !g_iKillerPoint[client][competance_pompe] )) {
		AddMenuItem(menu, "awp", "AWP / Cz75");
	}
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_pompe] && ( !g_iKillerPoint[client][competance_awp] && !g_iKillerPoint[client][competance_usp] )) {
		AddMenuItem(menu, "pompe", "Nova / Deagle");
	}
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_invis] ) {
		AddMenuItem(menu, "inv", "Invisibilité");
	}
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_hp] ) {
		AddMenuItem(menu, "vie", "Vie");
	}
	if( g_iKillerPoint[client][competance_left] > 0 && !g_iKillerPoint[client][competance_vitesse] ) {
		AddMenuItem(menu, "vit", "Vitesse");
	}
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
public int AddCompetanceToAssassin(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("AddCompetanceToAssassin");
	#endif
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, 63);
		
		if( !IsPlayerAlive(client) ) {
			OpenSelectSkill(client);
			return;
		}
		
		if( StrEqual(options, "annule", false) ) {
			LogToGame("[CONTRAT] %L a annulé son contrat.", client);
			SetContratFail(client);
		}
		else if( g_iKillerPoint[client][competance_left] <= 0 ) {
			return;
		}
		else if( StrEqual(options, "cut", false) ) {
			g_iKillerPoint[client][competance_cut] = 1;
			g_iKillerPoint_stored[client][competance_cut] = rp_GetClientInt(client, i_KnifeTrain);
			rp_SetClientInt(client, i_KnifeTrain, 100);
		}
		else if( StrEqual(options, "tir", false) ) {
			g_iKillerPoint[client][competance_tir] = 1;
			g_iKillerPoint_stored[client][competance_tir] = RoundToCeil( rp_GetClientFloat(client, fl_WeaponTrain) );
			rp_SetClientFloat(client, fl_WeaponTrain, 10.0);
		}
		else if( StrEqual(options, "usp", false) || StrEqual(options, "awp", false) || StrEqual(options, "pompe", false) ) {
			
			if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_JAIL || rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_LACOURS || rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_HAUTESECU )
				return;
			
			int wepIdx;
			
			for( int i = 0; i < 5; i++ ){
				if( i == CS_SLOT_KNIFE ) continue; 
				if( i == CS_SLOT_GRENADE ) continue;
				
				while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ){
					RemovePlayerItem( client, wepIdx );
					RemoveEdict( wepIdx );
				}
			}
			if( StrEqual(options, "usp", false) ){
				g_iKillerPoint[client][competance_usp] = 1;
				
				GivePlayerItem(client, "weapon_usp_silencer");
				GivePlayerItem(client, "weapon_m4a1_silencer");
			}
			else if( StrEqual(options, "awp", false) ){
				g_iKillerPoint[client][competance_awp] = 1;
				
				GivePlayerItem(client, "weapon_cz75a");
				GivePlayerItem(client, "weapon_awp");
			}
			else if( StrEqual(options, "pompe", false) ){
				g_iKillerPoint[client][competance_pompe] = 1;
				
				GivePlayerItem(client, "weapon_deagle");
				GivePlayerItem(client, "weapon_nova");
			}
		}
		else if( StrEqual(options, "inv", false) ) {
			g_iKillerPoint[client][competance_invis] = 1;
			SetEntPropFloat(client, Prop_Send, "m_fadeMinDist", 0.0);
			SetEntPropFloat(client, Prop_Send, "m_fadeMaxDist", 300.0);
			SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
			
		}
		else if( StrEqual(options, "vie", false) ) {
			g_iKillerPoint[client][competance_hp] = 1;
			g_iKillerPoint_stored[client][competance_hp] = GetClientHealth(client);
			SetEntityHealth(client, 500);
		}
		else if( StrEqual(options, "vit", false) ) {
			g_iKillerPoint[client][competance_vitesse] = 1;
			rp_HookEvent(client, RP_PrePlayerPhysic, fwdSpeed);
		}
		
		g_iKillerPoint[client][competance_left]--;
		OpenSelectSkill(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}
public void OnPostThinkPost(int client) {
	SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}
// ----------------------------------------------------------------------------
void RestoreAssassinNormal(int client) {
	#if defined DEBUG
	PrintToServer("RestoreAssassinNormal");
	#endif
	
	g_iKillerPoint[client][competance_left] = 0;
	
	if( g_iKillerPoint[client][competance_cut] ) {
		rp_SetClientInt(client, i_KnifeTrain, g_iKillerPoint_stored[client][competance_cut]);
	}
	if( g_iKillerPoint[client][competance_tir] ) {
		rp_SetClientFloat(client, fl_WeaponTrain, float(g_iKillerPoint_stored[client][competance_tir]));
	}
	if( g_iKillerPoint[client][competance_invis] ) {
		SetEntPropFloat(client, Prop_Send, "m_fadeMinDist", 0.0);
		SetEntPropFloat(client, Prop_Send, "m_fadeMaxDist", -1.0);
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	}
	if( g_iKillerPoint[client][competance_usp] || g_iKillerPoint[client][competance_awp] || g_iKillerPoint[client][competance_pompe] ) {
		
		int wepIdx;
		
		for( int i = 0; i < 5; i++ ){
			if( i == CS_SLOT_KNIFE ) continue; 
			if( i == CS_SLOT_GRENADE ) continue;
			
			while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ){
				RemovePlayerItem( client, wepIdx );
				RemoveEdict( wepIdx );
			}
		}
		
		FakeClientCommand(client, "use weapon_knife");
	}
	if( g_iKillerPoint[client][competance_vitesse] ) {
		rp_UnhookEvent(client, RP_PrePlayerPhysic, fwdSpeed);
	}
	
	g_iKillerPoint[client][competance_cut] = 0;
	g_iKillerPoint[client][competance_tir] = 0;
	g_iKillerPoint[client][competance_usp] = 0;
	g_iKillerPoint[client][competance_awp] = 0;
	g_iKillerPoint[client][competance_pompe] = 0;
	g_iKillerPoint[client][competance_invis] = 0;
	g_iKillerPoint[client][competance_hp] = 0;
	g_iKillerPoint[client][competance_vitesse] = 0;
	
	SDKUnhook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	rp_UnhookEvent(client, RP_OnPlayerDead, fwdTueurDead);
	rp_UnhookEvent(client, RP_OnFrameSeconde, fwdFrame);
	rp_UnhookEvent(client, RP_PreGiveDamage, fwdDamage);
	
	rp_UnhookEvent( rp_GetClientInt(client, i_ToKill), RP_OnPlayerDead, fwdTueurKill);
	
	rp_SetClientInt(client, i_ToKill, 0);
	rp_SetClientInt(client, i_ContratFor, 0);
	
	rp_ClientColorize(client);
}
void SetContratFail(int client, bool time = false) { // time = retro-compatibilité. 
	#if defined DEBUG
	PrintToServer("SetContratFail");
	#endif
	
	int jobClient = rp_GetClientJobID(client);
	
	if( time )
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas rempli votre contrat à temps.");
	else if( jobClient != 41 ) // si le tueur a démissionné entre temps
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes plus mercenaire, vous ne pouvez plus remplir votre contrat.");
	else
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes mort et n'avez pas rempli votre contrat.");
	
	int target = rp_GetClientInt(client, i_ContratFor);
	if(target != client){
		if( IsValidClient(target) ) {		
			
			if( time )
				CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N n'a pas rempli son contrat à temps.", client);
			else if( jobClient != 41 ) // si le tueur a démissionné entre temps
				CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N n'est plus mercenaire et ne peut plus remplir votre contrat.", client);
			else
				CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N a été tué et n'a pas pu remplir son contrat.", client);
			
			
			
			int prix = rp_GetClientInt(client, i_ContratPay);
			int reduction = rp_GetClientInt(client, i_Reduction);
			
			rp_SetClientInt(target, i_Bank, rp_GetClientInt(target, i_Bank) + prix - (RoundFloat((float(prix) / 100.0) * float(reduction)) / 2));
			rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) - (prix - RoundFloat( (float(prix) / 100.0) * float(reduction))) / 2);
			rp_SetJobCapital(41, rp_GetJobCapital(41) - (prix / 2));
			
			Call_StartForward(rp_GetForwardHandle(client, RP_OnPlayerSell));
			Call_PushCell(client);
			Call_PushCell(- (prix - RoundFloat( (float(prix) / 100.0) * float(reduction))) / 2);
			Call_Finish();
		}
		else {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre employeur s'est déconnecté, vous ne le remboursez pas.");
		}
	}
	
	
	target = rp_GetClientInt(client, i_ToKill);
	
	RestoreAssassinNormal(client);
	
	rp_SetClientInt(target, i_ContratTotal, rp_GetClientInt(target, i_ContratTotal) - 1);
}
// ----------------------------------------------------------------------------
public Action SendToTribunal(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("SendToTribunal");
	#endif
	
	if( Math_GetRandomInt(0, 1) )
		TeleportEntity(client, view_as<float>({-276.0, -276.0, -1980.0}), NULL_VECTOR, NULL_VECTOR);
	else
		TeleportEntity(client, view_as<float>({632.0, -1258.0, -1980.0}), NULL_VECTOR, NULL_VECTOR);
}
// ----------------------------------------------------------------------------
public Action SendToTueur(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("SendToTueur");
	#endif
	
	TeleportEntity(client,  view_as<float>({-5553.0, -2818.0, -1958.0}), NULL_VECTOR, NULL_VECTOR);
	
	char classname[64];
	for(int i=MaxClients; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
			
		
		GetEdictClassname(i, classname, sizeof(classname));
		
		if( StrContains(classname, "door") != -1 &&
			rp_GetZoneInt(rp_GetPlayerZone(i, 60.0) , zone_type_type) == 41
			) {
			AcceptEntityInput(i, "Close");
			rp_ScheduleEntityInput(i, 0.01, "Lock");
		}
	}
	int mnt;
	
	for(int i=0; i<MAX_ITEMS; i++) {
		mnt = rp_GetClientItem(client, i);
		
		if( mnt ) {
			rp_ClientGiveItem(client, i, mnt, true);
			rp_ClientGiveItem(client, i, -mnt, false);
		}
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez entendu dire que vos ravisseurs comptent vous libérer dans 6h. Vous pouvez tenter autre chose...");
	
	g_hTimer[client] = CreateTimer(6*60.0, FreeKidnapping, client);
	rp_HookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
	rp_HookEvent(client, RP_OnPlayerDead, fwdDead);
	rp_HookEvent(client, RP_OnFrameSeconde, fwdFrameKidnap);
	g_bShouldOpen[client] = true;
	
	OpenKidnappingMenu(client);
}
void clearKidnapping(int client) {
	if( rp_GetClientInt(client, i_KidnappedBy) > 0 ) {
		rp_UnhookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
		rp_UnhookEvent(client, RP_OnPlayerDead, fwdDead);
		rp_UnhookEvent(client, RP_OnFrameSeconde, fwdFrame);
	
		rp_SetClientInt(client, i_KidnappedBy, 0);
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = null;
		g_bShouldOpen[client] = false;
	}
}
public Action fwdZoneChange(int client, int newZone, int oldZone) {
	int newType = rp_GetZoneInt(newZone, zone_type_type);
	int oldType = rp_GetZoneInt(oldZone, zone_type_type);
	
	if( oldType == 41 && newType != 41 ) {
		float vecDest[3] =  { -3876.0, -2550.7, -2007.9 };
		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);
		
		if( GetVectorDistance(vecDest, vecOrigin) < 128.0 ) {
			int target = rp_GetClientInt(client, i_KidnappedBy);
			clearKidnapping(client);
			
			rp_SetClientInt( target, i_ContratFor, rp_GetClientInt(client, i_ToPay) );
			SetContratFail( target , true);
			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez pris la fuite, vous êtes libre !");
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N s'est échappé.", client);
		}
		else {
			TeleportEntity(client,  view_as<float>({-5553.9, -2838.9, -1959.9}), NULL_VECTOR, NULL_VECTOR);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Une tentative de triche a été détectée.");
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Êtes-vous sorti correctement, sans triche, sans téléportation ?");
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Si c'est le cas, contactez KoSSoLaX --> @Kossolax@ts-x.eu ");			
		}
	}
}
public Action fwdDead(int client, int attacker, float& respawn) {
	int target = rp_GetClientInt(client, i_KidnappedBy);
	clearKidnapping(client);
	
	rp_SetClientInt(target, i_ContratFor, rp_GetClientInt(client, i_ToPay) );
	SetContratFail( target , true);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vos ravisseurs vous ont tué.");
	CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N s'est échappé.", client);
	
	
	return Plugin_Continue;
}
public Action FreeKidnapping(Handle timer, any client) {
	if( g_hTimer[client] == null )
		return Plugin_Handled;
	
	int target = rp_GetClientInt(client, i_KidnappedBy);
	clearKidnapping(client);
	RestoreAssassinNormal(target);
	TeleportEntity(client,  view_as<float>({2911.0, 868.0, -1853.0}), NULL_VECTOR, NULL_VECTOR);
	rp_ClientSendToSpawn(client, true); // C'est proche du comico. 
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vos ravisseurs vous ont finalement libéré.");
	CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez libéré %N.", target);
	
	return Plugin_Continue;
}
public int eventKidnapping(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("eventKidnapping");
	#endif
	if (p_oAction == MenuAction_Select) {
		
		char options[64];
		GetMenuItem(p_hItemMenu, p_iParam2, options, 63);
		
		if( StrEqual( options, "pay", false) ) {
			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez payé la rançon de 2500$.");
			
			int from = rp_GetClientInt(client, i_ToPay);
			int target = rp_GetClientInt(client, i_KidnappedBy);
			
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - 2500);
			rp_SetClientInt(from, i_Bank, rp_GetClientInt(from, i_Bank) + 2500);			
			
			CPrintToChat(from, "{lightblue}[TSX-RP]{default} %N a payé la rançon de 2500$.", client);
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N a payé la rançon de 2500$.", client);
			
			rp_IncrementSuccess(from, success_list_kidnapping);
			
			clearKidnapping(client);
			RestoreAssassinNormal(target);
			
			TeleportEntity(client,  view_as<float>({2911.0, 868.0, -1853.0}), NULL_VECTOR, NULL_VECTOR);
			rp_ClientSendToSpawn(client, true);
		}
		else if( StrEqual( options, "free", false) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Les portes s'ouvriront toute les 20 secondes, vous n'avez qu'une seule chance de vous en sortir. Pas le droit à l'erreur, foncez !");
			float delay = 20.0;
			float time = 0.0;
			
			GivePlayerItem(client, "weapon_revolver");
			
			char door[128], doors[12][12], tmp[2][12];
			GetConVarString(g_vConfigTueur, door, sizeof(door));
			int amount = ExplodeString(door, ",", doors, sizeof(doors), sizeof(doors[]) );
			
			for (int i = 0; i <= amount; i++) {
				
				int dble = ExplodeString(doors[i], "-", tmp, sizeof(tmp), sizeof(tmp[]));
				int entity = StringToInt(tmp[0]) + MaxClients;
				
				for (float delta = 0.1; delta <= 1.0; delta+=0.1) {
					rp_ScheduleEntityInput(entity, time+delta, "Unlock");
					rp_ScheduleEntityInput(entity, time+delta+0.1, "Open");
				}
				
				if( dble == 2 ) {
					entity = StringToInt(tmp[1]) + MaxClients;
					for (float delta = 0.1; delta <= 1.0; delta+=0.1) {
						rp_ScheduleEntityInput(entity, time+delta, "Unlock");
						rp_ScheduleEntityInput(entity, time+delta+0.1, "Open");
					}
					rp_ScheduleEntityInput(entity, time+30.0, "Close");
					rp_ScheduleEntityInput(entity, time+30.1, "Lock");
				}
				
				time += delay;
			}
			
			g_bShouldOpen[client] = false;
		}
		else if( StrEqual( options, "cops", false) ) {
			char dest[128];
			rp_GetZoneData(rp_GetPlayerZone(client), zone_type_name, dest, sizeof(dest));
			
			for(int i=1; i<=MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				if( rp_GetClientJobID(i) != 1 && rp_GetClientJobID(i) != 101 )
					continue;
				
				CPrintToChat(i, "{lightblue}[TSX-RP]{default} Un enlèvement a eut lieu. Vous devez libérer %N dans %s.", client, dest);
				rp_Effect_BeamBox(i, client);
				ClientCommand(i, "play buttons/blip1.wav");
			}
			
		}
		else if( StrEqual( options, "mafia", false) ) {
			
			char dest[128];
			rp_GetZoneData(rp_GetPlayerZone(client), zone_type_name, dest, sizeof(dest));
			
			for(int i=1; i<=MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				if( rp_GetClientJobID(i) != 91 )
					continue;
				
				CPrintToChat(i, "{lightblue}[TSX-RP]{default} Un enlèvement a eu lieu. Vous devez libérer %N dans %s.", client, dest);
				rp_Effect_BeamBox(i, client);
				ClientCommand(i, "play buttons/blip1.wav");
			}
			
		}
		else if( StrEqual( options, "crier", false) ) {
			FakeClientCommand(client, "say \"Au secours, j'ai été enlevé !!!\"");
			
			OpenKidnappingMenu(client);
		}
		
	}
	else if (p_oAction == MenuAction_End ) {
		CloseHandle(p_hItemMenu);
	}
}
void OpenKidnappingMenu(int client) {
		
	if( g_bShouldOpen[client] && rp_GetZoneInt( rp_GetPlayerZone(client), zone_type_type) == 41 && rp_ClientCanDrawPanel(client) ) {
		Handle menu = CreateMenu(eventKidnapping);
		SetMenuTitle(menu, "Vous avez été enlevé ! Que faire ?");
			
		AddMenuItem(menu, "pay", "Payer la rançon de 2500$");
		AddMenuItem(menu, "free", "Tenter l'évasion");
		AddMenuItem(menu, "cops", "Appeler la police");
		AddMenuItem(menu, "mafia", "Appeler la mafia");
		AddMenuItem(menu, "crier", "Crier");		
		
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 180);
	}
}
public Action fwdFrameKidnap(int client) {
	OpenKidnappingMenu(client);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemCryptage(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCryptage");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if(rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit aux forces de l'ordre.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	int level = rp_GetClientInt(client, i_Cryptage) + 1;
	
	if( level > 5 )
		level = 5;
		
	rp_SetClientInt(client, i_Cryptage, level);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Les mercenaires vous couvrent, vous avez désormais %i/100 de chance d'être caché.", level*20);
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemEnqueteMenu(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemEnqueteMenu");
	#endif
	char arg1[12];
	GetCmdArg(1, arg1, 11);
	
	int client = StringToInt(arg1);
	
	Handle menu = CreateMenu(Cmd_ItemEnqueteMenu_2);
	SetMenuTitle(menu, "Sélectionner sur qui récupérer des informations :");
	
	char name[128], tmp[64];
	GetClientName(client, name, 127);
	Format(tmp, 64, "%i", client);
	
	AddMenuItem(menu, tmp, name);
	
	for(int i = 1; i <= MaxClients; i++) {
		
		if( !IsValidClient(i) )
			continue;
		if( !IsClientConnected(i) )
			continue;
		if( i == client )
			continue;
		
		GetClientName(i, name, 127);
		Format(tmp, 64, "%i", i);
		
		AddMenuItem(menu, tmp, name);		
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
public int Cmd_ItemEnqueteMenu_2(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemEnqueteMenu_2");
	#endif
	if (p_oAction == MenuAction_Select) {
		
		char szMenuItem[64];
		if( GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem)) ) {
			
			int target = StringToInt(szMenuItem);
			ServerCommand("rp_item_enquete \"%i\" \"%i\"", client, target);
		}		
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}
public Action Cmd_ItemEnquete(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemEnquete");
	#endif
	
	int client = GetCmdArgInt(1);
	int target = GetCmdArgInt(2);
	char tmp[255];
	
	
	rp_IncrementSuccess(client, success_list_detective);
	
	// Setup menu
	Handle menu = CreateMenu(MenuNothing);
	SetMenuTitle(menu, "Information sur %N:", target);
	
	PrintToConsole(client, "\n\n\n\n\n -------------------------------------------------------------------------------------------- ");
	
	rp_GetZoneData(rp_GetPlayerZone(target), zone_type_name, tmp, sizeof(tmp));
	
	AddMenu_Blank(client, menu, "Localisation: %s", tmp);	
	
	int killedBy = rp_GetClientInt(target, i_LastKilled_Reverse);
	if( IsValidClient(killedBy) ) {
		if( Math_GetRandomInt(1, 100) < rp_GetClientInt(target, i_Cryptage)*20 ) {
			
			String_GetRandom(tmp, sizeof(tmp), 24);
			
			AddMenu_Blank(client, menu, "Il a tué: %s", tmp);
			CPrintToChat(killedBy, "{lightblue}[TSX-RP]{default} Votre pot de vin envers un mercenaire vient de vous sauver.");
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L n'a pas montré qui l'a tué pour cause de pot de vin.", target);
		}
		else {	
			AddMenu_Blank(client, menu, "Il a tué: %N", killedBy);
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a montré qu'il a tué %L.", target, killedBy);
		}
	}
	else{
		LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a révélé qu'il n'a tué personne", target, killedBy);
	}
	
	if( rp_GetClientInt(target, i_KillingSpread) > 0 )
		AddMenu_Blank(client, menu, "Meurtre consécutif: %i", rp_GetClientInt(target, i_KillingSpread) );
	
	int killed = rp_GetClientInt(target, i_LastKilled);
	if( IsValidClient(killed) ) {
		
		if( Math_GetRandomInt(1, 100) < rp_GetClientInt(killed, i_Cryptage)*20 ) {	
			
			String_GetRandom(tmp, sizeof(tmp), 24);
			
			AddMenu_Blank(client, menu, "%s, l'a tué", tmp);
			CPrintToChat(killed, "{lightblue}[TSX-RP]{default} Votre pot de vin envers un mercenaire vient de vous sauver.");
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L n'a pas montré qui l'a tué pour cause de pot de vin.", target);
		}
		else {
			AddMenu_Blank(client, menu, "%N, l'a tué", killed);
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a montré que %L l'a tué.", target, killed);
		}
	}
	else{
		LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a révélé qu'il n'a été tué par personne.", target, killed);
	}
	
	if( IsValidClient(rp_GetClientInt(target, i_LastVol)) ) 
		AddMenu_Blank(client, menu, "%N, l'a volé", rp_GetClientInt(target, i_LastVol) );
	
	AddMenu_Blank(client, menu, "--------------------------------");
	
	AddMenu_Blank(client, menu, "Niveau d'entraînement: %i", rp_GetClientInt(target, i_KnifeTrain));
	AddMenu_Blank(client, menu, "Précision de tir: %.2f", rp_GetClientFloat(target, fl_WeaponTrain));
	
	int count=0;
	Format(tmp, sizeof(tmp), "Permis possédé:");
	
	if( rp_GetClientBool(target, b_License1) ) {	Format(tmp, sizeof(tmp), "%s léger", tmp);	count++;	}
	if( rp_GetClientBool(target, b_License2) ) {	Format(tmp, sizeof(tmp), "%s lourd", tmp);	count++;	}
	if( rp_GetClientBool(target, b_LicenseSell) ) {	Format(tmp, sizeof(tmp), "%s vente", tmp);	count++;	}
	
	if( count == 0 ) {
		Format(tmp, sizeof(tmp), "%s Aucun", tmp);
	}
	AddMenu_Blank(client, menu, "%s.", tmp);
	
	AddMenu_Blank(client, menu, "Argent: %i$ - Banque: %i$", rp_GetClientInt(target, i_Money), rp_GetClientInt(target, i_Bank));
	
	count = 0;
	Format(tmp, sizeof(tmp), "Appartement possédé: ");
	for (int i = 1; i <= 48; i++) {
		if( rp_GetClientKeyAppartement(target, i) ) {
			count++;
			if( count > 1 )
				Format(tmp, sizeof(tmp), "%s, ", tmp);
			Format(tmp, sizeof(tmp), "%s%d", tmp, i);
		}	
	}
	
	if( count == 0 )
		Format(tmp, sizeof(tmp), "%s Aucun", tmp);
	
	AddMenu_Blank(client, menu, tmp);
	
	AddMenu_Blank(client, menu, "Taux d'alcoolémie: %.3f", rp_GetClientFloat(client, fl_Alcool));
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ces informations ont été envoyées dans votre console.");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuNothing");
	#endif
	
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
void AddMenu_Blank(int client, Handle menu, const char[] myString , any ...) {
	#if defined DEBUG
	PrintToServer("AddMenu_Blank");
	#endif
	char[] str = new char[ strlen(myString)+255 ];
	VFormat(str, (strlen(myString)+255), myString, 4);
	
	AddMenuItem(menu, "none", str, ITEMDRAW_DISABLED);
	PrintToConsole(client, str);
}

public Action fwdWeapon(int victim, int attacker, float &damage, int wepID, float pos[3]) {
	bool changed = true;
	char sWeapon[32];
	GetEdictClassname(wepID, sWeapon, sizeof(sWeapon));
	
	if( StrContains(sWeapon, "taser") != -1 ) {
		
		int him = rp_GetClientInt(attacker, i_Protect_Him);
		int from = rp_GetClientInt(attacker, i_Protect_From);
		
			
		if( IsValidClient(him) || IsValidClient(from) ) {
			SetEntProp(attacker, Prop_Data, "m_iAmmo", 100, _, 19);
			
			if( victim != him && victim != from ) {
				
				rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);
				rp_SetClientFloat(victim, fl_TazerTime, GetGameTime() + 7.5);
				
				if(!rp_GetClientBool(victim, ch_Yeux))
					ServerCommand("sm_effect_flash %d 1.5 180", victim);
						
				if( rp_GetClientInt(attacker,i_Protect_Last) == victim ) {
					int heal = GetClientHealth(him);
					heal += 25;
					if( heal > 500 )
						heal = 500;
					SetEntityHealth(him, heal);
					
					heal = GetClientHealth(attacker);
					heal += 25;
					if( heal > 500 )
						heal = 500;
					SetEntityHealth(attacker, heal);
				}
			}
		}
		else {
			if(GetEntityFlags(victim) & FL_ONGROUND) {
				int flags = GetEntityFlags(victim);
				SetEntityFlags(victim, (flags&~FL_ONGROUND) );
				SetEntPropEnt(victim, Prop_Send, "m_hGroundEntity", -1);
			}
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
			SlapPlayer(victim, 0, true);
		}
		damage *= 0.0;
		return Plugin_Handled;
	}
	
	if( changed )
		return Plugin_Changed;
	return Plugin_Continue;
}
public Action Cmd_ItemMaps(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemMaps");
	#endif
	
	int client = GetCmdArgInt(1);
	rp_SetClientBool(client, b_Map, true);
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance2);
}
public Action fwdAssurance2(int client, int& amount) {
		amount += 1000;
}

