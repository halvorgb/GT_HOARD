class Hoard_Player
{
  // has the player already spawned?
  bool isSpawned;

  // is the player currently racing?
  String state;

  // the time the player joined
  uint joinedTime;

  // the player's best race
  uint bestRaceTime;
  
  // the halfwaytime from the best race! (not the best halfway time)
  // uint bestHalfwayTime;

  // number of attempts on the current map in current session
  uint tries;

  // Racing time
  uint racingTime;
  
  // Distance?
  uint64 distance;

  // old position
  Vec3 oldPosition;

  // current session speed record
  int highestSpeed;

  // the client corresponding to the player
  cClient @client;

  // the current race and the previous
  Hoard_Player_Race @race;
  Hoard_Player_Race @lastRace;

  // variables for the position function
  bool positionSaved;
  Vec3 positionOrigin;
  Vec3 positionAngles;
  uint positionLastCmd;



  int itemCount; // total number of items on the map
  array<bool> itemsVisited; // an array of bools, each corresponding to an item number.
  int itemsVisitedCount; // this counts how many items that have been visited, to 
  
bool hasReachedHalfwayPoint; // whether or not the player has reached halfway point, if you want to expand to more than one checkpoint use arrays!




  // for spamfilter
  int lastItemReceived;
  uint lastItemTime;
  
  

  // constructor
  Hoard_Player()
  {
  }

  // destructor
  ~Hoard_Player()
  {
  }
  
  void Initialize()
  {
    // did this happen?
    this.isSpawned = true;
    this.bestRaceTime = 0;
    this.positionSaved = false;
    this.tries = 0;
    this.racingTime = 0;
    this.highestSpeed = 0;
    this.state = "";
    
    this.lastItemReceived = -1;
    this.lastItemTime = 0;
    
    this.itemCount = getItemCount();

    this.itemsVisited = array<bool>(this.itemCount);
    this.itemsVisitedCount = 0;
    this.hasReachedHalfwayPoint = false;
    falseArray();
    
    this.positionSaved = false;
    this.positionLastCmd = 0;

    
  }
  
  void falseArray()
  {
    for(int i = 0; i < this.itemCount; i++)
      {
	this.itemsVisited[i] = false;
      }
  }
  
  void appear()
  {
    this.joinedTime = levelTime;
  }
  
  // Callback for a finished race
  void raceCallback(uint oldTime, uint oldBestTime, uint newTime)
  {
    uint bestTime;
    uint oldServerBestTime;
    
    //bestTime = oldTime;
    bestTime = oldBestTime;
    oldServerBestTime = map.getHighScore().getTime();
    this.sendAward( S_COLOR_CYAN + "Hoarding Complete!" );
    
    // wut
    bool noDelta = (0 == bestTime);
    
    if ( @this.getClient() != null )
      {
	G_CenterPrintMsg( this.getClient().getEnt(),
			  "Time: " + TimeToString( newTime ) + "\n"
			  + (noDelta ? "" : diffString( oldServerBestTime, newTime ) ) );
	
	this.sendMessage(S_COLOR_WHITE + "Hoarding " + S_COLOR_ORANGE + "#"
			 + this.tries + S_COLOR_WHITE + " finished: "
			 + TimeToString( newTime )
			 + S_COLOR_ORANGE + " Distance: " + S_COLOR_WHITE + ((this.lastRace.stopDistance - this.lastRace.startDistance)/1000) // racing distance
			 + S_COLOR_ORANGE + " Personal: " + S_COLOR_WHITE + diffString(bestTime, newTime) // personal best
			 + S_COLOR_ORANGE + "/Server: " + S_COLOR_WHITE + diffString(oldServerBestTime, newTime) // server best
			 + "\n");
      }
    
    // personal record
    if ( oldBestTime == 0 || newTime < oldBestTime )
      {
	this.setBestTime(newTime);
	this.sendAward( "Personal Record!");
      }
    // server record
    if ( oldServerBestTime == 0 || newTime < oldServerBestTime )
      {
	map.getHighScore().fromRace(this.lastRace);
	this.sendAward( S_COLOR_GREEN + "New server record!" ) ;
	G_PrintMsg(null, this.getName() + " " 
		   + S_COLOR_YELLOW + "made a new server record: "
		   + TimeToString( newTime ) + "\n" );
      }


    
    
  }

  void setLastRace(Hoard_Player_Race @race)
  {
    @this.lastRace = @race;
  }

  // set player's client
  Hoard_Player @setClient( cClient @client )
  {
    @this.client = @client;

    return @this;
  }
  
  // get player's client
  cClient @getClient()
  {
    return @this.client;
  }

  // get the player's best time
  uint getBestTime()
  {
    return this.bestRaceTime;
  }
  
  // set the players best time
  void setBestTime(uint time)
  {
    this.bestRaceTime = time;
  }

  // get player name
  String getName()
  {
    if (@this.client != null)
      {
	return this.client.name;
      }
    return "";
  }

  // should be called whenever the player is spawned
  void onSpawn()
  {
    this.isSpawned = true;
  }

  // check whether or not the player is currently racing
  bool isRacing()
  {
    if (@this.race == null)
      return false;
    return this.race.inRace();
  }

  // get the player's current speed
  int getSpeed()
  {
    Vec3 globalSpeed = this.getClient().getEnt().velocity;
    Vec3 horizontalSpeed = Vec3(globalSpeed.x, globalSpeed.y, 0);
    
    return horizontalSpeed.length();
  }

  // get the state of the player
  String getState()
  {
    if ( this.isRacing() )
      this.state = "^2racing";
    else
      this.state = "^3prerace";
    return this.state;
  }


  // this is called through the spamFilter method, if the player touches an item.
  void touchItem(int itemNum, cEntity @ent)
  {
    
    if( !this.isSpawned )
      return;

    // if the player is already in a race(has started) simply add the item to the array and check whether or not the player has collected all the items.
    if ( this.isRacing() )
      {
	if (visitItem(itemNum, @ent))
	    raceFinished();
	return;
      }
	

    // This is the first item touched - > start race
    // everything following in this method is for starting a race

    // BUT! Not if the player has prejumped (here meaning over DASH_SPEED 499)
    if (getSpeed() > 500)
      {
	this.sendAward(S_COLOR_RED + "Prejumped!");
	return;
      }
    
    // initialize array to all false

    falseArray();
    this.itemsVisitedCount = 0;

    
    @this.race = @Hoard_Player_Race();
    this.race.setPlayer(@this);
    this.race.start();
    this.tries++;

    // Motivation!
    sendAward(S_COLOR_WHITE + "Collect all the items!");

    // visit the first item
    visitItem(itemNum, @ent);
    

    
  }

  // Called by touchItem, this marks the item as visited and if all items have been visited it will return true.
  bool visitItem(int itemNum, cEntity @speaker)
  {      
    if (this.itemsVisited[itemNum] == true)
      return false;
    
    
        



    // play pickup sound!
    G_LocalSound( client, CHAN_ITEM, G_SoundIndex(speaker.item.pickupSound));

    // make the item disappear!
    hideItem((client.get_playerNum()), itemNum, this.client.getEnt());



    this.itemsVisited[itemNum] = true;
    this.itemsVisitedCount++;

    // check whether or not the player has just reached the halfway point!
    if (this.hasReachedHalfwayPoint == false)
     if (this.itemsVisitedCount >= (this.itemCount / 2))
	{
	  this.hasReachedHalfwayPoint = true;
	  
	}
    
    // if race is finished!
    if (this.itemsVisitedCount == this.itemCount)
      return true;
    return false;

  }

  void raceFinished()
  {
    this.race.stop();
    
    uint oldtime;
    if (@lastRace == null)
      oldtime = 0;
    else
      oldtime = lastRace.getTime();
    this.setLastRace(@this.race);

    uint newTime = this.race.getTime();

    // record..?
    //if (this.bestRaceTime == 0 || newTime / 100 < this.bestRaceTime )
    if (this.bestRaceTime == 0 || newTime < this.bestRaceTime )
      this.getClient().stats.setScore(this.race.getTime()/100);
    
    // - wrong, commented out.
    // this.isSpawned = false;
    this.racingTime += this.race.getTime();
    
    @this.race = null;
   
    
    // print shit
    raceCallback(oldtime, this.bestRaceTime, newTime);


    // respawn all the items that were hidden!
    resetArray(client.get_playerNum(), this.client.getEnt());
   
  }

  void restartRace()
  {
    if ( @this.client != null ) 
      {
	this.client.team = TEAM_PLAYERS;
	this.client.respawn( false );
      }
  }

  void restartingRace()
  {
;
    
    // reset spam filter!
    this.lastItemReceived = -1;
    this.lastItemTime = 0;

    this.itemsVisitedCount = 0;
    this.hasReachedHalfwayPoint = false;
    
    this.isSpawned = true;
    if (this.isRacing() )
	this.racingTime += this.race.getCurrentTime();
    
    @this.race = null;

    // respawn all the items that were hidden!
    resetArray(client.get_playerNum(), this.client.getEnt());
  }
  
  void cancelRace()
  {
    @this.race = null;
  }
  
  // advance distance, called once per frame.
  void advanceDistance()
  {
    Vec3 position = this.getClient().getEnt().origin;
    position.z = 0;
    this.distance += (position.distance(this.oldPosition ) * 1000 );
    this.oldPosition = position;
  }
  
  void sendMessage( String message )
  {
    if (@this.client == null)
      return;
    
    G_PrintMsg( this.client.getEnt(), message );
  }
  
  void sendAward ( String message )
  {
    if (@this.client == null)
      return;
    this.client.execGameCommand("aw \"" + message + "\"" );
    
    // show the award to all spectators following hte player...
    cTeam @spectators = @G_GetTeam( TEAM_SPECTATOR );
    cEntity @other;
    for ( int i = 0; @spectators.ent(i) != null; i++ )
      {
	@other = @spectators.ent(i);
	if (@other.client != null && other.client.chaseActive )
	  {
	    if (other.client.chaseTarget == this.client.playerNum + 1 )
	      other.client.execGameCommand( "aw \"" + message + "\"" );
	  }
      }
  }
  

  //send a message to another player's console
  // probably not needed.
  void sendMessage( String message, cClient @client )
  {
    G_PrintMsg( client.getEnt(), message );
  }

  // item number, entity for the sound effect
  void spamFilterOnInput(int item, cEntity @ent)
  {
    uint TIMEBUFFER_DOOM = 2000; //milliseconds???
    if (this.lastItemReceived != item)
      {
	this.lastItemTime = levelTime;
	this.lastItemReceived = item;
	touchItem(item, @ent);
	return;
      }
    if (levelTime > (this.lastItemTime + TIMEBUFFER_DOOM))
      {
	this.lastItemTime = levelTime;
	touchItem(item, ent);
	return;
      }
      
    return;      
  }


  //bool teleport( cVec3 origin, cVec3 angles, bool keepVelocity, bool kill )
  bool teleport()
  {
    Vec3 origin = this.positionOrigin;
    Vec3 angles = this.positionAngles;
    bool kill = false;
    bool keepVelocity = false;
    
    cEntity@ ent = @this.client.getEnt();
    if( @ent == null )
      return false;

    if( ent.team != TEAM_SPECTATOR )
      ent.teleportEffect( false );
    
    if(!keepVelocity)
      ent.set_velocity( Vec3(0,0,0) );
    ent.set_origin( origin );
    ent.set_angles( angles );
    if( ent.team != TEAM_SPECTATOR )
      ent.teleportEffect( false );
    return true;
  }

  bool positionSave()
  {
    if(this.positionLastCmd != 0)
      {
	if (levelTime < (this.positionLastCmd + 500))
	  return false;
      }
    this.positionLastCmd = levelTime;

    cEntity @ent = @this.client.getEnt();
    if (@ent == null)
      return false;
    this.positionOrigin = ent.get_origin();
    this.positionAngles = ent.get_angles();
    this.positionSaved = true;

    return true;
    
  }
  bool getPositionSaved()
  {
    return this.positionSaved;
  }
  
}
