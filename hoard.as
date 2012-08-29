/*
* Hoard gametype by halvorg, heavily based on RACESOW's gametypes
*
* This file in particular is mostly built up of race.as and main.as with some modifications.
*/

Hoard_Player[] players( maxClients );
Hoard_Map @map;
String playerList;
String spectatorList;
uint scoreboardLastUpdate;
bool scoreboardUpdated = false;


void GT_InitGametype()
{
    gametype.title = "Hoard";
    
    gametype.version = "0.1a";
    gametype.author = "sjn|halvor  g";



    // if the gametype doesn't have a config file, create it
    if ( !G_FileExists( "configs/server/gametypes/hoard.cfg" ) )
    {
        String config;

        // the config file doesn't exist or it's empty, create it
        config = "//*\n"
               + "//* Race settings\n"
               + "//*\n"
               + "set g_scorelimit \"0\" // a new feature..?\n"
               + "set g_warmup_timelimit \"0\" // ... \n"
               + "set g_maxtimeouts \"0\" \n"
               + "set g_disable_vote_timeout \"1\" \n"
               + "set g_disable_vote_timein \"1\" \n"
               + "set g_disable_vote_scorelimit \"1\" \n"
               + "\n"
               + "echo race.cfg executed\n";

        G_WriteFile( "configs/server/gametypes/hoard.cfg", config );
        G_Print( "Created default base config file for hoard\n" );
        G_CmdExecute( "exec configs/server/gametypes/hoard.cfg silent" );
    }


    gametype.spawnableItemsMask = ( IT_WEAPON | IT_AMMO | IT_ARMOR | IT_POWERUP | IT_HEALTH );
    gametype.respawnableItemsMask = gametype.spawnableItemsMask;
    gametype.dropableItemsMask = 0;
    gametype.pickableItemsMask = 0;


    // COPIED FROM main.as, with changes where commented.
    gametype.isRace = true;

    gametype.ammoRespawn = 0;
    gametype.armorRespawn = 0;
    gametype.weaponRespawn = 0;
    gametype.healthRespawn = 0;
    gametype.powerupRespawn = 0;
    gametype.megahealthRespawn = 0;
    gametype.ultrahealthRespawn = 0;

    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = false;
    gametype.countdownEnabled = false;
    gametype.mathAbortDisabled = true;
    // no shooting in this GT
    gametype.shootingDisabled = true ;
    gametype.infiniteAmmo = true;
    gametype.canForceModels = true;
    gametype.canShowMinimap = true;
    gametype.teamOnlyMinimap = true;


    gametype.isTeamBased = false;
    gametype.hasChallengersQueue = false;
    gametype.maxPlayersPerTeam = 0;
    gametype.spawnpointRadius = 0;

    // TODO: DO IT FUCKER
    // gives an error, I dunno.
    // g_warmup_timelimit.set("0"); //g_warmup_enabled was removed in warsow 0.6

    // set spawnsystem type
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
      gametype.setTeamSpawnsystem( team, SPAWNSYSTEM_INSTANT, 0, 0, false );




    G_ConfigString( CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %t 96 %i 48 %l 48 %s 85" );
    G_ConfigString( CS_SCB_PLAYERTAB_TITLES, "Name Clan Time Speed Ping State" );


    G_RegisterCommand( "racerestart" );
    G_RegisterCommand( "position" );
    G_RegisterCommand( "help" );

    G_Print( "Gametype '" + gametype.title + "' initialized\n" );

}

void GT_SpawnGametype()
{

  // Initiate the map
  @map = Hoard_Map();

  // setup players
  for ( int i = 0; i < maxClients; i++ )
      players[i].Initialize();


  // replace all items on the map wiith new replacementItems, it works.
  for ( int i = 0; i <= numEntities; i++ )
    {
      cEntity @ent = @G_GetEntity(i);
      if (@ent == null)
	continue;
      if(ent.type == ET_ITEM)
        {
	  cItem @Item = @ent.item;
	  if( @Item != null && ent.classname == Item.classname )
            {
	      if( ( ent.solid != SOLID_NOT ) || ( ( @ent.findTargetingEntity( null ) != null ) && ( ent.findTargetingEntity( null ).classname != "target_give" ) ) ) //ok, not connected to target_give
                {
		  // : ))))
		  ent.classname = "AS_" + Item.classname;
		  replacementItem( @ent );
                }
            }
        }
    }
  
}

void GT_Shutdown()
{
  // FUK NO I'M NOT GONNA CLEAN UP AFTER MYSELF
  // TODO: DO IT
}

bool GT_MatchStateFinished( int incomingMatchState )
{
    if (incomingMatchState == MATCH_STATE_POSTMATCH)
    {
        return map.allowEndGame();
    }
    return true;
}

void GT_MatchStateStarted()
{
    switch ( match.getState() )
    {
    case MATCH_STATE_WARMUP:
        match.launchState( MATCH_STATE_PLAYTIME );
        break;

    case MATCH_STATE_COUNTDOWN:
        break;

    case MATCH_STATE_PLAYTIME:
        map.setUpMatch();
        break; 

    case MATCH_STATE_POSTMATCH:
        GENERIC_SetUpEndMatch();
        break;

    default:
        break;
    }
}

void GT_ThinkRules()
{

  // -- main.as

  // needs to be always executed, because overtime occurs even in time-unlimited mode
  map.allowEndGame();

  // set all clients race stats
  for ( int i = 0; i < maxClients; i++ )
    {
      cClient @c = @G_GetClient( i );

      if ( c.state() < CS_SPAWNED )
	continue;


      Hoard_Player @player = @Racesow_GetPlayerByClient( c );
      
      player.advanceDistance();


		
	
      if( scoreboardUpdated)//send the scoreboard to the player
	{
	  String command = "scb \""
	    + playerList + " "
	    + "&s " + spectatorList + "\"";
	  c.execGameCommand( command );
	}

	
      // always clear all before setting
      c.setHUDStat( STAT_PROGRESS_SELF, 0 );
      c.setHUDStat( STAT_PROGRESS_OTHER, 0 );
      c.setHUDStat( STAT_IMAGE_SELF, 0 );
      c.setHUDStat( STAT_IMAGE_OTHER, 0 );
      c.setHUDStat( STAT_PROGRESS_ALPHA, 0 );
      c.setHUDStat( STAT_PROGRESS_BETA, 0 );
      c.setHUDStat( STAT_IMAGE_ALPHA, 0 );
      c.setHUDStat( STAT_IMAGE_BETA, 0 );
      c.setHUDStat( STAT_MESSAGE_SELF, 0 );
      c.setHUDStat( STAT_MESSAGE_OTHER, 0 );
      c.setHUDStat( STAT_MESSAGE_ALPHA, 0 );
      c.setHUDStat( STAT_MESSAGE_BETA, 0 );

    }



  // -- race.as 

  
  // set all clients race stats
  for ( int i = 0; i < maxClients; i++ )
    {
      cClient @d = @G_GetClient( i );

      if ( d.state() < CS_SPAWNED )
	continue;

      Hoard_Player @player = @Racesow_GetPlayerByClient( d );

      if( ( player.client.team == TEAM_SPECTATOR ) && !( player.client.chaseActive ) )
	@player.race = null;

      if ( player.isRacing() )
        {
	  d.setHUDStat( STAT_TIME_SELF, player.race.getCurrentTime() / 100 );
	  if ( player.highestSpeed < player.getSpeed() )
	    player.highestSpeed = player.getSpeed(); // updating the heighestSpeed attribute.
        }

      d.setHUDStat( STAT_TIME_BEST, player.getBestTime() / 100 );
      d.setHUDStat( STAT_TIME_RECORD, map.getHighScore().getTime() / 100 );

    }
}

void GT_playerRespawn( cEntity @ent, int old_team, int new_team )
{
    // -- main.as

    Hoard_Player @player = @Racesow_GetPlayerByClient( ent.client );

    // -- race.as

    if ( ent.isGhosting() )
        return;

    
    // set player movement to pass through other players and remove gunblade auto attacking
    ent.client.setPMoveFeatures( ent.client.pmoveFeatures & ~PMFEAT_GUNBLADEAUTOATTACK | PMFEAT_GHOSTMOVE );

    // give gunblade, select gunblade (for crosshair)
    ent.client.inventorySetCount( WEAP_GUNBLADE, 1 );
    ent.client.selectWeapon(-1);
    
    player.getClient().stats.setScore(player.bestRaceTime);
    player.restartingRace();


    // -- main.as
    // - If used in racesow:
    //ent.client.setPMoveDashSpeed( 450 );

}

void GT_scoreEvent( cClient @client, String &score_event, String &args )
{
    // from main.as

    if( @client == null)
        return;
    Hoard_Player @player = @Racesow_GetPlayerByClient( client );
	if (@player != null )
	{
		if ( score_event == "dmg" )
		{
		}
		else if ( score_event == "kill" )
		{
		}
		else if ( score_event == "award" )
		{
		}
		else if ( score_event == "connect" )
		{
			player.Initialize();
					}
		else if ( score_event == "enterGame" )
		{
		  player.appear();
		  
		}
		else if ( score_event == "disconnect" )
		  {
		    player.Initialize();
		  }
	}
	
}

String @GT_ScoreboardMessage( uint maxlen )
{
  
  //-- from race.as
  String scoreboardMessage, entry;
  cTeam @team;
  cEntity @ent;
  int i, playerID;
  int racing;
  
  
  @team = @G_GetTeam( TEAM_PLAYERS );
  
  // &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
  entry = "&t " + int( TEAM_PLAYERS ) + " 0 " + team.ping + " ";
  if ( scoreboardMessage.len() + entry.len() < maxlen )
    scoreboardMessage += entry;
  
  // "Name Time Ping State"
  for ( i = 0; @team.ent( i ) != null; i++ )
    {
      @ent = @team.ent( i );
      Hoard_Player @player = @Racesow_GetPlayerByClient( ent.client );

      int playerID = ( ent.isGhosting() && ( match.getState() == MATCH_STATE_PLAYTIME ) ) ? -( ent.playerNum + 1 ) : ent.playerNum;
      
      entry = "&p " + playerID + " " + ent.client.clanName + " "
	+ player.getBestTime() + " "
	+ player.highestSpeed + " "
	+ ent.client.ping + " " + player.getState() + " ";
      if ( scoreboardMessage.len() + entry.len() < maxlen )
            scoreboardMessage += entry;
    }
  
  //-- from main.as
  //custom scoreboard for ppl who are getting spectated
  if( levelTime > scoreboardLastUpdate + 1800 )
    {
      
      cTeam @spectators = @G_GetTeam( TEAM_SPECTATOR );
      cEntity @other;
        spectatorList = "";
        for ( int i = 0; @spectators.ent( i ) != null; i++ )
        {
	  @other = @spectators.ent( i );
	  if ( @other.client != null )
            {
	      if( !other.client.connecting && other.client.state() >= CS_SPAWNED )
		//add all other spectators
                {
		  spectatorList += other.client.playerNum + " " + other.client.ping + " ";
                }
	      else if( other.client.connecting ) //add connecting spectators
                {
		  spectatorList += other.client.playerNum + " " + -1 + " ";
                }
            }
        }
      
        playerList = scoreboardMessage;
        scoreboardLastUpdate = levelTime;
    }
  
  scoreboardUpdated = true;
  return @scoreboardMessage;
  
}


cEntity @GT_SelectSpawnPoint( cEntity @self )
{
  Hoard_Player @player = @Racesow_GetPlayerByClient(self.client);
  player.onSpawn();
  return GENERIC_SelectBestRandomSpawnPoint(self, "info_player_deathmatch");
}

bool GT_UpdateBotStatus( cEntity @self )
{
  return false;
}

bool GT_Command( cClient @client, String &cmdString, String &argsString, int argc )
{ 
  // disallow these commands for spectators.
  if ((cmdString == "racerestart" || (cmdString == "position" && argsString == "save")) && client.team != TEAM_PLAYERS)
    return false;
  
  String response = "";
  if (cmdString == "racerestart")
    {
      
      Hoard_Player @player = @Racesow_GetPlayerByClient(client);
      
      if (@player == null)
	return false;
      
      // restart race.. (CHECK IF RACING FIRST????)
      // not needed, the function checks!
      player.restartingRace();
      // if position saved:
      if (player.getPositionSaved() == true)
	{
	  
	  if (player.teleport())
	    return true;
	  else
	    {
	      G_PrintMsg(client.getEnt(), "Flood Protection...\n");
	      return false;
	    }
	}
      else
	{
	  // KILL THE PLAYER!!
	  cEntity @ent = @client.getEnt();
	  if (@ent != null && ent.type == ET_PLAYER )
	    ent.sustainDamage(@ent, null, Vec3(0,0,0), 9999, 0, 0, MOD_TELEFRAG );
	  //G_PrintMsg(client.getEnt(), "not yet implemented\n");
	  return true;
	}
    }
  else if (cmdString == "position" && argsString == "save")
    {
      Hoard_Player @player = @Racesow_GetPlayerByClient(client);
      
      if (player.isSpawned && player.positionSave())
	{
	  response += "Position saved!";
	  G_PrintMsg (client.getEnt(), response);
	  return true;
	}
      else 
	{
	  // if this happens, where does the message get sent? :D
	  // better safe than sorry!
	  response += "ERROR: client entity == null";
	  G_PrintMsg (client.getEnt(), response);
	  return false;
	}
    }
  else if (cmdString == "help")
    
    {
      response += "\n";
      response += "Help for Gametype: Hoard\n";
      response += "The goal of this gametype is to collect all the items as fast as possible.\n";
      response += "\n";
      response += "Commands: \n";
      response += "racerestart - Ends your current race(if you are in one) and teleports you to a spawnpoint or a saved position\n";
      response += "position save - Saves your current position for respawning at a later time";
      G_PrintMsg (client.getEnt(), response);
      return true;
    }
  else
    {
      response += "\n";
      response += "Unrecognized command \"" + cmdString +  "\", try \"help\"\n"; 
      return false;
    }
}