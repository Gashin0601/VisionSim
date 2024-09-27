import SwiftUI
import CoreData

/// プリセットの詳細を表示するビュー
struct PresetDetailView: View {
    @ObservedObject var preset: Preset
    @State var selectedTab: Int
    @State private var isEditingName: Bool = false
    @State private var editedName: String = ""
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // アイコンとプリセット名を横に並べて中央に配置
            HStack {
                Spacer()
                
                // ユーザーアイコンの表示
                if let iconData = preset.user?.icon?.imageData, let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                }
                
                // プリセット名の表示と編集
                if isEditingName {
                    TextField("プリセット名", text: $editedName, onCommit: {
                        preset.name = editedName
                        isEditingName = false
                        saveContext()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
                } else {
                    Text(preset.name ?? "Unnamed Preset")
                        .font(.headline)
                        .fontWeight(.bold)
                        .onTapGesture {
                            editedName = preset.name ?? ""
                            isEditingName = true
                        }
                }
                
                // 編集ボタン
                Button(action: {
                    if isEditingName {
                        preset.name = editedName
                        saveContext()
                    }
                    isEditingName.toggle()
                    editedName = preset.name ?? ""
                }) {
                    Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil")
                }
                
                Spacer()
            }
            .padding()
            
            // タブビュー（テキスト設定とシミュレーション）
            TabView(selection: $selectedTab) {
                TextSettingsView(textSetting: preset.textSetting!)
                    .tabItem {
                        Label("Text Setting", systemImage: "text.cursor")
                    }
                    .tag(0)

                VisualSimulationView(visualSimulation: preset.visualSimulation!)
                    .tabItem {
                        Label("Simulation", systemImage: "eye")
                    }
                    .tag(1)
            }
            .accentColor(.blue)  // 選択されたタブのテキスト色
            .onAppear {
                UITabBar.appearance().backgroundColor = .white  // タブバーの背景色
                UITabBar.appearance().unselectedItemTintColor = .gray  // 選択されていないタブのテキスト色
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom)  // タブバーがSafeAreaの外まで表示されるようにする
        .onDisappear {
            saveContext()
        }
    }
    
    /// コンテキストを保存するプライベート関数
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

/// PresetDetailViewのプレビュー用struct
struct PresetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        // サンプルのプリセットを作成
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
            PresetDetailView(preset: preset, selectedTab: 0)
                .environment(\.managedObjectContext, context)
        }
    }
}
