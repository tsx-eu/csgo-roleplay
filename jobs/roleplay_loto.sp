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
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define	INSTANT

#define getWheel(%1,%2,%3,%4) (g_iJoker[%1][%3] == %4 ? 6 : wheel[%2][%3][%4])
#define wheelButton 360


public Plugin myinfo = {
	name = "Jobs: Loto", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Loto",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};


int gain2[] =  { 0, 300, 400, 600, -5000, 900, 300, 500, 900, 300, 400, 550, 800, 500, 300, 500, 600, 5000, 600, 300, 700, 450, 350, 800, 0};
char symbol[][] = {" ☘ ", "㍴", " ♥ ", "☎", " ♫ ", "♘", "☆", "☠", "♕", " ♠ ", "Δ", "§", " ♦ ", " † ", "☀", "♙ "};
int wheel[10][3][13];
int gain[10][7] =  {
	{200,	100,	50,	25,	5,	3,	-1}, // 1
	{250,	100,	50,	20,	10,	5,	-1}, // 2
	{100,	50,		25,	20,	15,	10,	-1}, // 3
	{1000,	5,		4,	3,	2,	1,	-1}, // 4
	{100,	50,		20,	20,	20,	5,	-1}, // 5
	{100,	50,		30,	25,	20,	6,	-1}, // 6
	{500,	100,	20,	10,	6,	3,	-1}, // 7
	{150,	30,		25,	20,	15,	10,	-1}, // 8
	{15,	15,		15,	15,	15,	15,	-1}, // 9
	{0,		0,		0,	0,	0,	25,	-1}  // 10
};
int lstJOB[] =  { 11, 21, 31, 41, 51, 61, 71, 81, 111, 131, 171, 191, 211, 221 };
int g_iLastMachine[65], g_iRotation[65][2][3], g_iJettonInMachine[65], g_iJoker[65][3];
bool g_bPlaying[65];
float g_flNext[65][3];
int g_iJackpot = 1000;
bool canPlay = true;
Handle g_hTimer[65];

// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	// Loto
	RegServerCmd("rp_item_loto",		Cmd_ItemLoto,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_loto_bonus",	Cmd_ItemLotoBonus,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_stuffpvp", 	Cmd_ItemStuffPvP, 		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegAdminCmd("rp_force_loto", 		CmdForceLoto, 			ADMFLAG_ROOT);
	
	for (int i = 0; i < sizeof(wheel); i++) {
		wheel[i][0] =  { 0,	1,	2,	2,	3,	3,	4,	4,	4,	5,	5,	5, 5};
		wheel[i][1] =  { 0,	1,	1,	2,	3,	3,	4,	4,	4,	5,	5,	5, 6};
		wheel[i][2] =  { 0,	1,	2,	2,	3,	3,	4,	4,	5,	5,	5,	5, 6};
		
		int j;
		for (j = 0; j < 10000; j++) {
			rotateWheel(i);
			if( validate(i) )
				break;
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	HookSingleEntityOutput(wheelButton, "OnPressed", wheelButtonPressed);
	SDKHook(wheelButton, SDKHook_Touch, touch);
	SDKHook(wheelButton+1, SDKHook_Touch, touch);
	
	PrecacheSound("common/talk.wav");
	PrecacheSound("common/stuck1.wav");
}
public Action touch(int entity, int target) {
	
	if( IsValidClient(rp_IsGrabbed(target)) ) {
		CPrintToChat(rp_IsGrabbed(target), "{lightblue}[TSX-RP]{default} Ne touchez pas la roue.");
		rp_ClientDamage(rp_IsGrabbed(target), 50000, rp_IsGrabbed(target));
	}
		
	if( IsValidClient(target) ) {
		rp_ClientDamage(target, 5, target);
		
		float pos[3];
		Entity_GetAbsOrigin(target, pos);
		pos[0] -= 255.0;
		pos[2] += 8.0;
		
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Ne touchez pas la roue.");
		rp_ClientTeleport(target, pos);
	
	}
	else if( rp_IsMoveAble(target) )
		AcceptEntityInput(target, "Kill");
	
	return Plugin_Continue;
}
public Action wheelButtonPressed(const char[] output, int caller, int activator, float delay) {
	
	int jeton = getPlayerJeton(activator);
	SetEntPropFloat(caller, Prop_Data, "m_flWait", 1.0);
	
	if( !canPlay || GetEntProp(caller, Prop_Data, "m_bLocked") == 1 ) {
		CPrintToChat(activator, "{lightblue}[TSX-RP]{default} Impossible de jouer pour le moment.");
		return Plugin_Handled;
	}
	
	if( jeton < 5 ) {
		CPrintToChat(activator, "{lightblue}[TSX-RP]{default} Il faut 5 jetons pour jouer à cette machine.");
		return Plugin_Handled;
	}
	if( (rp_GetClientInt(activator, i_Money)+rp_GetClientInt(activator, i_Bank)) < 10000 ) {
		CPrintToChat(activator, "{lightblue}[TSX-RP]{default} Il faut 10.000$ pour jouer à cette machine.");
		return Plugin_Handled;
	}
	
	SetEntProp(caller, Prop_Data, "m_bLocked", 1);
	canPlay = false;
	takePlayerJeton(activator, 5);
	rp_SetClientStat(activator, i_LotoSpent, rp_GetClientStat(activator, i_LotoSpent) + 5*100); // 5 jetons * prix du jeton
	CreateTimer(0.25, wheelThink, activator);
	return Plugin_Continue;
}
public Action wheelThink(Handle timer, any client) {
	static float moveTime[2], lastRotation[3];
	
	moveTime[0] = GetEntPropFloat(wheelButton+1, Prop_Data, "m_flMoveDoneTime");
	EmitSoundToAll("common/talk.wav", wheelButton, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.33);
	EmitSoundToAll("common/talk.wav", wheelButton, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.33);
	
	float ang[3];
	Entity_GetAbsAngles(wheelButton + 1, ang);
	
	if( moveTime[0] == moveTime[1] && lastRotation[2] == ang[2] ) {
		EmitSoundToAll("common/stuck1.wav", wheelButton, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.33);
		EmitSoundToAll("common/stuck1.wav", wheelButton, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.33);
		
		for(int j; j < 3; j++) {
			if(ang[j] < -360.0 || ang[j] > 360.0)
			ang[j] = float(RoundFloat(ang[j]*1000) % 360000) / 1000.0;
			Entity_SetAbsAngles(wheelButton + 1, ang);
		}
		
		int c = RoundFloat((ang[2] + 360.0 - 12.5) / 15.0) - 1;
		if( c < 0 || c > sizeof(gain2) )
			c = 0;
		
		if( gain2[c] == 0 )
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez perdu un tour!");
		else if( gain2[c] > 0 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez gagné %d$!", gain2[c]);
			rp_SetClientStat(client, i_LotoWon, rp_GetClientStat(client, i_LotoWon) + (gain2[c]));
		}
		else {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} BANKRUPT! Vous avez perdu %d$!", gain2[c]);
			rp_SetClientStat(client, i_LotoSpent, rp_GetClientStat(client, i_LotoSpent) + gain2[c]);
		}
		
		if( Math_Abs(gain2[c]) >= 5000 )
			rp_ClientXPIncrement(client, 100);
		
		rp_ClientMoney(client, i_AddToPay, gain2[c]);
		CreateTimer(1.0, allowPlay);
	}
	else {
		moveTime[1] = moveTime[0];
		lastRotation[2] = ang[2];
		CreateTimer(0.1, wheelThink, client);
	}
}
public Action allowPlay(Handle timer, any none) {
	SetEntProp(wheelButton, Prop_Data, "m_bLocked", 0);
	canPlay = true;
}
public void OnAllPluginsLoaded() {
	char query[1024];
	Format(query, sizeof(query), "SELECT `jackpot` FROM `rp_csgo`.`rp_servers` WHERE `port`='%d'", GetConVarInt(FindConVar("hostport")));
	SQL_TQuery(rp_GetDatabase(), SQL_GetJackpot, query);
	CreateTimer(300.0, TIMER_SyncJackpot, 0, TIMER_REPEAT);
}
public Action TIMER_SyncJackpot(Handle timer, any none) {
	char query[1024];
	Format(query, sizeof(query), "UPDATE `rp_csgo`.`rp_servers` SET `jackpot`='%d' WHERE `port`='%d'", g_iJackpot, GetConVarInt(FindConVar("hostport")));
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
}
public void SQL_GetJackpot(Handle owner, Handle hQuery, const char[] error, any client) {
	if( SQL_FetchRow(hQuery) ) {
		g_iJackpot = SQL_FetchInt(hQuery, 0);
	}
}
// ------------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerBuild, fwdOnPlayerBuild);
	rp_HookEvent(client, RP_OnPlayerUse, fwdOnPlayerUse);
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
// ----------------------------------------------------------------------------
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "dé") ) {
		return Cmd_de(client, arg);
	}
	return Plugin_Continue;
}
public Action Cmd_de(int client, char[] arg) {
	
	int count = StringToInt(arg);
	if( count <= 0 )
		count = 1;
	if( count >= 5 )
		count = 5;
	
	if( rp_GetClientFloat(client, fl_CoolDown) > GetGameTime() ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez rien utiliser pour encore %.2f seconde(s).", rp_GetClientFloat(client, fl_CoolDown)-GetGameTime() );
		return Plugin_Handled;
	}
	
	rp_SetClientFloat(client, fl_CoolDown, GetGameTime() + 2.0);
	
	char tmp[128];
	int k, j;
	
	for (int i = 1; i <= count; i++) {
		j = Math_GetRandomInt(1, 6);
		k += j;
		Format(tmp, sizeof(tmp), "%s{purple}%d{default}, ", tmp, j);
	}
	tmp[strlen(tmp) - 2] = 0;
	
	if( count == 1 )
		PrintToChatClientArea(client, "%N lance un dé et fait {green}%d{default}!", client, k);
	else
		PrintToChatClientArea(client, "%N lance %d dé%s et fait %s ... soit un total de {green}%d{default}!", client, count, count>1 ? "s" : "", tmp, k);
	return Plugin_Handled;
}
public Action fwdOnPlayerBuild(int client, float& cooldown) {
	if( rp_GetClientJobID(client) != 171 )
		return Plugin_Continue;
	
	int target = rp_GetClientTarget(client);
	if( IsValidClient(target) && rp_IsEntitiesNear(client, target, true) && rp_GetZoneInt(rp_GetPlayerZone(target), zone_type_type) == 171
		&& rp_GetClientItem(target, ITEM_JETONBLEU) >= 1 && rp_ClientCanDrawPanel(target) ) {
		drawEchange(client, target, -1);
		cooldown = 1.0;
	}
	else {
		rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
		rp_Effect_Particle(client, "weapon_confetti_balloons", 10.0);
		cooldown = 10.0;
	}
	
	return Plugin_Stop;
}
public Action fwdOnPlayerUse(int client) {
	if( rp_GetPlayerZone(client) == 278 ) {
		displayCasino(client);
	}
}
public Action Cmd_ItemStuffPvP(int args) {
	int client = GetCmdArgInt(1);
	
	int amount = 0;
	int ItemRand[64];
	bool luck = rp_IsClientLucky(client);
	
	for (int i = 1; i <= 4; i++) {
		ItemRand[amount++] = 239;	// P90-PVP
		ItemRand[amount++] = 64;	// M4A1-S
		ItemRand[amount++] = 236;	// AK47
	}
	
	if( Math_GetRandomInt(1, 4) == 4 ) 
		ItemRand[amount++] = 27;	// Drapeau
	if( Math_GetRandomInt(1, 4) == 4 )
		ItemRand[amount++] = 67;	// Drapeau
	if( Math_GetRandomInt(1, 4) == 4 )
		ItemRand[amount++] = 118;	// Drapeau
	if( Math_GetRandomInt(1, 4) == 4 )
		ItemRand[amount++] = 126;	// Drapeau	
	
	ItemRand[amount++] = 238;	// AWP
	ItemRand[amount++] = 22;	// San-Andreas
	ItemRand[amount++] = 46;	// Incendiaire
	ItemRand[amount++] = 66;	// Sucette Duo
	ItemRand[amount++] = 94;	// EMP
	ItemRand[amount++] = 35;	// Cocaine
	ItemRand[amount++] = 184;	// Prop d'extérieur
	ItemRand[amount++] = 6;		// Seringue du Berserker
	ItemRand[amount++] = 114;	// Big Mac
	ItemRand[amount++] = 231;	// Cartouches explosives
	ItemRand[amount++] = 285;	// Bouclier Anti-émeute
	ItemRand[amount++] = 296;	// Paire de baskets
	ItemRand[amount++] = 53;	// Amelioration précision de tir
	
	int item_id = ItemRand[ Math_GetRandomInt(0, amount-1) ];
	rp_ClientGiveItem(client, item_id);
	if( item_id == 35 )
		rp_ClientGiveItem(client, item_id, 4);
	
	if( (luck || Math_GetRandomInt(1, 100) > 80) && (item_id == 6 || item_id == 64 || item_id == 114 || item_id == 236 || item_id == 239) )
		rp_ClientGiveItem(client, item_id);
	
	char tmp[64];
	rp_GetItemData(item_id, item_type_name, tmp, sizeof(tmp));
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu comme cadeau: %s", tmp);
}
public Action Cmd_ItemLotoBonus(int args) {
	int client = GetCmdArgInt(1);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous vous sentez chanceux aujourd'hui.");
	rp_IncrementLuck(client);
	rp_HookEvent(client, RP_OnAssurance, fwdAssurance, 30.0);
}
public Action fwdAssurance(int client, int& amount) {
	amount += 250;
}
public void SQL_GetLotoCount(Handle owner, Handle hQuery, const char[] error, any client) {
	
	if( SQL_FetchRow(hQuery) ) {
		int cpt = SQL_FetchInt(hQuery, 0);
		
		if( cpt == 0 ) {
			char query[1024], szSteamID[32];
			GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
			
			Format(query, sizeof(query), "INSERT INTO `rp_loto` (`id`, `steamid`) VALUES (NULL, '%s');", szSteamID);
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query, 0, DBPrio_High);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a été validé. Un tirage exceptionnel pour la brocante de Noël aura lieu mercredi vers 21h30.");
		}
		else {
			rp_ClientGiveItem(client, ITEM_TICKETID, 1, true);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a déjà été validé. Vous avez été remboursé dans votre banque.");
		}
	}		
}
int ticketAmountType[] =  { -1, 9999999, 1, 2, 3, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000 };
public Action Cmd_ItemLoto(int args) {
	
	int amount = GetCmdArgInt(1);
	int client = GetCmdArgInt(2);
	int itemID = GetCmdArgInt(args);
	int itemCount = rp_GetClientItem(client, itemID);

	if( amount > 1000)
		return Plugin_Handled;
	
	
	if( g_hTimer[client] ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes déjà entrain de gratter des tickets.");
		ITEM_CANCEL(client, itemID);
		return Plugin_Handled;
	}
	
	if( itemCount >= 9 ) {
		rp_ClientGiveItem(client, itemID);
		
		Handle dp;
		CreateDataTimer(0.1, Delay_MenuLoto, dp, TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dp, client);
		WritePackCell(dp, itemID);
		WritePackCell(dp, amount);
	}
	else {
		gratterTicket(client, amount, itemID);
	}


	return Plugin_Handled;
}
public Action Delay_MenuLoto(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int itemID = ReadPackCell(dp);
	int amount = ReadPackCell(dp);
	int count = rp_GetClientItem(client, itemID);
	
	Menu menu = CreateMenu(MenuLoto);
	if( amount == -1 )
		menu.SetTitle("Vous avez %d ticket cagnotte.\nCombien voulez-vous gratter?\n ", count);
	else
		menu.SetTitle("Vous avez %d ticket de %d$.\nCombien voulez-vous gratter?\n ", count, amount);
		
	char tmp[64], tmp2[64];
		
	for (int i = 0; i < sizeof(ticketAmountType); i++) {
		Format(tmp, sizeof(tmp), "%d %d %d", itemID, amount, ticketAmountType[i]);
		
		if( i > 2 && count < ticketAmountType[i] )
			continue;
		if( i == 0 && amount == -1 )
			continue;
		
		if( ticketAmountType[i] == -1 )
			Format(tmp2, sizeof(tmp2), "Gratter jusqu'à ce que je gagne");
		else if( ticketAmountType[i] > 1000 )
			Format(tmp2, sizeof(tmp2), "Gratter tous mes tickets");
		else
			Format(tmp2, sizeof(tmp2), "Gratter %d ticket%s", ticketAmountType[i], ticketAmountType[i] > 1 ? "s":"");
		
		menu.AddItem(tmp, tmp2);
	}
	
	menu.Display(client, 30);
}
public Action TIMER_Grattage(Handle timer, Handle dp) {
	ResetPack(dp);
	int total = ReadPackCell(dp);
	int client = ReadPackCell(dp);
	int itemID = ReadPackCell(dp);
	int amount = ReadPackCell(dp);
	
	if( rp_GetClientItem(client, itemID) <= 0 ) {
		delete g_hTimer[client];
		return Plugin_Stop;
	}
	
	rp_ClientGiveItem(client, itemID, -1);
	bool won = gratterTicket(client, amount, itemID);
	
	if( total < 0 && won ) {
		delete g_hTimer[client];
		return Plugin_Stop;
	}
	if( total == 1 ) {
		delete g_hTimer[client];
		return Plugin_Stop;
	}
	
	ResetPack(dp);
	WritePackCell(dp, total-1);
	return Plugin_Continue;
}
public int MenuLoto(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char szMenuItem[64], tmp[3][8];
		GetMenuItem(menu, param2, szMenuItem, sizeof(szMenuItem));
		ExplodeString(szMenuItem, " ", tmp, sizeof(tmp), sizeof(tmp[]));
		
		int itemID = StringToInt(tmp[0]);
		int amount = StringToInt(tmp[1]);
		int count = StringToInt(tmp[2]);
		
		Handle dp;
		g_hTimer[client] = CreateDataTimer(0.01, TIMER_Grattage, dp, TIMER_DATA_HNDL_CLOSE|TIMER_REPEAT);
		WritePackCell(dp, count);
		WritePackCell(dp, client);
		WritePackCell(dp, itemID);
		WritePackCell(dp, amount);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
bool gratterTicket(int client, int amount, int itemID) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
	
	if( amount == -1 ) {
		char query[1024];
		//Format(query, sizeof(query), "SELECT COUNT(*) FROM `rp_loto` WHERE `steamid`='%s';", szSteamID);
		//SQL_TQuery(rp_GetDatabase(), SQL_GetLotoCount, query, client, DBPrio_Low);
		//CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a été validé. Un tirage exceptionnel pour la brocante de Noël aura lieu mercredi vers 21h30.");
		Format(query, sizeof(query), "INSERT INTO `rp_loto` (`id`, `steamid`) VALUES (NULL, '%s');", szSteamID);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query, 0, DBPrio_High);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre ticket a été validé. Les tirages ont lieu le mardi et le samedi à 21h00.");
		
		return false;
	}
	int luck = 100;
	
	rp_SetClientStat(client, i_LotoSpent, rp_GetClientStat(client, i_LotoSpent) + amount);
	if( rp_GetClientJobID(client) == 171 ) // Pas de cheat inter job.
		luck += 40;
	if( !rp_IsClientLucky(client) )
		luck += 40;
	
	if( Math_GetRandomInt(1, luck) == 42 && itemID ) {
		
		rp_SetClientStat(client, i_LotoWon, rp_GetClientStat(client, i_LotoWon) + (amount*100));
		rp_ClientMoney(client, i_Bank, amount * 100);
		
		rp_SetJobCapital(171, rp_GetJobCapital(171) - (amount*100));
		
		char szQuery[1024];
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
		szSteamID, 171, GetTime(), -1, "LOTO", amount*100);			
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		LogToGame("[TSX-RP] [LOTO] %N gagne: %d jetons", client, (amount*100));
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Félicitations! Vous avez gagné %i$.", (amount*100));
		rp_IncrementSuccess(client, success_list_loterie, (amount*100));			
		rp_Effect_Particle(client, "weapon_confetti_balloons", 10.0);
			
		rp_ClientSave(client);
		
		return true;
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Désolé, vous n'avez rien gagné.");
	return false;
}
// ------------------------------------------------------------------------------
public Action CmdForceLoto(int client, int args) {
	CheckLotery();
	return Plugin_Handled;
}
void CheckLotery() {
	
 	/* Explication du tirage:
	10 boules dans un sac. 4 noire, 3 rouge, 2 verte, 1 jaune

	On mélange le sac. On prend la 1ière qui arrive.

	C'est une verte. On retire toute les vertes. 						<- PROBA NOIRE: 4/10	ROUGE: 3/10	VERT: 2/10	JAUNE: 1/10.
	On prend la suivante. C'est une rouge. On retire toute les rouges	<- PROBA NOIRE: 4/7		ROUGE: 3/7	JAUNE: 1/7
	On prend la suivante, c'est une noire. On retire les noires.		<- PROBA NOIRE: 4/5		JAUNE: 1/7
	
	FIN.
	
	En d'autre mots. La boule noire à 6/10 de NE PAS être choisie en premier. Bref, vous avez plus de chances de gagner...
	Mais pas forcément au premier rang. Ce qui rend les jeux en groupe inutile. Au 2ème rang, vous avez 3/7 de perdre. Au 3eme 1/5 de perdre.
	
	Notez aussi qu'en jouant en groupe, il vous est impossible de gagner à la fois le rang 1, et le rang 2. Qu'en jouant séparément, oui.
	Vous avez avez aussi joué beaucoup plus gros. À vos risques et péril. Vous faites un vrai quitte ou double. Vous savez aussi que
	seul le rang 1 permet de gagner plus que votre mise. Vous diminuez donc par 3 vos chances pour gagner 2x plus. Est-ce raisonable?
	
	Vous n'avez certes que 5% de chance de tout perdre dans cet exemple, mais il n'y a pas que 4 joueurs qui jouent au loto RP.
	Plus il y en a, plus vos chances de perdre augmentent.
	*/
	
	SQL_TQuery( rp_GetDatabase() , SQL_GetLoteryWiner, "SELECT DISTINCT T.`steamid`,`name` FROM ( SELECT `steamid` FROM `rp_loto` ORDER BY RAND()  ) AS T INNER JOIN `rp_users` U ON U.`steamid`=T.`steamid` LIMIT 3;");
}
public void SQL_GetLoteryWiner(Handle owner, Handle hQuery, const char[] error, any none) {
	int place = 0;
	int iGain = 0;
	CPrintToChatAll("{lightblue} ================================== {default}");
	char szSteamID[32], szName[64];
	
	int g_iLOTO = rp_GetServerInt(lotoCagnotte);
	
	while( SQL_FetchRow(hQuery) ) {
		place++;
		
		SQL_FetchString(hQuery, 0, szSteamID, sizeof(szSteamID));
		SQL_FetchString(hQuery, 1, szName, sizeof(szName));
		
		if( place == 1 ) {
			iGain = (g_iLOTO/100*70);
			CPrintToChatAll("{lightblue}[TSX-RP]{default} Le gagnant de la loterie est... %s et remporte %d$!", szName, iGain);
		}
		else if( place == 2 ) {
			iGain = (g_iLOTO/100*20);
			CPrintToChatAll("{lightblue}[TSX-RP]{default} suivi de.... %s et remporte %d$!", szName, iGain);
		}
		else if( place == 3 ) {
			iGain = (g_iLOTO/100*10);
			CPrintToChatAll("{lightblue}[TSX-RP]{default} %s remporte le lot de consolation de %d$!", szName, iGain);
		}
		LogToGame("[LOTO-%d] %s %s %d", place, szName, szSteamID, iGain);
		
		if( place == 1 ) {
			for (int client = 1; client <= MaxClients; client++) {
				if( !IsValidClient(client) )
					continue;
				GetClientAuthId(client, AuthId_Engine, szName, sizeof(szName));
				
				if( StrEqual(szSteamID, szName) ) {
					rp_IncrementSuccess(client, success_list_lotto);
				}
			}
		}
		
		
		char szQuery[1024];
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_users2` (`steamid`,  `bank`) VALUES ('%s', %d);", szSteamID, iGain);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
		szSteamID, 171, GetTime(), -1, "LOTO", iGain);			
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		Format(szQuery, sizeof(szQuery), "UPDATE `rp_success` SET `lotto`='-1' WHERE `SteamID`='%s';", szSteamID);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
	}
	
	rp_SetJobCapital(171, rp_GetJobCapital(171) - g_iLOTO);
	
	CPrintToChatAll("{lightblue} ================================== {default}");
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, "TRUNCATE `rp_loto`");
}
// ------------------------------------------------------------------------------
public Action OnPlayerRunCmd(int client) {
	float time = GetGameTime();
	
	if( g_bPlaying[client] && (g_flNext[client][0] < time || g_flNext[client][1] < time || g_flNext[client][2] < time) ) {
		int k[3];
		
		if( g_iRotation[client][0][0] == g_iRotation[client][1][0] && g_iRotation[client][0][1] == g_iRotation[client][1][1] && g_iRotation[client][0][2] == g_iRotation[client][1][2] ) {
			displayWheel(client, g_iLastMachine[client], g_iRotation[client][0], k, true);
			g_bPlaying[client] = false;
		}
		else {
			displayWheel(client,  g_iLastMachine[client], g_iRotation[client][0], k, false);
			for (int i = 0; i < 3; i++) {
				if ( g_iRotation[client][0][i] != g_iRotation[client][1][i] && g_flNext[client][i] < time ) {
					g_iRotation[client][0][i]++;
					g_flNext[client][i] = GetGameTime() + getSpeed(g_iRotation[client][1][i]-g_iRotation[client][0][i]);
				}
			}
#if defined INSTANT
			g_iRotation[client][0][0] = g_iRotation[client][1][0];
			g_iRotation[client][0][1] = g_iRotation[client][1][1];
			g_iRotation[client][0][2] = g_iRotation[client][1][2];
#endif
		}
	}
}
float getSpeed(int delta) {
#if defined INSTANT
	if( delta ) { }
	return -1.0;
#else
	float val = 0.15 - (delta / 140.0);
	return val;
#endif
}
public Action Cmd_ShowSymbol(int client, int args) {
	Menu menu = CreateMenu(MenuNothing);
	char tmp[64];
	
	for (int i = 0; i < sizeof(symbol); i++) {
		Format(tmp, sizeof(tmp), "%d --> %s", i, symbol[i]);
		menu.AddItem("", tmp);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}
void displayCasino(int client) {
	int n = rp_PlayerIsInCasinoMachine(client);
	if( n < 0 )
		return;
	
	char tmp[512];
	
	int jeton = getPlayerJeton(client);
	
	Format(tmp, sizeof(tmp), "Machine à sous n°%d\n", n + 1, g_iJackpot);
	Format(tmp, sizeof(tmp), "%sVous avez %d jeton%s\n----------------------------\n", tmp, jeton, jeton>1?"s":"");
	
	if( g_iJackpot >= 100 ) {
		Format(tmp, sizeof(tmp), "%s1.      %4s     %d jetons\n", tmp, symbol[6], g_iJackpot);
	
		for (int i = 0; i < sizeof(gain[])-1; i++)
			Format(tmp, sizeof(tmp), "%s%d.      %4s     %d jetons\n", tmp, i+2, symbol[i], gain[n][i]);
	}
	else {
		for (int i = 0; i < sizeof(gain[])-1; i++)
			Format(tmp, sizeof(tmp), "%s%d.      %4s     %d jetons\n", tmp, i+1, symbol[i], gain[n][i]);
	}
	
	Format(tmp, sizeof(tmp), "%s ", tmp);
	
	
	Menu menu = CreateMenu(MenuCasino);
	
	menu.AddItem("1", 		"Jouer 1 jeton", jeton >= 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("2", 		"Jouer 2 jetons", jeton >= 2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("3", 		"Jouer 3 jetons\n", jeton >= 3 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.SetTitle(tmp);
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	g_iLastMachine[client] = n;
}
void EffectCasino(int client, int jeton) {
	if( g_bPlaying[client] )
		return;
	if( rp_PlayerIsInCasinoMachine(client) < 0 )
		return;
	
	if( !takePlayerJeton(client, jeton) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez plus assez de jeton.");
		return;
	}
	
	int size = sizeof(wheel[][]);
	
	for (int i = 0; i < 3; i++)
		g_iRotation[client][1][i] = (size*i) + (Math_GetRandomInt(0, size*1024) % (size*2));
	
	rp_SetClientInt(client, i_JetonBleu, rp_GetClientItem(client, ITEM_JETONBLEU, false) + rp_GetClientItem(client, ITEM_JETONBLEU, true));
	
	g_iJackpot += jeton;
	g_bPlaying[client] = true;
	g_iRotation[client][0][0] = g_iRotation[client][0][1] = g_iRotation[client][0][2] = 0;
	g_iJettonInMachine[client] = jeton;
	
	if( g_iJackpot >= 100 ) {
		g_iJoker[client][0] = Math_GetRandomInt(-size*2, 11);
		g_iJoker[client][1] = Math_GetRandomInt(-size*8, 11);
		g_iJoker[client][2] = Math_GetRandomInt(-size*64, 11);
	}
	else {
		g_iJoker[client][0] = -1;
		g_iJoker[client][1] = -1;
		g_iJoker[client][2] = -1;
	}
}
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
public int MenuCasino(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char szMenuItem[64];
		GetMenuItem(menu, param2, szMenuItem, sizeof(szMenuItem));
		int jeton = StringToInt(szMenuItem);
		if( jeton > 0 ) {
			EffectCasino(client, jeton);
		}
		else
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
void displayWheel(int client, int n, int l[3], int k[3], bool last) { 
	static char tmp[128], pre[12], post[12], title[512];
	int i, j, size = sizeof(wheel[][]);
	
	Menu menu = CreateMenu( last ? MenuCasino : MenuNothing );
	
	int line[5], won;
	line[0] = last && g_iJettonInMachine[client] == 3 ? UpDownMatch(client, n, l, size) : 0;
	line[4] = last && g_iJettonInMachine[client] == 3 ? DownUpMatch(client, n, l, size) : 0;
	
	title[0] = 0;
	
	for (i = 0; i < 5; i++) {
		for (j = 0; j < 3; j++)
			k[j] = (l[j] + i) % size;
		
		line[i] = (i > 0 && i < 4 && last && (i==2 || g_iJettonInMachine[client] >= 2 ) ? lineMatch(client, n, k) : line[i]);
		won += line[i];
		
		preSymbol(client, pre, sizeof(pre), i, line[i]>0, line[0]>0, line[4]>0);
		postSymbol(client, post, sizeof(post), i, line[i]>0, line[0]>0, line[4]>0);
		
		
		if( i == 4 ) Format(title, sizeof(title), "%s  ────────────────\n", title);
		Format(title, sizeof(title), "%s %s │ %4s │ %4s │ %4s │ %s\n", title, pre, symbol[getWheel(client, n, 0, k[0])], symbol[getWheel(client, n, 1, k[1])], symbol[getWheel(client, n, 2, k[2])], post);
		if( i == 0 ) Format(title, sizeof(title), "%s  ────────────────\n", title);
	}
	
	Format(tmp, sizeof(tmp), " ");
	
	if( last && won>0 ) ClientCommand(client, "play common/stuck1.wav");
	if( last && won<=0 ) ClientCommand(client, "play common/stuck2.wav");
	
	if( last && won>0 ) {
		givePlayerJeton(client, won);
		rp_SetClientStat(client, i_LotoWon, rp_GetClientStat(client, i_LotoWon) + (won*100));
		
		if( (g_iJackpot-won) == 0 && won > 1000 ) {
			LogToGame("[CASINO] %L a remporté un jackpot de %d$.", client, won);
			PrintToChatZone(171, "{lightblue}[TSX-RP]{default} %L vient de gagner le jackpot de %d jetons !", client, won);
			rp_Effect_Particle(client, "weapon_confetti_balloons", 10.0);
		}
		
		g_iJackpot -= won;
		Format(tmp, sizeof(tmp), "Vous avez gagné %d jeton%s!", won, won>1?"s":"");
	}
	
	
	int jeton = getPlayerJeton(client);
	
	menu.SetTitle("Machine à sous n°%d\nIl vous reste %d jeton%s\n%s\n\n%s\n ", n+1, jeton, jeton>1?"s":"", tmp, title);
	
	menu.AddItem("1", 		"Jouer 1 jeton", last && jeton >= 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("2", 		"Jouer 2 jetons", last && jeton >= 2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("3", 		"Jouer 3 jetons\n", last && jeton >= 3 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
#if defined INSTANT
	if (last) CreateTimer(0.1, fake, client);
#endif
}
public Action fake(Handle timer, any client) {
	FakeClientCommand(client, "menuselect 3");
}
void rotateWheel(int n) {
	int a, b, c, d;
	d = sizeof(wheel[][]);
	
	for (int i = 0; i < sizeof(wheel[]); i++) {
		for (int j = 0; j < d; j++) {
			a = GetRandomInt(0, d-1);
			b = GetRandomInt(0, d-1);
			
			c = wheel[n][i][a];
			wheel[n][i][a] = wheel[n][i][b];
			wheel[n][i][b] = c;
		}
	}
}
int lineMatch(int client, int n, int k[3]) {
	if( getWheel(client, n, 0, k[0]) == getWheel(client, n, 1, k[1]) && getWheel(client, n, 1, k[1]) == getWheel(client, n, 2, k[2]) )
		return (gain[n][getWheel(client, n, 0, k[0])] == -1 ? g_iJackpot : gain[n][getWheel(client, n, 0, k[0])]);
	return 0;
}
int UpDownMatch(int client, int n, int l[3], int size) {
	int k[3];
	
	k[0] = (l[0] + 1) % size;
	k[1] = (l[1] + 2) % size;
	k[2] = (l[2] + 3) % size;
	
	return lineMatch(client, n, k);
}
int DownUpMatch(int client, int n, int l[3], int size) {
	int k[3];
	
	k[0] = (l[0] + 3) % size;
	k[1] = (l[1] + 2) % size;
	k[2] = (l[2] + 1) % size;
	
	return lineMatch(client, n, k);
}
// "↘", "→", "↗", "↙", "←", "↖", "⇘", "⇒", "⇗", "⇙","⇐","⇖"
void preSymbol(int client, char[] tmp, int length, int i, bool line, bool upDown, bool downUp) {
	
	if( g_iJettonInMachine[client] == 1 && i != 2 ) {
		Format(tmp, length, "   ");
	}
	else if( g_iJettonInMachine[client] == 2 && (i == 0 || i == 4) ) {
		Format(tmp, length, "   ");
	}
	else {
		if( i == 0 ) {
			if( upDown )	Format(tmp, length, "⇘ ");
			else			Format(tmp, length, "↘ ");
		}
		else if( i == 4 ) {
			if( downUp )	Format(tmp, length, "⇗ ");
			else			Format(tmp, length, "↗ ");
		}
		else {
			if( line )		Format(tmp, length, "⇒");
			else			Format(tmp, length, "→");
		}
	}
}
void postSymbol(int client, char[] tmp, int length, int i, bool line, bool upDown, bool downUp) {
	if( g_iJettonInMachine[client] == 1 && i != 2 ) {
		Format(tmp, length, "   ");
	}
	else if( g_iJettonInMachine[client] == 2 && (i == 0 || i == 4) ) {
		Format(tmp, length, "   ");
	}
	else {
		if( i == 0 ) {
			if( downUp )	Format(tmp, length, " ⇙");
			else			Format(tmp, length, " ↙");
		}
		else if( i == 4 ) {
			if( upDown )	Format(tmp, length, " ⇖\n ");
			else			Format(tmp, length, " ↖\n ");
		}
		else {
			if( line )		Format(tmp, length, " ⇐");
			else			Format(tmp, length, " ←");
		}
	}
}
bool validate(int n) {
	int i, j, k;
	for (i = 0; i < sizeof(wheel[][]); i++) {
		for (j = 0; j < sizeof(wheel[][]); j++) { 
			for (k = 0; k < sizeof(wheel[][]); k++) {
				if( subValidate(n, i, j, k) ) {
					return false;
				}
			}
		}
	}
	return true;
}
bool subValidate(int n, int i, int j, int k) {
	int m = sizeof(wheel[][]);

	if( wheel[n][0][i] == wheel[n][1][j] && wheel[n][1][j] == wheel[n][2][k] ) {
		if( wheel[n][0][ modulo(i-1,m) ] == wheel[n][1][ modulo(j-1,m) ] && wheel[n][1][ modulo(j-1,m) ] == wheel[n][2][ modulo(k-1,m) ] ) {
			return true;
		}
		if( wheel[n][0][ modulo(i+1,m) ] == wheel[n][1][ modulo(j+1,m) ] && wheel[n][1][ modulo(j+1,m) ] == wheel[n][2][ modulo(k+1,m) ] ) {
			return true;
		}
		if( wheel[n][0][ modulo(i+1,m) ] == wheel[n][1][ modulo(j,m) ] && wheel[n][1][ modulo(j,m) ] == wheel[n][2][ modulo(k-1,m) ] ) {			
			return true;
		}
		if( wheel[n][0][ modulo(i-1,m) ] == wheel[n][1][ modulo(j,m) ] && wheel[n][1][ modulo(j,m) ] == wheel[n][2][ modulo(k+1,m) ] ) {
			return true;
		}
	}
	if( wheel[n][0][modulo(i+1,m)] == wheel[n][1][modulo(j+1,m)] && wheel[n][1][modulo(j+1,m)] == wheel[n][2][modulo(k+1,m)] ) {
		if( wheel[n][0][ modulo(i+1,m) ] == wheel[n][1][ modulo(j,m) ] && wheel[n][1][ modulo(j,m) ] == wheel[n][2][ modulo(k-1,m) ] ) {			
			return true;
		}
		if( wheel[n][0][ modulo(i-1,m) ] == wheel[n][1][ modulo(j,m) ] && wheel[n][1][ modulo(j,m) ] == wheel[n][2][ modulo(k+1,m) ] ) {
			return true;
		}
	}
	if( wheel[n][0][modulo(i-1,m)] == wheel[n][1][modulo(j-1,m)] && wheel[n][1][modulo(j-1,m)] == wheel[n][2][modulo(k-1,m)] ) {
		if( wheel[n][0][ modulo(i+1,m) ] == wheel[n][1][ modulo(j,m) ] && wheel[n][1][ modulo(j,m) ] == wheel[n][2][ modulo(k-1,m) ] ) {			
			return true;
		}
		if( wheel[n][0][ modulo(i-1,m) ] == wheel[n][1][ modulo(j,m) ] && wheel[n][1][ modulo(j,m) ] == wheel[n][2][ modulo(k+1,m) ] ) {
			return true;
		}
		if( wheel[n][0][modulo(i+1,m)] == wheel[n][1][modulo(j+1,m)] && wheel[n][1][modulo(j+1,m)] == wheel[n][2][modulo(k+1,m)] ) {
			return true;
		}
	}
	
	
	
	return false;
}
int modulo(int i, int j) {
	return ((i % j) + j) % j;
}
int getPlayerJeton(int client) {
	return rp_GetClientItem(client, ITEM_JETONROUGE) + rp_GetClientItem(client, ITEM_JETONBLEU);
}
bool takePlayerJeton(int client, int amount) {
	if( getPlayerJeton(client) < amount )
		return false;
	
	int rouge = rp_GetClientItem(client, ITEM_JETONROUGE);	
	if( rouge >= amount ) {
		rp_ClientGiveItem(client, ITEM_JETONROUGE, -amount);
	}
	else {
		amount -= rouge;
		rp_ClientGiveItem(client, ITEM_JETONROUGE, -rouge);
		rp_ClientGiveItem(client, ITEM_JETONBLEU, -amount);
	}
	rp_SetClientStat(client, i_LotoSpent, rp_GetClientStat(client, i_LotoSpent) + amount*100);
	return true;
}
void givePlayerJeton(int client, int amount) {
	rp_ClientGiveItem(client, ITEM_JETONBLEU, amount);
}
void drawEchange(int client, int target, int jobID) {
	char tmp[64], tmp2[128], prettyJob[2][64];
	int price;
	
	Menu menu = CreateMenu( MenuTrade );
	
	int bleu = rp_GetClientItem(target, ITEM_JETONBLEU);
	
	if( jobID == -1 ) {
		menu.SetTitle("%N vous propose\nd'échanger vos jetons bleus\ncontre des lots.\n ", client);
		menu.AddItem("0", "Argent");
		
		for (int i = 0; i < sizeof(lstJOB); i++) {
			rp_GetJobData(lstJOB[i], job_type_name, tmp, sizeof(tmp));
			ExplodeString(tmp, " - ", prettyJob, sizeof(prettyJob), sizeof(prettyJob[]));
			Format(tmp, sizeof(tmp), "%d", lstJOB[i]);
			menu.AddItem(tmp, prettyJob[1]);
		}
		menu.ExitButton = true;
	}
	else {
		menu.SetTitle("Vous avez %d jeton%s bleu%s\nQue souhaitez-vous échanger?\n ", bleu, bleu > 1 ? "s" : "", bleu > 1 ? "s" : "");
		
		if( jobID == 0 ) {
			menu.AddItem("0 10000 125", "10 000$ - 125 Jetons bleus", bleu >= 125 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			menu.AddItem("0 100000 1200", "100 000$ - 1 200 Jetons bleus", bleu >= 1200 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			menu.AddItem("0 1000000 11000", "1 000 000$ - 1 1000 Jetons bleus", bleu >= 11000 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		else {
			for(int i = 0; i < MAX_ITEMS; i++) {
				if( rp_GetItemInt(i, item_type_job_id) != jobID )
					continue;
				
				rp_GetItemData(i, item_type_name, tmp2, sizeof(tmp2)); 
				price = RoundToCeil(float(rp_GetItemInt(i, item_type_prix)*10) * 1.2 / 100.0);
				
				Format(tmp, sizeof(tmp), "%d %d %d", jobID, i, price);
				Format(tmp2, sizeof(tmp2), "10x %s - %d Jetons bleus", tmp2, price);
				menu.AddItem(tmp, tmp2, bleu >= price ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}
		}
	}
	menu.Display(target, MENU_TIME_FOREVER);
}
public int MenuTrade(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char szMenuItem[64], tmp[3][8];
		GetMenuItem(menu, param2, szMenuItem, sizeof(szMenuItem));
		ExplodeString(szMenuItem, " ", tmp, sizeof(tmp), sizeof(tmp[]));
		
		int jobID = StringToInt(tmp[0]);
		int itemID = StringToInt(tmp[1]);
		int jetons = StringToInt(tmp[2]);
		
		if( jetons == 0 ) {
			drawEchange(0, client, jobID);
		}
		else {
			int bleu = rp_GetClientItem(client, ITEM_JETONBLEU);
			
			if( jetons > bleu ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas suffisement de jetons bleus.");
				return;
			}
			
			rp_SetJobCapital(171, rp_GetJobCapital(171) - RoundToCeil(float(jetons * 100) * 0.75));
			rp_ClientGiveItem(client, ITEM_JETONBLEU, -jetons);
			
			if( jobID == 0 ) {
				rp_ClientMoney(client, i_Bank, itemID);
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu: %d$!", itemID);
			}
			else {
				rp_ClientGiveItem(client, itemID, 10);
				rp_GetItemData(itemID, item_type_name, szMenuItem, sizeof(szMenuItem)); 
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu: 10x %s!", szMenuItem);
			}
			drawEchange(0, client, jobID);
		}
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	return;
}
