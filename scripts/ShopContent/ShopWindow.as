class ShopWindow : AWindowObject
{
	AShopContent@ m_shopContent;
	array<IShopItem@> m_shopItems;

	TextWidget@ m_shopTitle;

	EntryShopItemWidget@ m_buttonTemplate;
	ScrollbarWidget@ m_itemList;
	TextWidget@ m_itemDescription;
	TextWidget@ m_currencyText;
	TextWidget@ m_emptyPrompt;

	bool m_skipCost;
	bool m_gold;
	bool m_wood;
	bool m_stone;
	bool m_iron;
	bool m_crystal;
	bool m_dust;
	bool m_fragments;

	ShopWindow(GUIBuilder@ b, AShopContent@ content, const string &in fileName = "gui/shops/default.gui", bool skipCost = false)
	{
		super(b, fileName);
		m_skipCost = skipCost;

		@m_shopTitle = cast<TextWidget>(m_widget.GetWidgetById("title"));

		@m_buttonTemplate = cast<EntryShopItemWidget>(m_widget.GetWidgetById("template"));
		@m_itemList = cast<ScrollbarWidget>(m_widget.GetWidgetById("list"));
		@m_itemDescription = cast<TextWidget>(m_widget.GetWidgetById("description"));
		@m_currencyText = cast<TextWidget>(m_widget.GetWidgetById("currency"));
		@m_emptyPrompt = cast<TextWidget>(m_widget.GetWidgetById("empty"));

		BuildList(content);

		@m_input.m_menuContextOnPressed = WindowInput::OnFunc(this.MenuContext);

		PauseGame(true, true);
	}

	void OnClose() override
	{
		PauseGame(false, true);
	}

	void BuildList(AShopContent@ content)
	{
		Clear();

		if (content is null)
			return;

		if (m_shopTitle !is null)
			m_shopTitle.SetText(Resources::GetString(content.GetName()));

		@m_shopContent = content;

		Refresh();
	}

	void Clear()
	{
		if (m_shopTitle !is null)
			m_shopTitle.SetText("");

		@m_shopContent = null;

		if (m_itemList !is null)
			m_itemList.ClearChildren();
	}

	array<string>@ GetShownIcons() override
	{
		array<string> icons;
		
		if (m_gold)
			icons.insertLast("gold");
		if (m_wood)
			icons.insertLast("wood");
		if (m_stone)
			icons.insertLast("stone");
		if (m_iron)
			icons.insertLast("iron");
		if (m_crystal)
			icons.insertLast("crystal");
		if (m_dust)
			icons.insertLast("dust");
		if (m_fragments)
			icons.insertLast("fragments");
		
		return icons;
	}

	void Refresh()
	{
		m_itemList.ClearChildren();

		m_shopItems = m_shopContent.GetItems();
		for (uint i = 0; i < m_shopItems.length(); i++)
		{
			auto currItem = m_shopItems[i];
			
			auto newButton = cast<EntryShopItemWidget>(m_buttonTemplate.Clone());
			newButton.SetID(currItem.GetID());
			newButton.m_visible = true;
			newButton.SetTitle(currItem.GetTitle());
			newButton.SetSubTitle(currItem.GetSubTitle());
			
			auto iconColor = vec4(1);
			auto eqItem = cast<Equipment::Equipment>(currItem.GetItem());
			if (eqItem !is null && !m_shopContent.m_player.equipped.MayEquip(eqItem))
				iconColor = vec4(1,0,0,1);
			
			newButton.SetIcon(currItem.GetIcon(), iconColor);
			newButton.SetBackground(currItem.GetBackground());
			@newButton.m_shopItem = currItem;

			if (!m_skipCost)
			{
				auto cost = currItem.GetCost();
				if (cost !is null)
				{
					newButton.SetCostText(cost.GetText(m_shopContent.m_player, true));
					
					m_gold = m_gold || cost.GetCost(MaterialType::Gold) != 0;
					m_wood = m_wood || cost.GetCost(MaterialType::Wood) != 0;
					m_stone = m_stone || cost.GetCost(MaterialType::Stone) != 0;
					m_iron = m_iron || cost.GetCost(MaterialType::Iron) != 0;
					m_crystal = m_crystal || cost.GetCost(MaterialType::Crystals) != 0;
					m_dust = m_dust || cost.GetCost(MaterialType::Dust) != 0;
					m_fragments = m_fragments || cost.GetCost(MaterialType::Fragments) != 0;
				}
				else
					newButton.SetCostText("");
			}

			newButton.m_navPos = ivec2(0, i);

			m_itemList.AddChild(newButton);
		}

		if (m_shopItems.length() > 0)
			m_emptyPrompt.SetText("");
		else
			m_emptyPrompt.SetText(Resources::GetString(m_shopContent.GetEmptyShopText()));

		if (m_currencyText !is null)
		{
			m_currencyText.SetText("");

			auto builder = cast<BuildingBuilderContent>(m_shopContent);
			if (builder !is null && builder.m_currentlyBuilding is null)
				m_gold = m_wood = m_stone = m_iron = m_crystal = m_dust = m_fragments = false;

			auto record = GetLocalPlayerRecord();
			StringBuilder sb;
		
			if (m_gold)
			{
				sb += Resources::GetString(".tab.overlay.player.gold", {{ "amount", record.GetMaterial(MaterialType::Gold) }});
				sb += " ";
			}
			
			if (m_wood)
			{
				sb += Resources::GetString(".tab.overlay.player.wood", {{ "amount", record.GetMaterial(MaterialType::Wood) }});
				sb += " ";
			}
			
			if (m_stone)
			{
				sb += Resources::GetString(".tab.overlay.player.stone", {{ "amount", record.GetMaterial(MaterialType::Stone) }});
				sb += " ";
			}
			
			if (m_iron)
			{
				sb += Resources::GetString(".tab.overlay.player.iron", {{ "amount", record.GetMaterial(MaterialType::Iron) }});
				sb += " ";
			}
			
			if (m_crystal)
			{
				sb += Resources::GetString(".tab.overlay.player.crys", {{ "amount", record.GetMaterial(MaterialType::Crystals) }});
				sb += " ";
			}
			
			if (m_dust)
			{
				sb += Resources::GetString(".tab.overlay.player.dust", {{ "amount", record.GetMaterial(MaterialType::Dust) }});
				sb += " ";
			}
			
			if (m_fragments)
			{
				sb += Resources::GetString(".tab.overlay.player.frag", {{ "amount", record.GetMaterial(MaterialType::Fragments) }});
				sb += " ";
			}

			m_currencyText.SetText(sb.String());
		}

		RefreshInteractableWidgets(m_widget);
	}

	void OnInteractableIndexChanged() override
	{
		AWindowObject::OnInteractableIndexChanged();

		if (m_itemList is null)
			return;
		
		m_manager.CloseTooltip();

		print("Changed...");

		int refIndex = m_itemList.m_children.findByRef(m_itemList.m_input.GetCurrentInteractable());
		if (refIndex == -1)
			return;

		auto shopItem = m_shopItems[refIndex];
		auto actualItem = shopItem.GetItem();
		if (actualItem !is null && actualItem.IsEquippable())
			m_manager.SetTooltip(Item::BuildCompareItemTooltip(actualItem, actualItem.GetPrice()));
		else
			shopItem.ShowTooltip(m_manager); // Original

		
	}

	void MenuContext()
	{
		if (!m_shopContent.ShowInfo())
			return;

		int refIndex = m_itemList.m_children.findByRef(m_itemList.m_input.GetCurrentInteractable());
		if (refIndex == -1)
			return;

		auto shopItem = m_shopItems[refIndex];
		auto shopItemsItem = shopItem.GetItem();
		if (shopItemsItem !is null)
			m_manager.SetTooltip(Item::BuildCompareItemTooltip(shopItemsItem, shopItemsItem.GetPrice()));
	}

	void OnFunc(Widget@ sender, const string &in name) override
	{
		if (name == "close")
			m_closing = true;

		if (m_shopContent is null)
			return;

		int refIndex = m_itemList.m_children.findByRef(sender);
		if (refIndex == -1)
			return;

		print("OnFunc: " + name);
		string itemFunc = "";
		auto shopItem = m_shopItems[refIndex];
		if (shopItem !is null)
			itemFunc = shopItem.OnFunc();

		array<string> parse = name.split(" ");
		if (parse[0] == "buy")
		{
			bool bought = true;
			
			ShopCost@ cost = null;
			if (shopItem.AutoSpendCost())
				@cost = shopItem.GetCost();
			
			if (cost !is null)
			{
				auto item = shopItem.GetItem();
				if (item !is null)
				{
					if (!m_shopContent.m_player.CanAddItem(item) || !cost.CanAfford(m_shopContent.m_player))
						bought = false;
					else
						cost.Spend(m_shopContent.m_player);
				}
				else
				{
					if (!cost.CanAfford(m_shopContent.m_player))
						bought = false;
					else
						cost.Spend(m_shopContent.m_player);
				}
			}
			
			if (bought)
			{
				m_shopContent.Buy(itemFunc, HashString(sender.m_id), shopItem);
				Refresh();
			}
		}
		else if (parse[0] == "hover")
		{
			// if (parse[1] == "enter")
			// 	m_itemDescription.SetText(shopItem.GetDescription());
			// else if (parse[1] == "leave")
			// 	m_itemDescription.SetText("");
		}
		else if (parse[0] == "close")
			m_closing = true;
	}
}