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

int g_cBeam, g_cGlow;

// TODO: Partage auto des clés voiture / appart
// TODO: Rajouter personnalité / sexe aux conjoints
// TODO: Bonus s'ils sont proches differents si homme ou femme du coup ?

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
}
// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	rp_SetClientInt(client, i_MarriedTo, -1);
}
public void OnClientDisconnect(int client) {
	// Un mariage est terminé si un des deux mariés déco
	int mari = rp_GetClientInt(client, i_MarriedTo);
	if( mari > 0 ) {
		CPrintToChat(mari, "{lightblue}[TSX-RP]{default} Votre conjoint a quitté la ville précipitamment, vous n'êtes plus mariés.");
		rp_UnhookEvent(mari, RP_OnFrameSeconde, fwdFrame);
		rp_SetClientInt(mari, i_MarriedTo, -1);
		rp_SetClientInt(client, i_MarriedTo, -1);
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
	int zoneJuge = rp_GetPlayerZone(client);
	
	if( job != 101 && job != 102 && job != 103 && job != 104 && job != 105 && job != 106) { // Au dessus de HJ1 seulement
		ACCESS_DENIED(client);
	}
	
	if( rp_GetZoneInt( zoneJuge, zone_type_type) != 101 ) { // N'ouvre pas le menu en dehors du tribu
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cette commande ne peut être utilisée qu'au tribunal.");
		ACCESS_DENIED(client);
	}
	
	Handle menu = CreateMenu(eventMariage_1);
	SetMenuTitle(menu, "Qui voulez-vous marier ?"); // Le juge choisi la première personne à marier 
	char tmp[24], tmp2[64];


	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetPlayerZone(i) != zoneJuge )
			continue;
		if( rp_GetClientInt(i, i_MarriedTo) > 0 )
			continue;
		if( i == client )
			continue;

		Format(tmp, sizeof(tmp), "%i_%i", i, zoneJuge);
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
		char options[64], optionsBuff[2][64];
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, "_", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
		
		int target = StringToInt(optionsBuff[0]); // On choppe la premiere personne a marier
		int zoneJuge = StringToInt(optionsBuff[1]); // Salle du juge
		
		// Setup menu
		Handle menu2 = CreateMenu(eventMariage_2);
		Format(options, sizeof(options), "A qui voulez-vous vous marier %N ?", target); // On choisi la seconde personne
		SetMenuTitle(menu2, options);
		char tmp[24], tmp2[64];
		
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( i == target || i == client )
				continue;
			if( rp_GetClientInt(i, i_MarriedTo) > 0 )
				continue;
			if( rp_GetPlayerZone(i) != zoneJuge )
				continue;

			Format(tmp, sizeof(tmp), "%i_%i_%i", i, target, zoneJuge); // On relie les deux personne a marier
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
		char options[64], optionsBuff[3][64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, "_", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
		
		int target_1 = StringToInt(optionsBuff[0]); // premiere personne à marier
		int target_2 = StringToInt(optionsBuff[0]); // seconde
		int zoneJuge = StringToInt(optionsBuff[2]);	// salle du juge
		
		int pos_1 = rp_GetPlayerZone(target_1);
		int pos_2 = rp_GetPlayerZone(target_2);
		int pos_3 = rp_GetPlayerZone(client);
		
		// Messages d'erreurs double check
		if( rp_GetZoneInt(pos_3, zone_type_type) != 101 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas au tribunal, le mariage ne peut pas se dérouler.");
			CloseHandle(menu);
			return;
		}
		if( pos_1 != pos_3 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'est pas dans la même salle de tribunal que vous, le mariage ne peut pas se dérouler", target_1);
			CloseHandle(menu);
			return;
		}
		if( pos_2 != pos_3 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'est pas dans la même salle de tribunal que vous, le mariage ne peut pas se dérouler", target_1);
			CloseHandle(menu);
			return;
		}
		if( rp_GetClientInt(target_1, i_MarriedTo) == 0 || rp_GetClientInt(target_2, i_MarriedTo) == 0 ){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous essayez d'unir quelqu'un déjà marié, le mariage ne peut pas se dérouler.");
			CloseHandle(menu);
			return;
		}
		
		// Message à toute la salle
		PrintToChatZone(zoneJuge, "{lightblue}[TSX-RP]{default} Le juge %N s'exclame: %N, voulez-vous prendre pour époux %N et l'aimer jusqu'à ce que la mort vous sépare?", client, target_2, target_1);
		
		// Setup menu
		Handle menu2 = CreateMenu(eventMariage_3);
		
		// S'il n'y a pas d'erreurs, on envoie un menu de choix a la premiere personne
		Format(options, sizeof(options), "Voulez-vous prendre %N pour époux et l'aimer jusqu'à ce que la mort vous sépare ? (2000$)", target_1); 
		SetMenuTitle(menu2, options);
		
		Format(options, sizeof(options), "%i_%i_1_0_%i", target_1, client, zoneJuge); // le dernier 0 signifie que c'est la premiere personne
		AddMenuItem(menu2, options, "Oui!");
		
		Format(options, sizeof(options), "%i_%i_0_0_%i", target_1, client, zoneJuge);
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
		char options[64], optionsBuff[5][64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, "_", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
		
		int fiance = StringToInt(optionsBuff[0]);
		int juge = StringToInt(optionsBuff[1]);
		int reponse = StringToInt(optionsBuff[2]);
		int flag = StringToInt(optionsBuff[3]); // Pour savoir si c'est la premiere ou la seconde personne a qui on demande
		int zoneJuge = StringToInt(optionsBuff[4]);
		
		if( !reponse ) {
		// Message à toute la salle
			PrintToChatZone(zoneJuge, "{lightblue}[TSX-RP]{default} %N répond: NON, %N fond en pleurs... Stupéfaction dans la salle .", client, fiance);
			CloseHandle(menu);
		}
		else if( !flag ) { // Le premier a dit oui, on ouvre le même menu au second
			
			// Messages à toute la salle
			PrintToChatZone(zoneJuge, "{lightblue}[TSX-RP]{default} %N répond: OUI, les invités et %N sourient .", client, fiance);
			PrintToChatZone(zoneJuge, "{lightblue}[TSX-RP]{default} Le juge %N s'exclame: %N, voulez-vous prendre pour époux %N et l'aimer jusqu'à que la mort vous sépare?", juge, fiance, client);
			
			// Setup menu
			Handle menu2 = CreateMenu(eventMariage_3);
			
			Format(options, sizeof(options), "Voulez-vous prendre %N pour épouse et l'aimer jusqu'à ce que la mort vous sépare(2000$)", client);
			SetMenuTitle(menu2, options);
			
			Format(options, sizeof(options), "%i_%i_1_1_%i", client, juge, zoneJuge);
			AddMenuItem(menu2, options, "Oui!");
			
			Format(options, sizeof(options), "%i_%i_0_1_%i", client, juge, zoneJuge);
			AddMenuItem(menu2, options, "Non...");
			
			SetMenuExitButton(menu2, false);
			DisplayMenu(menu2, fiance, MENU_TIME_DURATION);
		}
		else{ // Les deux sont d'accord, on les marie
			Marier(client, fiance, juge, zoneJuge);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action Marier(int epoux, int epouse, int juge, int zoneJuge){
	
	int prix = 4000;

	if( (rp_GetClientInt(epoux, i_Bank)+rp_GetClientInt(epoux, i_Money)) < (prix/2) || (rp_GetClientInt(epouse, i_Bank)+rp_GetClientInt(epouse, i_Money)) < (prix/2) ) {
		PrintToChatZone(zoneJuge, "{lightblue}[TSX-RP]{default} L'un des mariés est en fait un SDF refoulé et n'a pas assez d'argent pour s'aquitter des frais du mariage, Vous pouvez huer les pauvres !");
		return Plugin_Handled;
	}
	
	PrintToChatZone(zoneJuge, "{lightblue}[TSX-RP]{default} %N répond: OUI !", epoux);
	PrintToChatZone(zoneJuge, "{lightblue}[TSX-RP]{default} %N et %N sont maintenant unis par les liens du mariage, vous pouvez féliciter les mariés !", epoux, epouse);
	
	CPrintToChat(epoux, "{lightblue}[TSX-RP]{default} Vous et %N êtes unis par les liens du mariage, vous pouvez embrasser la mariée félicitations !", epouse);
	CPrintToChat(epouse, "{lightblue}[TSX-RP]{default} Vous et %N êtes unis par les liens du mariage, félicitations !", epoux);
	
	// On paye le gentil juge et on preleve aux heureux élus
	rp_SetClientInt(epoux, i_Money, rp_GetClientInt(epoux, i_Money) - (prix / 2));
	rp_SetClientInt(epouse, i_Money, rp_GetClientInt(epouse, i_Money) - (prix / 2));
	rp_SetClientInt(juge, i_AddToPay, rp_GetClientInt(juge, i_AddToPay) + (prix / 4));
	rp_SetJobCapital(101, ( rp_GetJobCapital(101) + (prix/4)*3 ) );
	
	rp_SetClientInt(epoux, i_MarriedTo, epouse);
	rp_SetClientInt(epouse, i_MarriedTo, epoux);
	
	ShareKeyAppart(epoux, epouse);
	ShareKeyCar(epoux, epouse);
	
	rp_HookEvent(epoux, RP_OnFrameSeconde, fwdFrame);
	rp_HookEvent(epouse, RP_OnFrameSeconde, fwdFrame);
	
	return Plugin_Handled;
}

public Action fwdFrame(int client) {
	int target = rp_GetClientInt(client, i_MarriedTo);
	
	// Si les amoureux sont proches, regen et affiche un beamring rose autours d'eux
	bool areNear = rp_IsEntitiesNear(client, target, true);
	if( areNear ){
		if(Math_GetRandomInt(0, 10) == 6){
			ShareKeyAppart(client, target);
			ShareKeyCar(client, target);
		}
		
		float vecTarget[3];
		GetClientAbsOrigin(client, vecTarget);
		TE_SetupBeamRingPoint(vecTarget, 10.0, 100.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {255, 92, 205, 100}, 10, 0);
		TE_SendToAll();
		
		if( GetClientHealth(client) < 500 ) {
			SetEntityHealth(client, GetClientHealth(client)+5);
		}
	}
	
	if( target > 0  && !areNear)
		rp_Effect_BeamBox(client, target, NULL_VECTOR, 255, 92, 205); // Crée un laser / laser cube rose sur le/la marié(e)
}

public void ShareKeyAppart(int epoux, int epouse){
	// Cherche les apparts dont les mariés sont proprio et les partagent
	for (int i = 1; i < 200; i++) {
		int proprio = rp_GetAppartementInt(i, appart_proprio);
		
		if( proprio == epoux && !rp_GetClientKeyAppartement(epouse, i) ){
			rp_SetClientInt(epouse, i_AppartCount, rp_GetClientInt(epouse, i_AppartCount) + 1);
			rp_SetClientKeyAppartement(epouse, i, true);
		}
		if( proprio == epouse && !rp_GetClientKeyAppartement(epoux, i) ){
			rp_SetClientInt(epoux, i_AppartCount, rp_GetClientInt(epoux, i_AppartCount) + 1);
			rp_SetClientKeyAppartement(epoux, i, true);
		}
	}
}

public void ShareKeyCar(int epoux, int epouse){
	// Cherche les vehicules dont les mariés sont proprio et les partagent
	for (int i = MaxClients +1 ; i <= 2048; i++) {
		if( !rp_IsValidVehicle(i) )
			continue;
			
		int proprio = rp_GetVehicleInt(i, car_owner);
		
		if( proprio == epoux && !rp_GetClientKeyVehicle(epouse, i) ){
			rp_SetClientKeyVehicle(epouse, i, true);
		}
		if( proprio == epouse && !rp_GetClientKeyVehicle(epoux, i)){
			rp_SetClientKeyVehicle(epoux, i, true);
		}
	}
}
