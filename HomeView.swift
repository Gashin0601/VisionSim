import SwiftUI
import CoreData
import UniformTypeIdentifiers
import Combine

/// プリセットの変更を監視し、更新するためのクラス
class PresetObserver: ObservableObject {
    @Published var presets: [Preset] = []
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        // コンテキストの変更を監視し、プリセットを再読み込み
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .sink { [weak self] _ in
                self?.loadPresets(context: context)
            }
            .store(in: &cancellables)
        
        loadPresets(context: context)
    }

    /// プリセットをデータベースから読み込む
    private func loadPresets(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Preset> = Preset.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Preset.name, ascending: true)]
        
        do {
            presets = try context.fetch(request)
        } catch {
            print("Failed to fetch presets: \(error)")
        }
    }
}

/// アプリのホーム画面を表すView
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var presetObserver: PresetObserver
    
    // ユーザーデータを取得
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        predicate: NSPredicate(format: "isFromCountryside == %@", NSNumber(value: true)),
        animation: .default)
    private var users: FetchedResults<User>
    
    // プリセットデータを取得
    @FetchRequest(
        entity: Preset.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Preset.name, ascending: true)],
        animation: .default)
    private var presets: FetchedResults<Preset>

    // 状態変数
    @State private var isLoadingFile = false
    @State private var isExportingPreset = false
    @State private var presetToExport: Preset?
    @State private var showingDebugAlert = false
    @State private var debugMessage = ""
    @State private var newPreset: Preset?
    @State private var isShowingNewPreset = false
    @State private var selectedPreset: Preset?
    @State private var selectedTab: Int = 0

    init(context: NSManagedObjectContext) {
        _presetObserver = StateObject(wrappedValue: PresetObserver(context: context))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                if let currentUser = users.first {
                    userContentView(for: currentUser)
                } else {
                    noUserView
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingDebugAlert) {
                Alert(title: Text("Debug Info"), message: Text(debugMessage), dismissButton: .default(Text("OK")))
            }
            .background(navigationLinks)
        }
    }
    
    /// ヘッダービューを生成
    private var headerView: some View {
        HStack {
            Spacer()
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .imageScale(.large)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding()
        }
    }
    
    /// ユーザーコンテンツビューを生成
    private func userContentView(for user: User) -> some View {
        VStack {
            Text("こんにちは、\(user.name ?? "ユーザー")さん")
                .font(.largeTitle)
                .padding()

            List {
                Section(header: userPresetsSectionHeader) {
                    LazyVStack {
                        ForEach(presets.filter { $0.user == user }, id: \.self) { preset in
                            presetRow(for: preset)
                        }
                    }
                }
                
                Section(header: otherPresetsSectionHeader) {
                    LazyVStack {
                        ForEach(presets.filter { $0.user != user }, id: \.self) { preset in
                            presetRow(for: preset)
                        }
                        .onDelete(perform: deleteOtherPresets)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    /// ユーザープリセットセクションのヘッダービュー
    private var userPresetsSectionHeader: some View {
        HStack {
            Text("あなたのプリセット")
                .font(.title2)
            Spacer()
            Button(action: createAndNavigateToNewPreset) {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
            }
        }
    }
    
    /// プリセット行を生成
    private func presetRow(for preset: Preset) -> some View {
        PresetOverviewCard(preset: preset,
                      onTextSettingsTap: {
                          self.selectedPreset = preset
                          self.selectedTab = 0
                      },
                      onVisualSimulationTap: {
                          self.selectedPreset = preset
                          self.selectedTab = 1
                      })
    }
        
    /// その他のプリセットセクションのヘッダービュー
    private var otherPresetsSectionHeader: some View {
        HStack {
            Text("その他")
                .font(.title2)
            Spacer()
            Button(action: {
                isLoadingFile.toggle()
            }) {
                Image(systemName: "arrow.down.circle.fill")
                    .imageScale(.large)
            }
            .fileImporter(
                isPresented: $isLoadingFile,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    guard let file = files.first else {
                        debugMessage = "ファイルが選択されていません"
                        showingDebugAlert = true
                        return
                    }
                    
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    defer {
                        if gotAccess {
                            file.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    if !gotAccess {
                        debugMessage = "ファイルへのアクセス権限を取得できませんでした"
                        showingDebugAlert = true
                        return
                    }
                    
                    do {
                        let data = try Data(contentsOf: file)
                        let decoder = JSONDecoder()
                        let presetData = try decoder.decode(PresetData.self, from: data)
                        
                        createPresetFromData(presetData)
                        try viewContext.save()
                        debugMessage = "プリセットを正常に読み込みました"
                        showingDebugAlert = true
                    } catch {
                        debugMessage = "ファイルの読み込みに失敗しました: \(error.localizedDescription)"
                        showingDebugAlert = true
                    }
                case .failure(let error):
                    debugMessage = "ファイルの選択に失敗しました: \(error.localizedDescription)"
                    showingDebugAlert = true
                }
            }
        }
    }
    
    /// ユーザーが設定されていない場合のビュー
    private var noUserView: some View {
        VStack {
            Text("ユーザーが設定されていません")
                .font(.title2)
                .padding()
            
            NavigationLink(destination: TutorialView(showTutorial: .constant(true))) {
                Text("チュートリアルを開始")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    /// 新しいプリセットを作成し、そのビューに遷移
    private func createAndNavigateToNewPreset() {
        guard let currentUser = users.first else {
            print("ユーザーが見つかりません")
            return
        }

        let preset = Preset(context: viewContext)
        preset.id = UUID()
        preset.name = generateNewPresetName()
        preset.user = currentUser

        let textSetting = TextSetting(context: viewContext)
        textSetting.id = UUID()
        textSetting.textFieldData = "新しいプリセットのテキスト"
        textSetting.textSize = 18.0
        textSetting.textWeight = 0.5
        preset.textSetting = textSetting

        let visualSimulation = VisualSimulation(context: viewContext)
        visualSimulation.id = UUID()
        visualSimulation.blurriness = 0.0
        preset.visualSimulation = visualSimulation

        do {
            try viewContext.save()
            newPreset = preset
            isShowingNewPreset = true
        } catch {
            debugMessage = "新規プリセットの保存に失敗しました: \(error.localizedDescription)"
            showingDebugAlert = true
        }
    }

    /// 新しいプリセット名を生成
    private func generateNewPresetName() -> String {
        let existingPresets = presets
        let existingNames = Set(existingPresets.compactMap { $0.name })
        
        var index = 0
        var newName: String
        
        repeat {
            if index == 0 {
                newName = "新規プリセット"
            } else {
                newName = "新規プリセット \(index)"
            }
            index += 1
        } while existingNames.contains(newName)
        
        return newName
    }

    /// プリセットデータからプリセットを作成
    private func createPresetFromData(_ presetData: PresetData) {
        let preset = Preset(context: viewContext)
        preset.id = UUID()
        preset.name = presetData.name
        
        let textSetting = TextSetting(context: viewContext)
        textSetting.id = UUID()
        textSetting.textFieldData = presetData.textSetting.textFieldData
        textSetting.textSize = presetData.textSetting.textSize
        textSetting.textWeight = presetData.textSetting.textWeight
        
        if let colorCode = presetData.textSetting.colorCode {
            let fetchRequest: NSFetchRequest<ColorEntity> = ColorEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "colorCode == %@", colorCode)
            
            do {
                let results = try viewContext.fetch(fetchRequest)
                if let existingColor = results.first {
                    textSetting.backgroundColor = existingColor
                    textSetting.textColor = existingColor
                } else {
                    let newColor = ColorEntity(context: viewContext)
                    newColor.id = UUID()
                    newColor.colorCode = colorCode
                    newColor.backgroundColorCode = presetData.textSetting.backgroundColorCode ?? "#FFFFFF"
                    newColor.textColorCode = presetData.textSetting.textColorCode ?? "#000000"
                    textSetting.backgroundColor = newColor
                    textSetting.textColor = newColor
                }
            } catch {
                print("Failed to fetch or create ColorEntity: \(error)")
            }
        }
        
        preset.textSetting = textSetting

        let visualSimulation = VisualSimulation(context: viewContext)
        visualSimulation.id = UUID()
        visualSimulation.blurriness = presetData.visualSimulation.blurriness

        if let imageData = presetData.visualSimulation.imageData {
            let image = ImageData(context: viewContext)
            image.id = UUID()
            image.imageData = imageData
            visualSimulation.selectedImage = image
        }

        preset.visualSimulation = visualSimulation

        let user = fetchOrCreateUser(with: presetData.user)
        user.addToPresets(preset)
    }

    /// ユーザーデータからユーザーを取得または作成
    private func fetchOrCreateUser(with userData: UserData) -> User {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", userData.name)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let existingUser = results.first {
                return existingUser
            } else {
                let newUser = User(context: viewContext)
                newUser.id = UUID()
                newUser.name = userData.name
                newUser.isFromCountryside = userData.isFromCountryside
                return newUser
            }
        } catch {
            debugMessage = "ユーザーの取得または作成に失敗しました: \(error.localizedDescription)"
            showingDebugAlert = true
            return User(context: viewContext)
        }
    }

    /// その他のプリセットを削除
    private func deleteOtherPresets(at offsets: IndexSet) {
        viewContext.performAndWait {
            let otherPresets = presets.filter { $0.user != users.first }
            for index in offsets {
                if index < otherPresets.count {
                    viewContext.delete(otherPresets[index])
                }
            }
            
            do {
                try viewContext.save()
            } catch {
                DispatchQueue.main.async {
                    self.debugMessage = "Failed to delete preset: \(error.localizedDescription)"
                    self.showingDebugAlert = true
                }
            }
        }
    }

    /// ナビゲーションリンク
    private var navigationLinks: some View {
        Group {
            if let newPreset = newPreset {
                NavigationLink(destination: PresetDetailView(preset: newPreset, selectedTab: 0), isActive: $isShowingNewPreset) {
                    EmptyView()
                }
            }
            NavigationLink(
                destination: selectedPreset.map { PresetDetailView(preset: $0, selectedTab: selectedTab) },
                isActive: Binding(
                    get: { selectedPreset != nil },
                    set: { if !$0 { selectedPreset = nil } }
                )
            ) {
                EmptyView()
            }
        }
    }

    /// コンテキストを保存
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            debugMessage = "Failed to save context: \(error.localizedDescription)"
            showingDebugAlert = true
        }
    }
}

/// プリセットデータを表す構造体
struct PresetData: Codable {
    let name: String
    let textSetting: TextSettingData
    let visualSimulation: VisualSimulationData
    let user: UserData
}

/// テキスト設定データを表す構造体
struct TextSettingData: Codable {
    let textFieldData: String
    let textSize: Double
    let textWeight: Double
    let colorCode: String?
    let backgroundColorCode: String?
    let textColorCode: String?
}

/// 視覚シミュレーションデータを表す構造体
struct VisualSimulationData: Codable {
    let blurriness: Double
    let imageData: Data?
}

/// ユーザーデータを表す構造体
struct UserData: Codable {
    let name: String
    let isFromCountryside: Bool
}

/// HomeViewのプレビュー
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        HomeView(context: context)
            .environment(\.managedObjectContext, context)
    }
}
