uint g_playerMenuCharaterTabId = HashString("trinket-inventory");

class PlayerMenuCharacterTab : MenuTab
{
	PortraitWidget@ m_wPortrait;
	TextWidget@ m_playerName;
	TextWidget@ m_playerClass;
	TextWidget@ m_playerNG;

	CheckBoxGroupWidget@ m_checkBoxGroup;

	UnitWidget@ m_unitWidget;
	EquipmentWidget@ m_equipmentWidget;
	EquipmentInventoryWidget@ m_equipmentInventoryWidget;
	TrinketInventoryWidget@ m_trinketInventoryWidget;
	Widget@ m_materialsInventoryWidget;
	ScrollbarWidget@ m_inventroyScrollbar;
	Widget@ m_trinketLine;

	Widget@ m_statsGroup;

	Widget@ m_addStrength;
	Widget@ m_addDexterity;
	Widget@ m_addIntelligence;
	Widget@ m_addFocus;
	Widget@ m_addVitality;
	TextWidget@ m_placeablePointsText;
	int m_lastPlaceableStatPoints;

	TextWidget@ m_townGold;
	TextWidget@ m_townWood;
	TextWidget@ m_townStone;
	TextWidget@ m_townIron;
	TextWidget@ m_townCrystals;
	TextWidget@ m_townDust;
	TextWidget@ m_townFragments;

	TextWidget@ m_sessionGold;
	TextWidget@ m_sessionWood;
	TextWidget@ m_sessionStone;
	TextWidget@ m_sessionIron;
	TextWidget@ m_sessionCrystals;
	TextWidget@ m_sessionDust;
	TextWidget@ m_sessionFragments;

	int m_contextC;

	bool m_refreshTooltip;
	bool m_menuContext;

	PlayerMenuCharacterTab(GUIBuilder@ b, uint id)
	{
		super(b, id, "gui/playermenu/character.gui");

		@m_checkBoxGroup = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("tabs-container"));

		@m_unitWidget = cast<UnitWidget>(m_widget.GetWidgetById("unit"));
		@m_equipmentWidget = cast<EquipmentWidget>(m_widget.GetWidgetById("equipment"));

		@m_equipmentInventoryWidget = cast<EquipmentInventoryWidget>(m_widget.GetWidgetById("equipment-inventory"));
		@m_equipmentInventoryWidget.m_itemTemplate = cast<EquipmentItemWidget>(m_widget.GetWidgetById("equipment-item-template"));
		@m_equipmentInventoryWidget.m_window = this;

		@m_trinketInventoryWidget = cast<TrinketInventoryWidget>(m_widget.GetWidgetById("trinket-inventory"));
		@m_trinketInventoryWidget.m_itemTemplate = cast<EquipmentItemWidget>(m_widget.GetWidgetById("trinket-item-template"));
		@m_trinketInventoryWidget.m_window = this;

		@m_materialsInventoryWidget = m_widget.GetWidgetById("material-inventory");

		@m_inventroyScrollbar = cast<ScrollbarWidget>(m_widget.GetWidgetById("inventory-scroll"));
		@m_trinketLine = m_widget.GetWidgetById("trinket-line");

		@m_wPortrait = cast<PortraitWidget>(m_widget.GetWidgetById("portrait"));
		@m_statsGroup = m_widget.GetWidgetById("stats-group");
		@m_playerName = cast<TextWidget>(m_widget.GetWidgetById("player-name"));
		@m_playerClass = cast<TextWidget>(m_widget.GetWidgetById("player-class"));
		@m_playerNG = cast<TextWidget>(m_widget.GetWidgetById("player-ng"));

		@m_addStrength = m_widget.GetWidgetById("button-strength");
		@m_addDexterity = m_widget.GetWidgetById("button-dexterity");
		@m_addIntelligence = m_widget.GetWidgetById("button-intelligence");
		@m_addFocus = m_widget.GetWidgetById("button-focus");
		@m_addVitality = m_widget.GetWidgetById("button-vitality");
		@m_placeablePointsText = cast<TextWidget>(m_widget.GetWidgetById("placeable-points-text"));

		@m_townGold = cast<TextWidget>(m_widget.GetWidgetById("material-town-gold-text"));
		@m_townWood = cast<TextWidget>(m_widget.GetWidgetById("material-town-wood-text"));
		@m_townStone = cast<TextWidget>(m_widget.GetWidgetById("material-town-stone-text"));
		@m_townIron = cast<TextWidget>(m_widget.GetWidgetById("material-town-iron-text"));
		@m_townCrystals = cast<TextWidget>(m_widget.GetWidgetById("material-town-crystals-text"));
		@m_townDust = cast<TextWidget>(m_widget.GetWidgetById("material-town-dust-text"));
		@m_townFragments = cast<TextWidget>(m_widget.GetWidgetById("material-town-fragments-text"));

		@m_sessionGold = cast<TextWidget>(m_widget.GetWidgetById("material-session-gold-text"));
		@m_sessionWood = cast<TextWidget>(m_widget.GetWidgetById("material-session-wood-text"));
		@m_sessionStone = cast<TextWidget>(m_widget.GetWidgetById("material-session-stone-text"));
		@m_sessionIron = cast<TextWidget>(m_widget.GetWidgetById("material-session-iron-text"));
		@m_sessionCrystals = cast<TextWidget>(m_widget.GetWidgetById("material-session-crystals-text"));
		@m_sessionDust = cast<TextWidget>(m_widget.GetWidgetById("material-session-dust-text"));
		@m_sessionFragments = cast<TextWidget>(m_widget.GetWidgetById("material-session-fragments-text"));

		auto record = GetLocalPlayerRecord();
		if (record !is null)
		{
			AGameplayGameMode@ gm = cast<AGameplayGameMode>(g_gameMode);
			m_playerName.SetText(gm.GetPlayerDisplayName(record));
			
			if (record.playerClass.parent != 0)
			{
				auto parent = PlayerClass::Get(record.playerClass.parent);
				if (parent !is null)
					m_playerClass.SetText(Resources::GetString(parent.m_name) + " - " + Resources::GetString(record.playerClass.m_name));
				else
					m_playerClass.SetText(Resources::GetString(record.playerClass.m_name));
			}
			else
				m_playerClass.SetText(Resources::GetString(record.playerClass.m_name));

			if (record.ngp > 0)
				m_playerNG.SetText("ng+" + record.ngp);

			RefreshPortrait(record);

			m_equipmentWidget.SetOwner(record);
			m_equipmentInventoryWidget.SetOwner(record);
			m_trinketInventoryWidget.SetOwner(record);

			m_statsGroup.m_visible = true;

			if (record.actor !is null)
			{
				m_unitWidget.ClearUnits();
				
				auto unitScene = record.actor.m_unit.GetCurrentUnitScene();
				if (unitScene !is null)
					m_unitWidget.AddUnit(unitScene, record.actor.m_unit);
				/*
				array<array<vec4>> multiColors;
				for (uint i = 0; i < m_currColors.length(); i++)
				{
					if (m_currClass.m_colorSlotUsed[i])
						multiColors.insertLast(m_currColors[i].m_colors);
				}
				
				for (uint i = 0; i < m_wPreviewUnits.length(); i++)
					m_wPreviewUnits[i].m_multiColors = multiColors;
				*/
			}
		}
		
		
		@m_input.m_menuContextOnPressed = WindowInput::OnFunc(this.MenuContext);
		@m_input.m_menuContextOnUp = WindowInput::OnFunc(this.MenuContextUp);
		@m_input.m_menuContextOnDown = WindowInput::OnFuncInt(this.MenuContextDown);

		@m_input.m_menuAdditionalOnPressed = WindowInput::OnFunc(this.MenuAdditional);
	}

	void Initialize() override
	{
		auto record = GetLocalPlayerRecord();
		if (record !is null)
		{
			if (record.justGotEquipment)
				SetTab(HashString("equipment-inventory"));
			else
				SetTab(g_playerMenuCharaterTabId);
		}
		else
			SetTab(g_playerMenuCharaterTabId);
		
		
		RefreshInteractableWidgets(m_widget);
	}

	void OnInteractableIndexChanged() override
	{
		MenuTab::OnInteractableIndexChanged();

		m_contextC = 0;
		m_menuContext = false;
	}

	void MenuContextUp()
	{
		auto inventoryScroll = cast<ScrollbarWidget>(m_input.GetCurrentInteractable());
		if (inventoryScroll is null)
			return;

		auto equipment = cast<EquipmentItemWidget>(inventoryScroll.m_input.GetCurrentInteractable());
		if (equipment is null)
			return;

		if (equipment.m_item is null || equipment.m_type != ItemWidgetType::Inventory)
			return;

		if (m_contextC >= 1000)
		{
			GameEvents::PlayerLinkedItem(GetLocalPlayerRecord(), equipment.m_item);

			SValueBuilder builder;
			Item::SaveItem(builder, equipment.m_item);
			(Network::Message("PlayerLinkedItem") << builder.Build()).SendToAll();
			m_menuContext = false;
		}

		auto host = cast<AWindowObject>(m_tabSystem.m_host);
		if (host is null)
			return;

		if (host.m_navigationBar.m_texts.length() < 3)
			return;

		host.m_navigationBar.m_texts[2].m_line = 0;
		OnInteractableIndexChanged();
	}

	void MenuContextDown(int dt)
	{
		if (!m_menuContext)
			return;

		m_contextC += dt;

		auto host = cast<AWindowObject>(m_tabSystem.m_host);
		if (host is null)
			return;

		if (host.m_navigationBar.m_texts.length() < 3)
			return;

		host.m_navigationBar.m_texts[2].m_line = m_contextC / 1000.0f;
	}

	void MenuContext()
	{
		m_contextC = 0;

		auto inventoryScroll = cast<ScrollbarWidget>(m_input.GetCurrentInteractable());
		if (inventoryScroll is null)
			return;

		auto equipment = cast<EquipmentItemWidget>(inventoryScroll.m_input.GetCurrentInteractable());
		if (equipment is null)
			return;

		if (equipment.m_item is null || equipment.m_type != ItemWidgetType::Inventory)
			return;

		m_menuContext = true;

		if (cast<CompareItemTooltip>(m_manager.m_tooltip) !is null)
			m_manager.SetTooltip(Item::BuildItemTooltip(equipment.m_item, equipment.m_item.GetPrice(), 1));
		else
			m_manager.SetTooltip(Item::BuildCompareItemTooltip(equipment.m_item, equipment.m_item.GetPrice()));

		auto host = cast<AWindowObject>(m_tabSystem.m_host);
		if (host is null)
			return;

		if (host.m_navigationBar.m_texts.length() < 3)
			return;

		auto text = host.m_navigationBar.m_texts[2].m_text.GetText();
		auto parse = text.split(" ");
		@host.m_navigationBar.m_texts[2].m_text = m_navigationBar.m_font.BuildText(parse[0] + " link item");
	}

	void AlwaysTooltip() {
		m_contextC = 0;

		auto inventoryScroll = cast<ScrollbarWidget>(m_input.GetCurrentInteractable());
		if (inventoryScroll is null)
			return;

		auto equipment = cast<EquipmentItemWidget>(inventoryScroll.m_input.GetCurrentInteractable());
		if (equipment is null || equipment is previousInteractableEquipment)
			return;

		@previousInteractableEquipment = equipment;

		if (equipment.m_item is null || equipment.m_type != ItemWidgetType::Inventory)
			return;

		m_menuContext = true;

		if (cast<CompareItemTooltip>(m_manager.m_tooltip) !is null)
			m_manager.SetTooltip(Item::BuildItemTooltip(equipment.m_item, equipment.m_item.GetPrice(), 1));
		else
			m_manager.SetTooltip(Item::BuildCompareItemTooltip(equipment.m_item, equipment.m_item.GetPrice()));

		auto host = cast<AWindowObject>(m_tabSystem.m_host);
		if (host is null)
			return;

		if (host.m_navigationBar.m_texts.length() < 3)
			return;

		auto text = host.m_navigationBar.m_texts[2].m_text.GetText();
		auto parse = text.split(" ");
		@host.m_navigationBar.m_texts[2].m_text = m_navigationBar.m_font.BuildText(parse[0] + " link item");
	}

	void MenuAdditional()
	{
		auto inventoryScroll = cast<ScrollbarWidget>(m_input.GetCurrentInteractable());
		if (inventoryScroll is null)
			return;

		auto equipment = cast<EquipmentItemWidget>(inventoryScroll.m_input.GetCurrentInteractable());
		if (equipment is null)
			return;

		if (equipment.m_item is null || equipment.m_type != ItemWidgetType::Inventory)
			return;

		m_manager.CloseTooltip();
		g_gameMode.ShowDialog("destroy",
			Resources::GetString("destroy " + equipment.m_item.GetName() + "?"),
			Resources::GetString(".menu.yes"),
			Resources::GetString(".menu.no"),
			this
		);
	}

	void RefreshPortrait(PlayerRecord@ record)
	{
		m_wPortrait.SetPortrait(record.portrait);

		m_wPortrait.m_visible = record.level > 0;

		if (record.skinColor is null)
			return;

		array<PlayerColors@> col;
		PlayerColors::GetPlayerColors(col, record);
		m_wPortrait.SetColors(col);
	}

	void SetTab(uint i)
	{
		g_playerMenuCharaterTabId = i;
		m_manager.CloseTooltip();

		if (m_equipmentInventoryWidget.m_idHash == i)
		{
			m_equipmentInventoryWidget.m_visible = true;
			m_trinketInventoryWidget.m_visible = false;
			m_materialsInventoryWidget.m_visible = false;
			m_checkBoxGroup.SetChecked("equipment-inventory");

			auto record = GetLocalPlayerRecord();
			m_inventroyScrollbar.m_enabled = (record.equipInventory.m_items.length() > 24);

			m_trinketLine.m_visible = false;
			m_equipmentInventoryWidget.Refresh();
		}
		else if (m_trinketInventoryWidget.m_idHash == i)
		{
			m_equipmentInventoryWidget.m_visible = false;
			m_trinketInventoryWidget.m_visible = true;
			m_materialsInventoryWidget.m_visible = false;
			m_checkBoxGroup.SetChecked("trinket-inventory");
			m_inventroyScrollbar.m_enabled = true;
			m_trinketLine.m_visible = true;
			m_trinketInventoryWidget.Refresh();
		}
		else if (m_materialsInventoryWidget.m_idHash == i)
		{
			m_equipmentInventoryWidget.m_visible = false;
			m_trinketInventoryWidget.m_visible = false;
			m_materialsInventoryWidget.m_visible = true;
			m_checkBoxGroup.SetChecked("material-inventory");
			m_inventroyScrollbar.m_enabled = false;
			m_trinketLine.m_visible = false;
		}
	}

	void StepTab(int i)
	{
		m_manager.CloseTooltip();

		m_checkBoxGroup.StepChecked(i > 0);
		SetTab(HashString(m_checkBoxGroup.GetChecked().GetValue()));
	}

	void SetStatsText(const string &in id, int stat)
	{
		auto widget = cast<TextWidget>(m_widget.GetWidgetById(id));
		if (widget is null)
		{
			PrintError("Couldn't find widget " + id + " in PlayerMenu.");
			return;
		}

		widget.SetText(stat);
	}

	void SetStatsText(const string &in id, float stat)
	{
		auto widget = cast<TextWidget>(m_widget.GetWidgetById(id));
		if (widget is null)
		{
			PrintError("Couldn't find widget " + id + " in PlayerMenu.");
			return;
		}

		widget.SetText(StatsText::FloatStr(stat));
	}

	void SetStatsText(const string &in id, const string &in stat)
	{
		auto widget = cast<TextWidget>(m_widget.GetWidgetById(id));
		if (widget is null)
		{
			PrintError("Couldn't find widget " + id + " in PlayerMenu.");
			return;
		}

		widget.SetText(stat);
	}

	array<string> m_icons = {
		//"strength",
		//"intelligence",
		//"dexterity",
		//"focus",
		//"vitality",
		"health",
		"mana",
		"healthregen",
		"manaregen",
		"atkpwr",
		"splpwr",
		"armor",
		"evadechance",
		"movespeed",
		//"experience",
		//"attrpt",
		//"skillpt",
	};
	array<string>@ GetShownIcons() override
	{
		return m_icons;
	}

	bool Update(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		auto record = GetLocalPlayerRecord();

		if (record is null)
			return AWindowObject::Update(ms, gameInput, menuInput);

%if GAME
		if (menuInput.MenuPreviousSubTab.Pressed)
			StepTab(-1);
		if (menuInput.MenuNextSubTab.Pressed)
			StepTab(1);
%endif

		auto stats = record.currStats;

		// Attributes
		SetStatsText("strength-text", stats.Str);
		SetStatsText("intelligence-text", stats.Int);
		SetStatsText("dexterity-text", stats.Dex);
		SetStatsText("focus-text", stats.Foc);
		SetStatsText("vitality-text", stats.Vit);

		// Pools
		SetStatsText("health-text", stats.Health);
		SetStatsText("mana-text", stats.Mana);
		SetStatsText("health-regen-text", stats.HealthRegen);
		SetStatsText("mana-regen-text", stats.ManaRegen);

		SetStatsText("attack-dmg-text", stats.AttackPower);
		SetStatsText("spell-dmg-text", stats.SpellPower);
		SetStatsText("armor-text", stats.Armor);
		SetStatsText("evasion-text", int(stats.EvadeChance * 100.f) + "%");
		SetStatsText("movespeed-text", int(stats.MoveSpeed * 100.f) + "%");

		// Level
		int64 xpStart = record.LevelExperience(record.level - 1);
		int64 xpEnd = record.LevelExperience(record.level) - xpStart;
		int64 xpNow = record.experience - xpStart;
		float experience = xpNow / double(xpEnd);
		SetStatsText("player-level", "lvl " + record.level + " (" + int((experience * 100.f)) + "%" + ") ");

		auto placeableStatPoints = record.GetPlaceableStatPoints();
		if (m_lastPlaceableStatPoints != placeableStatPoints)
			RefreshStats(record);

		if (m_materialsInventoryWidget.m_visible)
		{
			m_sessionGold.SetText(record.materials[MaterialType::Gold]);
			m_sessionWood.SetText(record.materials[MaterialType::Wood]);
			m_sessionStone.SetText(record.materials[MaterialType::Stone]);
			m_sessionIron.SetText(record.materials[MaterialType::Iron]);
			m_sessionCrystals.SetText(record.materials[MaterialType::Crystals]);
			m_sessionDust.SetText(record.materials[MaterialType::Dust]);
			m_sessionFragments.SetText(record.materials[MaterialType::Fragments]);

			m_townGold.SetText(g_myTownRecord.GetMaterial(MaterialType::Gold));
			m_townWood.SetText(g_myTownRecord.GetMaterial(MaterialType::Wood));
			m_townStone.SetText(g_myTownRecord.GetMaterial(MaterialType::Stone));
			m_townIron.SetText(g_myTownRecord.GetMaterial(MaterialType::Iron));
			m_townCrystals.SetText(g_myTownRecord.GetMaterial(MaterialType::Crystals));
			m_townDust.SetText(g_myTownRecord.GetMaterial(MaterialType::Dust));
			m_townFragments.SetText(g_myTownRecord.GetMaterial(MaterialType::Fragments));
		}

		AlwaysTooltip();

		if (m_refreshTooltip)
		{
			m_refreshTooltip = false;

			auto inventoryScroll = cast<ScrollbarWidget>(m_input.GetCurrentInteractable());
			if (inventoryScroll is null)
				return AWindowObject::Update(ms, gameInput, menuInput);

			auto equipmentWidget = cast<EquipmentItemWidget>(inventoryScroll.m_input.GetCurrentInteractable());
			if (equipmentWidget is null)
				return AWindowObject::Update(ms, gameInput, menuInput);

			if (equipmentWidget.m_item is null || equipmentWidget.m_type != ItemWidgetType::Inventory)
				return AWindowObject::Update(ms, gameInput, menuInput);

			m_manager.SetTooltip(Item::BuildItemTooltip(equipmentWidget.m_item, equipmentWidget.m_item.GetPrice(), 1));
		}

		return AWindowObject::Update(ms, gameInput, menuInput);
	}

	void RefreshStats(PlayerRecord@ record)
	{
		if (record is null)
			return;

		auto placeableStatPoints = record.GetPlaceableStatPoints();
		auto placeableSkillPoints = record.GetFreeSkillPoints();

		string statPts = "";
		if (placeableStatPoints > 0)
			statPts = "\\\"icn-attrpt\"" + placeableStatPoints;

		string skillPts = "";
		if (placeableSkillPoints > 0)
			skillPts = "\\\"icn-skillpt\"" + placeableSkillPoints;

		m_placeablePointsText.SetText(statPts + " " + skillPts);

		if (placeableStatPoints > 0)
		{
			m_placeablePointsText.m_visible = true;

			if (m_lastPlaceableStatPoints == 0)
			{
				ivec2 cachedInteractableIndex = m_input.m_interactableIndex;
				RefreshInteractableWidgets(m_widget);
				m_input.SetIndex(cachedInteractableIndex.x, cachedInteractableIndex.y);
			}
		}
		else
		{
			m_placeablePointsText.m_visible = false;

			if (m_lastPlaceableStatPoints > 0)
				RefreshInteractableWidgets(m_widget);
		}

		m_lastPlaceableStatPoints = placeableStatPoints;
	}

	int CalcStatAddModifier(array<Modifiers::IModifier@> mods, const string &in statName, float intensity)
	{
		int ret = 0;
		for (uint i = 0; i < mods.length(); i++)
		{
			auto statAdd = cast<Modifiers::StatAdd>(mods[i]);
			if (statAdd is null)
				continue;

			if (statName == "str")
				ret += Modifiers::lerp(statAdd.m_str, intensity);
			else if (statName == "dex")
				ret += Modifiers::lerp(statAdd.m_dex, intensity);
			else if (statName == "int")
				ret += Modifiers::lerp(statAdd.m_int, intensity);
			else if (statName == "foc")
				ret += Modifiers::lerp(statAdd.m_foc, intensity);
			else if (statName == "vit")
				ret += Modifiers::lerp(statAdd.m_vit, intensity);
		}

		return ret;
	}

	int GetStatFromBase(PlayerRecord@ record, const string &in statName)
	{
		if (record.playerClass is null)
			return 1;

		if (statName == "str")
			return record.playerClass.base_str + (record.level - 1) * record.playerClass.level_str + record.pickedStr;
		else if (statName == "dex")
			return record.playerClass.base_dex + (record.level - 1) * record.playerClass.level_dex + record.pickedDex;
		else if (statName == "int")
			return record.playerClass.base_int + (record.level - 1) * record.playerClass.level_int + record.pickedInt;
		else if (statName == "foc")
			return record.playerClass.base_foc + (record.level - 1) * record.playerClass.level_foc + record.pickedFoc;
		else if (statName == "vit")
			return record.playerClass.base_vit + (record.level - 1) * record.playerClass.level_vit + record.pickedVit;

		return 1;
	}

	int GetStatFromEquipped(PlayerRecord@ record, const string &in statName)
	{
		int ret = 0;
		for (uint i = 0; i < record.equipped.m_items.length(); i++)
		{
			auto item = record.equipped.m_items[i];
			if (item is null)
				continue;
			
			if (!record.equipped.MayEquip(item))
				continue;
			
			float itemIntensity = item.GetModifierIntensity();
			auto itemModifers = item.GetModifiers();
			if (itemModifers is null)
				continue;

			ret += CalcStatAddModifier(itemModifers, statName, itemIntensity);
		}

		return ret;
	}

	int GetStatFromTrinkets(PlayerRecord@ record, const string &in statName)
	{
		int ret = 0;

		array<Item::TrinketSet@> sets;
		for (uint i = 0; i < record.trinketInventory.m_items.length(); i++)
		{
			auto set = record.trinketInventory.m_items[i].m_set;
			if (set !is null)
			{
				set.m_tmpCounter++;
				sets.insertLast(set);
			}

			auto trinketModifiers = record.trinketInventory.m_items[i].GetModifiers();
			if (trinketModifiers is null)
				continue;

			ret += CalcStatAddModifier(trinketModifiers, statName, 1.0f);
		}

		for (uint i = 0; i < sets.length(); i++)
		{
			if (sets[i].m_tmpCounter == 0)
				continue;

			auto setModifiers = sets[i].GetModifiers(sets[i].m_tmpCounter);
			if (setModifiers is null)
			{
				sets[i].m_tmpCounter = 0;
				continue;
			}

			ret += CalcStatAddModifier(setModifiers, statName, 1.0f);
			sets[i].m_tmpCounter = 0;
		}

		return ret;
	}

	int GetStatFromMisc(PlayerRecord@ record, const string &in statName)
	{
		int ret = 0;

		for (uint i = 0; i < record.shopUpgrades.length(); i++)
		{
			auto shopModifiers = record.shopUpgrades[i].upgrade.m_steps[record.shopUpgrades[i].level].m_modifiers;
			if (shopModifiers is null)
				continue;

			ret += CalcStatAddModifier(shopModifiers, statName, 1.0f);
		}

		for (uint i = 0; i < g_myTownRecord.m_heroTitles.length(); i++)
		{
			auto townModifiers = g_myTownRecord.m_heroTitles[i].m_title.m_modifiers;
			if (townModifiers is null)
				continue;

			ret += CalcStatAddModifier(townModifiers, statName, float(g_myTownRecord.m_heroTitles[i].m_attribValue) / 100.0f);
		}

		for (uint i = 0; i < record.missionBuffs.length(); i++)
		{
			auto missionModifiers = record.missionBuffs[i].m_buff.m_modifiers;
			if (missionModifiers is null)
				continue;

			ret += CalcStatAddModifier(missionModifiers, statName, 1.0f);
		}

		array<Modifiers::IModifier@> weapMods;
		for (uint i = 0; i < record.weaponMasteries.length(); i++)
			weapMods.insertLast(record.weaponMasteries[i]);

		ret += CalcStatAddModifier(weapMods, statName, 1.0f);

		auto player = cast<PlayerBase>(record.actor);
		if (player !is null)
		{
			// Add modifiers
			auto@ buffs = player.m_buffs.m_buffs;
			for (uint i = 0; i < buffs.length(); i++)
				if (buffs[i].m_def.m_modifiers.length() > 0)
					ret += CalcStatAddModifier(buffs[i].m_def.m_modifiers, statName, buffs[i].m_intensity);

			auto@ stacks = player.m_buffs.m_stacks;
			for (uint i = 0; i < stacks.length(); i++)
			{
				if (stacks[i].m_def.m_buffDef !is null && stacks[i].m_def.m_buffDef.m_modifiers.length() > 0)
					ret += CalcStatAddModifier(stacks[i].m_def.m_buffDef.m_modifiers, statName, stacks[i].GetIntensity());
			}

			for (uint i = 0; i < player.m_skills.length(); i++)
			{
				auto mods = player.m_skills[i].GetModifiers();
				if (mods !is null && mods.length() > 0)
					ret += CalcStatAddModifier(mods, statName, 1.0f);
			}

			// Add dynamic modifiers
			auto@ modList = record.modifiers.GetModifierList();
			for (uint i = 0; i < stacks.length(); i++)
			{
				auto mods = modList.DynamicStackModifiers(player, stacks[i].m_def);
				if (mods !is null && mods.length() > 0)
					ret += CalcStatAddModifier(mods, statName, stacks[i].GetIntensity());
			}
		}

		return ret;
	}

	void OnFunc(Widget@ sender, const string &in name) override
	{
		print("Character::" + name);

		auto parse = name.split(" ");
		if (parse[0] == "set-tab")
			SetTab(HashString(parse[1]));
		else if (parse[0] == "next-tab")
			StepTab(1);
		else if (parse[0] == "prev-tab")
			StepTab(-1);
		else if (parse[0] == "tooltip")
		{
			auto record = GetLocalPlayerRecord();
			if (record is null)
				return;

			int baseStat = GetStatFromBase(record, parse[1]);
			int equipmentStat = GetStatFromEquipped(record, parse[1]);
			int trinketStat = GetStatFromTrinkets(record, parse[1]);
			int miscStat = GetStatFromMisc(record, parse[1]);

			BaseGameMode@ gm = cast<BaseGameMode>(g_gameMode);
			if (gm !is null)
				gm.m_windowManager.SetTooltip(CreateAttributeTooltip("\\\"icn-" + parse[1] + "\" " + int(baseStat + equipmentStat + trinketStat + miscStat) + " " + parse[1], baseStat, equipmentStat, trinketStat, miscStat));
		}
		/*
		else if (parse[0] == "add")
		{
			auto record = GetLocalPlayerRecord();
			auto placeableStatPoints = record.GetPlaceableStatPoints();

			if (placeableStatPoints <= 0)
				return;

			if (record is null)
				return;

			if (parse[1] == "strength")
				record.pickedStr++;
			else if (parse[1] == "dexterity")
				record.pickedDex++;
			else if (parse[1] == "intelligence")
				record.pickedInt++;
			else if (parse[1] == "focus")
				record.pickedFoc++;
			else if (parse[1] == "vitality")
				record.pickedVit++;

			record.SyncStatPoints();

			if (record.actor !is null)
				cast<PlayerBase>(record.actor).RefreshModifiers();

			RefreshStats(record);
		}
		*/
		else if (parse[0] == "destroy")
		{
			if (parse[1] == "yes")
			{
				auto inventoryScroll = cast<ScrollbarWidget>(m_input.GetCurrentInteractable());
				if (inventoryScroll is null)
					return;

				auto equipmentWidget = cast<EquipmentItemWidget>(inventoryScroll.m_input.GetCurrentInteractable());
				if (equipmentWidget is null)
					return;

				if (equipmentWidget.m_item is null || equipmentWidget.m_type != ItemWidgetType::Inventory)
					return;

				GetLocalPlayerRecord().equipInventory.Remove(cast<Equipment::Equipment>(equipmentWidget.m_item));
				print("destroyed " + equipmentWidget.m_item.GetName());
			}
			else if (parse[1] == "no")
			{
				m_refreshTooltip = true;
			}
		}
	}
}