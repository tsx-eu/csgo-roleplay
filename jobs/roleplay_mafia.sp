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
#define MAX_AREA_DIST 		500
#define STEAL_TIME			30.0
#define ITEM_PIEDBICHE		1
#define ITEM_KITCROCHTAGE	2
#define ITEM_KITEXPLOSIF	3
#define MARCHE_NOIR			view_as<float>({-144.55,520.1,-2119.96})
#define MARCHE_PERCENT		50


// TODO: Repensé le /vol pour fusionner doublon.

public Plugin myinfo = {
	name = "Jobs: Mafia", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Mafia",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iLastDoor[65][3];
int g_iDoorDefine_LOCKER[2049];
float g_flAppartProtection[200];
Handle g_hForward_RP_OnClientStealItem, g_hForward_RP_OnClientWeaponPick, g_hForward_RP_OnMarcheNoireMafia, g_vCapture;
int g_cBeam;
DataPack g_hBuyMenu;
enum IM_Int {
	IM_Owner,
	IM_StealFrom,
	IM_ItemID,
	IM_Prix,
	IM_Max
}
bool doRP_CanClientStealItem(int client, int target) {
	Action a;
	Call_StartForward(g_hForward_RP_OnClientStealItem);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_Finish(a);
	if( a == Plugin_Handled || a == Plugin_Stop )
		return false;
	return true;
}
void doRP_OnClientWeaponPick(int client, int type) {
	Call_StartForward(g_hForward_RP_OnClientWeaponPick);
	Call_PushCell(client);
	Call_PushCell(type);
	Call_Finish();
}
void doRP_RP_OnMarcheNoireMafia(int client, int target, int victim, int itemID, int prix) {
	
	Call_StartForward(g_hForward_RP_OnMarcheNoireMafia);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(victim);
	Call_PushCell(itemID);
	Call_PushCell(prix);
	Call_Finish();
}
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_item_piedbiche", 	Cmd_ItemPiedBiche,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	RegServerCmd("rp_item_picklock", 	Cmd_ItemPickLock,		"RP-ITEM",	FCVAR_UNREGISTERED); 
	RegServerCmd("rp_item_picklock2", 	Cmd_ItemPickLock,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	// Epicier
	RegServerCmd("rp_item_doorDefine",	Cmd_ItemDoorDefine,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_doorprotect", Cmd_ItemDoorProtect,	"RP-ITEM",	FCVAR_UNREGISTERED);
	
	RegServerCmd("rp_GetStoreItem",	Cmd_GetStoreItem,		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	g_hBuyMenu = new DataPack();
	g_hBuyMenu.WriteCell(0);
	DataPackPos pos = g_hBuyMenu.Position;
	g_hBuyMenu.Reset();
	g_hBuyMenu.WriteCell(pos);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_hForward_RP_OnClientStealItem = CreateGlobalForward("RP_CanClientStealItem", ET_Event, Param_Cell, Param_Cell);
	g_hForward_RP_OnClientWeaponPick = CreateGlobalForward("RP_OnClientWeaponPick", ET_Event, Param_Cell, Param_Cell);
	g_hForward_RP_OnMarcheNoireMafia = CreateGlobalForward("RP_OnMarcheNoireMafia", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}
public Action Cmd_GetStoreItem(int args) {
	Cmd_BuyItemMenu(GetCmdArgInt(1), true);
}
public Action Cmd_ItemDoorProtect(int args) {
	int client = GetCmdArgInt(1);
	int vendeur = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	int appartID = rp_GetPlayerZoneAppart(client);
	if( appartID > 0 && rp_GetClientKeyAppartement(client, appartID) ) {
		float time = (appartID == 50 ? 12.0:24.0);
		
		if( g_flAppartProtection[appartID] <= GetGameTime() ) {
			g_flAppartProtection[appartID] = GetGameTime() + (time * 60.0);
		}
		else {
			g_flAppartProtection[appartID] += (time * 60.0);
		}
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} La protection est activée pour %d minutes", RoundFloat((g_flAppartProtection[appartID] - GetGameTime()) / 60.0));
	}
	else {
		float prix = float(rp_GetItemInt(item_id, item_type_prix));
		float reduc = prix / 100.0 * float(rp_GetClientInt(vendeur, i_Reduction));
		float taxe = rp_GetItemFloat(item_id, item_type_taxes);
		
		rp_SetClientInt(vendeur, i_AddToPay, rp_GetClientInt(vendeur, i_AddToPay) - RoundFloat((prix * taxe) - reduc));
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + RoundFloat(prix - reduc));
		rp_SetJobCapital(91, rp_GetJobCapital(91) - RoundFloat(prix * (1.0 - taxe)));
		
		rp_SetClientStat(vendeur, i_MoneyEarned_Sales, rp_GetClientStat(vendeur, i_MoneyEarned_Sales) - RoundFloat((prix * taxe) - reduc));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être dans votre appartement pour acheter cet objet.");
	}
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
public void OnConfigsExecuted() {
	g_vCapture =  FindConVar("rp_capture");
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
	rp_HookEvent(client, RP_OnPlayerSteal,	fwdOnPlayerSteal);
	rp_HookEvent(client, RP_OnPlayerBuild,	fwdOnPlayerBuild);
	rp_SetClientBool(client, b_MaySteal, true);
}
public void OnClientDisconnect(int client) {
	for(int i=0; i<2049; i++){
		if(g_iDoorDefine_LOCKER[i] == client)
			g_iDoorDefine_LOCKER[i] = 0;
	}
}
public Action fwdOnPlayerBuild(int client, float& cooldown){
	if( rp_GetClientJobID(client) != 91 )
		return Plugin_Continue;
	
	if( disapear(client) ) {
		int job = rp_GetClientInt(client, i_Job);
		switch( job ) {
			case 91:	cooldown = 120.0;
			case 92:	cooldown = 120.0;
			case 93:	cooldown = 130.0; // parrain
			case 94:	cooldown = 140.0; // pro
			case 95:	cooldown = 150.0; // mafieux
			case 96:	cooldown = 160.0; // apprenti
			default:	cooldown = 160.0;
		}
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible de se déguiser pour le moment.");
		cooldown = 0.1;
	}
	return Plugin_Stop;
}
public Action fwdOnPlayerSteal(int client, int target, float& cooldown) {
	if( rp_GetClientJobID(client) != 91 )
		return Plugin_Continue;
	static int RandomItem[MAX_ITEMS];
	static char tmp[128], szQuery[1024];
	
	if( rp_GetClientJobID(target) == 91 ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_BLOCKSTEAL ) {
		ACCESS_DENIED(client);
	}
	
	if( rp_GetZoneInt(rp_GetPlayerZone(target), zone_type_type) == 91 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler %N ici.", target);
		return Plugin_Handled;
	}
	
	if( rp_ClientFloodTriggered(client, target, fd_vol) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler %N, pour le moment.", target);
		return Plugin_Handled;
	}
	
	int VOL_MAX, amount, money, job, prix;
	money = rp_GetClientInt(target, i_Money);
	VOL_MAX = (money+rp_GetClientInt(target, i_Bank)) / 200;
	
	if( rp_IsClientNew(target) )
		amount = Math_GetRandomPow(1, VOL_MAX);
	else
		amount = Math_GetRandomInt(1, VOL_MAX);
	
	if( VOL_MAX > 0 && money <= 0 && rp_GetClientInt(client, i_Job) <= 93 && !rp_IsClientNew(target) && doRP_CanClientStealItem(client, target) ) {
		amount = 0;
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			
			if( rp_GetClientItem(target, i) <= 0 )
				continue;
				
			job = rp_GetItemInt(i, item_type_job_id);
			if( job == 0|| job == 91 || job == 101 || job == 181 )
				continue;
			if( job == 51 && !(rp_GetClientItem(target, i) >= 1 && Math_GetRandomInt(0, 1) == 1) ) // TODO: Double vérif voiture
				continue;
			
			RandomItem[amount++] = i;
		}
		
		if( amount == 0  ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'a pas d'argent, ni d'item sur lui.", target);
			cooldown = 1.0;
			return Plugin_Stop;
		}
		
		int i = RandomItem[ Math_GetRandomInt(0, (amount-1)) ];
		prix = rp_GetItemInt(i, item_type_prix) / 2;
		
		rp_ClientGiveItem(target, i, -1);
		
		rp_SetClientInt(client, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolAmount, (prix * MARCHE_PERCENT) / 100);
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVol, client);		
		rp_SetClientFloat(target, fl_LastVente, GetGameTime() + 10.0);
		
		rp_GetItemData(i, item_type_name, tmp, sizeof(tmp));
		
		addBuyMenu(client, target, i);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez volé %s à %N, il a été envoyé au marché noir.", tmp, target);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Quelqu'un vous a volé: %s.", tmp);
					
		LogToGame("[TSX-RP] [VOL] %L a vole %L 1 %s", client, target, tmp);
		
		GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp), false);
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '2', '%i', '%s', '%i');",
			tmp, rp_GetClientJobID(client), GetTime(), i, "Vol: Objet", amount);

		SQL_TQuery( rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		int alpha[4];
		alpha[1] = 255;
		alpha[3] = 50;
		
		if( rp_IsNight() ) {
			cooldown *= 1.5;
			alpha[3] = 25;
		}
		else {
			cooldown *= 2.0;
		}
		
		if( amount < 50 )
			cooldown *= 0.5;
		if( amount < 5 )
			cooldown *= 0.5;
		
		rp_ClientFloodIncrement(client, target, fd_vol, cooldown);
		
		float vecTarget[3];
		GetClientAbsOrigin(client, vecTarget);

		ServerCommand("sm_effect_particles %d Aura2 3", client);
		
		//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();		
	}
	else if( VOL_MAX > 0 && money >= 1 ) {
		if( amount > money )
			amount = money;
			
		rp_SetClientStat(target, i_MoneySpent_Stolen, rp_GetClientStat(target, i_MoneySpent_Stolen) + amount);
		rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + amount);
		rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amount);
		rp_SetClientInt(client, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolAmount, amount);
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVol, client);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez volé %d$ à %N.", amount, target);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Quelqu'un vous a volé %d$.", amount);

		//g_iSuccess_last_mafia[client][1] = GetTime();
		//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();
		LogToGame("[TSX-RP] [VOL] %L a vole %L %i$", client, target, amount);
		
		GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp), false);
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
			tmp, rp_GetClientJobID(client), GetTime(), 0, "Vol: Argent", amount);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		if( rp_IsNight() )
			cooldown *= 0.5;
		
		if( amount < 50 )
			cooldown *= 0.5;
		if( amount < 5 )
			cooldown *= 0.5;
			
		if( amount > 500 )
			rp_SetClientFloat(client, fl_LastVente, GetGameTime() + 10.0);
		if( amount > 2000 )
			rp_SetClientFloat(client, fl_LastVente, GetGameTime() + 30.0);
		
		rp_ClientFloodIncrement(client, target, fd_vol, cooldown);
		
		ServerCommand("sm_effect_particles %d Aura2 2", client);
		
		int cpt = rp_GetRandomCapital(91);
		rp_SetJobCapital(91, rp_GetJobCapital(91) + (amount/4));
		rp_SetJobCapital(cpt, rp_GetJobCapital(cpt) - (amount/4));
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'a pas d'argent sur lui.", target);
		cooldown = 1.0;
	}
	
	return Plugin_Stop;
}

public Action fwdOnPlayerUse(int client) {
	#if defined DEBUG
	PrintToServer("fwdOnPlayerUse");
	#endif
	static char tmp[128];
	
	if( rp_GetClientJobID(client) == 91 && rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == 91 ) {
		bool changed = false;
		
		for(int itemID=1; itemID<=3; itemID++) {
		
			int mnt = rp_GetClientItem(client, itemID);
			int max = GetMaxKit(client, itemID);
			if( mnt <  max ) {
				rp_ClientGiveItem(client, itemID, max - mnt);
				rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez récupéré %i %s.", max - mnt, tmp);
				
				changed = true;
			}
			
		}
		
		if(changed == true) {
			FakeClientCommand(client, "say /item");
		}
	}
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	if( GetVectorDistance(vecOrigin, MARCHE_NOIR) < 40.0 ) {
		Cmd_BuyItemMenu(client, false);
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemDoorDefine(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemDoorDefine");
	#endif
	char Arg1[12];	GetCmdArg(1, Arg1, 11);	
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	int door = getDoor(client);
	
	if( door == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser une porte.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	int doorID = rp_GetDoorID(door);
	if(g_iDoorDefine_LOCKER[doorID] != 0 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Un cadenas est déja présent sur cette porte.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
	g_iDoorDefine_LOCKER[doorID] = client;
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le cadenas a été placé avec succès.");
	
	return Plugin_Handled;
}
public Action Cmd_ItemPiedBiche(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPiedBiche");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetClientJobID(client) != 91 ) {
		return Plugin_Continue;
	}
	
	if( rp_GetClientBool(client, b_MaySteal) == false ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler pour le moment.");
		return Plugin_Handled;
	}
	
	int type;
	int target = getDistrib(client, type);
	if( target <= 0 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un distributeur, un téléphone, ou une imprimante.");
		return Plugin_Handled;
	}
	
	float start = 0.0;
	
	if( type == 3 || type == 4  )
		start = Math_GetRandomFloat(0.5, 0.66);
		
	
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) + 1);

	rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id));
	rp_SetClientBool(client, b_MaySteal, false);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, 100);
	rp_SetClientInt(client, i_LastVolTarget, -1);	
	rp_ClientReveal(client);
	
	char classname[64];
	GetEdictClassname(target, classname, sizeof(classname));
	
	ServerCommand("sm_effect_particles %d weapon_sensorgren_detonate 1 facemask", client);
	ServerCommand("sm_effect_particles %d Trail2 2 legacy_weapon_bone", client);
	
	Handle dp;
	CreateDataTimer(0.1, ItemPiedBiche_frame, dp, TIMER_DATA_HNDL_CLOSE|TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
	WritePackCell(dp, start);
	WritePackCell(dp, type);
	
	return Plugin_Handled;
}
public Action ItemPiedBiche_frame(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	float percent = ReadPackCell(dp);
	int type = ReadPackCell(dp);
	int type2;
	
	
	if( !IsValidClient(client ) ) {
		return Plugin_Stop;
	}
	if( getDistrib(client, type2) != target ) {
		MENU_ShowPickLock(client, percent, -1, type);
		rp_ClientColorize(client);
		CreateTimer(0.1, AllowStealing, client);
		rp_ClientGiveItem(client, ITEM_PIEDBICHE, 1);
		return Plugin_Stop;
	}
	if( percent >= 1.0 ) {
		rp_ClientColorize(client);
		
		rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
		rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
		
		float time = (rp_IsNight() ? STEAL_TIME:STEAL_TIME*2.0);
		int stealAMount;
		
		doRP_OnClientWeaponPick(client, type);
		
		switch(type) {
			case 2: { // Banque
				time *= 2.0;
				int count = rp_CountPoliceNear(client), rand = 4 + Math_GetRandomPow(0, 4), i;
				
				for (i = 0; i < count; i++)
					rand += (4 + Math_GetRandomPow(0, 12));
				for (i = 0; i < rand; i++)
					CreateTimer(i / 5.0, SpawnMoney, EntIndexToEntRef(target));
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} %d billets ont été sorti du distributeur.", rand);
				stealAMount = 25*rand;
			}
			case 3: { // Armu
				time /= 2.0;
				rp_ClientDrawWeaponMenu(client, target, true);
				stealAMount = 100; 
				
			}
			case 4: { // Imprimante
				time /= 4.0;
				CreateTimer(0.1, SpawnMoney, EntIndexToEntRef(target));
				stealAMount = 25;
				rp_ClientDamage(target, 25, client);
				
				int owner = rp_GetBuildingData(target, BD_owner);
				if( IsValidClient(owner) ) {
					rp_SetClientInt(owner, i_Bank, rp_GetClientInt(owner, i_Bank) - 25);
					CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Quelqu'un vol vos faux billets.");
				}
			}
			case 5: { // Photocopieuse
				time *= 4.0;
				
				for (int i = 0; i < 15; i++)
					CreateTimer(i / 5.0, SpawnMoney, EntIndexToEntRef(target));
				
				int owner = rp_GetBuildingData(target, BD_owner);
				if( IsValidClient(owner) ) {
					rp_SetClientInt(owner, i_Bank, rp_GetClientInt(owner, i_Bank) - (25 * 15));
					CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Quelqu'un vol vos faux billets.");
				}
				
				
				stealAMount = 25 * 15;
				rp_ClientDamage(target, 250, client);
				
			}
			case 6: { // Téléphone
				time *= 6.0;
				stealAMount = 250;
				missionTelephone(client);
			}
			case 7: { // Plant de drogue
				
				int count = rp_GetBuildingData(target, BD_count);
				if( count > 0  ) {
					char classname[64];
					int sub = rp_GetBuildingData(target, BD_item_id);
					
					rp_GetItemData(sub, item_type_name, classname, sizeof(classname));
					rp_ClientGiveItem(client, sub, count);
					rp_SetBuildingData(target, BD_count, 0);
					stealAMount = 75 * count;
					SetEntityModel(target, "models/custom_prop/marijuana/marijuana_0.mdl");
					SDKHooks_TakeDamage(target, client, client, 125.0);
					
					int owner = rp_GetBuildingData(target, BD_owner);
					if( IsValidClient(owner) ) {
						CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Quelqu'un vol votre drogue.");
					}
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez ramassé %d %s.", count, classname);
				}
			}
		}
		
		rp_SetClientInt(client, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolTarget, -1);
		rp_SetClientInt(client, i_LastVolAmount, stealAMount); 
		
		CreateTimer(time, AllowStealing, client);
		return Plugin_Stop;
	}
	
	if( Math_GetRandomInt(1, 10) == 8 )
		ServerCommand("sm_effect_particles %d Trail2 2 legacy_weapon_bone", client);
	if( Math_GetRandomInt(1, 30) == 8 )
		ServerCommand("sm_effect_particles %d Aura2 1 footplant_L", client);
	if( Math_GetRandomInt(1, 30) == 8 )
		ServerCommand("sm_effect_particles %d Aura2 1 footplant_R", client);
		
	if( Math_GetRandomInt(1, 500) == 42 )
		CreateTimer(0.01, timerAlarm, target); 
	
	float ratio = 15.0 / 2500.0;
	
	if( type )
		ratio *= 2.0;
	
	rp_SetClientFloat(client, fl_CoolDown, GetGameTime() + 0.15);
	
	ResetPack(dp);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
	WritePackCell(dp, percent + ratio);
	WritePackCell(dp, type);
	MENU_ShowPickLock(client, percent, 0, type);
	return Plugin_Continue;
}
public Action SpawnMoney(Handle timer, any target) {
	
	target = EntRefToEntIndex(target);
	if( !IsValidEdict(target) )
		return Plugin_Handled;
	
	char classname[64];
	GetEdictClassname(target, classname, sizeof(classname));
	
	float vecOrigin[3], vecAngle[3], vecPos[3], min[3], max[3];
	Entity_GetAbsOrigin(target, vecOrigin);
	Entity_GetAbsAngles(target, vecAngle);
	
	if( StrContains(classname, "rp_bank") == 0 ) {
		
		Math_RotateVector( view_as<float>({ 7.0, 0.0, 40.0 }), vecAngle, vecPos);
		vecOrigin[0] += vecPos[0];
		vecOrigin[1] += vecPos[1];
		vecOrigin[2] += vecPos[2];
		
		vecAngle[0] += Math_GetRandomFloat(-5.0, 5.0);
		vecAngle[1] += Math_GetRandomFloat(-5.0, 5.0);	
		Math_RotateVector( view_as<float>({ 0.0, 250.0, 40.0 }), vecAngle, vecPos);
		
		int rnd = Math_GetRandomInt(2, 5) * 10;
		int job = rp_GetRandomCapital(91);
		rp_SetJobCapital(job, rp_GetJobCapital(job) - rnd);
	}
	else {
		Entity_GetMinSize(target, min);
		Entity_GetMaxSize(target, max);
		
		vecOrigin[2] += max[2] - min[2];
		
		vecPos[0] += Math_GetRandomFloat(-100.0, 100.0);
		vecPos[1] += Math_GetRandomFloat(-100.0, 100.0);
		vecPos[2] += Math_GetRandomFloat(200.0, 300.0);
	}
	
	int m = rp_Effect_SpawnMoney(vecOrigin);
	TeleportEntity(m, NULL_VECTOR, NULL_VECTOR, vecPos);
	ServerCommand("sm_effect_particles %d Trail9 3", m);
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPickLock(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPickLock");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	bool fast = false;
	char arg[64];
	GetCmdArg(0, arg, sizeof(arg));
	if( StrEqual(arg, "rp_item_picklock2") )
		fast = true;
		
	if( rp_GetClientJobID(client) != 91 ) {
		return Plugin_Continue;
	}
	
	int door = getDoor(client);
	if( door == 0 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser une porte.");
		return Plugin_Handled;
	}
	
	int appartID = zoneToAppartID(rp_GetPlayerZone(door));
	if( appartID > 0 && g_flAppartProtection[appartID] > GetGameTime() ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible de crocheter cette porte pour encore %d minutes.", RoundFloat((g_flAppartProtection[appartID] - GetGameTime()) / 60.0));
		return Plugin_Handled;
	}
	
	
	// Anti-cheat:
	if( rp_GetClientItem(client, item_id) >= GetMaxKit(client, item_id)-1 ) {
		rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id) + GetMaxKit(client, item_id) - 1);
	}
	
	ServerCommand("sm_effect_particles %d weapon_sensorgren_detonate 1 facemask", client);
	ServerCommand("sm_effect_particles %d Trail2 2 legacy_weapon_bone", client);
	
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) + 1);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, 100);
	rp_SetClientInt(client, i_LastVolTarget, -1);
	
	rp_ClientReveal(client);
	runAlarm(client, door);	
	
	Handle dp;
	CreateDataTimer(0.1, ItemPickLockOver_frame, dp, TIMER_DATA_HNDL_CLOSE|TIMER_REPEAT); 
	WritePackCell(dp, client);
	WritePackCell(dp, door);
	WritePackCell(dp, rp_GetDoorID(door));
	WritePackCell(dp, (fast?0.75:0.0));
	
	return Plugin_Handled;
}
public Action ItemPickLockOver_frame(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("ItemPickLockOver_frame");
	#endif	
	ResetPack(dp);
	int client 	 = ReadPackCell(dp);
	int door = ReadPackCell(dp);
	int doorID = ReadPackCell(dp);
	float percent = ReadPackCell(dp);
	int target = getDoor(client);
	
	if( !IsValidClient(client ) ) {
		return Plugin_Stop;
	}
	if( target <= 0 || rp_GetDoorID(target) != doorID ) {
		MENU_ShowPickLock(client, percent, -1, 1);
		rp_ClientColorize(client);
		return Plugin_Stop;
	}
	
	int difficulte = 1;
	
	if( rp_IsInPVP(client) )
		difficulte += 1;
	if( rp_GetZoneBit( rp_GetPlayerZone(door)) & BITZONE_HAUTESECU )
		difficulte += 1;
	if( g_iDoorDefine_LOCKER[doorID] )
		difficulte += 2;
	
	if( percent >= 1.0 ) {
		
		if( IsValidClient(g_iDoorDefine_LOCKER[doorID]) ) {
			char zone[128];
 			rp_GetZoneData(rp_GetPlayerZone(door), zone_type_name, zone, sizeof(zone));
 			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Quelqu'un a ouvert votre porte cadnacée (%s).", zone);
			
			if( Math_GetRandomInt(1, 10) == 5 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cadenas a été détruit.");
				g_iDoorDefine_LOCKER[doorID] = 0;
			}
		}
		
		rp_ClientColorize(client);
		
		rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
		rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
		rp_SetClientFloat(client, fl_LastCrochettage, GetGameTime());
		
		if( g_iLastDoor[client][2] != doorID && g_iLastDoor[client][1] != doorID && g_iLastDoor[client][0] != doorID
			&& rp_GetPlayerZone(target) != 91 && rp_GetPlayerZone(client) != 91
			&& !rp_GetClientKeyDoor(client, doorID) && GetEntProp(target, Prop_Data, "m_bLocked") ) {
			
			g_iLastDoor[client][2] = g_iLastDoor[client][1];
			g_iLastDoor[client][1] = g_iLastDoor[client][0];
			g_iLastDoor[client][0] = doorID;
			
			int rnd = rp_GetRandomCapital(91);
			rp_SetJobCapital(rnd, rp_GetJobCapital(rnd) - (100*difficulte));
			rp_SetJobCapital(91, rp_GetJobCapital(91) + (100*difficulte));
		}
		
		rp_SetDoorLock(doorID, false); 
		rp_ClientOpenDoor(client, doorID, true);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} La porte a été ouverte.");
		
		return Plugin_Stop;
	}
	
	rp_SetClientFloat(client, fl_CoolDown, GetGameTime() + 0.15);
	float ratio = getKitDuration(client) / 5000.0;
	
	if( Math_GetRandomInt(1, 10) == 8 )
		ServerCommand("sm_effect_particles %d Trail2 2 legacy_weapon_bone", client);
	
	ratio = ratio / float(difficulte);
	ResetPack(dp);
	WritePackCell(dp, client);
	WritePackCell(dp, door);
	WritePackCell(dp, doorID);
	WritePackCell(dp, percent + ratio);
	MENU_ShowPickLock(client, percent, difficulte, 1);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action timerAlarm(Handle timer, any door) {
	#if defined DEBUG
	PrintToServer("timerAlarm");
	#endif
	
	EmitSoundToAllAny("UI/arm_bomb.wav", door, _, _, _, 0.5);
	return Plugin_Handled;
}
public Action AllowStealing(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowStealing");
	#endif
	
	rp_SetClientBool(client, b_MaySteal, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez à nouveau voler.");
}
int GetMaxKit(int client, int itemID) {
	#if defined DEBUG
	PrintToServer("GetMaxKit");
	#endif
	int max, job = rp_GetClientInt(client, i_Job);
	
	switch( job ) {
		case 91:	max = 7;
		case 92:	max = 6;
		case 93:	max = 5; // parrain
		case 94:	max = 5; // pro
		case 95:	max = 4; // mafieux
		case 96:	max = 3; // apprenti
		default:	max = 0;
	}
	
	if( itemID == ITEM_PIEDBICHE )
		max = 1;
	if( itemID == ITEM_KITEXPLOSIF )
		max = RoundToCeil(max / 3.0);
	
	return max;
}
int getDoor(int client) {
	if( !IsPlayerAlive(client) )
		return 0;
	int door = rp_GetClientTarget(client);
	if( !rp_IsValidDoor(door) && IsValidEdict(door) && rp_IsValidDoor(Entity_GetParent(door)) )
		door = Entity_GetParent(door);
	
	if( !rp_IsValidDoor(door) || !rp_IsEntitiesNear(client, door, true) )
		door = 0;
	return door;
}
int getDistrib(int client, int& type) {
	if( !IsPlayerAlive(client) )
		return 0;
	int target = rp_GetClientTarget(client);
	
	if( target <= MaxClients )
		return 0;
	if( !rp_IsEntitiesNear(client, target, true) )
		return 0;
	
	char classname[128];
	GetEdictClassname(target, classname, sizeof(classname));
	
	int owner = rp_GetBuildingData(target, BD_owner);
	
	
	if( StrEqual(classname, "rp_bank") && owner == 0 && !rp_GetBuildingData(target, BD_Trapped) )
		type = 2;
	if( StrEqual(classname, "rp_weaponbox") )
		type = 3;
	if( (StrEqual(classname, "rp_cashmachine") ) && rp_GetClientJobID(owner) != 91 &&
		!rp_IsClientNew(owner) && !rp_GetClientBool(owner, b_IsAFK) && Entity_GetHealth(target) == 100)
		type = 4;
	if( (StrEqual(classname, "rp_bigcashmachine") ) && rp_GetClientJobID(owner) != 91 &&
		!rp_IsClientNew(owner) && !rp_GetClientBool(owner, b_IsAFK) && Entity_GetHealth(target) == 1000)
		type = 5;
	if( StrEqual(classname, "rp_phone") )
		type = 6;
	if( (StrEqual(classname, "rp_plant") ) && rp_GetClientJobID(owner) != 91 &&
		!rp_IsClientNew(owner) && !rp_GetClientBool(owner, b_IsAFK) && rp_GetBuildingData(target, BD_count) > 0 )
		type = 7;
		
	return (type > 0 ? target : 0);
}
void runAlarm(int client, int door) {
	int doorID = rp_GetDoorID(door);
	int alarm = g_iDoorDefine_LOCKER[doorID];
	if( alarm ) {
		
		if( IsValidClient(alarm) ) {
			char zone[128];
			rp_GetZoneData(rp_GetPlayerZone(door), zone_type_name, zone, sizeof(zone));
			
			CPrintToChat(alarm, "{lightblue}[TSX-RP]{default} Quelqu'un crochette votre porte (%s).", zone );
			rp_Effect_BeamBox(alarm, client);
		}
		
		EmitSoundToAllAny("UI/arm_bomb.wav", door);
		CreateTimer(10.0, timerAlarm, door); 
	}
}
int getKitDuration(int client) {
	int job = rp_GetClientInt(client, i_Job);
	int ratio = 0;
	switch( job ) {
		case 91: ratio = 75;	// Chef
		case 92: ratio = 80;	// Co-chef
		case 93: ratio = 85; 	// Parrain
		case 94: ratio = 90;	// Pro
		case 95: ratio = 95;	// Mafieu
		case 96: ratio = 100;	// Apprenti
	}
	return ratio;
}
// ----------------------------------------------------------------------------
void MENU_ShowPickLock(int client, float percent, int difficulte, int type) {

	Handle menu = CreateMenu(eventMenuNone);
	switch( type ) {
		case 1: SetMenuTitle(menu, "== Mafia: Ouverture d'une porte");
		case 2: SetMenuTitle(menu, "== Mafia: Crochetage d'un distributeur");
		case 3: SetMenuTitle(menu, "== Mafia: Crochetage d'une armurerie");
		case 4: SetMenuTitle(menu, "== Mafia: Crochetage d'une imprimante");
		case 5: SetMenuTitle(menu, "== Mafia: Crochetage d'une photocopieuse");
		case 6: SetMenuTitle(menu, "== Mafia: Crochetage d'un téléphone");
		case 7: SetMenuTitle(menu, "== Mafia: Crochetage d'un plant de drogue");
	}
	
	char tmp[64];
	rp_Effect_LoadingBar(tmp, sizeof(tmp), percent );
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	
	switch( difficulte ) {
		case -1: AddMenuItem(menu, ".", "Difficulté: Échec", ITEMDRAW_DISABLED);
		case 1: AddMenuItem(menu, ".", "Difficulté: Facile", ITEMDRAW_DISABLED);
		case 2: AddMenuItem(menu, ".", "Difficulté: Moyenne", ITEMDRAW_DISABLED);
		case 3: AddMenuItem(menu, ".", "Difficulté: Difficile", ITEMDRAW_DISABLED);
		case 4: AddMenuItem(menu, ".", "Difficulté: Très difficile", ITEMDRAW_DISABLED);
	}
	
	Format(tmp, sizeof(tmp), "Policier proche: %d", rp_CountPoliceNear(client));
	AddMenuItem(menu, ".", tmp, ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 1);
}
public int eventMenuNone(Handle menu, MenuAction action, int client, int param2) {	
	if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
void missionTelephone(int client) {
	float vecDir[3];
	vecDir[0] = Math_GetRandomFloat(-3250.0, 2000.0);
	vecDir[1] = Math_GetRandomFloat(-5000.0, 900.0);
	
	float tmp[3];
	GetClientAbsOrigin(client, tmp);
	TE_SetupBeamPoints(vecDir, tmp, g_cBeam, 0, 0, 0, 17.5, 1.0, 10.0, 0, 0.0, {255, 255, 255, 100}, 20);
	TE_SendToClient(client);
	
	TE_SetupBeamRingPoint(vecDir, 50.0, 250.0, g_cBeam, 0, 0, 30, 17.5, 20.0, 0.0, { 255, 255, 255, 100 }, 10, 0);
	TE_SendToClient(client);
	
	vecDir[2] -= 2000.0;
	
	Handle dp;
	CreateDataTimer(7.5, Copter_Post, dp);
	WritePackFloat(dp, vecDir[0]);
	WritePackFloat(dp, vecDir[1]);
	
	char msg[256];
	rp_GetZoneData(rp_GetZoneFromPoint(vecDir), zone_type_name, msg, sizeof(msg));
	Handle menu = CreateMenu(eventMenuNone);
	SetMenuTitle(menu, "== MISSION TELEPHONE == ");
	AddMenuItem(menu, "_", "Un hélicoptère vous envois un colis.", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "_", "Il sera envoyé près de:", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "_", msg, ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);	
}
public Action Copter_Post(Handle timer, Handle dp ) {
	float vecDest[2];
	
	ResetPack(dp);
	vecDest[0] = ReadPackFloat(dp);
	vecDest[1] = ReadPackFloat(dp);
	
	ServerCommand("sm_effect_copter %f %f", vecDest[0], vecDest[1]);
	
	return Plugin_Stop;
}

bool disapear(int client) {
	char model[128];
	GetConVarString(g_vCapture, model, sizeof(model));
	if( StrEqual(model, "active") ) {
		return false;
	}
	int zoneJob = rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type);
	
	int rndClient[65], rndCount;
	if( zoneJob == 1 ) {
		for (int i = 1; i <= MaxClients; i++) {
			if( IsValidClient(i) && GetClientTeam(i) == CS_TEAM_CT ) {
				rndClient[rndCount++] = i;
			}
		}
	}
	else {
		for (int i = 1; i <= MaxClients; i++) {
			if( IsValidClient(i) && GetClientTeam(i) != CS_TEAM_CT && rp_GetClientJobID(i) != 91 && i != client ) {
				rndClient[rndCount++] = i;
			}
		}
	}
	if( rndCount == 0 )
		return false;
	int rnd = Math_GetRandomInt(0, rndCount - 1);
	
	Entity_GetModel(rndClient[rnd], model, sizeof(model));
	Entity_SetModel(client, model);
	rp_SetClientInt(client, i_FakeClient, rndClient[rnd]);
	
	rp_HookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
	rp_HookEvent(client, RP_OnPlayerDead, fwdDead);
	CreateTimer(10.0, appear, client);
	
	float vecCenter[3];
	Entity_GetAbsOrigin(client, vecCenter);
	TE_SetupBeamRingPoint(vecCenter, 1.0, 200.0, g_cBeam, g_cBeam, 0, 10, 0.25, 80.0, 0.0, {100, 100, 255, 10}, 1, 0);
	TE_SendToAll();
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous vous êtes déguisé en tant que %N.", rndClient[rnd]);
	LogToGame("[BUILD] [MAFIA] %L est maintenant invisible", client);
	return true;
}
public Action appear(Handle timer, any client) {
	if( rp_GetClientInt(client, i_FakeClient) != 0 ) {
		
		rp_SetClientInt(client, i_FakeClient, 0);
		rp_UnhookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
		rp_UnhookEvent(client, RP_OnPlayerDead, fwdDead);
		
		rp_ClientReveal(client);
		rp_ClientResetSkin(client);
		float vecCenter[3];
		Entity_GetAbsOrigin(client, vecCenter);
		TE_SetupBeamRingPoint(vecCenter, 1.0, 200.0, g_cBeam, g_cBeam, 0, 10, 0.25, 80.0, 0.0, {100, 100, 255, 10}, 1, 0);
		TE_SendToAll();
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes plus déguisé.");
		
		LogToGame("[BUILD] [MAFIA] %L est maintenant visible", client);
	}
}
public Action fwdZoneChange(int client, int newZone, int oldZone) {
	if( rp_GetZoneInt(newZone, zone_type_type) != rp_GetZoneInt(oldZone, zone_type_type) ) {
		CreateTimer(0.1, appear, client);
	}
}
public Action fwdDead(int client, int attacker) {
	CreateTimer(0.1, appear, client);
}

void deleteBuyMenu(DataPackPos pos) {
	g_hBuyMenu.Reset();
	DataPackPos max = g_hBuyMenu.ReadCell();
	DataPackPos position = g_hBuyMenu.Position;
	
	DataPack clone = new DataPack();
	clone.WriteCell(0);
	
	int data[IM_Max];
	 
	while( position < max ) {
		
		for (int i = 0; i < view_as<int>(IM_Max); i++) {
			data[i] = g_hBuyMenu.ReadCell();
		}
		
		if( position != pos) {
			for (int i = 0; i < view_as<int>(IM_Max); i++) {
				 clone.WriteCell(data[i]);
			}
		}
		
		position = g_hBuyMenu.Position;
	}
	position = clone.Position;
	clone.Reset();
	clone.WriteCell(position);
	delete g_hBuyMenu;
	g_hBuyMenu = clone;
}
void getBuyMenu(DataPackPos pos, int data[IM_Max]) {
	g_hBuyMenu.Position = pos;
	
	for (int i = 0; i < view_as<int>(IM_Max); i++) {
		data[i] = g_hBuyMenu.ReadCell();
	}
}
void addBuyMenu(int client, int target, int itemID) {
	
	int data[IM_Max];
	
	data[IM_Owner] = client;
	data[IM_StealFrom] = target;
	data[IM_ItemID] = itemID;
	data[IM_Prix] = (rp_GetItemInt(itemID, item_type_prix) * MARCHE_PERCENT) / 100;
	
	g_hBuyMenu.Reset();
	DataPackPos pos = g_hBuyMenu.ReadCell();
	g_hBuyMenu.Position = pos;
	for (int i = 0; i < view_as<int>(IM_Max); i++) {
		g_hBuyMenu.WriteCell(data[i]);
	}
	pos = g_hBuyMenu.Position;
	g_hBuyMenu.Reset();
	g_hBuyMenu.WriteCell(pos);
}
void Cmd_BuyItemMenu(int client, bool free) {
	g_hBuyMenu.Reset();
	DataPackPos max = g_hBuyMenu.ReadCell();
	DataPackPos position = g_hBuyMenu.Position;
	char tmp[8], tmp2[129];
	int data[IM_Max];
	
	if( position >= max ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Désolé il n'y a pas d'objet disponible pour le moment.");
		return;
	}
	
	Menu menu = new Menu(Menu_BuyWeapon);
	menu.SetTitle("Marché noir:");
	
	while( position < max ) {
		
		getBuyMenu(position, data);
		
		if( data[IM_Owner] == client )
			data[IM_Prix] /= 10;
		
		rp_GetItemData(data[IM_ItemID], item_type_name, tmp2, sizeof(tmp2));
		Format(tmp, sizeof(tmp), "%d %d", position, free);
		Format(tmp2, sizeof(tmp2), "%s pour %d$", tmp2, free?0:data[IM_Prix]);
		menu.AddItem(tmp, tmp2);
		
		position = g_hBuyMenu.Position;
	}

	menu.Display(client, 60);
	return;
}
public int Menu_BuyWeapon(Handle p_hMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("Menu_BuyWeapon");
	#endif
	if (p_oAction == MenuAction_Select) {
		
		char szMenu[64], tmp[64], buffer[2][32];
		if( GetMenuItem(p_hMenu, p_iParam2, szMenu, sizeof(szMenu)) ) {
			
			ExplodeString(szMenu, " ", buffer, sizeof(buffer), sizeof(buffer[]));
			int data[IM_Max];
			DataPackPos position = view_as<DataPackPos>(StringToInt(buffer[0]));
			getBuyMenu(position, data);
			
			if( data[IM_ItemID] == 0 )
				return 0;
			
			if( data[IM_Owner] == client ) {
				data[IM_Prix] /= 10;
				if( data[IM_Prix] == 0 )
					data[IM_Prix] = 1;
			}
			
			if( StringToInt(buffer[1]) == 1 ) {
				rp_SetClientInt(client, i_LastVolAmount, 100+data[BM_Prix]); 
				data[IM_Prix] = 0;
			}
			if( rp_GetClientInt(client, i_Bank) < data[IM_Prix] )
				return 0;
			
			float vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);
			
			if( GetVectorDistance(vecOrigin, MARCHE_NOIR) > 40.0 )
				return 0;
			
			
			deleteBuyMenu(position);
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - data[IM_Prix]);
			rp_ClientGiveItem(client, data[IM_ItemID]);
			rp_GetItemData(data[IM_ItemID], item_type_name, tmp, sizeof(tmp));
			
			doRP_RP_OnMarcheNoireMafia(client, data[IM_Owner], data[IM_StealFrom], data[IM_ItemID], data[IM_Prix]);
			
			LogToGame("[TSX-RP] [ITEM-VENDRE] %L a vendu 1 %s a %L", client, tmp, client);
			
			if( data[IM_Owner] == client ) {
				rp_SetJobCapital(91, rp_GetJobCapital(91) + RoundToCeil(float(data[IM_Prix]*10) * 0.5));
			}
			else if( IsValidClient(data[IM_Owner]) && rp_GetClientJobID(data[IM_Owner]) == 91 && data[IM_Prix] > 0 ) {
				rp_SetJobCapital(91, rp_GetJobCapital(91) + RoundToCeil(float(data[IM_Prix]) * 0.5));
				rp_SetClientInt(data[IM_Owner], i_AddToPay, rp_GetClientInt(data[IM_Owner], i_AddToPay) + RoundToFloor(float(data[IM_Prix]) * 0.5));
				
				CPrintToChat(data[IM_Owner], "{lightblue}[TSX-RP]{default} Vous avez vendu 1 %s à %N au marché noir pour %d$", tmp, client, data[IM_Prix]);
			}
			else {
				rp_SetJobCapital(91, rp_GetJobCapital(91) + data[IM_Prix]);
				
				if( IsValidClient(data[IM_Owner]) )
					CPrintToChat(data[IM_Owner], "{lightblue}[TSX-RP]{default} Quelqu'un vous a volé 1 %s au marché noir.", tmp);
			}
			
			
			
			for (int i = 1; i <= MaxClients; i++) {
				if( rp_GetClientJobID(i) == 91 )
					rp_ClientFloodIncrement(i, client, fd_vol, STEAL_TIME);
			}
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hMenu);
	}
	return 0;
}
int zoneToAppartID(int zoneID) {
	char tmp[64];
	rp_GetZoneData(zoneID, zone_type_type, tmp, sizeof(tmp));
	
	int res = 0;
	
	if( StrContains(tmp, "appart_", false) == 0 ) {
		ReplaceString(tmp, sizeof(tmp), "appart_", "");
		res = StringToInt(tmp);
	}
	
	return res;
}
