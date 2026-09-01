import Foundation

enum CreationMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case pictograph = "象形"
    case indicative = "指事"
    case associative = "會意"
    case phonoSemantic = "形聲"
    case derivative = "轉注"
    case phoneticLoan = "假借"

    var id: String { rawValue }

    var shortDefinition: String {
        switch self {
        case .pictograph: "畫出事物形象"
        case .indicative: "用符號指出抽象概念"
        case .associative: "合併字義產生新意"
        case .phonoSemantic: "形旁表義，聲旁提示讀音"
        case .derivative: "同源字互相訓釋"
        case .phoneticLoan: "借同音或近音字表達新義"
        }
    }

    var detail: String {
        switch self {
        case .pictograph:
            "用線條描畫看得見的事物。字形演變後雖然不再像圖畫，仍保留原始輪廓。"
        case .indicative:
            "對不容易當成圖畫的概念，用位置、符號或標記指出意思。"
        case .associative:
            "將兩個以上的字義組合，讓讀者從元件關係會出新意。"
        case .phonoSemantic:
            "一部分提示意義類別，另一部分提示古代讀音。現代讀音可能已改變。"
        case .derivative:
            "轉注的定義向來有爭議。國中教材常以「老、考」為同源互訓的例子。"
        case .phoneticLoan:
            "原本沒有專用字時，先借讀音相同或相近的現成字來記錄。"
        }
    }

    var examples: [String] {
        switch self {
        case .pictograph: ["日", "月", "山", "水"]
        case .indicative: ["上", "下", "本", "刃"]
        case .associative: ["休", "林", "森", "尖"]
        case .phonoSemantic: ["河", "晴", "銅", "清"]
        case .derivative: ["老↔考", "頂↔顛"]
        case .phoneticLoan: ["來", "自", "北", "萬"]
        }
    }

    var systemImage: String {
        switch self {
        case .pictograph: "photo.on.rectangle.angled"
        case .indicative: "hand.point.up.left.fill"
        case .associative: "square.3.layers.3d"
        case .phonoSemantic: "waveform.and.magnifyingglass"
        case .derivative: "arrow.triangle.2.circlepath"
        case .phoneticLoan: "arrow.left.arrow.right"
        }
    }
}
