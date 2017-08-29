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

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

public Plugin myinfo = {
	name = "Utils: Wedding", author = "Medzila/KoSSoLaX",
	description = "RolePlay - Utils: Wedding",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_SetClientInt(client, i_MarriedTo, 0);
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	
	char steamid[32], query[512];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	Format(query, sizeof(query), "SELECT `steamid` FROM `rp_wedding` WHERE `steamid2`='%s' AND `time`>=UNIX_TIMESTAMP() UNION SELECT `steamid2` FROM `rp_wedding` WHERE `steamid`='%s' AND `time`>=UNIX_TIMESTAMP();", steamid, steamid);
	
	SQL_TQuery(rp_GetDatabase(), SQL_CheckWedding, query, client);
}
public void SQL_CheckWedding(Handle owner, Handle handle, const char[] error, any client) {
	char steamid[32], target[32];
	if( SQL_FetchRow(handle) ) {
		SQL_FetchString(handle, 0, steamid, sizeof(steamid));
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) || i == client )
				continue;
			
			GetClientAuthId(i, AuthId_Engine, target, sizeof(target));
			
			if( StrEqual(steamid, target) && rp_GetClientInt(i, i_MarriedTo) == 0 ) {
				CPrintToChat(i, "{lightblue}[TSX-RP]{default} Votre conjoint %N a rejoint la ville.", client);
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre conjoint %N a rejoint la ville.", i);
				
				rp_SetClientInt(i, i_MarriedTo, client);
				rp_SetClientInt(client, i_MarriedTo, i);
				
				rp_HookEvent(client, RP_OnFrameSeconde, fwdFrame);
				rp_HookEvent(i, RP_OnFrameSeconde, fwdFrame);
				
				break;
			}
		}
	}
}
public void OnClientDisconnect(int client) {
	// Un mariage est terminé si un des deux mariés déco
	int mari = rp_GetClientInt(client, i_MarriedTo);
	if( mari > 0 ) {
		CPrintToChat(mari, "{lightblue}[TSX-RP]{default} Votre conjoint a quitté la ville précipitamment.");
		rp_UnhookEvent(mari, RP_OnFrameSeconde, fwdFrame);
		rp_SetClientInt(mari, i_MarriedTo, 0);
		rp_SetClientInt(client, i_MarriedTo, 0);
	}
}
// ----------------------------------------------------------------------------
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "mariage") ) {
		return Cmd_Mariage(client);
	}
	
	return Plugin_Continue;
}
public Action Cmd_Mariage(int client) {
	
	if( rp_GetClientJobID(client) != 101 ) { // Au dessus de HJ1 seulement
		ACCESS_DENIED(client);
	}
	
	int zoneJuge = rp_GetPlayerZone(client);
	
	if( rp_GetZoneInt( zoneJuge, zone_type_type) != 101 ) { // N'ouvre pas le menu en dehors du tribu
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cette commande ne peut être utilisée qu'au tribunal.");
		ACCESS_DENIED(client);
	}
	
	Menu menu = Menu_Main();
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
void Marier(int juge, int epoux, int epouse) {
	
	int pos_1 = rp_GetPlayerZone(juge);
	int prix = 10000;

	if( (rp_GetClientInt(epoux, i_Bank)+rp_GetClientInt(epoux, i_Money)) < (prix/2) || (rp_GetClientInt(epouse, i_Bank)+rp_GetClientInt(epouse, i_Money)) < (prix/2) ) {
		PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} L'un des mariés est en fait un SDF refoulé et n'a pas assez d'argent pour s'acquitter des frais du mariage, vous pouvez huer les pauvres !");
		return;
	}
	
	PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} %N répond: OUI !", epouse);
	PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} %N et %N sont maintenant unis par les liens du mariage, vous pouvez féliciter les mariés !", epoux, epouse);
	
	CPrintToChat(epoux, "{lightblue}[TSX-RP]{default} Vous et %N êtes unis par les liens du mariage, vous pouvez embrasser la mariée félicitation !", epouse);
	CPrintToChat(epouse, "{lightblue}[TSX-RP]{default} Vous et %N êtes unis par les liens du mariage, félicitations !", epoux);
	
	// On paye le gentil juge et on preleve aux heureux élus
	rp_ClientMoney(epoux, i_Money, -(prix / 2));
	rp_ClientMoney(epouse, i_Money, -(prix / 2));
	rp_ClientMoney(juge, i_AddToPay, prix / 2);
	rp_SetJobCapital(101, rp_GetJobCapital(101) + (prix/2) );
	
	rp_SetClientInt(epoux, i_MarriedTo, epouse);
	rp_SetClientInt(epouse, i_MarriedTo, epoux);
	
	ShareKey(epoux, epoux);
	ShareKey(epouse, epoux);
	
	rp_HookEvent(epoux, RP_OnFrameSeconde, fwdFrame);
	rp_HookEvent(epouse, RP_OnFrameSeconde, fwdFrame);
	
	char query[512], szClient[32], szTarget[32];
	GetClientAuthId(epoux, AuthId_Engine, szClient, sizeof(szClient));
	GetClientAuthId(epouse, AuthId_Engine, szTarget, sizeof(szTarget));
	Format(query, sizeof(query), "INSERT INTO `rp_wedding` (`steamid`, `steamid2`, `time`) VALUES ('%s', '%s', '%d');", szClient, szTarget, GetTime()+(7*24*60*60));
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
	
	return;
}
void ShareKey(int client, int target) {
	// Cherche les apparts dont les mariés sont proprio et les partagent
	for (int i = 1; i < 200; i++) {
		int proprio = rp_GetAppartementInt(i, appart_proprio);
		
		if( proprio == client && !rp_GetClientKeyAppartement(target, i) ) {
			rp_SetClientInt(target, i_AppartCount, rp_GetClientInt(target, i_AppartCount) + 1);
			rp_SetClientKeyAppartement(target, i, true);
		}
	}
	// Cherche les vehicules dont les mariés sont proprio et les partagent
	for (int i = MaxClients +1 ; i <= 2048; i++) {
		if( !rp_IsValidVehicle(i) )
			continue;
			
		int proprio = rp_GetVehicleInt(i, car_owner);
		
		if( proprio == client && !rp_GetClientKeyVehicle(target, i) ) {
			rp_SetClientKeyVehicle(target, i, true);
		}
	}
}
// ----------------------------------------------------------------------------
public Action fwdFrame(int client) {
	int target = rp_GetClientInt(client, i_MarriedTo);
	
	// Si les amoureux sont proches, regen et affiche un beamring rose autours d'eux
	bool areNear = rp_IsEntitiesNear(client, target, true);
	if( areNear ) {
		if( Math_GetRandomInt(0, 10) == 2 ) {
			ShareKey(client, target);
		}
		
		ServerCommand("sm_effect_particles %d trail_heart 3", client);		
		
		if( GetClientHealth(client) < 500 ) {
			SetEntityHealth(client, GetClientHealth(client)+5);
		}
	}
	
	if( target > 0  && !areNear)
		rp_Effect_BeamBox(client, target, NULL_VECTOR, 255, 92, 205); // Crée un laser / laser cube rose sur le/la marié(e)
}
// ----------------------------------------------------------------------------
Menu Menu_Main() {
	Menu subMenu = new Menu(eventMariage);
	subMenu.SetTitle("Tribunal de Princeton - Mariage\n ");
	subMenu.AddItem("0", "Marier des joueurs");
	subMenu.AddItem("1", "Prolonger un mariage");
	subMenu.AddItem("2", "Faire divorcer des joueurs");
	subMenu.AddItem("3", "Voir la durée d'un contrat de mariage");
	
	return subMenu;
}
// ----------------------------------------------------------------------------
Menu Menu_Mariage(int& client, int a, int b, int c, int d, int e, int f) {
	int zone = rp_GetPlayerZone(client);
	char tmp[64], tmp2[64], query[512];
	
	Menu subMenu = null;
	if( b == 0 ) {
		
		subMenu = new Menu(eventMariage);
		subMenu.SetTitle("Qui voulez-vous marier ?\n ");
		
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) || i == client || rp_GetPlayerZone(i) != zone )
				continue;
			if( rp_GetClientInt(i, i_MarriedTo) > 0 )
				continue;
	
			Format(tmp, sizeof(tmp), "0 %d %d", client, i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( c == 0 ) {
		subMenu = new Menu(eventMariage);
		subMenu.SetTitle("À qui voulez-vous marier %N?\n ", b);
		
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) || i == client || b == i || rp_GetPlayerZone(i) != zone )
				continue;
			if( rp_GetClientInt(i, i_MarriedTo) > 0 )
				continue;
	
			Format(tmp, sizeof(tmp), "0 %d %d %d", a, b, i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( d == 0 ) {
		
		GetClientAuthId(b, AuthId_Engine, tmp, sizeof(tmp));
		GetClientAuthId(c, AuthId_Engine, tmp2, sizeof(tmp2));
		
		DataPack dp = new DataPack();
		dp.WriteCell(a);
		dp.WriteCell(b);
		dp.WriteCell(c);		
		
		Format(query, sizeof(query), "SELECT `steamid` FROM `rp_wedding` WHERE (`steamid`='%s' OR `steamid2`='%s') AND `time`>=UNIX_TIMESTAMP() UNION SELECT `steamid2` FROM `rp_wedding` WHERE (`steamid`='%s' OR `steamid2`='%s') AND `time`>=UNIX_TIMESTAMP();", tmp, tmp, tmp2, tmp2);
		SQL_TQuery(rp_GetDatabase(), SQL_CheckWedding2, query, dp);
	}
	else if( d > 0 ) {
		if( d >= 2 ) {
			CPrintToChat(a, "{lightblue}[TSX-RP]{default} Vous essayez d'unir quelqu'un déjà marié, le mariage ne peut pas se dérouler.");
		}
		else {
			int pos_1 = rp_GetPlayerZone(a);
			int pos_2 = rp_GetPlayerZone(b);
			int pos_3 = rp_GetPlayerZone(c);
			int err = 0;
			
			// Messages d'erreurs double check
			if( rp_GetZoneInt(pos_1, zone_type_type) != 101 ) {
				CPrintToChat(a, "{lightblue}[TSX-RP]{default} Vous n'êtes pas au tribunal, le mariage ne peut pas se dérouler.");
				err++;
			}
			if( pos_1 != pos_3 || pos_2 != pos_3 ) {
				CPrintToChat(a, "{lightblue}[TSX-RP]{default} Tous les prétendants ne sont pas dans la même salle du tribunal, le mariage ne peut pas se dérouler.");
				err++;
			}
			if( rp_GetClientInt(b, i_MarriedTo) > 0 || rp_GetClientInt(c, i_MarriedTo) > 0 ) {
				CPrintToChat(a, "{lightblue}[TSX-RP]{default} Vous essayez d'unir quelqu'un déjà marié, le mariage ne peut pas se dérouler.");
				err++;
			}
			
			if( err == 0 ) {
				PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} Le juge %N s'exclame: %N, voulez-vous prendre pour époux %N et l'aimer jusqu'à ce que la mort vous sépare?", a, b, c);
				
				subMenu = new Menu(eventMariage);
				
				Format(query, sizeof(query), "Voulez-vous prendre %N pour époux\n et l'aimer jusqu'à ce que la mort vous sépare ?\nLe contrat de mariage dure 7 jours et coûte 5.000$.\n ", c); 
				subMenu.SetTitle(query);
				
				Format(tmp, sizeof(tmp), "0 %d %d %d -1 1", a, b, c); subMenu.AddItem(tmp, "Oui!");
				Format(tmp, sizeof(tmp), "0 %d %d %d -1 2", a, b, c); subMenu.AddItem(tmp, "Non...");
				subMenu.ExitButton = false;
				client = b;
			}
		}
	}
	else if( e > 0 ) {
		int pos_1 = rp_GetPlayerZone(a);
		
		if( e == 2 ) {
			PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} %N répond: NON, %N fond en larmes... Stupéfaction dans la salle .", b, c);
		}
		else {			
			// Messages à toute la salle
			PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} %N répond: OUI, les invités et %N sourient .", b, c);
			PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} Le juge %N s'exclame: %N, voulez-vous prendre pour épouse %N et l'aimer jusqu'à que la mort vous sépare?", a, c, b);
			
			subMenu = new Menu(eventMariage);
			
			Format(query, sizeof(query), "Voulez-vous prendre %N pour épouse\n et l'aimer jusqu'à ce que la mort vous sépare?\nLe contrat de mariage dure 7 jours et coûte 5.000$.\n ", c);
			subMenu.SetTitle(query);
			
			Format(tmp, sizeof(tmp), "0 %d %d %d -1 -1 1", a, b, c); subMenu.AddItem(tmp, "Oui!");
			Format(tmp, sizeof(tmp), "0 %d %d %d -1 -1 2", a, b, c); subMenu.AddItem(tmp, "Non...");
			subMenu.ExitButton = false;
			client = c;
		}
	}
	else if( f > 0 ) {
		
		int pos_1 = rp_GetPlayerZone(a);
		
		if( e == 2 ) {
			PrintToChatZone(pos_1, "{lightblue}[TSX-RP]{default} %N répond: NON, %N fond en larmes... Stupéfaction dans la salle .", c, b);
		}
		else {
			
			int pos_2 = rp_GetPlayerZone(b);
			int pos_3 = rp_GetPlayerZone(c);
			int err = 0;
			
			// Messages d'erreurs double check
			if( rp_GetZoneInt(pos_1, zone_type_type) != 101 ) {
				CPrintToChat(a, "{lightblue}[TSX-RP]{default} Vous n'êtes pas au tribunal, le mariage ne peut pas se dérouler.");
				err++;
			}
			if( pos_1 != pos_3 || pos_2 != pos_3 ) {
				CPrintToChat(a, "{lightblue}[TSX-RP]{default} Tous les prétendant ne sont pas dans la même salle du tribunal, le mariage ne peut pas se dérouler.");
				err++;
			}
			if( err == 0 )
				Marier(a, b, c);
		}
	}
	
	return subMenu;
}
public void SQL_CheckWedding2(Handle owner, Handle handle, const char[] error, any data) {
	DataPack dp = view_as<DataPack>(data);
	dp.Reset();
	int a = dp.ReadCell();
	int b = dp.ReadCell();
	int c = dp.ReadCell();
	delete dp;
	
	Menu subMenu = Menu_Mariage(a, a, b, c, SQL_GetRowCount(handle) + 1, 0, 0);
	subMenu.Display(a, MENU_TIME_FOREVER);
}
// ----------------------------------------------------------------------------
Menu Menu_Prolonge(int& client, int a, int b, int c, int d, int e) {
	int zone = rp_GetPlayerZone(client);
	char tmp[64], tmp2[64], query[512];
	
	Menu subMenu = null;
	
	if( rp_GetZoneInt(zone, zone_type_type) != 101 )
		return null;
	
	if( b == 0 ) {
		subMenu = new Menu(eventMariage);
		subMenu.SetTitle("Qui voulez-vous prolonger le mariage ?\n ");
		int to;
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) || i == client )
				continue;
			
			to = rp_GetClientInt(i, i_MarriedTo);
			
			if( to > 0 && i < to && rp_GetPlayerZone(i) == zone && rp_GetPlayerZone(to) == zone ) {
				Format(tmp, sizeof(tmp), "1 %d %d %d", client, i, to);
				Format(query, sizeof(query), "%N et %N", i, to);
				
				subMenu.AddItem(tmp, query);
				PrintToChatAll("found %N et %N", i, to);
			}
		}
	}
	else if( d == 0 ) {
		subMenu = new Menu(eventMariage);
		subMenu.SetTitle("Souhaitez vous prolonger votre\n mariage avec %N?\n ", c);
		
		Format(tmp, sizeof(tmp), "1 %d %d %d 1", a, b, c); subMenu.AddItem(tmp, "Oui! (1500$)");
		Format(tmp, sizeof(tmp), "1 %d %d %d 2", a, b, c); subMenu.AddItem(tmp, "Non...");
		subMenu.ExitButton = false;
		client = b;
	}
	else if( d > 0 ) {
		if( d == 1 ) {
			subMenu = new Menu(eventMariage);
			subMenu.SetTitle("Souhaitez vous prolonger votre\n mariage avec %N?\n ", b);
			
			Format(tmp, sizeof(tmp), "1 %d %d %d -1 1", a, b, c); subMenu.AddItem(tmp, "Oui! (1500$)");
			Format(tmp, sizeof(tmp), "1 %d %d %d -1 2", a, b, c); subMenu.AddItem(tmp, "Non...");
			subMenu.ExitButton = false;
			client = c;
		}
		else {
			PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} %N ne souhaite pas prolonger son marriage.", b);
		}
	}
	else if( e > 0 ) {
		if( e == 1 ) {
			
			int prix = 3000;

			if( (rp_GetClientInt(b, i_Bank)+rp_GetClientInt(b, i_Money)) < (prix/2) || (rp_GetClientInt(c, i_Bank)+rp_GetClientInt(c, i_Money)) < (prix/2) ) {
				PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} L'un des mariés n'a pas assez d'argent pour prolonger son contrat de mariage.");
				return null;
			}
			
			PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} Le contrat de mariage de %N et %N est prolongé de 7 jours!", b, c);
			
			// On paye le gentil juge et on preleve aux heureux élus
			rp_ClientMoney(b, i_Money, -(prix / 2));
			rp_ClientMoney(c, i_Money, -(prix / 2));
			rp_ClientMoney(a, i_AddToPay, prix / 2);
			rp_SetJobCapital(101, rp_GetJobCapital(101) + (prix/2) );
			
			GetClientAuthId(b, AuthId_Engine, tmp, sizeof(tmp));
			GetClientAuthId(c, AuthId_Engine, tmp2, sizeof(tmp2));			
			Format(query, sizeof(query), "UPDATE `rp_wedding` SET `time`=`time`+(7*24*60*60) WHERE (`steamid`='%s' AND `steamid2`='%s') OR (`steamid`='%s' AND `steamid2`='%s')", tmp, tmp2, tmp2, tmp);
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
		}
		else {
			PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} %N ne souhaite pas prolonger son mariage.", c);
		}
	}
	return subMenu;
}
// ----------------------------------------------------------------------------
Menu Menu_Divorce(int& client, int a, int b, int c) {
	int zone = rp_GetPlayerZone(client);
	char tmp[64], szSteamIDs[512], query[1024];
	
	Menu subMenu = null;
	
	if( rp_GetZoneInt(zone, zone_type_type) != 101 )
		return null;
	
	if( b == 0 ) {
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) || i == client )
				continue;
			if( rp_GetPlayerZone(i) == zone ) {
				GetClientAuthId(i, AuthId_Engine, tmp, sizeof(tmp));
				Format(szSteamIDs, sizeof(szSteamIDs), "%s'%s',", szSteamIDs, tmp);
			}
		}
		
		szSteamIDs[strlen(szSteamIDs) - 1] = 0;
		Format(query, sizeof(query), "SELECT W.`steamid`, U1.`name`, W.`steamid2`, U2.`name` FROM `rp_wedding` W INNER JOIN `rp_users` U1 ON U1.`steamid`=W.`steamid` INNER JOIN `rp_users` U2 ON U2.`steamid`=W.`steamid2` WHERE`time` >= UNIX_TIMESTAMP() AND (W.`steamid` IN (%s) OR W.`steamid` IN (%s))", szSteamIDs, szSteamIDs);
		PrintToConsole(client, query);
		SQL_TQuery(rp_GetDatabase(), SQL_CheckDivorce, query, client);
	}
	else if( c == 0 ) {
		
		subMenu = new Menu(eventMariage);
		subMenu.SetTitle("Souhaitez-vous rompre votre contrat de mariage?\n ");
		
		Format(tmp, sizeof(tmp), "2 %d %d 1", a, b, c); subMenu.AddItem(tmp, "Oui! (10.000$)");
		Format(tmp, sizeof(tmp), "2 %d %d 2", a, b, c); subMenu.AddItem(tmp, "Non...");
		
		client = b;
	}
	else {
		if( c == 1 ) {
			int prix = 10000;

			if( (rp_GetClientInt(b, i_Bank)+rp_GetClientInt(b, i_Money)) < (prix/2) ) {
				PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} %N n'a pas assez d'argent pour prolonger son contrat de mariage.", b);
				return null;
			}
			
			PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} %N a rompu son contrat de mariage!", b);
			
			
			rp_ClientMoney(b, i_Money, -(prix));
			rp_ClientMoney(a, i_AddToPay, prix / 2);
			rp_SetJobCapital(101, rp_GetJobCapital(101) + (prix/2) );
			
			if( rp_GetClientInt(b, i_MarriedTo) > 0 ) {
				CPrintToChat(rp_GetClientInt(b, i_MarriedTo), "{lightblue}[TSX-RP]{default} Votre conjoint a rompu votre contrat de mariage.");
				
				rp_UnhookEvent(rp_GetClientInt(b, i_MarriedTo), RP_OnFrameSeconde, fwdFrame);
				rp_UnhookEvent(b, RP_OnFrameSeconde, fwdFrame);
				
				rp_SetClientInt(rp_GetClientInt(b, i_MarriedTo), i_MarriedTo, 0);
				rp_SetClientInt(b, i_MarriedTo, 0);
			}
			GetClientAuthId(b, AuthId_Engine, tmp, sizeof(tmp));	
			Format(query, sizeof(query), "UPDATE `rp_wedding` SET `time`=UNIX_TIMESTAMP() WHERE (`steamid`='%s' OR `steamid2`='%s') AND `time`>=UNIX_TIMESTAMP()", tmp, tmp);
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
		}
		else {
			PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} %N ne veut pas rompre son contrat de mariage.", b);
		}
	}
	return subMenu;
}
public void SQL_CheckDivorce(Handle owner, Handle handle, const char[] error, any client) {
	char steamid[32], tmp[32], name[64];
	Menu subMenu = new Menu(eventMariage);
	subMenu.SetTitle("Quel couple doit divorcer?\n ");
	
	while( SQL_FetchRow(handle) ) {
		
		for (int i = 0; i <= 1; i++) {
			
			SQL_FetchString(handle, i * 2, steamid, sizeof(steamid));
			SQL_FetchString(handle, i == 0 ? 3 : i, name, sizeof(name));
			
			for (int j = 1; j <= MaxClients; j++) {
				if( !IsValidClient(j) )
					continue;
				
				GetClientAuthId(j, AuthId_Engine, tmp, sizeof(tmp));
				if( StrEqual(steamid, tmp) ) {
					Format(tmp, sizeof(tmp), "2 %d %d", client, j);
					Format(name, sizeof(name), "%N et %s", j, name);
					subMenu.AddItem(tmp, name);
				}
			}
		}
	}
	
	subMenu.Display(client, MENU_TIME_DURATION);
}
// ----------------------------------------------------------------------------
Menu Menu_Duration(int client, int a, int b) {
	int zone = rp_GetPlayerZone(client);
	char tmp[64], szSteamIDs[512], query[1024];
	if( rp_GetZoneInt(zone, zone_type_type) != 101 )
		return null;
	
	if( a == 0 ) {
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) || i == client )
				continue;
			if( rp_GetPlayerZone(i) == zone ) {
				GetClientAuthId(i, AuthId_Engine, tmp, sizeof(tmp));
				Format(szSteamIDs, sizeof(szSteamIDs), "%s'%s',", szSteamIDs, tmp);
			}
		}
			
		szSteamIDs[strlen(szSteamIDs) - 1] = 0;
		Format(query, sizeof(query), "SELECT W.`steamid`, U1.`name`, W.`steamid2`, U2.`name`, W.`time` FROM `rp_wedding` W INNER JOIN `rp_users` U1 ON U1.`steamid`=W.`steamid` INNER JOIN `rp_users` U2 ON U2.`steamid`=W.`steamid2` WHERE`time` >= UNIX_TIMESTAMP() AND (W.`steamid` IN (%s) OR W.`steamid` IN (%s))", szSteamIDs, szSteamIDs);
		SQL_TQuery(rp_GetDatabase(), SQL_CheckStatus, query, client);
	}
	else {
		float j = b / (24.0 * 60.0 * 60.0);
		PrintToChatZone(zone, "{lightblue}[TSX-RP]{default} %N est toujours marié pour une durée de %.1f jour%s.", a, j, j >= 2.0 ? "s" : "");
	}
	
	return null;
}
public void SQL_CheckStatus(Handle owner, Handle handle, const char[] error, any client) {
	int time;
	char steamid[32], tmp[32], name[64];
	Menu subMenu = new Menu(eventMariage);
	subMenu.SetTitle("Les couples dans ce Tribunal\n ");
	
	while( SQL_FetchRow(handle) ) {
		
		for (int i = 0; i <= 1; i++) {
			
			SQL_FetchString(handle, i * 2, steamid, sizeof(steamid));
			SQL_FetchString(handle, i == 0 ? 3 : i, name, sizeof(name));
			time = SQL_FetchInt(handle, 4) - GetTime();
			float k = time / (24.0 * 60.0 * 60.0);
			
			for (int j = 1; j <= MaxClients; j++) {
				if( !IsValidClient(j) )
					continue;
				
				GetClientAuthId(j, AuthId_Engine, tmp, sizeof(tmp));
				if( StrEqual(steamid, tmp) ) {
					Format(tmp, sizeof(tmp), "3 %d %d", j, time);
					Format(name, sizeof(name), "%N et %s - %.1f jour%s", j, name, k, k >= 2.0 ? "s" : "");
					subMenu.AddItem(tmp, name);
				}
			}
		}
	}
	
	subMenu.Display(client, MENU_TIME_DURATION);
}
// ----------------------------------------------------------------------------
public int eventMariage(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		
		char options[128], expl[7][12];
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, " ", expl, sizeof(expl), sizeof(expl[]));
		
		int t = StringToInt(expl[0]);
		int a = StringToInt(expl[1]);
		int b = StringToInt(expl[2]);
		int c = StringToInt(expl[3]);
		int d = StringToInt(expl[4]);
		int e = StringToInt(expl[5]);
		int f = StringToInt(expl[6]);
		
		Menu subMenu;
		
		switch(t) {
			case 0: subMenu = Menu_Mariage(client, a, b, c, d, e, f);
			case 1: subMenu = Menu_Prolonge(client, a, b, c, d, e);
			case 2: subMenu = Menu_Divorce(client, a, b, c);
			case 3: subMenu = Menu_Duration(client, a, b);
			
			default: subMenu = Menu_Main();
		}
		
		if( subMenu )
			subMenu.Display(client, MENU_TIME_FOREVER);
		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
