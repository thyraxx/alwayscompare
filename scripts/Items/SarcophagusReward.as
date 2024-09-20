class SarcophagusReward
{
	SarcophagusReward() {}

	void GiveReward(PlayerRecord@ record) {}
	ITooltip@ GetTooltip() { return null; }
	ScriptSprite@ GetIcon() { return null; }
	Item::Quality GetQuality() const { return Item::Quality::None; }
	int GetSortingOrder() const { return 0; }
	int GetCurseCost() { return 0; }

	int opCmp(const SarcophagusReward &in reward)
	{
		int sortA = GetSortingOrder();
		int sortB = reward.GetSortingOrder();
		if (sortA != sortB)
		{
			if (sortA < sortB)
				return -1;

			return 1;
		}

		Item::Quality qualityA = GetQuality();
		Item::Quality qualityB = reward.GetQuality();
		if (qualityA != qualityB)
		{
			if (qualityA < qualityB)
				return -1;

			return 1;
		}

		// TODO Sort by name?

		return 0;
	}
}

class SarcophagusRewardTrinket : SarcophagusReward
{
	Item::Trinket@ m_item;

	SarcophagusRewardTrinket(SValue& params, PlayerRecord@ record)
	{
		super();

		auto data = params.GetArray();
		auto quality = Item::ParseQuality(data[1].GetString());

		@m_item = cast<Item::Trinket>(Item::GetRandomTrinket(record, quality)); // We set m_seen = false if not picked in sarcophagus behavior.
	}

	void GiveReward(PlayerRecord@ record) override
	{
		record.GiveItem(m_item);
	}

	Item::Quality GetQuality() const override
	{
		return m_item.GetQuality();
	}

	int GetCurseCost() override
	{
		switch (m_item.GetQuality())
		{
			case Item::Quality::Common: return 1;
			case Item::Quality::Uncommon: return 2;
			case Item::Quality::Rare: return 5;
			case Item::Quality::Epic: return 10;
			case Item::Quality::Legendary: return 15;
		}
		return 0;
	}

	ITooltip@ GetTooltip() override
	{
		return Item::BuildItemTooltip(m_item, m_item.GetPrice(), 1);
	}

	ScriptSprite@ GetIcon() override
	{
		return m_item.GetIcon();
	}

	int GetSortingOrder() const override
	{
		return 0;
	}
}

class SarcophagusRewardEquipment : SarcophagusReward
{
	Equipment::Item@ m_item;

	SarcophagusRewardEquipment(SValue& params, PlayerRecord@ record)
	{
		super();

		UnitPtr u;

		Equipment::Slot slots = Equipment::Slot::None;
		array<SValue@>@ slotArr = GetParamArray(u, params, "slot", false);
		if (slotArr !is null)
		{
			for (uint j = 0; j < slotArr.length(); j++)
				slots = Equipment::Slot(uint(slots) | uint(Equipment::ParseItemSlot(slotArr[j].GetString())));
		}
		else
			slots = Equipment::Slot(uint(Equipment::Slot::MainHand) | uint(Equipment::Slot::OffHand) | uint(Equipment::Slot::TwoHanded) | uint(Equipment::Slot::Head) | uint(Equipment::Slot::Chest) | uint(Equipment::Slot::Feet) | uint(Equipment::Slot::Hands));

		array<uint> tags;
		auto tagArr = GetParamArray(u, params, "tags", false);
		if (tagArr !is null)
		{
			for (uint j = 0; j < tagArr.length(); j++)
				tags.insertLast(HashString(tagArr[j].GetString()));
		}

		array<uint> modTags;
		auto modTagArr = GetParamArray(u, params, "modifier-tags", false);
		if (modTagArr !is null)
		{
			for (uint j = 0; j < modTagArr.length(); j++)
				modTags.insertLast(HashString(modTagArr[j].GetString()));
		}

		ivec2 ilvl = GetParamIVec2(u, params, "ilvl", false, ivec2(0,0));

		Equipment::Generator gen;
		gen.m_qualities = Item::ParseQuality(GetParamString(u, params, "quality", false));
		gen.m_slots = slots;

		auto missionGM = cast<MissionGameModeBase>(g_gameMode);
		if (missionGM !is null && missionGM.m_missionLevel !is null)
			gen.m_ilvl = max(1, missionGM.m_missionLevel.m_diffLevel + Modifiers::lerp(ilvl, randf()));
		else
			gen.m_ilvl = max(1, 1 + Modifiers::lerp(ilvl, randf()));

		@m_item = gen.GenerateKindItem(record, tags, modTags);
	}

	void GiveReward(PlayerRecord@ record) override
	{
		record.GiveItem(m_item);
	}

	Item::Quality GetQuality() const override
	{
		return m_item.GetQuality();
	}

	int GetCurseCost() override
	{
		switch (m_item.GetQuality())
		{
			case Item::Quality::Common: return 2;
			case Item::Quality::Uncommon: return 3;
			case Item::Quality::Rare: return 6;
			case Item::Quality::Epic: return 12;
			case Item::Quality::Legendary: return 18;
		}
		return 0;
	}

	ITooltip@ GetTooltip() override
	{
		//return Item::BuildItemTooltip(m_item, m_item.GetPrice(), 1);
		return Item::BuildCompareItemTooltip(m_item, m_item.GetPrice());
	}

	ScriptSprite@ GetIcon() override
	{
		return m_item.GetIcon();
	}

	int GetSortingOrder() const override
	{
		return 1;
	}
}

class SarcophagusRewardSkillSphere : SarcophagusReward
{
	PlayerSkillDef@ m_skillItem;
	int m_skillLevel;
	Sarcophagus@ m_sarcophagusItem;
	PlayerRecord@ m_record;

	SarcophagusRewardSkillSphere(SValue& params, PlayerRecord@ record, Sarcophagus@ sarcophagusItem)
	{
		super();

		@m_record = record;
		@m_sarcophagusItem = sarcophagusItem;

		array<PlayerSkillDef@> possibleSkills;
		for (uint i = 0; i < record.playerClass.m_skillDefs.length(); i++)
			FillPossibleSkills(record, possibleSkills, record.playerClass.m_skillDefs[i], false);

		
		
		@m_skillItem = PickSkill(possibleSkills);
		m_skillLevel = min(record.GetSkillLevel(m_skillItem.m_id) + 1, m_skillItem.m_levelParams.length() - 1);
	}

	void GiveReward(PlayerRecord@ record) override
	{
		record.SkillTempUp(m_skillItem.m_id);
	}

	void FillPossibleSkills(PlayerRecord@ record, array<PlayerSkillDef@>@ possibleSkills, PlayerSkillDef@ skill, bool modSkill)
	{
		if (skill is null)
			return;

		for (uint i = 0; i < skill.m_reqSkills.length(); i++)
		{
			auto sDefB = record.playerClass.GetSkillDef(HashString(skill.m_reqSkills[i]));
			if (sDefB !is null && record.GetSkillLevel(sDefB.m_id) <= 0)
				return;
		}

		for (uint i = 0; i < skill.m_blockerSkills.length(); i++)
		{
			auto sDefB = record.playerClass.GetSkillDef(HashString(skill.m_blockerSkills[i]));
			if (sDefB !is null && record.GetSkillLevel(sDefB.m_id) > 0)
				return;
		}

		int skillLvl = record.GetSkillLevel(skill.m_id);
		if (modSkill && skillLvl < int(skill.m_levelSkillCost.length()))
			possibleSkills.insertLast(skill);

		if (skillLvl > 0)
		{
			for (uint i = 0; i < skill.m_modSkills.length(); i++)
				FillPossibleSkills(record, possibleSkills, skill.m_modSkills[i], true);
		}
	}

	PlayerSkillDef@ PickSkill(array<PlayerSkillDef@>@ possibleSkills)
	{
		if (possibleSkills.length() < 1)
			return null;

		auto sacrophagusSkills = m_sarcophagusItem.GetSkills();

		int totChance = 0;
		for (uint i = 0; i < possibleSkills.length(); i++)
		{
			bool blocked = false;
			for (uint j = 0; j < sacrophagusSkills.length(); j++)
			{
				if (possibleSkills[i].m_parentSkill is sacrophagusSkills[j].m_parentSkill)
					blocked = true;
			}

			if (blocked)
				possibleSkills[i]._m_tmpChanceCounter = 0;
			else
				possibleSkills[i]._m_tmpChanceCounter = GetSkillDropRateChance(possibleSkills[i]);

			totChance += possibleSkills[i]._m_tmpChanceCounter;
		}

		int r = randi(totChance);
		for (uint i = 0; i < possibleSkills.length(); i++)
		{
			r -= possibleSkills[i]._m_tmpChanceCounter;
			if (r < 0)
			{
				auto skill = possibleSkills[i];
				possibleSkills.removeAt(i);
				return skill;
			}
		}

		int idx = randi(possibleSkills.length());
		auto skill = possibleSkills[idx];
		possibleSkills.removeAt(idx);

		return skill;
	}

	Item::Quality GetQuality() const override
	{
		return m_skillItem.m_levelQualities[m_skillLevel];
	}

	int GetCurseCost() override
	{
		switch (m_skillItem.m_levelQualities[m_skillLevel])
		{
			case Item::Quality::Common: return 2;
			case Item::Quality::Uncommon: return 3;
			case Item::Quality::Rare: return 6;
			case Item::Quality::Epic: return 12;
			case Item::Quality::Legendary: return 18;
		}
		return 0;
	}

	ITooltip@ GetTooltip() override
	{
		return CreateSkillSphereTooltip(m_record, m_skillItem);
	}

	ScriptSprite@ GetIcon() override
	{
		return m_skillItem.m_icon;
	}

	int GetSortingOrder() const override
	{
		return 2;
	}
}