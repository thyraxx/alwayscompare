namespace alwayscompare
{
	//WindowInput@ g_windowInput;
	AGameplayGameMode@ m_aGameplayMode;
	int tabWindowIndex = 0;

	[Hook]
	void GameModeStart(AGameplayGameMode@ aGameplayGameMode, SValue@ save) 
	{
		//g_windowInput = WindowInput();
	}

	[Hook]
	void GameModeUpdate(BaseGameMode@ baseGameMode, int ms, GameInput& gameInput, MenuInput& menuInput) 
	{
		// Keycode 58 = F1
		//if(!Platform::GetKeyState(58).Pressed)
		//	return;

		// Showing how many Window objects there are, if 0 you don't have any UI windows open like Character sheet or guild hall
		//print("m_objects.length(): " + baseGameMode.m_windowManager.m_objects.length());
		if(GetLocalPlayer() is null)
			return;

		auto equipmentOnFloor = cast<Item::UnitBehavior>(GetLocalPlayer().GetTopUsable());
		if(equipmentOnFloor !is null)
			ShowCompareGroundEquipment(equipmentOnFloor);

		if(!Lobby::IsInLobby())
			return;

		ShowCompareTooltipForUI(baseGameMode);

		// Ugly stuff, dont want (big) loops in GameModeUpdate
		// but if more tabs are added its also not guaranteed it stay in the same place
		// for now assume it will stay the same
		//if (plyCharTab !is null)
		//{
		//	if(tabWindowIndex == -1){
		//		uint charId = HashString("character");
		//		for (uint j = 0; j < plyCharTab.m_tabSystem.m_tabs.length(); j++)
		//		{
		//			auto tab = plyCharTab.m_tabSystem.m_tabs[j];
		//			if (tab.m_id == charId)
		//			{
		//				ShowCompareTooltip(tab);
		//			}
		//		}
		//	}else{
		//		ShowCompareTooltip(plyCharTab.m_tabSystem.m_tabs[tabWindowIndex];
		//	}
		//}

	}

	[Hook]
	void GameModePausedUpdate(BaseGameMode@ baseGameMode, int ms, GameInput& gameInput, MenuInput& menuInput) 
	{
		ShowCompareTooltipForUI(baseGameMode);
	}

	// Main function
	void ShowCompareTooltipForUI(BaseGameMode@ baseGameMode) {
		auto sarcophagusWindow = cast<SarcophagusWindow>(GetOpenWindow(baseGameMode));
		if(sarcophagusWindow !is null)
			CompareSarcophagusEquipmentTooltip(sarcophagusWindow);

		auto shopWindow = cast<ShopWindow>(GetOpenWindow(baseGameMode));
		if(shopWindow !is null)
			ShowShopWindowCompareTooltip(shopWindow);

		auto plyCharTab = cast<PlayerMenu>(GetOpenWindow(baseGameMode));
		if(plyCharTab !is null)
			ShowCompareInventoryTooltip(plyCharTab);
	}

	void CompareSarcophagusEquipmentTooltip(SarcophagusWindow@ window) {
		//print(Reflect::GetTypeName(cast<SpriteButtonWidget>(cast<SarcophagusWindow>(cast<BaseGameMode>(g_gameMode).m_windowManager.GetCurrentWindow()).m_input.GetCurrentInteractable())));
		//cast<SarcophagusReward>(cast<SarcophagusWindow>(cast<BaseGameMode>(g_gameMode).m_windowManager.GetCurrentWindow()).m_input.GetCurrentInteractable())

		int hoverIndex = parseInt(cast<SarcophagusWindow>(cast<BaseGameMode>(g_gameMode).m_windowManager.GetCurrentWindow()).m_input.GetCurrentInteractable().m_id);
		auto equipment = cast<SarcophagusRewardEquipment>(window.m_sarcophagusItem.m_rewardPairs[hoverIndex].m_reward);
		//auto equipment = cast<SarcophagusRewardEquipment>(window.m_input.GetCurrentInteractable());
		if (equipment is null)
			return;

		if(equipment.m_item is null)
			return;

		// Small debug printing
		//print(equipment.m_item.GetName());
		//print("start comparing...");

		if (cast<CompareItemTooltip>(window.m_manager.m_tooltip) is null)
			window.m_manager.SetTooltip(Item::BuildCompareItemTooltip(equipment.m_item, equipment.m_item.GetPrice()));
	}

	void ShowCompareGroundEquipment(Item::UnitBehavior@ behavior) {
		if(cast<Equipment::Equipment>(behavior.m_item) !is null)
			@behavior.m_tooltip = Item::BuildCompareItemTooltip(behavior.m_item, behavior.m_item.GetPrice());
	}

	void ShowCompareInventoryTooltip(PlayerMenu@ plyCharTab) {
		//for(uint i = 0; i < plyCharTab.m_tabSystem.m_tabs.length(); i++)
		//	print("tab " + i + ": " + plyCharTab.m_tabSystem.m_tabs[i].m_id);

		auto tab = plyCharTab.m_tabSystem.m_tabs[tabWindowIndex];
		auto charWindow = cast<PlayerMenuCharacterTab>(tab);
		if (charWindow !is null) {
			auto inventoryScroll = cast<ScrollbarWidget>(tab.m_input.GetCurrentInteractable());
			if (inventoryScroll is null)
				return;

			auto equipment = cast<EquipmentItemWidget>(inventoryScroll.m_input.GetCurrentInteractable());
			if (equipment is null)
				return;

			if(equipment.m_item is null || equipment.m_type != ItemWidgetType::Inventory)
				return;

			// Small debug printing
			//print(equipment.m_item.GetName());
			//print("start comparing...");

			if (cast<CompareItemTooltip>(plyCharTab.m_manager.m_tooltip) is null)
				plyCharTab.m_manager.SetTooltip(Item::BuildCompareItemTooltip(equipment.m_item, equipment.m_item.GetPrice()));
				//plyCharTab.m_manager.SetTooltip(Item::BuildItemTooltip(equipment.m_item, equipment.m_item.GetPrice(), 1));
			//else
		}
	}

	void ShowShopWindowCompareTooltip(ShopWindow@ shopWindow) {
		int refIndex = shopWindow.m_itemList.m_children.findByRef(shopWindow.m_itemList.m_input.GetCurrentInteractable());
		if (refIndex == -1)
			return;

		auto shopItem = shopWindow.m_shopItems[refIndex];
		auto actualItem = shopItem.GetItem();
		if (actualItem !is null && actualItem.IsEquippable()){
			shopWindow.m_manager.SetTooltip(Item::BuildCompareItemTooltip(actualItem, actualItem.GetPrice()));
		}
		else
			shopItem.ShowTooltip(shopWindow.m_manager); // Original
	}

	AWindowObject@ GetOpenWindow(BaseGameMode@ baseGameMode){
		return baseGameMode.m_windowManager.GetCurrentWindow();
	}

	[Hook]
	void GameModePostStart(AGameplayGameMode@ aGameplayGameMode)
	{
	}

}