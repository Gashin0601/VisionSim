import SwiftUI
import CoreData

/// プリセットの概要を表示するカードビュー
struct PresetOverviewCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var preset: Preset
    @State private var showingDebugAlert = false
    @State private var debugMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    var onTextSettingsTap: () -> Void
    var onVisualSimulationTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // ユーザーアイコンとプリセット名
            HStack(alignment: .center, spacing: 15) {
                if let iconData = preset.user?.icon?.imageData, let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                }
                Text(preset.name ?? "Unnamed Preset")
                    .font(.title)
                Spacer()
            }
            .padding(.horizontal, 10)

            // テキスト設定とビジュアルシミュレーションのプレビュー
            HStack(spacing: 0) {
                TextEditorComponent(
                    text: .constant(preset.textSetting?.textFieldData ?? ""),
                    fontSize: CGFloat(preset.textSetting?.textSize ?? 18),
                    fontWeightValue: preset.textSetting?.textWeight ?? 0.5,
                    textColor: UIColor(Color(hex: preset.textSetting?.textColor?.textColorCode ?? "#000000")),
                    backgroundColor: UIColor(Color(hex: preset.textSetting?.backgroundColor?.backgroundColorCode ?? "#FFFFFF")),
                    isEditable: false
                )
                .aspectRatio(1, contentMode: .fit)
                .background(Color.white)
                .cornerRadius(10, corners: [.topLeft, .bottomLeft])
                .padding(.trailing, 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTextSettingsTap()
                }

                VisualSimulationComponent(
                    image: preset.visualSimulation?.selectedImage?.imageData.flatMap(UIImage.init) ?? UIImage(systemName: "photo")!,
                    blurAmount: CGFloat(preset.visualSimulation?.blurriness ?? 0)
                )
                .aspectRatio(1, contentMode: .fit)
                .background(Color.white)
                .cornerRadius(10, corners: [.topRight, .bottomRight])
                .padding(.leading, 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    onVisualSimulationTap()
                }
            }

            // 共有と削除のボタン
            HStack {
                Spacer()
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 10)
                .buttonStyle(PlainButtonStyle())

                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .imageScale(.large)
                        .foregroundColor(.red)
                }
                .padding(.trailing, 10)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding()
        .alert(isPresented: $showingDebugAlert) {
            Alert(title: Text("Debug Info"), message: Text(debugMessage), dismissButton: .default(Text("OK")))
        }
        .actionSheet(isPresented: $showingDeleteConfirmation) {
            ActionSheet(
                title: Text("プリセットを削除"),
                message: Text("このプリセットを削除してもよろしいですか？"),
                buttons: [
                    .destructive(Text("削除")) { deletePreset() },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = createPresetJSONFile(from: preset) {
                ActivityViewController(activityItems: [url])
            }
        }
    }

    /// プリセットを共有する
    private func sharePreset() {
        showingShareSheet = true
    }

    /// プリセットを削除する
    private func deletePreset() {
        viewContext.delete(preset)
        saveContext()
    }

    /// プリセットのJSONファイルを作成する
    private func createPresetJSONFile(from preset: Preset) -> URL? {
        guard let user = preset.user as? User else {
            debugMessage = "Failed to get user for preset"
            showingDebugAlert = true
            return nil
        }

        let presetData = PresetData(
            name: preset.name ?? "",
            textSetting: TextSettingData(
                textFieldData: preset.textSetting?.textFieldData ?? "",
                textSize: preset.textSetting?.textSize ?? 14.0,
                textWeight: preset.textSetting?.textWeight ?? 1.0,
                colorCode: preset.textSetting?.backgroundColor?.colorCode,
                backgroundColorCode: preset.textSetting?.backgroundColor?.backgroundColorCode,
                textColorCode: preset.textSetting?.textColor?.textColorCode
            ),
            visualSimulation: VisualSimulationData(
                blurriness: preset.visualSimulation?.blurriness ?? 0.0,
                imageData: preset.visualSimulation?.selectedImage?.imageData
            ),
            user: UserData(
                name: user.name ?? "",
                isFromCountryside: user.isFromCountryside
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(presetData)
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let fileURL = tempDirectoryURL.appendingPathComponent("\(preset.name ?? "preset").json")
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            debugMessage = "Failed to create JSON file: \(error.localizedDescription)"
            showingDebugAlert = true
            return nil
        }
    }

    /// コンテキストを保存する
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            debugMessage = "Failed to save context: \(error.localizedDescription)"
            showingDebugAlert = true
        }
    }
}

/// UIActivityViewControllerをSwiftUIで使用するためのラッパー
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

/// Viewに角丸を適用するための拡張
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// 角丸の形状を定義するShape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

/// PresetOverviewCardのプレビュー
struct PresetOverviewCard_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let preset = Preset(context: context)
        preset.name = "Sample Preset"
        let textSetting = TextSetting(context: context)
        textSetting.textFieldData = "Sample Text"
        textSetting.textSize = 14.0
        textSetting.textWeight = 1.0
        preset.textSetting = textSetting
        let visualSimulation = VisualSimulation(context: context)
        visualSimulation.blurriness = 0.5
        preset.visualSimulation = visualSimulation

        return NavigationView {
            PresetOverviewCard(preset: preset, onTextSettingsTap: {}, onVisualSimulationTap: {})
                .environment(\.managedObjectContext, context)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
