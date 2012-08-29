int itemCount;
array<array<cEntity@>> itemStorage;
  
void reset_items()
{
  itemCount = 0;
  itemStorage = array<array<cEntity@>>(maxClients, array<cEntity@>(numEntities));
}

// unused param. later!
void resetArray(int clientNumber, cEntity @owner)
{
  // fixed to item count from max entity count
  for (int i = 0; i < itemCount; i++)
    {
      if (@itemStorage[clientNumber][i] == null)
	{
	  break;
	}
      else
	{  
	  // THIS IS TO SHOW THE ITEM!
	  itemStorage[clientNumber][i].svflags = SVF_ONLYOWNER;

	  // Best leave this one in!
	  itemStorage[clientNumber][i].linkEntity();
	}
    }

}


// called from hoard.as, GT_Thinkrules - If a player is spectating AND following a player -> show the items the player that is racing sees!
void spectatorArray(int racer, int coward)
{
  for (int i = 0; i < itemCount; i++)
    {
      if (@itemStorage[coward][i] == null || @itemStorage[racer][i] == null)
	break;
      else
	{
	  itemStorage[coward][i].svflags = itemStorage[racer][i].svflags;
	  itemStorage[coward][i].linkEntity();
	}
    }
}





void hideItem(int clientNumber, int itemNumber, cEntity @owner)
{

  itemStorage[clientNumber][itemNumber].svflags |= SVF_NOCLIENT;
  itemStorage[clientNumber][itemNumber].linkEntity();
}

int findInItemStorage(cEntity @ent, int owner)
{
  for (int i = 0; i < itemCount; i++)
    {
      if (@itemStorage[owner][i] == @ent)
	return i;
    }
  return -1;
} 

// just a straight copy.
void replacementItem( cEntity @oldItem, int itemIndex)
{
  for (int i = 0; i < maxClients; i++)
    {

      cEntity @owner = @G_GetClient(i).getEnt();
      
      Vec3 min, max;
      cEntity @ent = @G_SpawnEntity( oldItem.classname );
      
      
      cItem @item = @G_GetItem( oldItem.item.tag );
      @ent.item = @item;
      
  
      

      ent.origin = oldItem.origin;
      oldItem.getSize( min, max );
      ent.setSize( min, max );
      ent.type = ET_ITEM;
      ent.solid = SOLID_TRIGGER;
      ent.moveType = MOVETYPE_NONE;
      ent.count = oldItem.count;
      ent.spawnFlags = oldItem.spawnFlags;
      

      @ent.owner = @owner;
      ent.ownerNum = owner.get_entNum();
      
      ent.svflags = SVF_ONLYOWNER;// | SVF_BROADCAST;

     
      ent.style = oldItem.style;
      ent.target = oldItem.target;
      ent.targetname = oldItem.targetname;
      ent.setupModel( oldItem.item.model, oldItem.item.model2 );
  
  
  
      ent.wait = oldItem.wait;
      if( ent.wait > 0 )
	{
	  ent.nextThink = levelTime + ent.wait;
	}
      
      ent.skinNum = oldItem.skinNum;

      // don't remove oldEntity until all copies are made!
      if (i == (maxClients - 1)) 
	{
	  oldItem.solid = SOLID_NOT;
	  oldItem.classname = "ASmodel_" + ent.item.classname;
	  oldItem.freeEntity();
	}
      @ent.think = replacementItem_think;
      @ent.touch = replacementItem_touch;
      @ent.use = replacementItem_use;
  
      
      ent.linkEntity();
      
      @itemStorage[i][itemIndex] = @ent;
    }
  setItemCount(itemIndex + 1);
}

  void setItemCount(int n)
  {
    itemCount = n;
  }
  
  int getItemCount()
  {
    return itemCount;
  }
  
  // this function calls the player's spam filter.
  void replacementItem_touch( cEntity @ent, cEntity @other, const Vec3 planeNormal, int surfFlags )
{
  if( @other.client == null || other.moveType != MOVETYPE_PLAYER)
    return;
  if( ( other.client.pmoveFeatures & PMFEAT_ITEMPICK ) == 0 )
    return;
  
  // play pickup sound!
  //G_Sound( other, CHAN_ITEM, G_SoundIndex( ent.item.pickupSound ), 0.875 );
  // --!  Pickup sound is played in the player class.
  int c = -1;
  for (int i = 0; i < maxClients; i++)
    {
      if (ent.ownerNum == G_GetClient(i).getEnt().get_entNum())
	c = i;
    }
  if (c == -1)
    {
      G_Print("ERROR: Ownership of item not established!");
      return; 
    }
  
  int index = findInItemStorage(ent, c);
    
  // just give the message to player!
  Racesow_GetPlayerByClient(other.client).spamFilterOnInput(index, ent);
    
}

void replacementItem_think( cEntity @ent )
{
  ent.respawnEffect();
}

/*
 * Soundfix
 * This is not used BUT I DARE NOT REMOVE IT!
 */ 
void replacementItem_use( cEntity @ent, cEntity @other, cEntity @activator )
{
  if( ent.wait > 0 )
    {
      ent.nextThink = levelTime + ent.wait;
    }
  else
    {
      ent.nextThink = levelTime + 1;
    }
 }
