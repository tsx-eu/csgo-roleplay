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

public Plugin myinfo = {
	name = "Utils: HDV", author = "KoSSoLaX, Leethium",
	description = "RolePlay - Utils: HDV",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
public void OnPluginStart() {	
	RegConsoleCmd("rp_hdv",	Cmd_Hdv);
}
public Action Cmd_Hdv(int client, int args) {
	int target = rp_GetClientTarget(client);
	char classname[128];
	GetEdictClassname(target, classname, sizeof(classname));
	if(StrContains(classname, "rp_bank") != -1){
		if( rp_IsEntitiesNear(client, target, true) ){
			HDV_Main(client);
		}
	}
	return Plugin_Handled;
}
void HDV_Main(int client) {
	
	
	if( rp_GetServerRules(rules_HDV, rules_Enabled) == 1 ) {
		if( rp_GetClientJobID(client) == rp_GetServerRules(rules_HDV, rules_Target) || rp_GetClientGroupID(client) == (rp_GetServerRules(rules_HDV, rules_Target)-1000) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le maire vous a interdit l'HDV.");
			return;
		}
	}
	
	if(!(rp_GetClientBool(client, b_HaveAccount))) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez posséder une clé de coffre pour accéder à l'HDV.");
		return;
	}
	
	Menu menu = CreateMenu(Handler_MainHDV);
	menu.SetTitle("Hotel des ventes\n ");
	menu.AddItem("sell", "Vendre", rp_GetClientInt(client, i_ItemCount) > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("buy", "Acheter");
	menu.AddItem("history", "Votre historique");

	menu.Display(client, MENU_TIME_FOREVER);
}
void HDV_Sell(int client, int itemID, int quantity, int sellPrice, int confirm) {
	
	char tmp[32], tmp2[64], tmp3[64];
	Menu menu = CreateMenu(Handler_MainHDV);
	
	if( itemID == 0 ) {
		menu.SetTitle("Hotel des ventes: Vendre\n ");
		
		for (itemID = 1; itemID <= MAX_ITEMS; itemID++) {
			quantity = rp_GetClientItem(client, itemID);
			if( quantity <= 0 )
				continue;
			if( rp_GetItemInt(itemID, item_type_prix) == 0 )
				continue;
			if( rp_GetItemInt(itemID, item_type_job_id) == 0 )
				continue;
			if( rp_GetItemInt(itemID, item_type_auto) == 1 )
				continue;
			
			Format(tmp, sizeof(tmp), "sell %d", itemID);
			rp_GetItemData(itemID, item_type_name, tmp2, sizeof(tmp2));
			menu.AddItem(tmp, tmp2);
		}
	}
	else if( quantity == 0 ) {
		
		quantity = rp_GetClientItem(client, itemID);
		rp_GetItemData(itemID, item_type_name, tmp3, sizeof(tmp3));
		menu.SetTitle("Hôtel des ventes: Vendre\nCombien voulez-vous vendre de\n%s?\n ", tmp3);
		
		
		for (int i = 1; i <= quantity; i++) {
			
			if( quantity <= 0 )
				continue;
			
			Format(tmp, sizeof(tmp), "sell %d %d", itemID, i);
			Format(tmp2, sizeof(tmp2), "%dx %s", i, tmp3);
			menu.AddItem(tmp, tmp2);
		}
	}
	else if( sellPrice == 0 ) {
		rp_GetItemData(itemID, item_type_name, tmp3, sizeof(tmp3));
	
		int minPrice = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * 0.75);
		int maxPrice = RoundToCeil(rp_GetItemFloat(itemID, item_type_prix) * 1.25);
		int step = RoundToCeil(rp_GetItemFloat(itemID, item_type_prix) * 0.01);
		int lastp = 0;
		
		menu.SetTitle("Hôtel des ventes: Vendre\nA quel prix voulez-vous vendre\n%d %s?\n ", quantity, tmp3);
		for (int p = maxPrice; p >= minPrice; p -= step) {
			if(lastp == p)
				continue;
			lastp = p;
			int tax = 0;
			if( rp_GetClientJobID(client) != 211 || rp_GetClientBool(client, b_GameModePassive) ){
				float taxfact = (1 - float(p) / (rp_GetItemFloat(itemID, item_type_prix))) / 10;
				tax = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * (0.05 + taxfact) * quantity);
			}
			Format(tmp, sizeof(tmp), "sell %d %d %d", itemID, quantity, p*quantity);
			Format(tmp2, sizeof(tmp2), "%d$  (%d$/Unité)    (Coût du dépot: %d$)", p*quantity, p, tax);
			menu.AddItem(tmp, tmp2);
		}
	}
	else if( confirm == 0 ) {
		int tax = 0;
		if( rp_GetClientJobID(client) != 211 || rp_GetClientBool(client, b_GameModePassive) ){
			float taxfact = (1 - float(sellPrice) / (rp_GetItemFloat(itemID, item_type_prix) * quantity)) / 10;
			tax = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * (0.05 + taxfact) * quantity);
		}

		rp_GetItemData(itemID, item_type_name, tmp3, sizeof(tmp3));
		menu.SetTitle("Hôtel des ventes: Vendre\nVous allez déposer une offre pour\n%d %s pour %d$?\nCoût du dépot: %d$\n \nConfirmez-vous ?\n ", quantity, tmp3, sellPrice, tax);
		
		Format(tmp, sizeof(tmp), "sell %d %d %d 1", itemID, quantity, sellPrice);
		
		menu.AddItem("sell", "Non, j'annule mon dépot");
		menu.AddItem(tmp, "Oui, j'accepte");
		
	}
	else {
		int tax = 0;
		if( rp_GetClientJobID(client) != 211 || rp_GetClientBool(client, b_GameModePassive) ){
			float taxfact = (1 - float(sellPrice) / (rp_GetItemFloat(itemID, item_type_prix) * quantity)) / 10;
			tax = RoundToFloor(rp_GetItemFloat(itemID, item_type_prix) * (0.05 + taxfact) * quantity);
		}
		
		if( rp_GetClientItem(client, itemID) < quantity ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas la quantité que vous avez spécifiée.");
			delete menu;
			return;
		}
		
		if( rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank) < tax ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas payer la taxe de mise en vente.");
			delete menu;
			return;
		}
		
		rp_ClientMoney(client, i_Money, -tax);
		rp_ClientGiveItem(client, itemID, -quantity);
		rp_IncrementSuccess(client, success_list_hdv);
		char szQuery[256], steamid[32];
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackCell(pack, itemID);
		WritePackCell(pack, quantity);
		WritePackCell(pack, tax);
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_trade`(`steamid`, `itemID`, `amount`, `price`, `time`) VALUES ('%s', '%d', '%d', '%d', '%d')", steamid, itemID, quantity, sellPrice/quantity, GetTime());
		SQL_TQuery(rp_GetDatabase(), SQL_DepositCB, szQuery, pack);
		delete menu;
		return;
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}
void HDV_Buy(int client, int jobID, int itemID, int transactID, int confirm, int dataQte, int dataPrix) {
	
	char tmp[32];
	Menu menu = CreateMenu(Handler_MainHDV);

	if( jobID == 0 ) {
		
		char szQuery[256];
		Format(szQuery, sizeof(szQuery), "SELECT COUNT(`itemID`), `job_id` FROM `rp_trade` T INNER JOIN `rp_items` I ON T.`itemID`=I.`id` WHERE T.`done`=0 GROUP BY `job_id` ORDER BY `job_id`");
		SQL_TQuery(rp_GetDatabase(), SQL_ListJobCB, szQuery, client);
		delete menu;
		return;
		
	}
	else if(itemID == 0){
		
		char szQuery[256];
		Format(szQuery, sizeof(szQuery), "SELECT COUNT(`itemID`), `itemID` FROM `rp_trade` T INNER JOIN `rp_items` I ON T.`itemID`=I.`id` WHERE I.`job_id`=%d AND T.`done`=0  GROUP BY `itemID`", jobID);
		SQL_TQuery(rp_GetDatabase(), SQL_ListJobItemsCB, szQuery, client);
		delete menu;
		return;
		
	}
	else if(transactID == 0){
		
		char szQuery[256];
		Format(szQuery, sizeof(szQuery), "SELECT `id`, `itemID`, `amount`, `price` FROM `rp_trade` WHERE `done`=0 AND `itemID`=%d ORDER BY (`price`/`amount`)", itemID);
		SQL_TQuery(rp_GetDatabase(), SQL_ListItemsCB, szQuery, client);
		delete menu;
		return;
		
	}
	else if(confirm == 0){
		
		rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
		menu.SetTitle("Hotel des ventes: Acheter\nVous allez acheter\n%d %s pour %d$?\n \nConfirmez-vous ?\n ", dataQte, tmp, dataPrix);
		menu.AddItem("buy", "Non, j'annule mon achat");
		Format(tmp, sizeof(tmp), "buy -1 %d %d 1 %d %d", itemID, transactID, dataQte, dataPrix);
		if(rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank) < dataPrix )
			menu.AddItem(tmp, "N'y pense même pas, tu es fauché !", ITEMDRAW_DISABLED);
		else
			menu.AddItem(tmp, "Oui, j'accepte");
			
	}
	else{
		
		if(rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank) < dataPrix ){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas assez d'argent'.");
			delete menu;
			return;
		}
		char szQuery[256], steamid[32];
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackCell(pack, itemID);
		WritePackCell(pack, transactID);
		WritePackCell(pack, dataQte);
		WritePackCell(pack, dataPrix);
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		Format(szQuery, sizeof(szQuery), "UPDATE `rp_trade` SET `time`=UNIX_TIMESTAMP(), `done`=1, `boughtBy`='%s' WHERE `id`=%d AND `done`=0", steamid, transactID);
		SQL_TQuery(rp_GetDatabase(), SQL_AchatCB, szQuery, pack);
		delete menu;
		return;
		
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

void HDV_History(int client, int action, int cancelID, int confirm, int dataAmount, int dataPrice, int dataItemID) {
	char tmp[32];
	if(action == 0){
		Menu menu = CreateMenu(Handler_MainHDV);
		menu.SetTitle("Hotel des ventes: Historique\n ");
		menu.AddItem("history 1", "Ventes en cours");
		menu.AddItem("history 2", "Historique des achats");
		menu.AddItem("history 3", "Historique des ventes");
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(cancelID == 0){
		char szQuery[256];
		GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp));
		if(action == 1)
			Format(szQuery, sizeof(szQuery), "SELECT `id`, `itemID`, `amount`, `price`, `time` FROM `rp_trade` WHERE `done`=0 AND `steamid`='%s' ORDER BY `time`", tmp);
		else if(action == 2)
			Format(szQuery, sizeof(szQuery), "SELECT `id`, `itemID`, `amount`, `price`, `time` FROM `rp_trade` WHERE `done`=1 AND `boughtBy`='%s' ORDER BY `time` DESC LIMIT 50", tmp);
		else
			Format(szQuery, sizeof(szQuery), "SELECT `id`, `itemID`, `amount`, `price`, `time` FROM `rp_trade` WHERE `done`=1 AND `steamid`='%s' ORDER BY `time` DESC LIMIT 50", tmp);
			
		int data = client + action*1000;
		SQL_TQuery(rp_GetDatabase(), SQL_HistoryCB, szQuery, data);
	}
	else if(confirm == 0){
		rp_GetItemData(dataItemID, item_type_name, tmp, sizeof(tmp));
		Menu menu = CreateMenu(Handler_MainHDV);
		menu.SetTitle("Hotel des ventes: Historique\nVous allez annuler la vente de \n%d %s pour %d$?\n \nConfirmez-vous ?\n(La taxe de mise en vente ne vous sera pas réstituée)\n ", dataAmount, tmp, dataAmount*dataPrice);
		menu.AddItem("history", "Non, j'annule mon achat");
		Format(tmp, sizeof(tmp), "history 1 %d 1 %d %d %d", cancelID, dataAmount, dataPrice, dataItemID);
		menu.AddItem(tmp, "Oui, j'accepte");
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else{
		char szQuery[128];
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackCell(pack, dataItemID);
		WritePackCell(pack, dataAmount);
		Format(szQuery, sizeof(szQuery), "DELETE FROM `rp_trade` WHERE `id`=%d AND `done`=0", cancelID);
		SQL_TQuery(rp_GetDatabase(), SQL_CancelCB, szQuery, pack);
	}
}
public int Handler_MainHDV(Handle hItem, MenuAction oAction, int client, int param) {
	if (oAction == MenuAction_Select) {
		char options[128], exploded[8][32];
		GetMenuItem(hItem, param, options, sizeof(options));
		
		ExplodeString(options, " ", exploded, sizeof(exploded), sizeof(exploded[]));
		
		if( StrContains(options, "sell") == 0 ) {
			HDV_Sell(client, StringToInt(exploded[1]), StringToInt(exploded[2]), StringToInt(exploded[3]), StringToInt(exploded[4]));
		}
		else if( StrContains(options, "buy") == 0 ) {
			HDV_Buy(client, StringToInt(exploded[1]), StringToInt(exploded[2]), StringToInt(exploded[3]), StringToInt(exploded[4]), StringToInt(exploded[5]), StringToInt(exploded[6]));
		}
		else if( StrContains(options, "history") == 0 ) {
			HDV_History(client, StringToInt(exploded[1]), StringToInt(exploded[2]), StringToInt(exploded[3]), StringToInt(exploded[4]), StringToInt(exploded[5]), StringToInt(exploded[6]));
		}
	}
	else if (oAction == MenuAction_End ) {
		CloseHandle(hItem);
	}
}

public void SQL_DepositCB(Handle owner, Handle handle, const char[] error, any data) {
	if( strlen(error) >= 1  ) {
		ResetPack(data);
		int client, itemID ,quantity ,tax;
		client = ReadPackCell(data);
		itemID = ReadPackCell(data);
		quantity = ReadPackCell(data);
		tax = ReadPackCell(data);
		
		rp_ClientMoney(client, i_Bank, tax);
		rp_ClientGiveItem(client, itemID, quantity);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Une erreur s'est produite lors de la mise en vente, vos objets ainsi que la taxe de mise en vente vous ont été restitués.");
		LogError("[SQL] [ERROR] %s - HDVDeposit", error);
		return;
	}
}

public void SQL_ListJobCB(Handle owner, Handle row, const char[] error, any client) {
	if( strlen(error) >= 1  ) {
		LogError("[SQL] [ERROR] %s", error);
		return;
	}
	char tmp[64], tmp2[64], tmp3[2][32];
	int jobID;
	if(row != INVALID_HANDLE){
		Menu menu = CreateMenu(Handler_MainHDV);
		menu.SetTitle("Hotel des ventes: Acheter\n ");
		while( SQL_FetchRow(row) ) {
			jobID = SQL_FetchInt(row, 1);
			if( jobID == 0 )
				continue;
			
			rp_GetJobData(jobID, job_type_name, tmp2, sizeof(tmp2));
			ExplodeString(tmp2, "-", tmp3, sizeof(tmp3), sizeof(tmp3[]));
			
			Format(tmp, sizeof(tmp), "buy %d", jobID);
			Format(tmp2, sizeof(tmp2), "%s (%d lots)", tmp3[1], SQL_FetchInt(row, 0));
			menu.AddItem(tmp, tmp2);
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else{
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Aucun objet ne peut être acheté pour le moment.");
		return;
	}
}
public void SQL_ListJobItemsCB(Handle owner, Handle row, const char[] error, any client) {
	if( strlen(error) >= 1  ) {
		LogError("[SQL] [ERROR] %s", error);
		return;
	}
	char tmp[64], tmp2[64];
	int itemID;
	if(row != INVALID_HANDLE){
		Menu menu = CreateMenu(Handler_MainHDV);
		menu.SetTitle("Hotel des ventes: Acheter\n ");
		while( SQL_FetchRow(row) ) {
			itemID = SQL_FetchInt(row, 1);
			rp_GetItemData(itemID, item_type_name, tmp2, sizeof(tmp2));
			Format(tmp, sizeof(tmp), "buy -1 %d", itemID);
			Format(tmp2, sizeof(tmp2), "%s (%d lots)", tmp2, SQL_FetchInt(row, 0));
			menu.AddItem(tmp, tmp2);
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else{
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Aucun objet n'est en vente pour ce job.");
		return;
	}
}

public void SQL_ListItemsCB(Handle owner, Handle row, const char[] error, any client) {
	if( strlen(error) >= 1  ) {
		LogError("[SQL] [ERROR] %s", error);
		return;
	}
	char tmp[64], tmp2[64];
	int transactID, itemID, amount, price;
	if(row != INVALID_HANDLE){
		Menu menu = CreateMenu(Handler_MainHDV);
		while( SQL_FetchRow(row) ) {
			transactID = SQL_FetchInt(row, 0);
			itemID = SQL_FetchInt(row, 1);
			amount = SQL_FetchInt(row, 2);
			price = SQL_FetchInt(row, 3);
			Format(tmp, sizeof(tmp), "buy -1 %d %d 0 %d %d", itemID, transactID, amount, price*amount);
			Format(tmp2, sizeof(tmp2), "%d unités pour %d$ (%d$/unité)", amount, price*amount, price);
			menu.AddItem(tmp, tmp2);
		}
		rp_GetItemData(itemID, item_type_name, tmp2, sizeof(tmp2));
		Format(tmp2, sizeof(tmp2), "Acheter %s", tmp2);
		menu.SetTitle(tmp2);
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else{
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Tous les objets ont déjà été achetés.");
		return;
	}
}

public void SQL_AchatCB(Handle owner, Handle handle, const char[] error, any data) {
	ResetPack(data);
	int client = ReadPackCell(data);
	int itemID = ReadPackCell(data);
	int transactID = ReadPackCell(data);
	int dataQte = ReadPackCell(data);
	int dataPrix = ReadPackCell(data);
	if( strlen(error) >= 1  ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Une erreur s'est produite lors de l'achat, l'argent ne vous a pas été retiré.");
		LogError("[SQL] [ERROR] %s - HDVAchat", error);
		return;
	}
	if(SQL_GetAffectedRows(handle) == 0){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce lot n'est plus en vente, l'argent ne vous a pas été retiré.");
		return;
	}
	char szQuery[256], tmp[64];
	rp_ClientGiveItem(client, itemID, dataQte);
	rp_ClientMoney(client, i_Money, -dataPrix);
	Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_users2`(`steamid`, `bank`, `pseudo`) VALUES ((SELECT `steamid` FROM `rp_trade` WHERE `id`=%d), %d, 'vente HDV')", transactID, dataPrix);
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
	rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez acheté %d %s à %d$.", dataQte, tmp, dataPrix);
}

public void SQL_HistoryCB(Handle owner, Handle row, const char[] error, any data) {
	int client = data%1000;
	data = (data-client)/1000;
	if( strlen(error) >= 1  ) {
		LogError("[SQL] [ERROR] %s", error);
		return;
	}
	char tmp[64],tmp2[128];
	int transactID, itemID, amount, price;
	if(row != INVALID_HANDLE){
		Menu menu = CreateMenu(Handler_MainHDV);
		while( SQL_FetchRow(row) ) {
			transactID = SQL_FetchInt(row, 0);
			itemID = SQL_FetchInt(row, 1);
			rp_GetItemData(itemID, item_type_name, tmp2, sizeof(tmp2));
			amount = SQL_FetchInt(row, 2);
			price = SQL_FetchInt(row, 3);
			FormatTime(tmp, sizeof(tmp), "%d/%m", SQL_FetchInt(row, 4));
			Format(tmp2, sizeof(tmp2), "Le %s: %d %s à %d$ (%d$/unité)", tmp, amount, tmp2, price*amount, price);
			Format(tmp, sizeof(tmp), "history 1 %d 0 %d %d %d", transactID, amount, price, itemID);
			if(data == 1)
				menu.AddItem(tmp, tmp2);
			else
				menu.AddItem(tmp, tmp2, ITEMDRAW_DISABLED);
		}
		if(data == 1)
			menu.SetTitle("Hôtel des ventes: Ventes en cours\n ");
		else if(data == 2)
			menu.SetTitle("Hôtel des ventes: Historique des achats\n ");
		else
			menu.SetTitle("Hôtel des ventes: Historique des ventes\n ");
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else{
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Pas de transactions récentes.");
		return;
	}
}

public void SQL_CancelCB(Handle owner, Handle handle, const char[] error, any data) {
	ResetPack(data);
	int client = ReadPackCell(data);
	int itemID = ReadPackCell(data);
	int dataQte = ReadPackCell(data);
	if( strlen(error) >= 1  ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Une erreur s'est produite lors de l'annulation.");
		LogError("[SQL] [ERROR] %s - HDVAchat", error);
		return;
	}
	if(SQL_GetAffectedRows(handle) == 0){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce lot à déjà été acheté, il est impossible d'annuler la vente.");
		return;
	}
	char tmp[64];
	rp_ClientGiveItem(client, itemID, dataQte);
	rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez récupéré vos %d %s.", dataQte, tmp);
}
