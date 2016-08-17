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

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define	MAX_ENTITIES	2048

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
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "hdv") ) {
		HDV_Main(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
void HDV_Main(int client) {
	Menu menu = CreateMenu(Handler_MainHDV);
	menu.SetTitle("Hotel des ventes\n ");
	
	menu.AddItem("sell", "Vendre", rp_GetClientInt(client, i_ItemCount) > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("buy", "Acheter", ITEMDRAW_DISABLED);
	menu.AddItem("history", "Votre historique", ITEMDRAW_DISABLED);
	
	menu.Display(client, 30);
}
void HDV_Sell(int client, int itemID, int quantity, int sellPrice, int confirm) {
	
	char tmp[32], tmp2[64], tmp3[64];
	Menu menu = CreateMenu(Handler_MainHDV);
	
	PrintToChatAll("%d %d %d %d", itemID, quantity, sellPrice, confirm);
	
	if( itemID == 0 ) {
		menu.SetTitle("Hotel des ventes: Vendre\n ");
		
		for (itemID = 1; itemID <= MAX_ITEMS; itemID++) {
			quantity = rp_GetClientItem(client, itemID);
			if( quantity <= 0 )
				continue;
			
			Format(tmp, sizeof(tmp), "sell %d", itemID);
			rp_GetItemData(itemID, item_type_name, tmp2, sizeof(tmp2));
			menu.AddItem(tmp, tmp2);
		}
	}
	else if( quantity == 0 ) {
		
		quantity = rp_GetClientItem(client, itemID);
		rp_GetItemData(itemID, item_type_name, tmp3, sizeof(tmp3));
		float price = rp_GetItemFloat(itemID, item_type_prix) * 0.05;
		menu.SetTitle("Hotel des ventes: Vendre\nCombien voulez-vous vendre de\n%s?\n ", tmp3);
		
		
		for (int i = 1; i <= quantity; i++) {
			
			if( quantity <= 0 )
				continue;
			
			Format(tmp, sizeof(tmp), "sell %d %d", itemID, i);
			Format(tmp2, sizeof(tmp2), "%s - taxe: %d$", tmp3, RoundToFloor(price * i));
			menu.AddItem(tmp, tmp2);
		}
	}
	else if( sellPrice == 0 ) {
		rp_GetItemData(itemID, item_type_name, tmp3, sizeof(tmp3));
		
		// TODO: Taxe supplémentaire si l'item coute moins cher (10% moins cher, 1% de taxe en plus. 10% plus cher, 1% de taxe en moins.
		// + L'afficher
		
		int price = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * 0.05 * quantity);
		int minPrice = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * 0.75 * quantity);
		int maxPrice = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * 1.25 * quantity);
		int step = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * 0.01 * quantity);
		
		menu.SetTitle("Hotel des ventes: Vendre\nA quel prix voulez-vous vendre\n%d %s?\n ", quantity, tmp3);
		
		for (int p = maxPrice; p >= minPrice; p -= step) {
			Format(tmp, sizeof(tmp), "sell %d %d %d", itemID, quantity, p);
			Format(tmp2, sizeof(tmp2), "%d$", p);
			menu.AddItem(tmp, tmp2);
		}
	}
	else if( confirm == 0 ) {
		
		// TODO: Taxe supplémentaire si l'item coute moins cher (10% moins cher, 1% de taxe en plus. 10% plus cher, 1% de taxe en moins.
		
		int price = RoundToFloor( rp_GetItemFloat(itemID, item_type_prix) * 0.05 * quantity );
		rp_GetItemData(itemID, item_type_name, tmp3, sizeof(tmp3));
		menu.SetTitle("Hotel des ventes: Vendre\nVoulez-vous déposer une offre pour\n%d %s pour %d$?\nCoût du dépot: %d$\n \nConfirmez-vous ?\n ", quantity, tmp3, sellPrice, price);
		
		Format(tmp, sizeof(tmp), "sell %d %d %d 1", itemID, quantity, sellPrice);
		
		menu.AddItem("sell", "Non, j'annule mon dépot");
		menu.AddItem(tmp, "Oui, j'accepte");
		
	}
	else {
		int price = RoundToFloor( rp_GetItemFloat(itemID, item_type_prix) * 0.05 * quantity );
		
		if( rp_GetClientItem(client, itemID) < quantity ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas la quantité que vous avez spécifié.");
			return;
		}
		
		if( rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank) < price ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas la quantité que vous avez spécifié.");
			return;
		}
		
		// TODO: INSERT INTO...
		delete menu;
		return;
	}
	
	menu.Display(client, 30);
}
public int Handler_MainHDV(Handle hItem, MenuAction oAction, int client, int param) {
	#if defined DEBUG
	PrintToServer("menuOpenMenu");
	#endif
	if (oAction == MenuAction_Select) {
		char options[128], exploded[8][32];
		GetMenuItem(hItem, param, options, sizeof(options));
		
		ExplodeString(options, " ", exploded, sizeof(exploded), sizeof(exploded[]));
		PrintToChatAll("%s", options);
		
		if( StrContains(options, "sell") == 0 ) {
			HDV_Sell(client, StringToInt(exploded[1]), StringToInt(exploded[2]), StringToInt(exploded[3]), StringToInt(exploded[4]));
		}		
	}
	else if (oAction == MenuAction_End ) {
		CloseHandle(hItem);
	}
}

