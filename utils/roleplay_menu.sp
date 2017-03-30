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

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

float g_flPressUse[MAXPLAYERS + 1];
bool g_bPressedUse[MAXPLAYERS + 1];
bool g_bClosed[MAXPLAYERS + 1];
bool g_bInsideMenu[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "Utils: Menu", author = "KoSSoLaX",
	description = "RolePlay - Utils: Menu",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
public void OnPluginStart() {	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnClientPostAdminCheck(int client) {
	g_flPressUse[client] = -1.0;
	g_bPressedUse[client] = false;
	g_bClosed[client] = false;
	
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "menu") ) {
		
		openMenuGeneral(client);
		
		if( g_bClosed[client] == true )	
			g_bClosed[client] = false;
		
		openMenuInteractif(client);
		return Plugin_Handled;
	}
	if( StrEqual(command, "rp") || StrEqual(command, "rpmenu") ) {
		openMenuGeneral(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action OnPlayerRunCmd(int client, int &button) {
	if( button & IN_USE && g_bPressedUse[client] == false ) {
		g_bPressedUse[client] = true;
		g_flPressUse[client] = GetGameTime();
	}
	if( !(button & IN_USE) && g_bPressedUse[client] == true ) {
		g_bPressedUse[client] = false;
		if( (GetGameTime() - g_flPressUse[client]) < 0.2 && !g_bClosed[client] && rp_GetClientVehicle(client) <= 0 && rp_IsTutorialOver(client) ) {
			if( rp_ClientCanDrawPanel(client) || g_bInsideMenu[client] )
				CreateTimer(0.1, taskOpenMenu, client);
		}
	}
}
public Action taskOpenMenu(Handle timer, any client) {
	if( rp_ClientCanDrawPanel(client) || g_bInsideMenu[client] )
		 openMenuInteractif(client);
}
void openMenuInteractif(int client) {
	int target = rp_GetClientTarget(client);
	bool veryNear = rp_IsEntitiesNear(client, target, true);
	bool near = rp_IsEntitiesNear(client, target, false);
	
	
	int jobID = rp_GetClientJobID(client);
	int optionCount = 0;
	
	Menu menu = CreateMenu(menuOpenMenu);
	menu.SetTitle("RolePlay\n ");
	
	if( IsValidClient(target) ) {
		bool hear = rp_IsTargetHear(client, target);
		
		menu.SetTitle("RolePlay: %N\n ", target);
		
		if( near && ((jobID >= 11 && jobID <= 81) || jobID >= 111) ) {
			menu.AddItem("vendre", "Vendre");
			optionCount++;
		}
		
		
		if( veryNear && rp_GetClientBool(client, b_MaySteal) && (jobID == 81 || jobID == 91) ) {
			menu.AddItem("vol", "Voler le joueur");
			optionCount++;
		}
		
		if( near && jobID == 71 ) {
			menu.AddItem("cutinfo", "Informations entraînement");
			optionCount++;
		}
		
		if( near && jobID == 11 ) {
			menu.AddItem("heal", "Soigner le joueur");
			optionCount++;
		}
		
		
		if( hear && (jobID == 1 || jobID == 101) ) {
			menu.AddItem("search", "Vérifier les permis");
			menu.AddItem("jail", "Mettre en prison");
			menu.AddItem("tazer", "Coup de tazer");
			optionCount++;
		}
		
		
		
		if( hear && jobID > 0 && rp_GetPlayerZone(target) == rp_GetPlayerZone(client) && rp_GetZoneInt(client, zone_type_type) == jobID ) {
			menu.AddItem("out", "Sortir le joueur");
		}
		
		
		if( near && rp_GetClientInt(client, i_Money) > 0 && !rp_IsClientNew(client) ) {
			menu.AddItem("give", "Donner de l'argent");
			optionCount++;
		}
	}
	else if( rp_IsValidDoor(target) ) {
		menu.SetTitle("RolePlay: Une porte\n ");
		
		int doorID = rp_GetDoorID(target);
		if( doorID > 0 && rp_GetClientKeyDoor(client, doorID) ) {
			if( GetEntProp(target, Prop_Data, "m_bLocked") ) 
				menu.AddItem("unlock", "Déverrouiller la porte");
			else
				menu.AddItem("lock", "Verrouiller la porte");
			
			optionCount++;
		}
		
		if( jobID == 1 && rp_GetClientInt(client, i_Job) <= 7 )
			menu.AddItem("perquiz", "Perquisitionner");
		if( jobID == 101 )
			menu.AddItem("perquiz", "Perquisitionner");
	}
	
	if( optionCount == 0 ) {
		delete menu;
		return;
	}
	
	menu.AddItem("exit", "Ne plus ouvrir ce menu automatiquement");
	menu.Pagination = 8;
	menu.Display(client, 30);
	
	g_bInsideMenu[client] = true;
}
void openMenuGeneral(int client) {
	int jobID = rp_GetClientJobID(client);
	
	Menu menu = CreateMenu(menuOpenMenu);
	menu.SetTitle("RolePlay\n ");
	
	menu.AddItem("item", "Ouvrir l'inventaire");
	menu.AddItem("passif", "Changer le mode de jeu");
	
	if( jobID == 101 && rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == 101 ) {
		menu.AddItem("conv", "Convoquer un joueur");
	}
	
	
	if( jobID == 11 ) {
		menu.AddItem("mort", "Faire revivre les morts");
	}
	if( jobID == 11 || jobID == 21 || jobID == 31 || jobID == 51 || jobID == 71 || jobID == 81 || jobID == 111 || jobID == 171 || jobID == 191 || jobID == 211 || jobID == 221 ) {
		menu.AddItem("build", "Construire");
	}
	if( jobID >= 0 ) {
		menu.AddItem("shownote", "Information sur mon job");
	}
	menu.AddItem("job", "Appeler un joueur");
	menu.AddItem("gps", "Trouver un lieu sur la carte");
	menu.AddItem("aide", "Besoin d'aide");
	menu.AddItem("stats", "Statistiques");
	menu.AddItem("report", "Signaler un mauvais comportement");
	
	
	
	menu.Display(client, 30);
	
	g_bInsideMenu[client] = true;
}
public int menuOpenMenu(Handle hItem, MenuAction oAction, int client, int param) {
	#if defined DEBUG
	PrintToServer("menuOpenMenu");
	#endif
	if (oAction == MenuAction_Select) {
		char options[64];
		if( GetMenuItem(hItem, param, options, sizeof(options)) ) {
			if( StrEqual(options, "give") ) {
				if( rp_GetClientInt(client, i_Money) < 1 )
					return;
				
				Menu menu = CreateMenu(menuOpenMenu);
				menu.SetTitle("RolePlay: Donner de l'argent\n ");
				if( rp_GetClientInt(client, i_Money) >= 1 ) menu.AddItem("give 1", "1$");
				if( rp_GetClientInt(client, i_Money) >= 10 ) menu.AddItem("give 10", "10$");
				if( rp_GetClientInt(client, i_Money) >= 100 ) menu.AddItem("give 100", "100$");
				if( rp_GetClientInt(client, i_Money) >= 1000 ) menu.AddItem("give 1000", "1.000$");
				if( rp_GetClientInt(client, i_Money) >= 10000 ) menu.AddItem("give 10000", "10.000$");
				if( rp_GetClientInt(client, i_Money) >= 100000 ) menu.AddItem("give 100000", "100.000$");
				
				menu.Display(client, 10);
				return;
			}
			if( StrEqual(options, "exit") ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez réouvrir ce menu avec /menu.");
				g_bClosed[client] = true;
				return;
			}
			FakeClientCommand(client, "say /%s", options);
		}		
	}
	else if (oAction == MenuAction_End ) {
		CloseHandle(hItem);
	}
	else if (oAction == MenuAction_Cancel ) {
		g_bInsideMenu[client] = false;
	}
}

