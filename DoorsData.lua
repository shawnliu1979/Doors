
DoorsData = DoorsData or {}

-- 各种族经典口号
DoorsData.RACE_SLOGANS = {
    ["兽人"] = { "鲜血与雷鸣！", "为了部落！", "胜利或死亡！" },
    ["人类"] = { "为了暴风城！", "荣耀与正义！", "联盟万岁！" },
    ["矮人"] = { "为了铁炉堡！", "为了烈酒！", "为了联盟！" },
    ["暗夜精灵"] = { "为了艾露恩！", "暗影庇护我们。", "月光指引！" },
    ["亡灵"] = { "为了遗忘者！", "黑暗新生！", "女王万岁！" },
    ["巨魔"] = { "为了巨魔部族！", "祖尔灿烂！", "头颅属于巨魔！" },
    ["牛头人"] = { "为了卡利姆多！", "大地母亲指引我们。", "图腾的力量！" },
    ["侏儒"] = { "为了诺莫瑞根！", "科技改变世界！", "侏儒智慧！" },
    ["地精"] = { "为了财富与荣耀！", "生意兴隆通四海！", "爆炸才是艺术！" },
    ["血精灵"] = { "太阳之井万岁！", "魔法永恒！", "银月城荣耀！" },
    ["德莱尼"] = { "为了纳鲁！", "圣光庇护我们。", "远行者的荣耀！" },
    ["狼人"] = { "吉尔尼斯万岁！", "野性觉醒！", "为家园而战！" },
    ["熊猫人"] = { "为了家园！", "和谐与平衡。", "美食与武道！" },
    ["虚空精灵"] = { "虚空指引着我们！", "虚空之力！", "暗影永恒！" },
    ["夜之子"] = { "苏拉玛万岁！", "魔法与优雅。", "夜之子荣耀！" },
    ["至高岭牛头人"] = { "高岭之巅！", "部族团结！", "图腾守护！" },
    ["玛格汉兽人"] = { "德拉诺之力！", "玛格汉荣耀！", "部落新生！" },
    ["赞达拉巨魔"] = { "赞达拉万岁！", "祖宗保佑！", "帝国荣耀！" },
    ["库尔提拉斯人"] = { "库尔提拉斯之力！", "海洋的意志！", "家族荣耀！" },
    ["黑铁矮人"] = { "黑铁意志！", "烈焰不灭！", "铁与火的传承！" },
    ["机械侏儒"] = { "机械觉醒！", "创新无极限！", "钢铁意志！" },
    ["狐人"] = { "狡诈与机智！", "冒险无极限！", "小身材大智慧！" },
    ["暗铁矮人"] = { "黑铁意志！", "烈焰不灭！", "铁与火的传承！" },
    ["龙希尔"] = { "觉醒者前行！", "龙之荣耀！", "焰火与风暴！" },
}

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
    {
        name = "Sporefall",
        subtitle = "孢陨幽境",
        sample = false,
        journalInstanceID = 1305,
        journalEncounterIDs = { 2711 },
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
    {
        name = "Sporefall",
        subtitle = "孢陨幽境",
        spellID = nil,
        seasons = { "12.0-S1" },
    },
}

-- 尾王资料表：
-- finalBoss: 尾王名字
-- quotes: 口头禅列表（可放开怪、转阶段、击杀等经典台词）
DoorsData.FINAL_BOSS_QUOTES = {
    dungeons = {
        {
            name = "Magisters' Terrace",
            subtitle = "魔导师平台",
            finalBoss = "迪詹崔乌斯",
            quotes = {
                "仅仅是挫折而已！",
                "你们很快就会理解，反抗毫无意义。",
            },
        },
        {
            name = "Maisara Caverns",
            subtitle = "迈萨拉洞窟",
            finalBoss = "拉克图尔，聚魂之器",
            quotes = {
                "灵魂的低语在此回荡。",
                "你们的意志将被聚魂之器吞噬。",
                "拉克图尔渴望新的祭品！",
                "黑暗深渊，无尽轮回。",
            },
        },
        {
            name = "Nexus-Point Xenas",
            subtitle = "节点希纳斯",
            finalBoss = "洛萨克森",
            quotes = {
                "虚空的力量在此汇聚。",
                "你们无法承受节点的能量！",
                "洛萨克森将吞噬一切。",
                "数据流动，混沌降临。",
                "你们的存在只是短暂的变量。",
            },
        },
        {
            name = "Windrunner Spire",
            subtitle = "风行者之塔",
            finalBoss = "无眠之心",
            quotes = {
                "风暴将吞没一切胆敢靠近者。",
                "无眠之心注视着你们的每一步。",
                "在风行者之塔，安眠只是传说。",
                "你们的恐惧将随风飘散。",
            },
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
            finalBoss = "宇宙之冕",
            quotes = {
                "你们攀登得越高，坠入虚空就越深。",
                "在这里，现实只剩下被吞噬的命运。",
            },
        },
        {
            name = "The Dreamrift",
            subtitle = "梦境裂隙",
            finalBoss = "奇美鲁斯, 未梦之神",
            quotes = {},
        },
        {
            name = "Assault on Quel'Danas",
            subtitle = "进军奎尔丹纳斯",
            finalBoss = "贝洛朗, 奥的子嗣",
            quotes = {},
        },
        {
            name = "Sporefall",
            subtitle = "孢陨幽境",
            finalBoss = "腐沼",
            quotes = {},
        },
    },
}
