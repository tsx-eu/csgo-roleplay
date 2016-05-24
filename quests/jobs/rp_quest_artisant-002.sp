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

#define __LAST_REV__       "v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>   // https://www.ts-x.eu

//#define DEBUG
#define QUEST_UNIQID   "artisant-002"
#define QUEST_NAME      "Commande d'artisanat"
#define QUEST_TYPE      quest_daily

public Plugin myinfo =  {
	name = "Quête: Commande d'artisanat", author = "KoSSoLaX", 
	description = "RolePlay - Quête artisant: Commande d'artisanat", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iItemsPrice[MAX_ITEMS], g_iCraftItem[65], g_iCraftLeft[65];
bool g_bDoingQuest[65];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	SQL_TQuery(rp_GetDatabase(), SQL_LoadReceipe, "SELECT `itemid`, `prix` FROM rp_craft C INNER JOIN rp_items I ON C.`itemid`=I.`id` GROUP BY `itemid`;", 0, DBPrio_Low);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start, QUEST_NULL, QUEST_NULL, QUEST_NULL);
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
	menu.AddItem("", "Nous vous fournirons tout les matériaux", ITEMDRAW_DISABLED);
	menu.AddItem("", "nécessaire pendant votre travail.", ITEMDRAW_CONTROL);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iCraftLeft[client] = count;
	g_iCraftItem[client] = itemID;
	g_bDoingQuest[client] = true;
}
public Action RP_CanClientCraftForFree(int client, int itemID) {
	if( g_bDoingQuest[client] && g_iCraftItem[client] == itemID && g_iCraftLeft[client] > 0 )
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action RP_ClientCraftOver(int client, int itemID) {
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
