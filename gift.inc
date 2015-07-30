//GiftMode include file

#if defined _gift_included
 #endinput
#endif
#define _gift_included

/**
 * Gets the total amount of abilities available
 * @return		Int - total number of abilities available
 */
native Gift_Total();

/**
 * Returns the duration of effects
 * @return		float - Seconds how long effect last
 */
native Float:Gift_Duration();

/**
 * Checks whether player has active ability
 * @return		false - Player has no active ability
				true - Player has active ability
 */
native bool:Gift_Active(client);

/**
 * Enables Godmode on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Godmode(client);

/**
 * Enables Toxic on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Toxic(client);

/**
 * Enables Gravity on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Gravity(client);

/**
 * Enables Jarate Swimming on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Swimming(client);

/**
 * Enables Bumper cars on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Bumper(client);

/**
 * Enables Scary bullets on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Scary(client);

/**
 * Enables Scary bullets on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Knockers(client);

/**
 * Enables Scary bullets on client
 * @input		client id
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Incendiary(client);

/**
 * Spawns a gift at position
 * @input		Float:pos_x, pos_y, pos_z
 * @return		true - Action was successful
				false - Action was unsuccessful
 */
native bool:Gift_Spawn(posx, posy, posz);

