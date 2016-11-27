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

public Plugin myinfo = {
	
	name = "Utils: Tribunal", author = "KoSSoLaX",
	description = "RolePlay - Utils: Tribunal",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

enum TribunalData {
	td_Target,
	td_Time,
	td_Owner,
	
	td_Max
};
int g_cBeam;

// Numéro, Résumé, heure, amende, dédo, détail
char g_szArticles[28][6][512] = {
	{"221-1-a",		"Meurtre d'un civil",							"18",	"1250",		"1000",	"Toutes atteintes volontaires à la vie d’un citoyen sont condamnées à une peine maximale de 18h de prison et  1250$ d’amende." },
	{"221-1-b",		"Meurtre d'un policier",						"24",	"5500",		"1500",	"Toutes atteintes volontaires à la vie d’un officier des forces de l’ordre sont condamnées à une peine maximale de 24h de prison et  5 500$ d’amende." },
	{"221-2",		"Vol",											"6",	"450",		"-1",	"Le vol est un acte punis d’une peine maximale de 6h de prison et 450$ d’amende." },
	{"221-3",		"Manquement convocation",						"18",	"4000",		"0",	"Le manquement à une convocation devant les tribunaux sans motif valable est puni d’une peine maximale de 18h de prison et 4.000$ d'amende." },
	{"221-4",		"Faux aveux / Dénonciation calomnieuses",		"6",	"1500",		"0",	"Les faux aveux ou les dénonciations calomnieuses sont punis d’une peine maximale de 6h de prison et 1500$ d’amende." },
	{"221-5-a",		"Nuisances sonores", 							"6",	"1500", 	"0",	"Les nuisances sonores sont punies d’une peine maximale de 6h de prison et 1 500$ d'amende." },
	{"221-5-b",		"Insultes / irrespects", 						"6",	"1000", 	"1250",	"Les insultes sont passibles d’une peine maximale de 6h de prison et 1000$ d’amende." },
	{"221-5-c",		"Harcèlements / Menaces", 						"6",	"800",		"300",	"Les actes de harcèlement et/ou menaces sont passibles d'une peine maximale de 6h de prison et 800$ d'amende." },
	{"221-6",		"Récidive",										"6",	"15000",	"0",	"Toute personne condamnée pour une récidive vis-à-vis de meurtre ou d'une infraction déjà jugée sera condamnée à une peine plus lourde, l'amende peut être augmentée progressivement de 15 000$ et la peine de prison de 6h." },
	{"221-7",		"Obstruction ",									"6",	"650",		"0",	"Tous actes obstruant les forces de l’ordre (Masque/Suicide/Pilules/Pots de vins que ce soit avant ou pendant l’audience/Changement de pseudo délibéré, pendant la recherche du criminel et GHB), ou la fuite délibérée, ou mutinerie, sont passible d’une peine maximale de 6h de prison et 650$ d'amende. " },
	{"221-8",		"Bavure policière",								"24",	"3000",		"0",	"Toute acte de maltraitance policière (taser, balle perdue, jail/déjail répétitif...) pourra être rapporté devant les tribunaux. La maltraitance est passible de 24h de prison au maximum, et d'une amende de 3 000$ au maximum" },
	{"221-9",		"Abus de métier",								"6",	"1000",		"500",	"Tout abus d’un métier est passible d’une peine maximale de 6h de prison et 1 000$ d'amende, ainsi qu’un remboursement intégral de la caution prélevée (si abus Justice/Police)." },
	{"221-10-a",	"Fraude",										"24",	"5000",		"0",	"Tout acte de fraude (transaction d'argent) pour éviter des sanctions juridiques peut être rapporté et signalé. Les personnes étant complices de cette fraude peuvent encourir une peine maximale de 24h de prison et 5000$ d'amende." },
	{"221-10-b",	"Association de malfaiteurs",					"6",	"500",		"0",	"Toute association de malfaiteurs (Défense lors de perquisitions notamment) est punissable d’une peine maximale de 6h de prison et 500$ d’amende." },
	{"221-11-a",	"Vente forcée",									"12",	"5000",		"-1",	"Toute personne essayant de vendre sans le consentement libre et éclairé d'une personne peut-être condamnée à une peine maximale de 12h de prison et 5.000$ d’amende, ainsi qu'un remboursement de la totalité de ce dernier. (Le remboursement n’est pas un dédommagement est n’est donc pas soumis aux avocats)." },
	{"221-11-b",	"Refus de vente",								"6",	"1500",		"0",	"Tout refus de vente est punissable par 6h de prison et une amende de 1.500$ au maximum." },
	{"221-12",		"Profiter de la vulnérabilité d’une personne",	"18",	"3000",		"1500",	"Le fait de soumettre une personne à un acte criminel en abusant de sa vulnérabilité ou de sa dépendance à son travail est punis d’une peine maximale de 18h de prison et 3 000$ d’amende en plus de la peine du crime commis" },
	{"221-13-a",	"Destruction de bien d’autrui",					"6",	"1500",		"1000",	"Tout acte volontaire ou involontaire de destruction de bien d'autrui et ce quel que soit les méthodes de destruction utilisées, peut-être condamné par 6h de prison et 1500$ au maximum" },
	{"221-13-b",	"Atteinte à la vie privée",						"6",	"950",		"500",	"Les atteintes à la vie privée telles que l’espionnage, ou l’enregistrement d’une conversation intime, sont punies d’une peine maximale de 6h de prison et 950$ d'amende" },
	{"221-13-c",	"Intrusion dans une propriété privée",			"6",	"800",		"500",	"La violation d’une propriété privée est punie d’une peine maximale de 6h de prison et 800$ d’amende." },
	{"221-13-d",	"Intrusion dans un batiment fédéral",			"18",	"5000",		"500",	"La violation d’un batiment fédéral est punie d’une peine maximale de 18h de prison et 5000$ d’amende." },
	{"221-14-a",	"Usage produit illicite",						"6",	"1000",		"250",	"Droguer ou alcooliser une personne à son insu est un acte punis d’une peine maximale de 6h de prison et 1000$ d’amende. " },
	{"221-14-b",	"Trafic d’armes",								"6",	"750",		"0",	"La vente ou la possession illégale d’armes est passible d’une peine maximale de 6h de prison et 750$ d'amende." },
	{"221-15-a",	"Tentative de corruption",						"24",	"10000",	"0",	"Tout acte de corruption ou de tentative de corruption, est puni d’une peine maximale de 24h de prison et 10 000$ d’amende." },
	{"221-15-b",	"Escroquerie",									"18",	"5000",		"-1",	"Tout acte d’escroquerie est puni d’une peine maximale de 24h de prison et 5 000$ d’amende." },
	{"221-16",		"Séquestration",								"6",	"800",		"500",	"Les actes de séquestrations sont passibles d'une peine maximale de 6h de prison et 800$ d'amende." },
	{"221-17",		"Acte de proxénétisme / prostitution",			"6",	"450",		"0",	"Tout acte de proxénétisme ou de prostitution est passible d'une peine maximale de 6h de prison et 450$ d’amende." },
	{"221-18",		"Asile politique",								"24",	"1500",		"1000",	"Le tribunal est une zone internationale indépendante des lois de la police, tout citoyen y est protégé par asile juridique. De ce fait, tout policier mettant une personne étant dans le tribunal en prison encourt une peine maximale de 24h de prison et 1 500$ d'amende." }
};
char g_szAcquittement[3][32] = { "Non coupable", "Conciliation", "Impossible de prouver les faits"};
char g_szCondamnation[5][32] = { "très indulgent", "indulgent", "juste", "sévère", "très sévère" };
float g_flCondamnation[5] = {0.2, 0.4, 0.6, 0.8, 1.0};

int g_iArticles[3][28];
int g_iTribunalDispo[3][td_Max];

#define TRIBUJAIL_1 287
#define TRIBUJAIL_2 288
#define TRIBUNAL_1 289
#define TRIBUNAL_2 290

#define isTribunalDisponible(%1) (g_iTribunalDispo[%1][td_Target]<=0?true:false)
#define GetTribunalZone(%1) (%1==1?TRIBUNAL_1:TRIBUNAL_2)
#define GetTribunalJail(%1) (%1==1?TRIBUJAIL_1:TRIBUJAIL_2)
#define GetTribunalType(%1) (%1 == TRIBUNAL_1 ? 1 : %1 == TRIBUNAL_2 ? 2 : 0)


public void OnPluginStart() {
	
	CreateTimer(1.0, Timer_Light, _, TIMER_REPEAT);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action Timer_Light(Handle timer, any none) {
	
	TE_SetupBeamPoints(view_as<float>({308.0, -1530.0, -1870.0}), view_as<float>({200.0, -1530.0, -1870.0}), g_cBeam, g_cBeam, 0, 0, 1.1, 4.0, 4.0, 0, 0.0, tribunalColor(2), 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(view_as<float>({-508.0, -818.0, -1870.0}), view_as<float>({-508.0, -712.0, -1870.0}), g_cBeam, g_cBeam, 0, 0, 1.1, 4.0, 4.0, 0, 0.0, tribunalColor(1), 0);
	TE_SendToAll();
}
// ----------------------------------------------------------------------------
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrContains(command, "tb2") == 0 ) {
		return Cmd_Tribunal(client);
	}
	return Plugin_Continue;
}
public Action Cmd_Tribunal(int client) {
	if( rp_GetClientJobID(client) != 101 )
		return Plugin_Stop;
	int type = GetTribunalType(rp_GetPlayerZone(client));
	if( type == 0 )
		return Plugin_Handled;
	
	char tmp[64], tmp2[64];
	Menu menu = new Menu(MenuTribunal);
	menu.SetTitle("Tribunal de Princeton\n ");
	
	if( isTribunalDisponible(type) ) {
		menu.AddItem("start -1", "Débuter une audience");
	}
	else {
		int heure, amende;
		int admin = (g_iTribunalDispo[type][td_Owner] == client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
		
		for (int i = 0; i < sizeof(g_szArticles); i++) {
			if( g_iArticles[type][i] <= 0 )
				continue;
			
			Format(tmp, sizeof(tmp), "del %d", i);
			Format(tmp2, sizeof(tmp2), "%dx %s", g_iArticles[type][i], g_szArticles[i][1]);
			
			menu.AddItem(tmp, tmp2, admin);
			heure += (g_iArticles[type][i] * StringToInt(g_szArticles[i][2]));
			amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][3]));
		}
		Format(tmp2, sizeof(tmp2), "Condamnation MAX: %d heures %d$ d'amendes\n ", heure, amende);
		
		menu.AddItem("add -1", "Ajouter un article", admin);
		menu.AddItem("_", tmp2, ITEMDRAW_DISABLED);
		menu.AddItem("condamner -1", "Condamner", admin);
		menu.AddItem("acquitter -1", "Acquitter", admin);
		menu.AddItem("stop", "Annuler l'audience", admin);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
Menu AUDIENCE_Start(int client, int type, int articles) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	
	
	if( articles <= 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Quel joueur convoquer?\n ");
		
		for (int i = 1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( i == client )
				continue;
			
			Format(tmp, sizeof(tmp), "start %d", i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( g_iTribunalDispo[type][td_Target] <= 0 ) {
		g_iTribunalDispo[type][td_Target] = articles;
		g_iTribunalDispo[type][td_Owner] = client;
		
		CreateTimer(1.0, AUDIENCE_Timer, type, TIMER_REPEAT);
	}
	
	return subMenu;
}
public Action AUDIENCE_Timer(Handle timer, any type) {
	
	int target = g_iTribunalDispo[type][td_Target];
	int time = g_iTribunalDispo[type][td_Time];
	int zone = rp_GetPlayerZone(target);
	int tzone = GetTribunalZone(type);
	
	if( !IsValidClient(target) ) {
		AUDIENCE_Stop(type);
		return Plugin_Stop;
	}
		
	if( time < 60 && time % 20 == 0 )
		PrintToChatSearch(tzone, target, "{lightblue}[TSX-RP]{default} %N est convoqué par le {green}Tribunal %d{default} de Princeton [%d/3].", target, type, time/20 + 1);
	else if( time % 60 == 0 )
		PrintToChatSearch(tzone, target, "{lightblue}[TSX-RP]{default} %N est recherché par le {green}Tribunal %d{default} de Princeton depuis %d minutes.", target, type, time/60);
	
	if( zone == GetTribunalJail(type) ) {
		PrintToChatSearch(tzone, target, "{lightblue}[TSX-RP]{default} %N est arrivé après %d minutes.", target, time/60);
		return Plugin_Stop;
	}	
	
	g_iTribunalDispo[type][td_Time]++;
	return Plugin_Continue;
}
Menu AUDIENCE_Stop(int type) {
	g_iTribunalDispo[type][td_Target] = -1;
	g_iTribunalDispo[type][td_Time] = 0;
	for (int i = 0; i < sizeof(g_szArticles[]); i++)
		g_iArticles[type][i] = 0;
	return null;
}
Menu AUDIENCE_AddArticles(int type, int articles) {
	Menu subMenu = null;
	char tmp[64];
	
	if( articles == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Liste des articles\n ");
		for (int i = 0; i < sizeof(g_szArticles); i++) {
			Format(tmp, sizeof(tmp), "add %d", i);
			
			subMenu.AddItem(tmp,  g_szArticles[i][1]);
		}
	}
	else {
		g_iArticles[type][articles]++;
	}
	
	return subMenu;
}
Menu AUDIENCE_RemoveArticles(int type, int articles) {
	g_iArticles[type][articles]--;
	return null;
}
Menu AUDIENCE_Condamner(int type, int articles) {
	Menu subMenu = null;
	char tmp[64];
	if( articles == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Quel est votre verdicte?\n ");
		for (int i = 0; i < sizeof(g_szCondamnation); i++) {
			Format(tmp, sizeof(tmp), "condamner %d", i);
			
			subMenu.AddItem(tmp, g_szCondamnation[i]);
		}
	}
	else {
		
		int heure, amende, target;
		
		for (int i = 0; i < sizeof(g_szArticles); i++) {
			if( g_iArticles[type][i] <= 0 )
				continue;
			heure += (g_iArticles[type][i] * StringToInt(g_szArticles[i][2]));
			amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][3]));
		}
		
		heure = RoundFloat(float(heure) * g_flCondamnation[articles]);
		amende = RoundFloat(float(amende) * g_flCondamnation[articles]);
		target = g_iTribunalDispo[type][td_Target];
		
		PrintToChatSearch(GetTribunalZone(type), target, "{lightblue}[TSX-RP]{default} %N a été condamné à %d heures et %d$ d'amende. Le juge a été %s.", target, heure, amende, g_szCondamnation[articles]);
		
		AUDIENCE_Stop(type);
	}
	
	return subMenu;
}
Menu AUDIENCE_Acquitter(int type, int articles) {
	Menu subMenu = null;
	char tmp[64];
	if( articles == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Pour quel raison doit-il être acquitté?\n ");
		for (int i = 0; i < sizeof(g_szAcquittement); i++) {
			Format(tmp, sizeof(tmp), "acquitter %d", i);
			
			subMenu.AddItem(tmp, g_szAcquittement[i]);
		}
	}
	else {
		PrintToChatSearch(GetTribunalZone(type), g_iTribunalDispo[type][td_Target], "{lightblue}[TSX-RP]{default} %N a été acquitté: %s.", g_iTribunalDispo[type][td_Target], g_szAcquittement[articles]);
		AUDIENCE_Stop(type);
	}
	
	return subMenu;
}
// ----------------------------------------------------------------------------
public int MenuTribunal(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], expl[4][32];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, " ", expl, sizeof(expl), sizeof(expl[]));
		int a = StringToInt(expl[1]);
		int type = GetTribunalType(rp_GetPlayerZone(client));
		Menu subMenu = null;
		
		if( StrEqual(expl[0], "start") )
			subMenu = AUDIENCE_Start(client, type, a);
		else if( StrEqual(expl[0], "stop") )
			subMenu = AUDIENCE_Stop(type);
		else if( StrEqual(expl[0], "add") )
			subMenu = AUDIENCE_AddArticles(type, a);
		else if( StrEqual(expl[0], "del") )
			subMenu = AUDIENCE_RemoveArticles(type, a);
		else if( StrEqual(expl[0], "acquitter") )
			subMenu = AUDIENCE_Acquitter(type, a);
		else if( StrEqual(expl[0], "condamner") )
			subMenu = AUDIENCE_Condamner(type, a);
		
		if( subMenu == null )
			Cmd_Tribunal(client);
		else
			subMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
// ----------------------------------------------------------------------------
int[] tribunalColor(int type) {
	int color[4];
	color[3] = 128;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( rp_GetClientJobID(i) == 101 && !rp_GetClientBool(i, b_IsAFK) ) {
			if( type == 1 && rp_GetPlayerZone(i) == TRIBUNAL_1 )
				color[1] = 255;
			else if( type == 2 && rp_GetPlayerZone(i) == TRIBUNAL_2 )
				color[1] = 255;
		}
	}
	if( color[1] == 0 ) {
		color[0] = 255;
		color[1] = 255;
	}
	
	if( !isTribunalDisponible(type) ) {
		color[0] = 255;
		color[1] = 0;
	}
	
	return color;
}
stock void PrintToChatSearch(int zone, int target, const char[] message, any...) {
	char buffer[MAX_MESSAGE_LENGTH];
	VFormat(buffer, sizeof(buffer), message, 4);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		
		if (i == target || rp_GetPlayerZone(i) == zone ) {
			CPrintToChat(i, buffer);
		}
	}
}
