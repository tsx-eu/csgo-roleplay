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
	name = "Jobs: Loto", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Loto",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iTicketID = 76;
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	// Loto
	RegServerCmd("rp_item_loto",		Cmd_ItemLoto,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_loto_bonus",	Cmd_ItemLotoBonus,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_stuffpvp", 	Cmd_ItemStuffPvP, 		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
// ------------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerBuild, fwdOnPlayerBuild);
}
public Action fwdOnPlayerBuild(int client, float& cooldown){
	if( rp_GetClientJobID(client) != 171 )
		return Plugin_Continue;
	
	rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
	rp_Effect_Particle(client, "weapon_confetti_balloons", 10.0);
	cooldown = 10.0;
	
	return Plugin_Stop;
}
public Action Cmd_ItemStuffPvP(int args) {
	int client = GetCmdArgInt(1);
	
	int amount = 0;
	int ItemRand[32];
	bool luck = rp_IsClientLucky(client);
	
	for (int i = 1; i <= 4; i++) {
		ItemRand[amount++] = 239;	// P90-PVP
		ItemRand[amount++] = 64;	// M4A1-S
		ItemRand[amount++] = 236;	// AK47
	}
	
	if( Math_GetRandomInt(1, 4) == 4 ) 
		ItemRand[amount++] = 27;	// Drapeau
	if( Math_GetRandomInt(1, 4) == 4 )
		ItemRand[amount++] = 67;	// Drapeau
	if( Math_GetRandomInt(1, 4) == 4 )
		ItemRand[amount++] = 118;	// Drapeau
	if( Math_GetRandomInt(1, 4) == 4 )
		ItemRand[amount++] = 126;	// Drapeau	
	
	ItemRand[amount++] = 238;	// AWP
	ItemRand[amount++] = 22;	// San-Andreas
	ItemRand[amount++] = 46;	// Incendiaire
	ItemRand[amount++] = 66;	// Sucette Duo
	ItemRand[amount++] = 242;	// Hummer
	ItemRand[amount++] = 94;	// EMP
	ItemRand[amount++] = 35;	// Cocaine
	ItemRand[amount++] = 184;	// Prop d'extérieur
	ItemRand[amount++] = 6;		// Seringue du Berserker
	ItemRand[amount++] = 114;	// Big Mac
	ItemRand[amount++] = 231;	// Cartouches explosives
	ItemRand[amount++] = 285;	// Bouclier Anti-émeute
	ItemRand[amount++] = 296;	// Paire de baskets
	ItemRand[amount++] = 53;	// Amelioration précision de tir
	
	int item_id = ItemRand[ Math_GetRandomInt(0, amount-1) ];
	rp_ClientGiveItem(client, item_id);
	if( item_id == 35 )
		rp_ClientGiveItem(client, item_id, 4);
	
	if( (luck || Math_GetRandomInt(1, 100) > 90) && (item_id == 6 || item_id == 64 || item_id == 114 || item_id == 236 || item_id == 239) )
		rp_ClientGiveItem(client, item_id);
	
	char tmp[64];
	rp_GetItemData(item_id, item_type_name, tmp, sizeof(tmp));
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu comme cadeau: %s", tmp);
}
public Action Cmd_ItemLotoBonus(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLotoBonus");
	#endif
	int client = GetCmdArgInt(1);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous vous sentez chanceux aujourd'hui.");
	rp_IncrementLuck(client);
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance);
}
public Action fwdAssurance(int client, int& amount) {
		amount += 250;
}
public void SQL_GetLotoCount(Handle owner, Handle hQuery, const char[] error, any client) {
	
	if( SQL_FetchRow(hQuery) ) {
		int cpt = SQL_FetchInt(hQuery, 0);
		
		if( cpt == 0 ) {
			char query[1024], szSteamID[32];
			GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
			
			Format(query, sizeof(query), "INSERT INTO `rp_loto` (`id`, `steamid`) VALUES (NULL, '%s');", szSteamID);
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query, 0, DBPrio_High);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a été validé. Un tirage exceptionnel pour la brocante de Noël aura lieu mercredi vers 21h30.");
		}
		else {
			rp_ClientGiveItem(client, g_iTicketID, 1, true);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a déjà été validé. Vous avez été remboursé dans votre banque.");
		}
	}		
}
public Action Cmd_ItemLoto(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLoto");
	#endif
	
	int amount = GetCmdArgInt(1);
	int client = GetCmdArgInt(2);

	if( amount > 1000)
		return Plugin_Handled;

	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
	
	if( amount == -1 ) {
		char query[1024];
		g_iTicketID = GetCmdArgInt(3);
		//Format(query, sizeof(query), "SELECT COUNT(*) FROM `rp_loto` WHERE `steamid`='%s';", szSteamID);
		//SQL_TQuery(rp_GetDatabase(), SQL_GetLotoCount, query, client, DBPrio_Low);
		//CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a été validé. Un tirage exceptionnel pour la brocante de Noël aura lieu mercredi vers 21h30.");
		Format(query, sizeof(query), "INSERT INTO `rp_loto` (`id`, `steamid`) VALUES (NULL, '%s');", szSteamID);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query, 0, DBPrio_High);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a été validé. Le tirage a lieu le mardi et le samedi à 21h00.");
		
		return Plugin_Handled;
	}
	int luck = 100;
	
	rp_SetClientStat(client, i_LotoSpent, rp_GetClientStat(client, i_LotoSpent) + amount);
	if( rp_GetClientJobID(client) == 171 ) // Pas de cheat inter job.
		luck += 40;
	if( !rp_IsClientLucky(client) )
		luck += 40;
	
	if( Math_GetRandomInt(1, luck) == 42 ) {
			
		rp_SetClientStat(client, i_LotoWon, rp_GetClientStat(client, i_LotoWon) + (amount*100));
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
