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
#include <sdkhooks>
#include <smlib>
#include <colors_csgo>
#include <basecomm>

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

bool g_dataloaded[MAXPLAYERS];
int g_iStat_LastSave[MAXPLAYERS][i_uStat_nosavemax];
int_stat_data g_Sassoc[] = { // Fait le lien entre une stat et sa valeur sauvegardée
	i_nostat, // Pas une stat à save
	i_nostat,
	i_S_MoneyEarned_Pay,
	i_S_MoneyEarned_Phone,
	i_S_MoneyEarned_Mission,
	i_S_MoneyEarned_Sales,
	i_S_MoneyEarned_Pickup,
	i_S_MoneyEarned_CashMachine,
	i_S_MoneyEarned_Give,
	i_S_MoneySpent_Fines,
	i_S_MoneySpent_Shop,
	i_S_MoneySpent_Give,
	i_S_MoneySpent_Stolen,
	i_nostat,
	i_S_LotoSpent,
	i_S_LotoWon,
	i_S_DrugPickedUp,
	i_S_Kills,
	i_S_Deaths,
	i_S_ItemUsed,
	i_S_ItemUsedPrice,
	i_nostat,
	i_S_TotalBuild,
	i_S_RunDistance,
	i_S_JobSucess,
	i_S_JobFails,
	i_nostat,
	i_nostat,
};

char g_szLevelData[64][3][256];

public Plugin myinfo = {
	name = "Utils: Stats", author = "Leethium",
	description = "RolePlay - Utils: Stats",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

public void OnPluginStart() {
	CreateTimer(120.0, saveStats, _, TIMER_REPEAT);
	
	for (int i = 1; i <= MaxClients; i++) {
		if( IsValidClient(i) ){
			OnClientPostAdminCheck(i);
			fwdDataLoaded(i);
		}
	}
}
public void OnAllPluginsLoaded() {
	SQL_TQuery(rp_GetDatabase(), SQL_loadLevelData, "SELECT `level`, `rank`, `description` FROM `rp_level`");
}

public void OnClientPostAdminCheck(int client) {
	g_dataloaded[client] = false;
	rp_HookEvent(client, RP_OnPlayerDataLoaded, fwdDataLoaded);
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	for(int i=0; i<view_as<int>(i_uStat_max); i++)
		rp_SetClientStat(client, view_as<int_stat_data>(i), 0);
	for(int i=0; i<view_as<int>(i_uStat_nosavemax); i++)
		g_iStat_LastSave[client][i] = 0;
}

public void OnClientDisconnect(int client) {	
	SaveClient(client);
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	#if defined DEBUG
	PrintToServer("fwdCommand");
	#endif
	if( StrEqual(command, "compteur") || StrEqual(command, "count") || StrEqual(command, "stats") || StrEqual(command, "stat") || StrEqual(command, "statistics") || StrEqual(command, "level") ) {
		Handle menu = CreateMenu(MenuViewStats);
		SetMenuTitle(menu, "Quelles stats afficher ?\n ");
		AddMenuItem(menu, "sess", "Sur la connexion");
		//AddMenuItem(menu, "full", "Le total");
		AddMenuItem(menu, "real", "En temps réel");
		AddMenuItem(menu, "coloc", "Infos appartement");
		AddMenuItem(menu, "level", "Mon niveau");
		AddMenuItem(menu, "succes", "Mes succès");
		DisplayMenu(menu, client, 60);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action fwdDataLoaded(int client){
	rp_SetClientStat(client, i_Money_OnConnection, ( rp_GetClientInt(client, i_Money) + rp_GetClientInt(client, i_Bank) ));
	rp_SetClientStat(client, i_PVP_OnConnection, rp_GetClientInt(client, i_PVP));
	rp_SetClientStat(client, i_Vitality_OnConnection, RoundToNearest(rp_GetClientFloat(client, fl_Vitality)) );
	char steamID[32], query[256];
	GetClientAuthId(client, AuthId_Engine, steamID, sizeof(steamID), false);
	Format(query, sizeof(query), "SELECT `stat_id`, `data` FROM `rp_statdata` WHERE `steamid`=\"%s\"", steamID);
	SQL_TQuery(rp_GetDatabase(), SQL_StatLoadCB, query, client, DBPrio_High);
}

public void SQL_StatLoadCB(Handle owner, Handle row, const char[] error, any client) {
	if(row != INVALID_HANDLE){
	    while( SQL_FetchRow(row) ) {
	        rp_SetClientStat(client, view_as<int_stat_data>(SQL_FetchInt(row, 0)), SQL_FetchInt(row, 1));
	    }
	}
	g_dataloaded[client] = true;
}

public int MenuViewStats(Handle menu, MenuAction action, int client, int param ) {
	#if defined DEBUG
	PrintToServer("MenuViewStats");
	#endif
	
	if( action == MenuAction_Select ) {
		char szMenuItem[64];
		
		if( GetMenuItem(menu, param, szMenuItem, sizeof(szMenuItem)) ) {
			if(StrEqual(szMenuItem, "full"))
				DisplayStats(client, true);
			else if(StrEqual(szMenuItem, "sess"))
				DisplayStats(client, false);
			else if(StrEqual(szMenuItem, "coloc"))
				FakeClientCommand(client, "say /infocoloc");
			else if(StrEqual(szMenuItem, "succes"))
				FakeClientCommand(client, "say /succes");
			else if(StrEqual(szMenuItem, "real"))
				DisplayRTStats(client);
			else if(StrEqual(szMenuItem, "level"))
				DisplayLevelStats(client);

		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}

public void DisplayStats(int client, bool full){
	if(!g_dataloaded[client])
		return;
	UpdateStats(client);
	char tmp[128];
	Handle menu = CreateMenu(MenuNothing);
	if(full){
		SetMenuTitle(menu, "Vos stats totales\n ");
		Format(tmp, sizeof(tmp), "Argent gagné par la paye: %d", rp_GetClientStat(client, i_S_MoneyEarned_Pay));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné par les missions téléphones: %d", rp_GetClientStat(client, i_S_MoneyEarned_Phone));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné via metier: %d", rp_GetClientStat(client, i_S_MoneyEarned_Sales));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent ramassé: %d", rp_GetClientStat(client, i_S_MoneyEarned_Pickup));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné par les machines: %d", rp_GetClientStat(client, i_S_MoneyEarned_CashMachine));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent reçu: %d", rp_GetClientStat(client, i_S_MoneyEarned_Give));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);

		AddMenuItem(menu, "", "------------------------------------------", ITEMDRAW_DISABLED);

		Format(tmp, sizeof(tmp), "Argent perdu en amendes: %d", rp_GetClientStat(client, i_S_MoneySpent_Fines));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent perdu en achetant: %d", rp_GetClientStat(client, i_S_MoneySpent_Shop));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent donné: %d", rp_GetClientStat(client, i_S_MoneySpent_Give));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent perdu par Vol: %d", rp_GetClientStat(client, i_S_MoneySpent_Stolen));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);

		AddMenuItem(menu, "", "------------------------------------------", ITEMDRAW_DISABLED);

		Format(tmp, sizeof(tmp), "Nombre d'items utilisés: %d", rp_GetClientStat(client, i_S_ItemUsed));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Prix des items utilisés: %d", rp_GetClientStat(client, i_S_ItemUsedPrice));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent perdu au loto: %d", rp_GetClientStat(client, i_S_LotoSpent));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné au loto: %d", rp_GetClientStat(client, i_S_LotoWon));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Nombre de build: %d", rp_GetClientStat(client, i_S_TotalBuild));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Distance courue: %dm", rp_GetClientStat(client, i_S_RunDistance));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Actions de job réussies: %d", rp_GetClientStat(client, i_S_JobSucess));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Actions de job ratées: %d", rp_GetClientStat(client, i_S_JobFails));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	}
	else{
		SetMenuTitle(menu, "Vos stats sur la connection\n ");
		if(( rp_GetClientInt(client, i_Money) + rp_GetClientInt(client, i_Bank) )-rp_GetClientStat(client, i_Money_OnConnection) > 0)
			Format(tmp, sizeof(tmp), "Evolution de l'argent: +%d", ( rp_GetClientInt(client, i_Money) + rp_GetClientInt(client, i_Bank) )-rp_GetClientStat(client, i_Money_OnConnection));
		else
			Format(tmp, sizeof(tmp), "Evolution de l'argent: %d", ( rp_GetClientInt(client, i_Money) + rp_GetClientInt(client, i_Bank) )-rp_GetClientStat(client, i_Money_OnConnection));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné par la paye: %d", rp_GetClientStat(client, i_MoneyEarned_Pay));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné par les missions téléphones: %d", rp_GetClientStat(client, i_MoneyEarned_Phone));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné via metier: %d", rp_GetClientStat(client, i_MoneyEarned_Sales));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent ramassé: %d", rp_GetClientStat(client, i_MoneyEarned_Pickup));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné par les machines: %d", rp_GetClientStat(client, i_MoneyEarned_CashMachine));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent reçu: %d", rp_GetClientStat(client, i_MoneyEarned_Give));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);

		AddMenuItem(menu, "", "------------------------------------------", ITEMDRAW_DISABLED);

		Format(tmp, sizeof(tmp), "Argent perdu en amendes: %d", rp_GetClientStat(client, i_MoneySpent_Fines));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent perdu en achetant: %d", rp_GetClientStat(client, i_MoneySpent_Shop));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent donné: %d", rp_GetClientStat(client, i_MoneySpent_Give));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent perdu par Vol: %d", rp_GetClientStat(client, i_MoneySpent_Stolen));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);

		AddMenuItem(menu, "", "------------------------------------------", ITEMDRAW_DISABLED);

		if(RoundToNearest(rp_GetClientFloat(client, fl_Vitality))-rp_GetClientStat(client, i_Vitality_OnConnection) > 0)
			Format(tmp, sizeof(tmp), "Evolution de la vitalité: +%d", RoundToNearest(rp_GetClientFloat(client, fl_Vitality))-rp_GetClientStat(client, i_Vitality_OnConnection));
		else
			Format(tmp, sizeof(tmp), "Evolution de la vitalité: %d", RoundToNearest(rp_GetClientFloat(client, fl_Vitality))-rp_GetClientStat(client, i_Vitality_OnConnection));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Nombre d'items utilisés: %d", rp_GetClientStat(client, i_ItemUsed));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Prix des items utilisés: %d", rp_GetClientStat(client, i_ItemUsedPrice));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent perdu au loto: %d", rp_GetClientStat(client, i_LotoSpent));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Argent gagné au loto: %d", rp_GetClientStat(client, i_LotoWon));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		if(rp_GetClientInt(client, i_PVP)-rp_GetClientStat(client, i_PVP_OnConnection) > 0)
			Format(tmp, sizeof(tmp), "Evolution des points PVP: +%d", rp_GetClientInt(client, i_PVP)-rp_GetClientStat(client, i_PVP_OnConnection));
		else
			Format(tmp, sizeof(tmp), "Evolution des points PVP: %d", rp_GetClientInt(client, i_PVP)-rp_GetClientStat(client, i_PVP_OnConnection));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Nombre de build: %d", rp_GetClientStat(client, i_TotalBuild));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Distance courue: %dm", rp_GetClientStat(client, i_RunDistance));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Actions de job réussies: %d", rp_GetClientStat(client, i_JobSucess));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Actions de job ratées: %d", rp_GetClientStat(client, i_JobFails));
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	}

	DisplayMenu(menu, client, 60);
}
public void DisplayRTStats(int client){
	if(!g_dataloaded[client])
		return;
	char tmp[128];
	Handle menu = CreateMenu(MenuNothing);
	int wep_id = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetMenuTitle(menu, "Vos stats en temps réel\n ");
	Format(tmp, sizeof(tmp), "Nombre de machines: %d", CountMachine(client, false));
	AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	Format(tmp, sizeof(tmp), "Nombre de photocopieuses: %d", CountMachine(client, true));
	AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	Format(tmp, sizeof(tmp), "Nombre de plants: %d", CountPlants(client));
	AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	Format(tmp, sizeof(tmp), "Levels cuts: %d", rp_GetClientInt(client, i_KnifeTrain));
	AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	Format(tmp, sizeof(tmp), "Levels d'esquive: %d", rp_GetClientInt(client, i_Esquive));
	AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	Format(tmp, sizeof(tmp), "Précision de tir: %.2f", rp_GetClientFloat(client, fl_WeaponTrain));
	AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	if(rp_GetClientJobID(client) != 0){	
		Format(tmp, sizeof(tmp), "Dans le job depuis: %.2f heures ",  float(rp_GetClientPlaytimeJob(client, rp_GetClientJobID(client), true))/3600.0);
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Au même grade depuis: %.2f heures", float(rp_GetClientPlaytimeJob(client, rp_GetClientInt(client, i_Job), false))/3600.0);
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	}

	GetEdictClassname(wep_id, tmp, sizeof(tmp));
	if( StrContains(tmp, "weapon_bayonet") != 0 && StrContains(tmp, "weapon_knife") != 0 ) {
		AddMenuItem(menu, "", "------ Votre Arme ------", ITEMDRAW_DISABLED);
		Format(tmp, sizeof(tmp), "Nombre de balles: %d", Weapon_GetPrimaryClip(wep_id));
	}

	DisplayMenu(menu, client, 60);
}
public void DisplayLevelStats(int client){
	char tmp[512];
	Handle menu = CreateMenu(MenuNothing);

	Format(tmp, sizeof(tmp), "Vous êtes niveau %d, prochain niveau: %d/3600 \nListe des bonus:\n", rp_GetClientInt(client, i_PlayerLVL), rp_GetClientInt(client, i_PlayerXP)%3600);
	SetMenuTitle(menu, tmp);
	for(int i=0; i<sizeof(g_szLevelData); i++){
		Format(tmp, sizeof(tmp), "Au niveau %s: %s - %s", g_szLevelData[i][0], g_szLevelData[i][1], g_szLevelData[i][2]);
		AddMenuItem(menu, "", tmp, ITEMDRAW_DISABLED);
	}

	DisplayMenu(menu, client, 60);
}

public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuNothing");
	#endif
	if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}

public void UpdateStats(int client){
	if(!g_dataloaded[client])
		return;

	for(int j=1; j < view_as<int>(i_uStat_nosavemax);j++){
		if(g_Sassoc[j] == i_nostat)
			continue;
		if(g_iStat_LastSave[client][j] == rp_GetClientStat(client, view_as<int_stat_data>(j)))
			continue;
		rp_SetClientStat(client, g_Sassoc[j], (rp_GetClientStat(client, g_Sassoc[j]) + (rp_GetClientStat(client, view_as<int_stat_data>(j)) - g_iStat_LastSave[client][j]) ) );
		g_iStat_LastSave[client][j] = rp_GetClientStat(client, view_as<int_stat_data>(j));
	}
}
char sCQuery[65536];
public Action saveStats(Handle timer){
	#if defined DEBUG
	PrintToServer("saveStats");
	#endif
	
	for (int i = 1; i <= MaxClients; i++){
		if(!IsValidClient(i))
			continue;
		if(!g_dataloaded[i])
			continue;
		UpdateStats(i);
		SaveClient(i);
	}
}

public void SaveClient(int client){
	char sCUID[32];
	UpdateStats(client);
	GetClientAuthId(client, AuthId_Engine, sCUID, sizeof(sCUID), false);
	Format(sCQuery, sizeof(sCQuery), "REPLACE INTO `rp_statdata`(`steamid`, `stat_id`, `data`) VALUES ");
	for(int j = view_as<int>(i_S_MoneyEarned_Pay); j < view_as<int>(i_uStat_max); j++){
		Format(sCQuery, sizeof(sCQuery), "%s (\"%s\", \"%i\", \"%i\"),", sCQuery, sCUID, j, rp_GetClientStat(client, view_as<int_stat_data>(j)));
	}
	sCQuery[strlen(sCQuery)-1] = 0;
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, sCQuery);
}

int CountMachine(int client, bool big) {
	int count = 0;
	char classname[64], bigclassname[64], tmp[128];
	Format(bigclassname, sizeof(bigclassname), "rp_bigcashmachine");
	Format(classname, sizeof(classname), "rp_cashmachine");
	
	for(int i=MaxClients; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, 63);
		
		if(big){
			if(StrEqual(bigclassname, tmp) && rp_GetBuildingData(i, BD_owner) == client ){
				return 1;
			}
		}
		else{
			if(StrEqual(classname, tmp) && rp_GetBuildingData(i, BD_owner) == client ){
				count++;
			}
		}
	}
	return count;
}
int CountPlants(int client){
	int count;
	char tmp2[64];
	Format(tmp2, sizeof(tmp2), "rp_plant");
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		char tmp[64];
		GetEdictClassname(i, tmp, 63);
		
		
		if( StrEqual(tmp, tmp2) && rp_GetBuildingData(i, BD_owner) == client ) {
			count++;
		}
	}
	return count;
}

public void SQL_loadLevelData(Handle owner, Handle row, const char[] error, any data) {
	if(row != INVALID_HANDLE){
		int j=0;
		while( SQL_FetchRow(row) ) {
			for(int i=0; i<=3; i++)
				SQL_FetchString(row, i, g_szLevelData[j][i], sizeof(g_szLevelData[][]));
			j++;
	    }
	}
}
