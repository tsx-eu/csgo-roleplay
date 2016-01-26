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
Handle g_vAllTalk;
bool g_bAllTalk = false;

public Plugin myinfo = {
	name = "Utils: VoiceProximity", author = "KoSSoLaX",
	description = "RolePlay - Utils: VoiceProximity",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
	RegConsoleCmd("sm_job", Cmd_job, "Ouvre la liste des jobs");
	g_vAllTalk = CreateConVar("rp_alltalk", "0", "alltalk en zone event", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_vAllTalk, OnCvarChange);
}
public void OnCvarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	
	if( cvar == g_vAllTalk ) {
		if( StrEqual(newVal, "1") )
			g_bAllTalk = true;
		else 
			g_bAllTalk = false;
	}
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerHear, fwdHear);
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	#if defined DEBUG
	PrintToServer("fwdCommand");
	#endif
	if( StrEqual(command, "me") || StrEqual(command, "annonce") ) {
		
		if( !rp_GetClientBool(client, b_IsNoPyj) ) {
			ACCESS_DENIED(client);
		}
		if( BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteGlobal) ) {
			PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat global.");
			return Plugin_Handled;
		}
		if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
			if( !rp_GetClientBool(client, b_MaySteal) ) {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez attendre encore quelques secondes, avant d'utiliser à nouveau le chat annonce.");
					return Plugin_Handled;
			}
			
			rp_SetClientBool(client, b_MaySteal, false);
			CreateTimer(10.0, AllowStealing, client);
		}
		
		if( !rp_GetClientBool(client, b_Crayon)) {
			CRemoveTags(arg, strlen(arg)+1);
		}
		
		CPrintToChatAll("{lightblue}%N{default} ({olive}ANNONCE{default}): %s", client, arg);
		LogToGame("[TSX-RP] [ANNONCES] %L: %s", client, arg);

		return Plugin_Handled;
	}
	else if( StrEqual(command, "c") || StrEqual(command, "coloc") || StrEqual(command, "colloc") ) {
		if( rp_GetClientInt(client, i_AppartCount) == 0 ) {
			ACCESS_DENIED(client);
		}
		if( BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteLocal) ) {
			PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat local.");
			return Plugin_Handled;
		}
		
		for (int i = 1; i < 200; i++) {
			if( !rp_GetClientKeyAppartement(client, i) )
				continue;
			
			for(int j=1; j<=MaxClients; j++) {
				if( !IsValidClient(j) )
					continue;
				if( !rp_GetClientKeyAppartement(j, i) )
					continue;
					
				CPrintToChatEx(j, client, "{lightblue}%N{default} ({purple}COLOC{default}): %s", client, arg);
			}
		}
		return Plugin_Handled;
	}
	else if( StrEqual(command, "t") || StrEqual(command, "team") ) {
		
		if( rp_GetClientJobID(client) == 0 ) {
			ACCESS_DENIED(client);
		}

		if( BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteLocal) ) {
			PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat local.");
			return Plugin_Handled;
		}

		int j = rp_GetClientJobID(client);
		if( j == 101 )
			j = 1;

		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;

			int j2 = rp_GetClientJobID(i);
			if( j2 == 101 )
				j2 = 1;

			if( j == j2 ) {
				CPrintToChatEx(i, client, "{lightblue}%N{default} ({orange}TEAM{default}): %s", client, arg);
			}
		}

		return Plugin_Handled;
	}
	else if( StrEqual(command, "m") || StrEqual(command, "marie") ) {
		
		int mari = rp_GetClientInt(client, i_MarriedTo);
		if( mari == 0 ) {
			ACCESS_DENIED(client);
		}
		
		CPrintToChatEx(mari, client, "{lightblue}%N{default} ({red}MARIÉ{default}): %s", client, arg);
		CPrintToChatEx(client, client, "{lightblue}%N{default} ({red}MARIÉ{default}): %s", client, arg);
		

		return Plugin_Handled;
	}
	else if( StrEqual(command, "g") || StrEqual(command, "group") ) {
		if( rp_GetClientGroupID(client) == 0 ) {
			ACCESS_DENIED(client);
		}

		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;

			if( rp_GetClientGroupID(i) == rp_GetClientGroupID(client) ) {
				CPrintToChatEx(i, client, "{lightblue}%N{default} ({red}GROUP{default}): %s", client, arg);
			}
		}

		return Plugin_Handled;
	}
	else if( StrEqual(command, "stopsound") ) {
		ClientCommand(client, "stopsound");
		FakeClientCommand(client, "stopsound");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action fwdHear(int client, int target, float& dist) {
	
	int Czone = rp_GetPlayerZone(client), Ctype = rp_GetZoneInt(Czone, zone_type_type);
	int Tzone = rp_GetPlayerZone(target), Ttype = rp_GetZoneInt(Tzone, zone_type_type), Tbit = rp_GetZoneBit(Tzone);
	
	if( IsValidClient(target) ) {
		if( rp_GetClientBool(target, b_IsMuteVocal) )
			return Plugin_Stop;
	}
	else if( rp_IsValidVehicle(target) ) {
		if( rp_GetClientBool(Vehicle_GetDriver(target), b_IsMuteVocal) )
			return Plugin_Stop;
	}
	
	if( g_bAllTalk && Tbit & BITZONE_EVENT && Czone == Tzone ) {
		dist = 1.0;
		return Plugin_Continue;
	}
	if( (Tbit & BITZONE_JAIL || Tbit & BITZONE_HAUTESECU) ) {
		return Plugin_Stop;
	}
	
	if( Ctype != Ttype && (Ctype==0||Ttype==0) ) {
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs){
	if((strcmp(sArgs, "thetime", false) == 0) || (strcmp(sArgs, "timeleft", false) == 0) || (strcmp(sArgs, "/ff", false) == 0) || (strcmp(sArgs, "ff", false) == 0) || (strcmp(sArgs, "currentmap", false) == 0) || (strcmp(sArgs, "nextmap", false) == 0)){
		if( rp_GetClientBool(client, b_IsMuteGlobal) ) {
			PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat.");
			return Plugin_Stop;
		}
		if( !rp_GetClientBool(client, b_MaySteal) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez attendre encore quelques secondes.");
			return Plugin_Stop;
		}
		rp_SetClientBool(client, b_MaySteal, false);
		CreateTimer(10.0, AllowStealing, client);
	}
	return Plugin_Continue;
}
public Action AllowStealing(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowStealing");
	#endif
	rp_SetClientBool(client, b_MaySteal, true);
}

public Action Cmd_job(int client, int args){
	Handle jobmenu = CreateMenu(MenuJobs);
	SetMenuTitle(jobmenu, "Liste des jobs disponibles:");
	AddMenuItem(jobmenu, "-1", "Tout afficher");
	AddMenuItem(jobmenu, "-2", "Avocats");
	char tmp[12], tmp2[64];
	bool bJob[MAX_JOBS];

	for(int i = 1; i <= MaxClients; i++) {

		if( !IsValidClient(i) )
			continue;
		if( !IsClientConnected(i) )
			continue;
		if( rp_GetClientInt(i, i_Job) == 0 )
			continue;
		if( i == client )
			continue;

		int job = rp_GetClientJobID(i);

		if( job == 1 )
			continue;

		bJob[job] = true;
	}


	for(int i=1; i<MAX_JOBS; i++) {
		if( bJob[i] == false )
			continue;
		Format(tmp, sizeof(tmp), "%d", i);
		rp_GetJobData(i, job_type_name, tmp2, sizeof(tmp2));

		AddMenuItem(jobmenu, tmp, tmp2);
	}

	SetMenuExitButton(jobmenu, true);
	DisplayMenu(jobmenu, client, 60);
	return Plugin_Handled;
}

public int MenuJobs(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	if (p_oAction == MenuAction_Select) {
		char szMenuItem[8];
		if (GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem))){
			Handle menu = CreateMenu(MenuJobs2);
			SetMenuTitle(menu, "Liste des employés connectés:");
			int jobid = StringToInt(szMenuItem);
			int amount = 0;
			char tmp[128], tmp2[128];

			for(int i=1; i<MAXPLAYERS+1;i++){
				if(!IsValidClient(i))
					continue;

				if(jobid == -2 && rp_GetClientInt(i, i_Avocat) <= 0)
					continue;

				if(jobid >= 0 && (i == client || rp_GetClientJobID(i) != jobid))
					continue;

				Format(tmp2, sizeof(tmp2), "%i", i);
				int ijob = rp_GetClientJobID(i)== 1 && GetClientTeam(i) == 2 ? 0 : rp_GetClientInt(i, i_Job);
				rp_GetJobData(ijob, job_type_name, tmp, sizeof(tmp));

				if(rp_GetClientBool(i, b_IsAFK))
					Format(tmp, sizeof(tmp), "[AFK] %N - %s", i, tmp);
				else if(rp_GetClientInt(i, i_JailTime) > 0)
					Format(tmp, sizeof(tmp), "[JAIL] %N - %s", i, tmp);
				else if(rp_GetZoneBit(rp_GetPlayerZone(i)) & BITZONE_EVENT)
					Format(tmp, sizeof(tmp), "[EVENT] %N - %s", i, tmp);
				else
					Format(tmp, sizeof(tmp), "%N - %s", i, tmp);

				if(jobid == -2){
					Format(tmp, sizeof(tmp), "%s (%d$)", tmp, rp_GetClientInt(i, i_Avocat));
				}

					
				AddMenuItem(menu, tmp2, tmp);
				amount++;
			}

			if( amount == 0 ) {
				CloseHandle(menu);
			}
			else {
				SetMenuExitButton(menu, true);
				DisplayMenu(menu, client, 60);
			}
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}

public int MenuJobs2(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	if (p_oAction == MenuAction_Select) {
		char szMenuItem[8];
		if (GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem))){
			Handle menu = CreateMenu(MenuJobs3);
			SetMenuTitle(menu, "Que voulez vous lui demander:");
			int target = StringToInt(szMenuItem);
			int jobid = rp_GetClientJobID(target);
			int amount = 0;
			char tmp[128], tmp2[128];

			if(rp_GetClientInt(target, i_Job)%10 == 1 || rp_GetClientInt(target, i_Job)%10 == 2 && jobid !=1 && jobid != 101){
				Format(tmp2, sizeof(tmp2), "%i_-1", target);
				AddMenuItem(menu, tmp2, "Demander à être recruté");
				amount++;
			}
			if(jobid == 91){
				Format(tmp2, sizeof(tmp2), "%i_-2", target);
				AddMenuItem(menu, tmp2, "Demander pour un crochetage de porte");
				amount++;
			}
			if(jobid == 181){
				Format(tmp2, sizeof(tmp2), "%i_-3", target);
				AddMenuItem(menu, tmp2, "Acheter / Vendre une arme");
				amount++;
			}
			if(rp_GetClientInt(target, i_Avocat) > 0){
				Format(tmp2, sizeof(tmp2), "%i_-5", target);
				AddMenuItem(menu, tmp2, "Demander ses services d'avocat");
				amount++;
			}
			if(jobid == 101 && !(jobid == 103 || jobid == 104 || jobid == 105 || jobid == 106)){
				Format(tmp2, sizeof(tmp2), "%i_-4", target);
				AddMenuItem(menu, tmp2, "Demander pour une audience");
				amount++;
			}
			if(jobid == 61){
				Format(tmp2, sizeof(tmp2), "%i_-6", target);
				AddMenuItem(menu, tmp2, "Demander un Appartement");
				amount++;
			}
			else{
				for(int i=1;i<MAX_ITEMS;i++){
					rp_GetItemData(i, item_type_job_id, tmp, sizeof(tmp));
					if(StringToInt(tmp) != jobid || StringToInt(tmp)==0)
						continue;

					rp_GetItemData(i, item_type_name, tmp, sizeof(tmp));
					Format(tmp2, sizeof(tmp2), "%i_%i", target, i);
					AddMenuItem(menu, tmp2, tmp);
					amount++;
				}
			}

			if( amount == 0 ) {
				CloseHandle(menu);
			}
			else {
				SetMenuExitButton(menu, true);
				DisplayMenu(menu, client, 60);
			}
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}

public int MenuJobs3(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	if (p_oAction == MenuAction_Select) {
		char szMenuItem[16];
		if (GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem))){
			if(!rp_GetClientBool(client, b_MaySteal)){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez attendre encore quelques instants avant d'envoyer une demande");
				return;
			}
			rp_SetClientBool(client, b_MaySteal, false);
			CreateTimer(10.0, AllowStealing, client);
			char data[2][32], tmp[128];
			ExplodeString(szMenuItem, "_", data, sizeof(data), sizeof(data[]));
			int target = StringToInt(data[0]);
			int item_id = StringToInt(data[1]);
			char zoneName[64];
			rp_GetZoneData(rp_GetPlayerZone(client), zone_type_name, zoneName, sizeof(zoneName));
			switch(item_id){
				case -1: CPrintToChat(target, "{lightblue}[TSX-RP]{default} Le joueur %N aimerait être recruté, il est actuellement: %s", client, zoneName);
				case -2: CPrintToChat(target, "{lightblue}[TSX-RP]{default} Le joueur %N a besoin d'un crochetage de porte, il est actuellement: %s", client, zoneName);
				case -3: CPrintToChat(target, "{lightblue}[TSX-RP]{default} Le joueur %N aimerait acheter ou vendre une arme, il est actuellement: %s", client, zoneName);
				case -4: CPrintToChat(target, "{lightblue}[TSX-RP]{default} Le joueur %N a besoin d'un juge, il est actuellement: %s", client, zoneName);
				case -5: CPrintToChat(target, "{lightblue}[TSX-RP]{default} Le joueur %N a besoin d'un avocat, il est actuellement: %s", client, zoneName);
				case -6: CPrintToChat(target, "{lightblue}[TSX-RP]{default} Le joueur %N souhaiterait acheter un appartement, merci de le contacter pour plus de renseignement. Il est actuellement: %s", client, zoneName);
				default:{
					rp_GetItemData(item_id, item_type_name, tmp, sizeof(tmp));
					CPrintToChat(target, "{lightblue}[TSX-RP]{default} Le joueur %N a besoin de {lime}%s{default}, il est actuellement: %s", client, tmp, zoneName);
				}
			}
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} La demande à été envoyée à la personne");
			ClientCommand(target, "play buttons/blip1.wav");
			rp_Effect_BeamBox(target, client, NULL_VECTOR, 122, 122, 0);
			Handle dp;
			CreateDataTimer(1.0, ClientTargetTracer, dp, TIMER_REPEAT);
			WritePackCell(dp, client);
			WritePackCell(dp, target);
			WritePackCell(dp, GetTime());
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}

public Action ClientTargetTracer(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	int starttime = ReadPackCell(dp);
	if(!IsValidClient(client) || !IsValidClient(target)){
		CloseHandle(dp);
		return Plugin_Stop;
	}
	
	rp_Effect_BeamBox(target, client, NULL_VECTOR, 122, 122, 0);

	if(starttime + 5 < GetTime()){
		CloseHandle(dp);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
