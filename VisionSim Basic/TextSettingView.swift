import SwiftUI
import CoreData

struct TextSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var textSetting: TextSetting
    @State private var isControlPanelVisible = true

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // TextEditorComponent
                    TextEditorComponent(
                        text: Binding(
                            get: { textSetting.textFieldData ?? "" },
                            set: {
                                textSetting.textFieldData = $0
                                try? viewContext.save()
                            }
                        ),
                        fontSize: CGFloat(textSetting.textSize),
                        fontWeightValue: textSetting.textWeight,
                        textColor: UIColor(Color(hex: textSetting.textColor?.textColorCode ?? "#000000")),
                        backgroundColor: UIColor(Color(hex: textSetting.backgroundColor?.backgroundColorCode ?? "#FFFFFF")),
                        isEditable: true
                    )
                    .frame(height: isControlPanelVisible ? geometry.size.height * 0.6 : geometry.size.height)

                    Spacer()
                }

                VStack {
                    // コントロールパネル
                    if isControlPanelVisible {
                        ControlPanel(
                            textSetting: textSetting,
                            isVisible: $isControlPanelVisible
                        )
                        .frame(height: geometry.size.height * 0.4)
                        .transition(.move(edge: .bottom))
                    } else {
                        // 表示ボタン（下中央に配置）
                        ShowControlPanelButton(isVisible: $isControlPanelVisible)
                            .padding(.bottom, 90)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.spring(), value: isControlPanelVisible)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ControlPanel: View {
    @ObservedObject var textSetting: TextSetting
    @Binding var isVisible: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ColorEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ColorEntity.colorCode, ascending: true)]
    ) var colorPairs: FetchedResults<ColorEntity>
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
                Spacer()
                Text("設定")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            HStack(alignment: .top, spacing: 20) {
                // コントラストパターン選択
                VStack {
                    Text("コントラスト")
                        .font(.headline)
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(colorPairs, id: \.self) { colorPair in
                                Button(action: {
                                    textSetting.backgroundColor = colorPair
                                    textSetting.textColor = colorPair
                                    try? viewContext.save()
                                }) {
                                    VStack {
                                        ColorPairPreview(backgroundColor: colorPair, textColor: colorPair)
                                            .frame(height: 50)
                                            .cornerRadius(5)
                                        Text(colorPair.colorCode ?? "")
                                            .font(.caption2)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }

                // テキスト設定スライダー
                VStack {
                    TextSettingSlider(value: $textSetting.textSize, range: 10...30, step: 1, title: "文字の大きさ")
                    TextSettingSlider(value: $textSetting.textWeight, range: 0...5, step: 0.1, title: "文字の太さ")
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct ShowControlPanelButton: View {
    @Binding var isVisible: Bool

    var body: some View {
        Button(action: { isVisible = true }) {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.white)
                .padding(10)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
}

struct ColorPairPreview: View {
    let backgroundColor: ColorEntity
    let textColor: ColorEntity

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: backgroundColor.backgroundColorCode ?? "#FFFFFF"))
            VStack {
                Text("Aa")
                    .font(.caption)
                    .fontWeight(.bold)
                Text("あア亜")
                    .font(.caption2)
            }
            .foregroundColor(Color(hex: textColor.textColorCode ?? "#000000"))
        }
    }
}

struct TextSettingSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let title: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Slider(value: $value, in: range, step: step)
            Text(String(format: "%.1f", value))
                .font(.caption)
        }
    }
}

extension UIColor {
    convenience init(color: Color) {
        let components = color.components()
        self.init(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
        }
        return (r, g, b, a)
    }
}

struct TextSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let textSetting = TextSetting(context: context)
        textSetting.textFieldData = "サンプルテキスト"
        textSetting.textSize = 16
        textSetting.textWeight = 0.5
        
        let colorEntity = ColorEntity(context: context)
        colorEntity.colorCode = "黒on白"
        colorEntity.backgroundColorCode = "#FFFFFF"
        colorEntity.textColorCode = "#000000"
        
        textSetting.backgroundColor = colorEntity
        textSetting.textColor = colorEntity
        
        return TextSettingsView(textSetting: textSetting)
            .environment(\.managedObjectContext, context)
    }
}
