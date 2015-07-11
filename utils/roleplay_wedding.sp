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
#include <sdkhooks>
#include <cstrike>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MENU_TIME_DURATION 10

public Plugin myinfo = {
	name = "Utils: Wedding", author = "Medzila",
	description = "RolePlay - Utils: Wedding",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

// TODO: Partage auto des clés voiture / appart
// TODO: Halo roses s'ils sont cote a cote
// TODO: Regen si ils sont cote a cote
// TODO: Rajouter personnalité / sexe aux conjoints
// TODO: Bonus s'ils sont proches differents si homme ou femme du coup ?

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}

// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public void OnClientDisconnect(int client) {
	rp_UnhookEvent(client, RP_OnPlayerCommand, fwdCommand);
	
	// Un mariage est terminé si un des deux mariés déco
	int mari = rp_GetClientInt(client, i_MarriedTo);
	if( mari > 0 ) {
		rp_UnhookEvent(client, RP_OnFrameSeconde, fwdFrame);
		rp_UnhookEvent(mari, RP_OnFrameSeconde, fwdFrame);
		rp_SetClientInt(mari, i_MarriedTo, 0);
		rp_SetClientInt(client, i_MarriedTo, 0);
		CPrintToChat(mari, "{lightblue}[TSX-RP]{default} Votre conjoint a quitté la ville précipitamment, vous n'êtes plus mariés.");
	}
}

public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "mariage") ) {
		return Cmd_Mariage(client);
	}
	
	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action Cmd_Mariage(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Mariage");
	#endif
	
	int job = rp_GetClientInt(client, i_Job);
		
	if( job != 101 && job != 102 && job != 103 && job != 104) { // Au dessus de HJ1 seulement
		ACCESS_DENIED(client);
	}
	
	if( rp_GetZoneInt( rp_GetPlayerZone(client), zone_type_type) != 101 ) { // N'ouvre pas le menu en dehors du tribu
		ACCESS_DENIED(client);
	}
	
	Handle menu = CreateMenu(eventMariage_1);
	SetMenuTitle(menu, "Qui voulez vous marier ?:"); // Le juge choisi la première personne à marier 
	char tmp[24], tmp2[64];

	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( rp_GetZoneInt( rp_GetPlayerZone(i), zone_type_type) != 101 )
			continue;

		Format(tmp, sizeof(tmp), "%i", i);
		Format(tmp2, sizeof(tmp2), "%N", i);

		AddMenuItem(menu, tmp, tmp2);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION*6);

	return Plugin_Handled;
}
public int eventMariage_1(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventMariage_1");
	#endif
	
	if( action == MenuAction_Select ) {
		char options[128];
		GetMenuItem(menu, param2, options, sizeof(options));
		int target = StringToInt(options); // On choppe la premiere personne a marier

		// Setup menu
		Handle menu2 = CreateMenu(eventMariage_2);
		Format(options, sizeof(options), "A qui voulez vous marier %N", target); // On choisi la seconde personne
		SetMenuTitle(menu2, options);
		char tmp[24], tmp2[64];
		
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
				
			if( i == target )
				continue;
				
			if( rp_GetZoneInt( rp_GetPlayerZone(i), zone_type_type) != 101 )
				continue;

			Format(tmp, sizeof(tmp), "%i_%i", i, target); // On relie les deux personne a marier
			Format(tmp2, sizeof(tmp2), "%N", i);
			
			AddMenuItem(menu2, tmp, tmp2);
		}
		
		SetMenuExitButton(menu2, true);
		DisplayMenu(menu2, client, MENU_TIME_DURATION*6);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int eventMariage_2(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventMariage_2");
	#endif
	
	if( action == MenuAction_Select ) {
		char options[64], optionsBuff[2][64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, "_", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
		
		int target_1 = StringToInt(optionsBuff[0]); // premiere personne à marier
		int target_2 = StringToInt(optionsBuff[1]); // seconde
		
		int pos_1 = rp_GetZoneInt(rp_GetPlayerZone(target_1), zone_type_type);
		int pos_2 = rp_GetZoneInt(rp_GetPlayerZone(target_2), zone_type_type);
		int pos_3 = rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type);
		
		// Messages d'erreurs
		if( pos_1 != 101 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'est pas au tribunal, le mariage ne peut pas se dérouler.", target_1);
			CloseHandle(menu);
		}
		if( pos_2 != 101 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'est pas au tribunal, le mariage ne peut pas se dérouler.", target_2);
			CloseHandle(menu);
		}
		if( pos_3 != 101 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas au tribunal, le mariage ne peut pas se dérouler.");
			CloseHandle(menu);
		}
		if( rp_GetClientInt(target_1, i_MarriedTo) != 0 || rp_GetClientInt(target_2, i_MarriedTo) != 0 ){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous essayez d'unir quelqu'un déjà marié, le mariage ne peut pas se dérouler.");
			CloseHandle(menu);
		}
		
		// Setup menu
		Handle menu2 = CreateMenu(eventMariage_3);
		// S'il n'y a pas d'erreurs, on envoie un menu de choix a la premiere personne
		Format(options, sizeof(options), "Voulez-vous prendre %N pour epoux et l'aimer jusqu'a que la mort vous separe(2000$)", target_1); 
		SetMenuTitle(menu2, options);
		
		Format(options, sizeof(options), "%i_%i_1_0", target_1, client); // le dernier 0 signifie que c'est la premiere personne
		AddMenuItem(menu2, options, "Oui!");
		
		Format(options, sizeof(options), "%i_%i_0_0", target_1, client);
		AddMenuItem(menu2, options, "Non...");
		
		SetMenuExitButton(menu2, false);
		DisplayMenu(menu2, target_2, MENU_TIME_DURATION);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int eventMariage_3(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventMariage_3");
	#endif
	
	if( action == MenuAction_Select ) {
		char options[64], optionsBuff[4][64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, "_", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
		
		int fiance = StringToInt(optionsBuff[0]);
		int juge = StringToInt(optionsBuff[1]);
		int reponse = StringToInt(optionsBuff[2]);
		int flag = StringToInt(optionsBuff[3]); // Pour savoir si c'est la premiere ou la seconde personne a qui on demande
		
		if( !reponse ) {
			CPrintToChat(juge, "{lightblue}[TSX-RP]{default} Stupéfaction dans la salle, %N refuse le mariage avec %N .", client, fiance);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous refusez le mariage avec %N .", fiance);
			CloseHandle(menu);
		}
		else if( !flag ) { // Le premier a dit oui, on ouvre le même menu au second
			// Setup menu
			Handle menu2 = CreateMenu(eventMariage_3);
			
			Format(options, sizeof(options), "Voulez-vous prendre %N pour epouse et l'aimer jusqu'a que la mort vous separe(2000$)", client);
			SetMenuTitle(menu2, options);
			
			Format(options, sizeof(options), "%i_%i_1_1", client, juge);
			AddMenuItem(menu2, options, "Oui!");
			
			Format(options, sizeof(options), "%i_%i_0_1", client, juge);
			AddMenuItem(menu2, options, "Non...");
			
			SetMenuExitButton(menu2, false);
			DisplayMenu(menu2, fiance, MENU_TIME_DURATION);
		}
		else{ // Les deux sont d'accord, on les marie
			Marier(client, fiance, juge);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action Marier(int epoux, int epouse, int juge){
	#if defined DEBUG
	PrintToServer("Marier");
	#endif
	
	CPrintToChat(epoux, "{lightblue}[TSX-RP]{default} Vous et %N êtes unis par les liens du mariage, vous pouvez embrasser la mariée félicitation !", epouse);
	CPrintToChat(epouse, "{lightblue}[TSX-RP]{default} Vous et %N êtes unis par les liens du mariage, félicitation !", epoux);
	
	for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( i == epoux || i == epouse )
				continue;
			if( rp_GetZoneInt( rp_GetPlayerZone(i), zone_type_type) == 101 )
				CPrintToChat(juge, "{lightblue}[TSX-RP]{default}  %N et %N sont maintenant unis par les liens du mariage !", epoux, epouse);
	}
	
	// On paye le gentil juge et on preleve aux heureux élus
	rp_SetClientInt(epoux, i_Bank, rp_GetClientInt(epoux, i_Bank) - 2000);
	rp_SetClientInt(epouse, i_Bank, rp_GetClientInt(epouse, i_Bank) - 2000);
	rp_SetClientInt(juge, i_Bank, rp_GetClientInt(juge, i_Bank) + 4000);
	
	rp_SetClientInt(epoux, i_MarriedTo, epouse);
	rp_SetClientInt(epouse, i_MarriedTo, epoux);
		
	rp_HookEvent(epoux, RP_OnFrameSeconde, fwdFrame);
	rp_HookEvent(epouse, RP_OnFrameSeconde, fwdFrame);
	
	return Plugin_Handled;
}

public Action fwdFrame(int client) {
	int target = rp_GetClientInt(client, i_MarriedTo);
	 
	if( target > 0 )
		rp_Effect_BeamBox(client, target, NULL_VECTOR, 255, 92, 205); // Crée un laser / laser cube rose sur le/la marié(e)
}
