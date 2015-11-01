//=============================================================================
// RandomItemSpawner.
//=============================================================================
class RandomItemSpawner expands WildcardsSpawners;
// Deprecated

/*

#exec OBJ LOAD File=relics.u

Event Timer()
{
	local int Selection;
	local int Choice;
	local inventorySpot aI;

	if ( (SiegeGI(Level.Game) != none) && !SiegeGI(Level.Game).bMatchStarted )
	{
		SetTimer( MinutesBeforeFirstSpawn * 0.75, false);
		return;
	}

	Spawn(SpawnEffect);
	PlaySound(RespawnSound);

	if ( SpawnRandomItems == false )
		Product = Spawn(ItemToSpawn);
	else
		{
			Choice = Rand(AmountOfRandomItems);
			for ( Selection = 0; Selection < AmountOfRandomItems; Selection++ )
				{
					if ( Choice == Selection && Choice != AmountOfRandomItems-1 )
						{
							Product = Spawn(RandomItem[Choice]);
							break;
						}
					else
						if ( Choice == AmountOfRandomItems-1 )
							{
								Choice = Rand(100);
								if ( Choice <= 40 )
									Product = Spawn(class'SuperWRU15',self);
								if ( Choice > 40 && Choice < 70 )
									Product = Spawn(class'SuperWRU30',self);
								if ( Choice >= 70 && Choice < 85 )
									Product= Spawn(class'SuperWRU60',self);
								if ( Choice >= 85 && Choice < 95 )
									Product = Spawn(class'SuperWRU120',self);
								if ( Choice >= 95 )
									Product = Spawn(class'SuperWRU240',self);
								if ( Product != none )
									break;
							}
				}
		}

	if ( Product == none )
		{
			SetTimer(1,false);
			DebugShout("RANDOM ITEM FAILED TO SPAWN!!! Choice: "@Choice);
			return;
		}

	if ( Product.IsA('Weapon') )
		Weapon(Product).bWeaponStay = false;

	Product.LightEffect=LE_Rotor;
	Product.LightBrightness=255;
	Product.LightHue=85;
	Product.LightRadius=32;
	Product.LightSaturation=0;
	Product.LightType=LT_Steady;

	ForEach RadiusActors (class'InventorySpot',aI, 70)
		if ( aI.MarkedItem == none )
		{
			aI.MarkedItem = Product;
			Product.MyMarker = aI;
			break;
		}
}

Event Tick(float deltaTime)
{
	if ( Product != None )
		if ( Product.bHidden == true )
		{
			SetTimer(SecondsBeforeRespawn+Rand(60),false);
			Product.Destroy();
			Product = None;
		}
}


defaultproperties
{
     MinutesBeforeFirstSpawn=10
     SecondsBeforeRespawn=60.000000
     SpawnEffect=Class'SpawnFX'
     RespawnSound=Sound'PickUpRespawn'
     SpawnRandomItems=True
     AmountOfRandomItems=10
     RandomItem(0)=Class'HyperLeecher'
     RandomItem(1)=Class'AsmdPulseRifle'
     RandomItem(2)=Class'SiegeInstaGibRifle'
     RandomItem(3)=Class'Botpack.UDamage'
     RandomItem(4)=Class'MegaHealth'
     RandomItem(5)=Class'WildcardsMetalSuit'
     RandomItem(6)=Class'WildcardsRubberSuit'
	 RandomItem(7)=Class'FlameThrower'
     RandomItem(8)=Class'sgGrenadeLauncher'
     bHidden=True
}
*/