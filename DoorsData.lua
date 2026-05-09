DoorsData = DoorsData or {}

DoorsData.WOW_TIPS = {
    "提示：钥石词缀会显著改变节奏，开打前先统一打断和减伤分工。",
    "提示：高层本里，灭团大多源于机制处理，不是单纯伤害不够。",
    "提示：合理留爆发给关键小怪波次，通常比全程无脑交技能更稳。",
    "提示：治疗留一个强力技能给意外情况，能大幅提高容错率。",
    "提示：多利用控制技能减少读条压力，队伍会更轻松。",
    "提示：开怪前标记目标并约定打断顺序，能减少很多失误。",
    "提示：移动中的小细节很重要，尽量边走位边保持输出循环。",
    "提示：了解每个本的高危技能，往往比盲目堆装等更有效。",
    "提示：拉怪节奏要和技能循环匹配，避免关键技能全在空档期。",
    "提示：遇到高压波次先保命再贪伤害，活着才有持续输出。",
    "提示：近战注意脚下与正面锥形，很多猝死都来自站位错误。",
    "提示：坦克开怪前说清路线，能有效减少误开和漏怪。",
    "提示：打断链断掉时，立刻补控而不是硬吃整条读条。",
    "提示：把位移技能留给机制处理，通常比当作纯加速更值。",
    "提示：治疗提前铺 HOT/护盾能显著降低爆发伤害窗口风险。",
    "提示：遇到长读条 boss 技能，先确认是否可规避再考虑硬抗。",
    "提示：团队减伤尽量轮转使用，不要全部堆在同一波。",
    "提示：熟悉每个职业的关键控制，副本容错会高很多。",
    "提示：仇恨不稳时先停手 1 秒，避免无意义减员。",
    "提示：清小怪时注意巡逻怪路径，避免连锁误拉。",
    "提示：钥石层数越高，路线和细节越重要，盲打很难稳定。",
    "提示：面对持续流血类伤害时，预留解控和驱散资源。",
    "提示：高层本中复活战术价值极高，别在低收益时机交掉。",
    "提示：能躲的技能就躲，治疗资源要留给不可避免伤害。",
    "提示：切目标前先看读条，优先处理危险施法单位。",
    "提示：副本里保持沟通简短明确，越关键时刻越需要清晰信息。",
    "提示：如果一波总是翻车，先复盘死因再调整拉法。",
    "提示：稳定通关来自一致执行，而不是偶尔的极限操作。",
}

-- 地下城数据表（按赛季池组织）：
-- name         英文名，主要给 tooltip 和后续 spell 名映射用。
-- subtitle     中文展示名。
-- spellID      对应传送法术 ID。未知时可留 nil。
-- fallbackIcon 没有专用贴图时的临时图标。
-- seasons      当前仅保留 12.0-S1。
-- color        卡片主题色。
DoorsData.DUNGEONS = {
    {
        name = "Magisters' Terrace",
        subtitle = "魔导师平台",
        spellID = 1254572,
        fallbackIcon = 135986,
        seasons = { "12.0-S1" },
        color = {0.77, 0.56, 0.24},
    },
    {
        name = "Maisara Caverns",
        subtitle = "迈萨拉洞窟",
        spellID = 1254559,
        fallbackIcon = 134430,
        seasons = { "12.0-S1" },
        color = {0.29, 0.62, 0.52},
    },
    {
        name = "Nexus-Point Xenas",
        subtitle = "节点希纳斯",
        spellID = 1254563,
        fallbackIcon = 237538,
        seasons = { "12.0-S1" },
        color = {0.46, 0.42, 0.74},
    },
    {
        name = "Windrunner Spire",
        subtitle = "风行者之塔",
        spellID = 1254400,
        fallbackIcon = 132321,
        seasons = { "12.0-S1" },
        color = {0.73, 0.52, 0.70},
    },
    {
        name = "Algeth'ar Academy",
        subtitle = "艾杰斯亚学院",
        spellID = 393273,
        fallbackIcon = 4672495,
        seasons = { "12.0-S1" },
        color = {0.63, 0.69, 0.36},
    },
    {
        name = "Pit of Saron",
        subtitle = "萨隆矿坑",
        spellID = 1254555,
        fallbackIcon = 236712,
        seasons = { "12.0-S1" },
        color = {0.44, 0.62, 0.72},
    },
    {
        name = "Seat of the Triumvirate",
        subtitle = "执政团之座",
        spellID = 1254551,
        fallbackIcon = 1714939,
        seasons = { "12.0-S1" },
        color = {0.61, 0.46, 0.80},
    },
    {
        name = "Skyreach",
        subtitle = "通天峰",
        spellID = 159898,
        fallbackIcon = 1041234,
        seasons = { "12.0-S1" },
        color = {0.81, 0.69, 0.39},
    },
}

-- 副本掉落表：一条记录对应一个副本，不再按中英文拆分 key。
-- sample=true 表示当前只是 UI 演示数据，itemID 不是最终权威掉落。
-- track: "CHAMPION" / "HERO" / "MYTH"，前端按装备等级层级筛选。
DoorsData.DUNGEON_LOOT = {
    {
        name = "Magisters' Terrace",
        subtitle = "魔导师平台",
        sample = false,
        journalInstanceID = 1300,
        journalEncounterIDs = { 2659, 2661, 2660, 2662 },
        drops = {},
    },
    {
        name = "Maisara Caverns",
        subtitle = "迈萨拉洞窟",
        sample = false,
        journalInstanceID = 1315,
        journalEncounterIDs = { 2810, 2811, 2812 },
        drops = {},
    },
    {
        name = "Nexus-Point Xenas",
        subtitle = "节点希纳斯",
        sample = false,
        journalInstanceID = 1316,
        journalEncounterIDs = { 2813, 2814, 2815 },
        drops = {},
    },
    {
        name = "Windrunner Spire",
        subtitle = "风行者之塔",
        sample = false,
        journalInstanceID = 1299,
        journalEncounterIDs = { 2655, 2656, 2657, 2658 },
        drops = {},
    },
    {
        name = "Algeth'ar Academy",
        subtitle = "艾杰斯亚学院",
        sample = false,
        journalInstanceID = 1201,
        journalEncounterIDs = { 2509, 2512, 2495, 2514 },
        drops = {},
    },
    {
        name = "Pit of Saron",
        subtitle = "萨隆矿坑",
        sample = false,
        journalInstanceID = 278,
        journalEncounterIDs = { 608, 609, 610 },
        drops = {},
    },
    {
        name = "Seat of the Triumvirate",
        subtitle = "执政团之座",
        sample = false,
        journalInstanceID = 945,
        journalEncounterIDs = { 1979, 1980, 1981, 1982 },
        drops = {},
    },
    {
        name = "Skyreach",
        subtitle = "通天峰",
        sample = false,
        journalInstanceID = 476,
        journalEncounterIDs = { 965, 966, 967, 968 },
        drops = {},
    },
}

-- 团本掉落表：结构与 DUNGEON_LOOT 保持一致。
-- 当前先把 12.0-S1 团本入口预留出来，后续可直接补 journal 信息或静态掉落池。
DoorsData.RAID_LOOT = {
    {
        name = "The Voidspire",
        subtitle = "虚影尖塔",
        sample = false,
        journalInstanceID = 1307,
        journalEncounterIDs = { 2733, 2734, 2736, 2735, 2737, 2738 },
        drops = {},
    },
    {
        name = "The Dreamrift",
        subtitle = "梦境裂隙",
        sample = false,
        journalInstanceID = 1314,
        journalEncounterIDs = { 2795 },
        drops = {},
    },
    {
        name = "Assault on Quel'Danas",
        subtitle = "进军奎尔丹纳斯",
        sample = false,
        journalInstanceID = 1308,
        journalEncounterIDs = { 2739, 2740 },
        drops = {},
    },
}

-- 团本数据表：当前用于数据归档，spellID 未知可留 nil。
DoorsData.RAIDS = {
    {
        name = "The Voidspire",
        subtitle = "虚影尖塔",
        spellID = nil,
        seasons = { "12.0-S1" },
    },
    {
        name = "The Dreamrift",
        subtitle = "梦境裂隙",
        spellID = nil,
        seasons = { "12.0-S1" },
    },
    {
        name = "Assault on Quel'Danas",
        subtitle = "进军奎尔丹纳斯",
        spellID = nil,
        seasons = { "12.0-S1" },
    },
}

-- 尾王资料表：
-- finalBoss: 尾王名字（待核对时可先写“待补充”）
-- quotes: 口头禅列表（可放开怪、转阶段、击杀等经典台词）
DoorsData.FINAL_BOSS_QUOTES = {
    dungeons = {
        {
            name = "Magisters' Terrace",
            subtitle = "魔导师平台",
            finalBoss = "凯尔萨斯·逐日者",
            quotes = {
                "仅仅是挫折而已！（经典台词）",
                "你们很快就会理解，反抗毫无意义。",
            },
        },
        {
            name = "Maisara Caverns",
            subtitle = "迈萨拉洞窟",
            finalBoss = "待补充",
            quotes = {},
        },
        {
            name = "Nexus-Point Xenas",
            subtitle = "节点希纳斯",
            finalBoss = "待补充",
            quotes = {},
        },
        {
            name = "Windrunner Spire",
            subtitle = "风行者之塔",
            finalBoss = "待补充",
            quotes = {},
        },
        {
            name = "Algeth'ar Academy",
            subtitle = "艾杰斯亚学院",
            finalBoss = "多拉苟萨的回响",
            quotes = {
                "知识属于强者，而你们不配触碰。",
                "奥术将净化一切杂音。",
            },
        },
        {
            name = "Pit of Saron",
            subtitle = "萨隆矿坑",
            finalBoss = "天灾领主泰兰努斯",
            quotes = {
                "前进吧，寒冰将碾碎你们的希望。",
                "在巫妖王的意志前，你们无处可逃。",
            },
        },
        {
            name = "Seat of the Triumvirate",
            subtitle = "执政团之座",
            finalBoss = "鲁拉",
            quotes = {
                "你们终将被虚空低语吞没。",
                "光与影的平衡，将由我来改写。",
            },
        },
        {
            name = "Skyreach",
            subtitle = "通天峰",
            finalBoss = "高阶贤者维里克斯",
            quotes = {
                "我沐浴于太阳之力。",
                "太阳之辉将把你们化为灰烬。",
            },
        },
    },
    raids = {
        {
            name = "The Voidspire",
            subtitle = "虚影尖塔",
            finalBoss = "萨尔哈达尔（待最终确认）",
            quotes = {
                "你们攀登得越高，坠入虚空就越深。",
                "在这里，现实只剩下被吞噬的命运。",
            },
        },
        {
            name = "The Dreamrift",
            subtitle = "梦境裂隙",
            finalBoss = "待补充",
            quotes = {},
        },
        {
            name = "Assault on Quel'Danas",
            subtitle = "进军奎尔丹纳斯",
            finalBoss = "待补充",
            quotes = {},
        },
    },
}
