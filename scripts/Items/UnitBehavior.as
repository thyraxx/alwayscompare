namespace Item
{
	const Guid g_sharedItem("zeroed, invalid");

	class UnitBehavior : IUsable
	{
		Guid m_playerOwner;
		
		UnitPtr m_unit;
		Item@ m_item;
		int m_stackCount;
		
		int m_pickupCooldown;
		UnitScene@ m_particle;
		int m_particleCd;
		
		CustomUnitScene m_unitScene;
		UnitScene@ m_baseScene;
		CustomUnitSprite@ m_baseSprite;
		
		UnitDropAnimator m_dropAnim;
		int m_dropAnimCMax;
		int m_dropAnimC;
		
		bool m_picked;
		
		SoundEvent@ m_sound;
		
		ITooltip@ m_tooltip;
		
		
		
		UnitBehavior(UnitPtr unit, SValue& params)
		{
			m_playerOwner = g_sharedItem;
			m_unit = unit;
			m_picked = false;
			
			m_pickupCooldown = GetParamInt(unit, params, "pickup-cooldown", false, 250);
			m_unit.SetUpdateDistanceLimit(500);
		}

		SValue@ Save()
		{
			SValueBuilder sval;
			sval.PushArray();
			sval.PushBoolean(m_picked);
			sval.PushInteger(m_stackCount);
			Item::SaveItem(sval, m_item);
			sval.PushString(m_playerOwner);
			return sval.Build();
		}
		
		void Load(SValue@ data)
		{
			auto arr = data.GetArray();
			m_picked = arr[0].GetBoolean();
			int count = arr[1].GetInteger();
			auto item = Item::LoadItem(arr[2]);
			
			if (arr.length() > 3)
				Initialize(item, count, false, arr[3].GetString());
			else
				Initialize(item, count, false);
		}
		
		void Initialize(Item@ item, int count, bool dropAnimation, Guid owner = g_sharedItem)
		{
			if (item is null)
				return;

			@m_item = item;
			m_playerOwner = owner;
			@m_particle = m_unit.GetUnitScene("particle_" + Item::QualityToString(item.GetQuality()));

			m_stackCount = count;
			
			if (m_picked)
			{
				m_unit.SetHidden(true);
				m_unit.SetShouldCollide(false);
			}
			else
			{
				m_unit.SetHidden(false);
				m_unit.SetShouldCollide(true);
			}
			
			//auto id = localPlr is null ? Guid() : localPlr.id; // TODO: Why does this hit angelscript assert
			if (m_playerOwner != g_sharedItem)
			{
				auto localPlr = GetLocalPlayerRecord();
				
				Guid peerId;
				if (localPlr is null)
					peerId = GetUniquePeerId(Lobby::GetLocalPeer());
				else
					peerId = localPlr.id;
				
				if (peerId != m_playerOwner)
				{
					m_unit.SetHidden(true);
					m_unit.SetShouldCollide(false);
				}
			}

			auto trinket = cast<Item::Trinket>(m_item);
			if (trinket !is null)
			{
				ScriptSprite@ sprite = m_item.GetIcon();
				
				if (sprite.m_texture is null)
					PrintError("Trinket \"" + m_item.GetName() + "\" is missing a texture for its scene sprite!");
				
				array<vec4> frames;
				array<int> frameTimes = { 100 };
				
				for (uint i = 0; i < sprite.m_frames.length(); i++)
					frames.insertLast(sprite.m_frames[i].frame);
				
				Material@ mat = GetQualityMaterial(item.GetQuality());
				
				vec2 halfSize = vec2(
					sprite.GetWidth() / 2,
					sprite.GetHeight() / 2
				);
				
				@m_baseSprite = CustomUnitSprite(halfSize, sprite.m_texture, mat, frames, frameTimes, true, 0);
				m_unitScene.AddSprite(m_baseSprite, 0, vec2(), 0, 0);
			}
			else
			{
				auto graphic = m_item.GetGraphic();
				
				string file;
				string name;
				
				int i = graphic.findFirst(":");
				if (i >= 0)
				{
					name = graphic.substr(i + 1);
					file = graphic.substr(0, i);
				
					auto prod = Resources::GetUnitProducer(file);
					if (prod !is null)
					{
						auto set = prod.GetSceneSet(name);
						if (set.length() > 0)
							@m_baseScene = prod.GetUnitScene(set[randi(set.length())]);
						else
							@m_baseScene = prod.GetUnitScene(name);
					}
				}
				
				if (m_baseScene is null)
					@m_baseScene = m_unit.GetUnitScene("default");
				
				m_unitScene.AddScene(m_baseScene, 0, vec2(), 0, 0);
			}
			m_unit.SetUnitScene(m_unitScene, false);
			
			auto svSound = m_unit.FetchData("sound");
			if (svSound !is null)
				@m_sound = Resources::GetSoundEvent(svSound.GetString());
			else
				@m_sound = Resources::GetSoundEvent("event:/sfx/items/item_default");

			if (dropAnimation)
			{
				m_dropAnimCMax = m_dropAnimC = int((0.8f + randf() * 0.2f) * Tweak::ItemDropTime * m_dropAnim.StartAnimation(m_unit, 20.0f));
				PlaySound3D(m_sound, m_unit.GetPosition());
			}
			//else
			//	AddQualityScene();
			
			
			auto svManQual = m_unit.FetchData("manual-quality");
			if (svManQual is null || !svManQual.GetBoolean())
				AddQualityScene();
			
			Update(0);
		}
		
		void AddQualityScene()
		{
			m_pickupCooldown = max(1, m_pickupCooldown);
		
			m_unit.SetUnitScene("default", false);
			m_unitScene.Clear();
		
			auto scene = m_unit.GetUnitScene(Item::QualityToString(m_item.GetQuality()));
			if (scene !is null)
				m_unitScene.AddScene(scene, 0, vec2(), 0, 0);
			else
				m_unitScene.AddScene(m_unit.GetUnitScene("none"), 0, vec2(), 0, 0);
			
			if (m_baseSprite !is null)
				m_unitScene.AddSprite(m_baseSprite, 0, vec2(), 0, 0);
			if (m_baseScene !is null)
				m_unitScene.AddScene(m_baseScene, 0, vec2(), 0, 0);
			
			m_unit.SetUnitScene(m_unitScene, false);
		}
		
		void Update(int dt)
		{
			/*
			if (m_tooltip !is null)
			{
				auto plr = GetLocalPlayer();
				if (plr !is null && plr.GetTopUsable() is this)
				{
					auto gm = cast<BaseGameMode>(g_gameMode);
					gm.m_windowManager.SetTooltip(m_tooltip, m_unit);
				}
				else
				{
					@m_tooltip = null;
					m_unit.SetUpdateFrequency(200);
				}
			}
			*/
			
			if (m_particle !is null)
			{
				m_particleCd -= dt;
				if (m_particleCd <= 0)
				{
					vec3 pos = m_unit.GetPosition();
					int timeOffset = randi(1000);
					g_scene.AddParticle(m_particle, xy(pos) + vec2(randf() - 0.5f, randf() - 0.5f), vec2(0, -1.25f), 2.0f, 3000 - timeOffset, timeOffset, 0.66f, 0.66f, 1.0f);
					m_particleCd = 50 + randi(50);
				}
			}
			
			if (m_pickupCooldown > 0)
				m_pickupCooldown -= dt;
			
			if (m_dropAnimC > 0)
			{
				m_dropAnimC -= dt;
				
				if (m_dropAnimC <= 0)
				{
					//PlaySound3D(g_baseGoldSound, pos, {{ "amount", m_amount }});
					auto uPos = m_unit.GetPosition() + xyz(m_dropAnim.m_dropDir);
					m_unit.SetPosition(uPos.x, uPos.y, 0, true);
					m_unit.SetUpdateDistanceLimit(200);
					m_dropAnim.m_dropDir = 0;
					m_unit.SetMultiplyColor(vec4(1,1,1,1));
					m_unit.SetRotation(0);
					
					if (m_tooltip is null)
						m_unit.SetUpdateFrequency(200);
				}
				else
				{
					float t = m_dropAnimC / float(m_dropAnimCMax);
					float tFrac = float(dt) / float(m_dropAnimC);
					m_dropAnim.Update(m_unit, t, tFrac);
					m_unit.SetMultiplyColor(vec4(1,1,1, smoothstep(clamp((1.0f - t) * 3 - 1, 0.0f, 1.0f))));
					
					if (m_dropAnimC % 50 < dt)
						m_unit.SetRotation(randf() * PI * 2.0f);
				}
			}
		}
		
		void NetUse(PlayerHusk@ player) {}
		UnitPtr GetUseUnit() { return m_unit; }
		bool CanUse(PlayerBase@ player) { return true; }
		UsableIcon GetIcon(Player@ player) { return UsableIcon::Generic; }
		int UsePriority() { return 1; }
		bool IsInside(UnitPtr unit) { return m_unit.IsColliding(unit); }
		
		
		bool IsInstaPickup()
		{
			if (cast<Item::Trinket>(m_item) !is null)
				return !GetVarBool("g_item_pickup_tooltip_trinket");
			
			if (cast<Equipment::Equipment>(m_item) !is null)
				return !GetVarBool("g_item_pickup_tooltip_equipment");
			
			return true;
		}
		
		ITooltip@ GetTooltip() { return m_tooltip; }
		
		void Collide(UnitPtr unit, vec2 pos, vec2 normal)
		{
			if (m_picked || m_item is null)
				return;
			
			if (!IsInstaPickup())
			{
				auto player = cast<Player>(unit.GetScriptBehavior());
				if (player !is null)
				{
					player.AddUsable(this);
					
					auto gm = cast<BaseGameMode>(g_gameMode);
					//@m_tooltip = Item::BuildItemTooltip(m_item, 0, 1);

					@m_tooltip = Item::BuildCompareItemTooltip(m_item, m_item.GetPrice());

				}
			}
			else
			{
				//if (m_dropAnimC > 0)
				//	return;
				
				if (m_pickupCooldown > 0)
					return;
				
				Take(unit);
			}
		}
		
		void EndCollision(UnitPtr unit)
		{
			//m_tooltip.CloseTooltip();
			//auto gm = cast<BaseGameMode>(g_gameMode);
			//if(gm !is null && gm.m_windowManager !is null)
			//	gm.m_windowManager.CloseTooltip();

			auto player = cast<Player>(unit.GetScriptBehavior());
			if (player !is null)
				player.RemoveUsable(this);
			
			if (m_dropAnimC <= 0)
				m_unit.SetUpdateFrequency(200);
			
			if (m_picked || m_item is null)
				return;
			
			if (IsInstaPickup())
			{
				if (m_dropAnimC > 0)
					return;
				
				if (m_pickupCooldown > 0)
					return;
				
				Take(unit);
			}
		}
		

		void Use(PlayerBase@ player) 
		{
			if (m_dropAnimC > 0)
				return;
			
			if (m_pickupCooldown > 0)
				return;
			
			Take(player.m_unit);
		}
		
		void Take(UnitPtr unit)
		{
			ref@ b = unit.GetScriptBehavior();
			Player@ a = cast<Player>(b);
			
			if (a is null || a.m_record.IsDead())
				return;
			
			if (!a.m_record.CanAddItem(m_item))
				return;
			
			
			auto pos = unit.GetPosition();
			
			if (a.m_record.id == m_playerOwner)
			{
				PlaySound3D(m_sound, pos);
				AddFloatingText(FloatingTextType::Pickup, m_item.GetPickupText(), pos);
				NetPick();
				
				if (!Network::IsServer())
				{
					m_unit.SetHidden(true);
					m_unit.SetShouldCollide(false);
					(Network::Message("PickedItem") << m_unit).SendToHost();
				}
				else
					m_unit.Destroy();
			}
			else if (m_playerOwner == g_sharedItem)
			{
				PlaySound3D(m_sound, pos);
				AddFloatingText(FloatingTextType::Pickup, m_item.GetPickupText(), pos);
				
				if (Network::IsServer())
				{
					(Network::Message("PickedItem") << m_unit).SendToAll();
					NetPick();
					m_unit.Destroy();
				}
				else
				{
					(Network::Message("PickedItem") << m_unit).SendToHost();
					m_unit.SetHidden(true);
					m_unit.SetShouldCollide(false);
				}
			}
		}
		
		void NetPick()
		{
			if (m_picked)
				return;
			
			auto localPlr = GetLocalPlayerRecord();
			if (m_playerOwner == g_sharedItem)
			{
				%PROFILE_START PlayerRecord.GiveItem
				localPlr.GiveItem(m_item);
				%PROFILE_STOP
				if (Network::IsServer())
					(Network::Message("PickedItem") << m_unit).SendToAll();
			}
			else if (localPlr.id == m_playerOwner)
			{
				%PROFILE_START PlayerRecord.GiveItem
				localPlr.GiveItem(m_item);
				%PROFILE_STOP
			}
			
			m_picked = true;
			m_unit.SetHidden(true);
			m_unit.SetShouldCollide(false);
		}
	}
	
	class UnitPickup
	{
		[Editable default=true]
		bool Respawn;
		float m_respawnTime;
	
		UnitPtr m_unit;
		Item@ m_item;
		int m_stackCount;
		
		SoundEvent@ m_sound;
		

		UnitPickup(UnitPtr unit, SValue& params)
		{
			m_unit = unit;

			@m_item = Item::Get(GetParamString(unit, params, "item", true));
			m_stackCount = GetParamInt(unit, params, "count", false, 1);
			m_respawnTime = GetParamFloat(unit, params, "respawn-time", false, 0.0f);
			
			auto svSound = m_unit.FetchData("sound");
			if (svSound !is null)
				@m_sound = Resources::GetSoundEvent(svSound.GetString());
			else
				@m_sound = Resources::GetSoundEvent("event:/sfx/items/item_default");
		}

		void Collide(UnitPtr unit, vec2 pos, vec2 normal)
		{
			if (m_item is null)
				return;
		
			ref@ b = unit.GetScriptBehavior();
			Player@ a = cast<Player>(b);
			
			if (a is null || a.m_record.IsDead())
				return;
			
			PlaySound3D(m_sound, xyz(pos));
			AddFloatingText(FloatingTextType::Pickup, m_item.GetName(), xyz(pos));

			if (Respawn && m_respawnTime > 0)
			{
				auto spawnUnit = g_spawnerUnit.Produce(g_scene, m_unit.GetPosition());
				auto behavior = cast<SpawnerBehavior>(spawnUnit.GetScriptBehavior());
				//behavior.Initialize(m_unit.GetUnitProducer(), m_respawnTime, m_unit.GetScriptProperties());
				behavior.Initialize(m_unit, lerp(m_respawnTime * 0.9f, m_respawnTime * 1.1f, randf()), false);
			}
			
			m_unit.Destroy();
		}
	}
}