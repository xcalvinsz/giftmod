//GiftMode include file

#if defined _gift_included
 #endinput
#endif
#define _gift_included

/**
 * Gets the total amount of good abilities available
 * @return		Int - total number of good abilities available
 */
native Gift_TotalGood();

/**
 * Gets the total amount of bad abilities available
 * @return		Int - total number of bad abilities available
 */
native Gift_TotalBad();

/**
 * Removes all active abilities on client	
 */
native Gift_Remove();

/**
 * Checks if client has an active effect
 * @return		true - Player has active effect
				false - Player has no active effect
 */
native bool:Gift_Active(client);

/**
 * Enables Godmode on client
 * @input		client id
 */
native Gift_Godmode(client, Float:duration);

/**
 * Enables Toxic on client
 * @input		client id
 */
native Gift_Toxic(client, Float:duration);

/**
 * Enables Gravity on client
 * @input		client id
 */
native Gift_Gravity(client, Float:duration);

/**
 * Enables Jarate Swimming on client
 * @input		client id
 */
native Gift_Swimming(client, Float:duration);

/**
 * Enables Bumper cars on client
 * @input		client id
 */
native Gift_Bumper(client, Float:duration);

/**
 * Enables Scary bullets on client
 * @input		client id
 */
native Gift_Scary(client, Float:duration);

/**
 * Enables Knockers on client
 * @input		client id
 */
native Gift_Knockers(client, Float:duration);

/**
 * Enables Incendiary ammo on client
 * @input		client id
 */
native Gift_Incendiary(client, Float:duration);

/**
 * Enables speed on client
 * @input		client id
 */
native Gift_Speed(client, Float:duration);

/**
 * Enables jump on client
 * @input		client id
 */
native Gift_Jump(client, Float:duration);

/**
 * Freezes a client
 * @input		client id
 */
native Gift_Freeze(client, Float:duration);

/**
 * Force taunt on client
 * @input		client id
 */
native Gift_Taunt(client, Float:duration);

/**
 * Force blind on client
 * @input		client id
 */
native Gift_Blind(client, Float:duration);

/**
 * Force OneHP on client
 * @input		client id
 */
native Gift_OneHP(client);

/**
 * Force explode on client
 * @input		client id
 */
native Gift_Explode(client);

/**
 * Force nostalgia on client
 * @input		client id
 */
native Gift_Nostalgia(client, Float:duration);

/**
 * Force drug on client
 * @input		client id
 */
native Gift_Drug(client, Float:duration);

/**
 * Force brain dead on client
 * @input		client id

 */
native Gift_BrainDead(client, Float:duration);

/**
 * Force melee only on client
 * @input		client id
 */
native Gift_Melee(client);

/**
 * Force snail on client
 * @input		client id
 */
native Gift_Snail(client, Float:duration);

/**
 * Spawns a gift at position
 * @input		Float:pos_x, pos_y, pos_z
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Spawn(client, Float:posx, Float:posy, Float:posz);

