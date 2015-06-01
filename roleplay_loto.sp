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
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG

public Plugin myinfo = {
	name = "Jobs: Mc'Do", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Mc'Donalds",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

// ----------------------------------------------------------------------------
public void OnPluginStart() {
	// Loto
	RegServerCmd("rp_item_loto",		Cmd_ItemLoto,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_loto_bonus",	Cmd_ItemLotoBonus,		"RP-ITEM",	FCVAR_UNREGISTERED);
}
// ------------------------------------------------------------------------------

public Action Cmd_ItemLotoBonus(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLotoBonus");
	#endif
	int client = GetCmdArgInt(1);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous vous sentez chanceux aujourd'hui.");
	rp_IncrementLuck(client);
}
public Action Cmd_ItemLoto(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLoto");
	#endif
	
	int amount = GetCmdArgInt(1);
	int client = GetCmdArgInt(2);
	
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
	
	if( amount == -1 ) {
		char query[1024];
		
		Format(query, sizeof(query), "INSERT INTO `rp_loto` (`id`, `steamid`) VALUES (NULL, '%s');", szSteamID);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query, 0, DBPrio_Low);
		
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a été validé. Le tirage a lieu le mardi et le samedi à 21h00.");
		return Plugin_Handled;
	}
	int luck = 100;
	
	if( rp_GetClientJobID(client) == 171 ) // Pas de cheat inter job.
		luck += 40;
	if( !rp_IsClientLucky(client) )
		luck += 40;
	
	if( Math_GetRandomInt(1, luck) == 42 ) {
			
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + (amount * 100));
		rp_SetJobCapital(171, rp_GetJobCapital(171) - (amount*100));
			
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Félicitations! Vous avez gagné %i$.", (amount*100));
		LogToGame("[TSX-RP] [LOTO] %N gagne: %d$", client, (amount*100));
		
		char szQuery[1024];
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
		szSteamID, 171, GetTime(), -1, "LOTO", amount*100);			
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		rp_IncrementSuccess(client, success_list_loterie, (amount*100));			
		rp_Effect_Particle(client, "weapon_confetti_balloons", 10.0);
			
		rp_ClientSave(client);
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Désolé, vous n'avez rien gagné.");
	}


	return Plugin_Handled;
}