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
  // halfway time of the best race.
  uint bestHalfwayTime;

  
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
  
  array<cEntity@> itemArray;
  
  // this is to circumvent redundant reassignements of SVF_Flags.
  bool allItemsVisible;
  int itemsVisited; 
  
  bool hasReachedHalfwayPoint; // whether or not the player has reached halfway point, if you want to expand to more than one checkpoint use arrays!


  // this is to prevent the player from automatically restarting the race upon finishing it.
  cEntity @finishingItem;
  uint finishHoardTime;
  uint finishHoardBuffer;


  Hoard_Player() {}

  // constructor
  Hoard_Player(int clientNumber)
  {
    this.isSpawned = true;
    this.bestRaceTime = 0;
    this.bestHalfwayTime = 0;
    this.positionSaved = false;
    this.tries = 0;
    this.racingTime = 0;
    this.highestSpeed = 0;
    this.state = "";
    this.positionSaved = false;
    this.positionLastCmd = 0;
    this.itemsVisited = 0;


    @this.client = @G_GetClient(clientNumber);
    this.itemArray = getItemsCopy();
    // set up touch, assign this.client to be the owner!
    touchOwnerArray();

    this.allItemsVisible = true;
    
    @this.finishingItem = null;
    this.finishHoardTime = 0;
    this.finishHoardBuffer = 2000;     
  }



  // destructor
  ~Hoard_Player() 
  {
  }
  
  // sets up ownership of entities, makes them visible to owner.
  // sets up touchListen for each entity.
  void touchOwnerArray()
  {
    for(int i = 0; i < itemCount; i++)
      {
	// set up ownership
	// do it in 2 ways just because
	@this.itemArray[i].owner = @this.client.getEnt();
	this.itemArray[i].ownerNum = this.client.getEnt().get_entNum();
	
	// set svflag to ONLYOWNER!
	this.itemArray[i].svflags = SVF_ONLYOWNER;

	// set touch! -- goes to player_touchListen.as because I couldnt get it to work within this class.
	@this.itemArray[i].touch = touchListener;

	this.itemArray[i].linkEntity();
      }
  }

  void showAllItems()
  {
    if (!this.allItemsVisible)
      {
	for (int i = 0; i < itemCount; i++)
	  {
	    this.itemArray[i].svflags = SVF_ONLYOWNER;
	    this.itemArray[i].linkEntity();
	  }
	this.allItemsVisible = true;
      }
  }

  void resetPlayer(int clientNumber)
  {
    // this is different from the constructor.
    this.allItemsVisible = false;




    this.isSpawned = true;
    this.bestRaceTime = 0;
    this.bestHalfwayTime = 0;
    this.positionSaved = false;
    this.tries = 0;
    this.racingTime = 0;
    this.highestSpeed = 0;
    this.state = "";
    this.positionSaved = false;
    this.positionLastCmd = 0;
    this.itemsVisited = 0;
    @this.client = @G_GetClient(clientNumber);
    @this.finishingItem = null;
    this.finishHoardTime = 0;
    this.finishHoardBuffer = 2000;

    showAllItems();

  }
  void appear(int clientNumber)
  {
    this.joinedTime = levelTime;
    resetPlayer(clientNumber);
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
    showAllItems();
    this.itemsVisited = 0;
   
  }

  // this is called when the player uses the racerestart Command
  void restartingRace()
  {
    this.itemsVisited = 0;
    this.hasReachedHalfwayPoint = false;
    
    this.isSpawned = true;
    if (this.isRacing() )
	this.racingTime += this.race.getCurrentTime();
    
    @this.race = null;

    // respawn all the items that were hidden!
    showAllItems();
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





  // an item belonging to the player in this class has been touched (I think!)
  void fireTouched( cEntity @ent, cEntity @other, const Vec3 planeNormal, int surfFlags )
  {
    if( @other.client == null || other.moveType != MOVETYPE_PLAYER)
      return;
    // is the toucher not the owner of the touchee?
    if (!(ent.ownerNum == other.get_entNum()))
      {
	return; 
      }



    if( ( other.client.pmoveFeatures & PMFEAT_ITEMPICK ) == 0 )
      return;

    // check if the item has already been visited (i.e. it is hidden from view)
    if (ent.svflags == SVF_NOCLIENT || (!this.isSpawned))
      return;
	
    // If this is the first item: Try starting!
    if (this.itemsVisited == 0)
      {
	if (getSpeed() > 500)
	  {
	    this.sendAward(S_COLOR_RED + "Prejumped!");
	    return;
	  }

	// this is to prevent immediate restart after finish
	if (@this.finishingItem == @ent && (levelTime < (this.finishHoardTime + this.finishHoardBuffer)))
	  return;
	
	// ok Start!
	@this.race = @Hoard_Player_Race();
	this.race.setPlayer(@this);
	this.race.start();
	this.tries++;

	// Motivation!
	sendAward(S_COLOR_WHITE + "Collect all the items!");
      }
    
    // see definition for expl.
    this.allItemsVisible = false;
	

    // play pickup sound!
    G_LocalSound( client, CHAN_ITEM, G_SoundIndex(ent.item.pickupSound));

    // mark the item as visited (hide it)
    ent.svflags = SVF_NOCLIENT;
    // ------------- ent.linkEntity()??? I don't think so
    this.itemsVisited++;
    //remaining items are now (itemCount - this.itemsVisited)

    if (this.itemsVisited == (itemCount / 2))
      {
	this.race.setHalfwayTime();
	this.hasReachedHalfwayPoint = true;
      }
    else if (this.itemsVisited == itemCount)
      {
	this.finishHoardTime = levelTime;
	@this.finishingItem = @ent;
	// race is finished
	raceFinished();
      }     
  }



  /*
   * Activated by command itemlist, this will print out all the remaining items.
   */

  String listRemainingItems()
  {
    // iterate over all the items that have flag SVF_ONLYCLIENT!
    String prntStr;
    prntStr += "Out of " + itemCount + " items, you have picked up " + this.itemsVisited + "!\n\n";
    prntStr += "Items you have not picked up: \n";

    for (int i = 0; i < itemCount; i++)
	if (this.itemArray[i].svflags == SVF_ONLYOWNER)
	  prntStr += this.itemArray[i].item.get_name() + "\n";

    return (prntStr);
    
  } 

  











  /*
   *
   *  Prints score shit upon a finished race.
   *
   */
  
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
	// lastrace because .race has already been set to null in raceFinished(..
	this.bestHalfwayTime = this.lastRace.getHalfwayTime();
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
  
  uint getBestHalfwayTime()
  {
    return this.bestHalfwayTime;
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


  /*
   *
   * HELPER FUNCTIONS
   *
   */
  
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
  

  // send message directly to the player's console
  void sendMessage( String message, cClient @client )
  {
    G_PrintMsg( client.getEnt(), message );
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
    if(this.positionLastCmd != 0 || !itemCheck())
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
  
  // this is called when the player tries to save a position, it will return false if the player is within the pickup radius of an item. (Would be quite bad if the best route on a map involveed spawning on the outskirts of an item and dashing away instantly).
  bool itemCheck()
  {
    /* FIXME
    float ITEM_PICKUP_RADIUS = 128.0;
    for (int i = 0; i < itemCount; i++)
	if (client.getEnt().origin.distance(itemArray[i].origin) <= ITEM_PICKUP_RADIUS)
	  return false;
    */
    return true;
  }






  bool getPositionSaved()
  {
    return this.positionSaved;
  }













  void freeEntityArray()
  {
    if (itemArray.length() < 1)
      return;
	       
    for (int i = 0; i < itemCount; i++)
      this.itemArray[i].freeEntity();
  }
  
}
