array<String> entStorage(maxEntities);
int itemCount = 0;

array<cEntity@> itemStorage(maxEntities);

int findInItemStorage(cEntity @ent)
{
  for (int i = 0; i < itemCount; i++)
    {
      if (@itemStorage[i] == @ent)
	return i;
    }

  return -1;
}

// not sure if this is used.
void addToEntStorage( int id, String string)
{
  int i = entStorage.length();
  if (i < id)
    entStorage.resize(id);
  entStorage[id] = string;
}

// just a straight copy.
void replacementItem( cEntity @oldItem )
{
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
  ent.svflags &= ~SVF_NOCLIENT;
  ent.style = oldItem.style;
  ent.target = oldItem.target;
  ent.targetname = oldItem.targetname;
  ent.setupModel( oldItem.item.model, oldItem.item.model2 );
  oldItem.solid = SOLID_NOT;
  oldItem.classname = "ASmodel_" + ent.item.classname;
  ent.wait = oldItem.wait;
  if( ent.wait > 0 )
    {
      ent.nextThink = levelTime + ent.wait;
    }

  
  // this, wtf does this mean...?
  if( oldItem.item.type == uint(IT_WEAPON) )
    {
      ent.skinNum = oldItem.skinNum;
      oldItem.freeEntity();
    }
  @ent.think = replacementItem_think;
  @ent.touch = replacementItem_touch;
  @ent.use = replacementItem_use;
  ent.linkEntity();

  @itemStorage[itemCount] = @ent;
  itemCount++;
}

void replacementItem_think( cEntity @ent )
{
    ent.respawnEffect();
}

/*
 * Soundfix
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



// this function calls the player's spam filter.
void replacementItem_touch( cEntity @ent, cEntity @other, const Vec3 planeNormal, int surfFlags )
{
	if( @other.client == null || other.moveType != MOVETYPE_PLAYER )
		return;
	if( ( other.client.pmoveFeatures & PMFEAT_ITEMPICK ) == 0 )
	    return;

    // play pickup sound!
    //G_Sound( other, CHAN_ITEM, G_SoundIndex( ent.item.pickupSound ), 0.875 );
    // pickup sound is played in the player class.
    
    int index = findInItemStorage(ent);
    
    // just give the message to player!
    Racesow_GetPlayerByClient(other.client).spamFilterOnInput(index, ent);
    
}


int getItemCount()
{
  return itemCount;
}
