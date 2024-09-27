import SwiftUI
import CoreData

/// ユーザープロフィールの編集画面を表すView
struct ProfileEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // ユーザーデータのフェッチリクエスト
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        predicate: NSPredicate(format: "isFromCountryside == %@", NSNumber(value: true))
    ) var users: FetchedResults<User>
    
    // 状態変数
    @State private var userName: String = ""
    @State private var userIcon: UIImage?
    @State private var isImagePickerPresented = false
    @State private var useDefaultIcon = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("プロフィール情報")) {
                // ユーザー名入力フィールド
                TextField("名前", text: $userName)
                
                // デフォルトアイコン使用のトグル
                Toggle("デフォルトのアイコンを使用", isOn: $useDefaultIcon)
                
                // カスタムアイコン選択ボタン
                if !useDefaultIcon {
                    Button(action: { isImagePickerPresented = true }) {
                        Text("新しいアイコンを選択")
                    }
                }
                
                // ユーザーアイコン表示
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    if let userIcon = userIcon {
                        Image(uiImage: userIcon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if useDefaultIcon {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 100)
                    } else if let iconData = users.first?.icon?.imageData, let uiImage = UIImage(data: iconData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 100)
                    }
                }
                .padding()
            }
            
            // 保存ボタン
            Section {
                Button("保存") {
                    updateProfile()
                }
            }
        }
        .navigationBarTitle("プロフィール編集", displayMode: .inline)
        .onAppear(perform: loadUserData)
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $userIcon, sourceType: .photoLibrary)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    /// ユーザーデータをロードする
    private func loadUserData() {
        if let user = users.first {
            userName = user.name ?? ""
            if let iconData = user.icon?.imageData {
                userIcon = UIImage(data: iconData)
            }
            useDefaultIcon = user.icon == nil
        }
    }
    
    /// プロフィールを更新する
    private func updateProfile() {
        guard let user = users.first else {
            alertMessage = "ユーザーが見つかりません"
            showAlert = true
            return
        }
        
        viewContext.performAndWait {
            user.name = userName
            
            if useDefaultIcon {
                if let icon = user.icon {
                    viewContext.delete(icon)
                }
                user.icon = nil
            } else if let newIcon = userIcon {
                let iconData = newIcon.cropToCircle().pngData()
                if let userIcon = user.icon {
                    userIcon.imageData = iconData
                } else {
                    let newUserIcon = UserIcon(context: viewContext)
                    newUserIcon.id = UUID()
                    newUserIcon.imageData = iconData
                    user.icon = newUserIcon
                }
            }
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                alertMessage = "プロフィールの更新に失敗しました: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

/// ProfileEditViewのプレビュー
struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        return ProfileEditView()
            .environment(\.managedObjectContext, context)
    }
}
