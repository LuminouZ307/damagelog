#include <a_samp>

#define             MAX_LISTED_DAMAGE           55
#define 			INVALID_DAMAGE_ID			-1

#define             BODY_PART_TORSO             (3)
#define             BODY_PART_GROIN             (4)
#define             BODY_PART_LEFT_ARM          (5)
#define             BODY_PART_RIGHT_ARM         (6)
#define             BODY_PART_LEFT_LEG          (7)
#define             BODY_PART_RIGHT_LEG         (8)
#define             BODY_PART_HEAD              (9)


main() 
{

}

enum E_DAMAGE_DATA {
    bool:DAMAGE_EXISTS,
    DAMAGE_ID,
    DAMAGE_WEAPONID,
    DAMAGE_TIME,
    DAMAGE_BODYPART,
    DAMAGE_ISSUER,
    DAMAGE_AMOUNT
};
new
    DamageData[MAX_PLAYERS][MAX_LISTED_DAMAGE][E_DAMAGE_DATA];


ReturnDuration(time)
{
	new
	    str[32];

	if (time < 0 || time == gettime()) {
	    format(str, sizeof(str), "Never");
	    return str;
	}
	else if (time < 60)
		format(str, sizeof(str), "%d seconds", time);

	else if (time >= 0 && time < 60)
		format(str, sizeof(str), "%d seconds", time);

	else if (time >= 60 && time < 3600)
		format(str, sizeof(str), (time >= 120) ? ("%d minutes") : ("%d minute"), time / 60);

	else if (time >= 3600 && time < 86400)
		format(str, sizeof(str), (time >= 7200) ? ("%d hours") : ("%d hour"), time / 3600);

	else if (time >= 86400 && time < 2592000)
 		format(str, sizeof(str), (time >= 172800) ? ("%d days") : ("%d day"), time / 86400);

	else if (time >= 2592000 && time < 31536000)
 		format(str, sizeof(str), (time >= 5184000) ? ("%d months") : ("%d month"), time / 2592000);

	else if (time >= 31536000)
		format(str, sizeof(str), (time >= 63072000) ? ("%d years") : ("%d year"), time / 31536000);

	strcat(str, " ago");

	return str;
}

GetDamageFreeID(playerid) {
    new index = INVALID_DAMAGE_ID;
    for(new i = 0; i < MAX_LISTED_DAMAGE; i++) if(!DamageData[playerid][i][DAMAGE_EXISTS]) {
        index = i;
        break;
    }
    return index;
}

GetSameDamageInfo(playerid, weaponid, bodypart) {

    new index = INVALID_DAMAGE_ID;
    for(new i = 0; i < MAX_LISTED_DAMAGE; i++) if(DamageData[playerid][i][DAMAGE_EXISTS]) {
        if(DamageData[playerid][i][DAMAGE_BODYPART] == bodypart && DamageData[playerid][i][DAMAGE_WEAPONID] == weaponid) {
            index  = i;
            break;
        }
    }
    return index;
}

AddDamageToPlayer(playerid, weaponid, bodypart) {

    new
        id = -1;

    if((id = GetSameDamageInfo(playerid, weaponid, bodypart)) != INVALID_DAMAGE_ID) {
        DamageData[playerid][id][DAMAGE_AMOUNT]++;
        DamageData[playerid][id][DAMAGE_TIME] = gettime();
        // Update the damagelog.

    }
    else {
        if((id = GetDamageFreeID(playerid)) != INVALID_DAMAGE_ID) {

            DamageData[playerid][id][DAMAGE_WEAPONID] = weaponid;
            DamageData[playerid][id][DAMAGE_AMOUNT]++;
            DamageData[playerid][id][DAMAGE_BODYPART] = bodypart;
            DamageData[playerid][id][DAMAGE_TIME] = gettime();
            DamageData[playerid][id][DAMAGE_EXISTS] = true;

            // Issue new damagelog.
        }
		else {
			printf("[err damagelog] unable to issue new damagelog to player %d.", playerid);
		}
    }

    return 1;
}

ResetPlayerDamage(playerid) {
    for(new i = 0; i < MAX_LISTED_DAMAGE; i++) {
        DamageData[playerid][i][DAMAGE_AMOUNT] = 0;
        DamageData[playerid][i][DAMAGE_BODYPART] = 0;
        DamageData[playerid][i][DAMAGE_EXISTS] = false;
        DamageData[playerid][i][DAMAGE_TIME] = 0;
    }
}

GetBodyPartName(bodypart)
{
    new body_part[11];
    switch(bodypart)
    {
        case BODY_PART_TORSO: body_part = "Torso";
        case BODY_PART_GROIN: body_part = "Groin";
        case BODY_PART_LEFT_ARM: body_part = "Left Arm";
        case BODY_PART_RIGHT_ARM: body_part = "Right Arm";
        case BODY_PART_LEFT_LEG: body_part = "Left Leg";
        case BODY_PART_RIGHT_LEG: body_part = "Right Leg";
        case BODY_PART_HEAD: body_part = "Head";
        default: body_part = "None";
    }
    return body_part;
}

CountPlayerDamage(playerid) {
    new count = 0;
    for(new i = 0; i < MAX_LISTED_DAMAGE; i++) if(DamageData[playerid][i][DAMAGE_EXISTS]) {
        count++;
    }
    return count;
}

ShowDamageToPlayer(playerid, show_to_id) {

    if(!IsPlayerConnected(playerid))
        return 0;

    if(!IsPlayerConnected(show_to_id))
        return 0;

    if(!CountPlayerDamage(playerid)) {
        return SendClientMessage(show_to_id, -1, "There is no damages to display...");
    }

    new string[1012], weapon_name[24];

    format(string, sizeof(string), "Weapon\tBullet(s)\tBodypart\tLast Updated\n");
    for(new i = 0; i < MAX_LISTED_DAMAGE; i++) if(DamageData[playerid][i][DAMAGE_EXISTS]) {

        GetWeaponName(DamageData[playerid][i][DAMAGE_WEAPONID], weapon_name, 24);

        format(string, sizeof(string), "%s%s\t%d bullet\t%s\t%s\n", 
            string, weapon_name, DamageData[playerid][i][DAMAGE_AMOUNT], GetBodyPartName(DamageData[playerid][i][DAMAGE_BODYPART]), ReturnDuration(gettime() - DamageData[playerid][i][DAMAGE_TIME]));
    }
    return ShowPlayerDialog(playerid, 1, DIALOG_STYLE_TABLIST_HEADERS, "Damagelog", string, "Ok", "");
}
public OnPlayerConnect(playerid) {
	ResetPlayerDamage(playerid);

	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart) {
    if(weaponid >= 22 && weaponid <= 38) {
        AddDamageToPlayer(playerid, weaponid, bodypart);
    }
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[]) {
    if(!strcmp(cmdtext, "/mydamages", true))
    {
        ShowDamageToPlayer(playerid, playerid);
        return 1;
    }
    return 0;
}