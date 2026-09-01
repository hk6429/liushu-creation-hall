import Foundation

struct JourneyChapter: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let hook: String
    let characters: [String]
    let storyIndex: Int

    static let all: [JourneyChapter] = [
        .init(id: 0, title: "楔子・結繩記事", hook: "阿滿一覺醒來，站在繩結堆成的上古倉庫。", characters: [], storyIndex: 0),
        .init(id: 1, title: "第一章・象形", hook: "眼睛看得到的輪廓，能不能直接變成字？", characters: ["日", "月", "山", "水", "木", "火"], storyIndex: 1),
        .init(id: 2, title: "第二章・指事", hook: "畫不出的方向與部位，要怎麼『指』給人看？", characters: ["上", "下", "本", "末", "刃", "旦"], storyIndex: 2),
        .init(id: 3, title: "第三章・會意", hook: "字不夠用，倉頡開始玩『文加文』的加法。", characters: ["休", "步", "林", "森"], storyIndex: 3),
        .init(id: 4, title: "第四章・假借", hook: "造字追不上說話，先借一個聲音相近的字。", characters: ["其", "箕", "莫", "暮"], storyIndex: 4),
        .init(id: 5, title: "第五章・形聲", hook: "一邊管意思、一邊提示聲音，造字開始加速。", characters: ["江", "河", "晴", "鴿", "草", "想", "園", "聞"], storyIndex: 5),
        .init(id: 6, title: "第六章・轉注", hook: "隔著時間與地域，近義字仍能互相注釋。", characters: ["考", "老"], storyIndex: 6),
        .init(id: 7, title: "尾聲・把證據帶去答題", hook: "故事可以幫你記，真正的判斷要靠證據。", characters: ["本", "休", "江", "莫", "考", "老"], storyIndex: 7)
    ]
}

struct MasterDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let title: String
    let imageName: String
    let attack: Int
    let unlock: Int
    let level: String?
    let focus: Set<String>
    let taunt: String

    static let all: [MasterDefinition] = [
        .init(id: "wangyirong", name: "王懿榮", title: "甲骨文發現者", imageName: "master-wangyirong", attack: 6, unlock: 0, level: nil, focus: ["象形"], taunt: "一片龍骨，讓我看見三千年前的文字。你呢？"),
        .init(id: "lisi", name: "李斯", title: "小篆定於一尊", imageName: "master-lisi", attack: 9, unlock: 8, level: nil, focus: ["指事", "會意"], taunt: "書同文字！六國異形，皆廢於我手。"),
        .init(id: "guifu", name: "桂馥", title: "說文四大家・義證", imageName: "master-guifu", attack: 12, unlock: 18, level: nil, focus: ["假借"], taunt: "《說文義證》五十卷，字字有據。"),
        .init(id: "wangjun", name: "王筠", title: "說文四大家・句讀", imageName: "master-wangjun", attack: 14, unlock: 30, level: nil, focus: ["會意"], taunt: "我為初學者解說文，也考你這初學者。"),
        .init(id: "zhujunsheng", name: "朱駿聲", title: "說文四大家・通訓定聲", imageName: "master-zhujunsheng", attack: 17, unlock: 45, level: "進階", focus: ["形聲"], taunt: "轉注、假借，盡在我《通訓定聲》彀中。"),
        .init(id: "duanyucai", name: "段玉裁", title: "說文四大家・段注", imageName: "master-duanyucai", attack: 20, unlock: 65, level: "進階", focus: ["轉注", "假借"], taunt: "《說文解字注》三十年而成，豈懼你半日之功？"),
        .init(id: "xushen", name: "許慎", title: "五經無雙・說文解字", imageName: "master-xushen", attack: 24, unlock: 90, level: "進階", focus: Set(CreationMethod.allCases.map(\.rawValue)), taunt: "六書之名，自我而定。敢在關公面前耍大刀？"),
        .init(id: "cangjie", name: "倉頡", title: "四目造字・天雨粟鬼夜哭", imageName: "character-cangjie", attack: 30, unlock: 120, level: "挑戰", focus: Set(CreationMethod.allCases.map(\.rawValue)), taunt: "我造字時，天雨粟、鬼夜哭。你答錯時，也會想哭。")
    ]
}

struct ClassroomPrompt: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let question: String
    let options: [String]
    let answer: String
    let reason: String

    static let evidenceOptions = ["輪廓描畫", "指示記號", "部件會義", "讀音線索", "借音用字", "近義互訓"]
    static let confidenceOptions = ["不確定", "有點把握", "很有把握"]
    static let all: [ClassroomPrompt] = [
        .init(id: "ben-xiu", title: "本與休：都有木，分類一樣嗎？", question: "『本』和『休』都看得到木，兩字的構形方式是否相同？", options: ["相同", "不同"], answer: "不同", reason: "本以短橫指出樹根，是指事；休由人、木會出休息之意，是會意。"),
        .init(id: "mo-axis", title: "莫：一個字，兩條判斷軸", question: "題目問『莫』借作否定詞時，應答哪一類？", options: ["會意", "假借", "形聲"], answer: "假借", reason: "日落草叢是字形構成的會意；借作否定詞則是用字關係的假借。"),
        .init(id: "kao-lao", title: "考與老：何時才是轉注？", question: "題目問『考、老』彼此訓釋的關係時，應答哪一類？", options: ["形聲", "象形", "轉注"], answer: "轉注", reason: "轉注說明兩個同類近義字互相訓釋，不是單看一個字的構形。")
    ]
}
