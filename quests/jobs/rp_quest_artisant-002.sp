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
#include <sdktools>
#include <cstrike>
#include <colors_csgo>   // https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>      // https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#pragma newdecls required
#include <roleplay.inc>   // https://www.ts-x.eu


#define QUEST_UNIQID   "artisant-002"
#define QUEST_NAME      "Commande d'artisanat"
#define QUEST_TYPE      quest_daily

public Plugin myinfo =  {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX", 
	description = "RolePlay - Quête artisant: "...QUEST_NAME, 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iItemsPrice[MAX_ITEMS], g_iCraftItem[65], g_iCraftLeft[65];
bool g_bDoingQuest[65];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	SQL_TQuery(rp_GetDatabase(), SQL_LoadReceipe, "SELECT `itemid`, `prix` FROM rp_craft C INNER JOIN rp_items I ON C.`itemid`=I.`id` WHERE I.`job_id`>0 AND I.`extra_cmd`<>'rp_item_spawnflag' GROUP BY `itemid`;", 0, DBPrio_Low);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	

	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start, Q1_Frame, Q_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL, Q2_Frame, Q_Abort, Q_Done);
}
public void Q1_Frame(int objectiveID, int client) {
	float maxDist;
	
	int table1 = findMyTable(client);
	int table2 = findNearestTable(client, maxDist);
	
	if( table1 > 0 ) {
		rp_Effect_BeamBox(client, table1);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\nPlacer une table de craft", QUEST_NAME);
	}
	if( table2 > 0 && maxDist < 128.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
}	
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	char tmp[64];
	int itemID = getRandomItem();
	int prix = rp_GetItemInt(itemID, item_type_prix);
	int count = 50000 / prix;
	rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
	
	Format(tmp, sizeof(tmp), "%d %s", count, tmp);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Monsieur, nous avons une commande de", ITEMDRAW_DISABLED);
	menu.AddItem("", tmp, ITEMDRAW_DISABLED);
	menu.AddItem("", "Pouvez vous nous les crafter au plus vite?", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous vous fournirons tous les matériaux", ITEMDRAW_DISABLED);
	menu.AddItem("", "nécessaires pendant votre travail.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iCraftLeft[client] = count;
	g_iCraftItem[client] = itemID;
	g_bDoingQuest[client] = true;
	
	rp_HookEvent(client, RP_PreClientCraft, fwdPreClientCraft);
	rp_HookEvent(client, RP_PostClientCraft, fwdPostClientCraft);
}
public void Q2_Frame(int objectiveID, int client) {
	if( g_iCraftLeft[client] == 0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		char tmp[64];
		rp_GetItemData(g_iCraftItem[client], item_type_name, tmp, sizeof(tmp));
		PrintHintText(client, "<b>Quête</b>: %s\nIl reste à construire\n %d %s", QUEST_NAME, g_iCraftLeft[client], tmp);
	}
}
public void Q_Abort(int objectiveID, int client) {
	g_iCraftLeft[client] = 0;
	g_iCraftItem[client] = 0;
	g_bDoingQuest[client] = false;
	rp_UnhookEvent(client, RP_PreClientCraft, fwdPreClientCraft);
	rp_UnhookEvent(client, RP_PostClientCraft, fwdPostClientCraft);
}
public void Q_Done(int objectiveID, int client) {
	Q_Abort(objectiveID, client);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Merci pour votre aide, voici 2500$ !");
	rp_ClientMoney(client, i_AddToPay, 2500);
	rp_ClientXPIncrement(client, 1000);
	
	int MP[] =  { 128, 129, 234, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257 };
	int rnd = Math_GetRandomInt(0, sizeof(MP) - 1);
	char tmp[128];
	rp_GetItemData(MP[rnd], item_type_name, tmp, sizeof(tmp));
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez trouvé 25x%s", tmp);
	rp_ClientGiveItem(client, MP[rnd], 25);
}
public Action fwdPreClientCraft(int client, int itemID, int& free) {
	if( g_bDoingQuest[client] && g_iCraftItem[client] == itemID && g_iCraftLeft[client] > 0 ) {
		free += g_iCraftLeft[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action fwdPostClientCraft(int client, int itemID) {
	if( g_bDoingQuest[client] && g_iCraftItem[client] == itemID && g_iCraftLeft[client] > 0 ) {
		g_iCraftLeft[client]--;
		rp_ClientGiveItem(client, itemID, -1);
	}
}

public void SQL_LoadReceipe(Handle owner, Handle hQuery, const char[] error, any client) {
	while( SQL_FetchRow(hQuery) ) {
		g_iItemsPrice[SQL_FetchInt(hQuery, 0)] = SQL_FetchInt(hQuery, 1);
	}
	return;
}
int getRandomItem() {
	int stackItem[MAX_ITEMS], stackCount;
	for (int i = 0; i < MAX_ITEMS; i++) {
		if( g_iItemsPrice[i] > 0 )
			stackItem[stackCount++] = i;
	}
	return stackItem[Math_GetRandomInt(0, stackCount - 1)];
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	return (rp_GetClientInt(client, i_ArtisanLevel) > 1);
}
// ----------------------------------------------------------------------------
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
	else if (action == MenuAction_End) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
}
int findMyTable(int client) {
	char classname[65];
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		GetEdictClassname(i, classname, sizeof(classname));
		
		if( StrEqual(classname, "rp_table") && rp_GetBuildingData(i, BD_owner) == client )
			return i;
	}
	return -1;
}
int findNearestTable(int client, float& maxDist) {
	maxDist = 9999999.9;
	float tmp;
	int entity = -1;
	float vecStart[3], vecEnd[3];
	GetClientAbsOrigin(client, vecStart);
	
	char classname[65];
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		GetEdictClassname(i, classname, sizeof(classname));
		
		if( StrEqual(classname, "rp_table") ) {
			Entity_GetAbsOrigin(i, vecEnd);
			tmp = GetVectorDistance(vecStart, vecEnd);
			if( tmp < maxDist ) {
				entity = i;
				maxDist = tmp;
			}
		}
	}
	return entity;
}