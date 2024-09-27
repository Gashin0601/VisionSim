import SwiftUI
import CoreData

/// チュートリアル画面を表すView
struct TutorialView: View {
    @Binding var showTutorial: Bool
    @State private var currentPage = 0
    @State private var userName: String = ""
    @State private var userIcon: UIImage?
    @State private var isImagePickerPresented = false
    @State private var useDefaultIcon = false
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        predicate: NSPredicate(format: "isFromCountryside == %@", NSNumber(value: true))
    ) var users: FetchedResults<User>
    
    /// チュートリアルページの配列
    var pages: [TutorialPage] {
        var basePages = [
            TutorialPage(
                title: "Vision Simへようこそ",
                description: "Vision Simは「見え方」を伝えるシミュレーションアプリです。詳しくは[こちら](https://gashincreations.com/app-development)をご覧ください。",
                imageName: "welcome"
            ),
            TutorialPage(
                title: "プリセット",
                description: "ホームではプリセットを管理できます。。"
                    + "プリセットを追加または選択して、次のページへ進みましょう。",
                imageName: "home"
            ),
            TutorialPage(
                title: "テキストの編集",
                description: "テキスト設定タブでは、テキストサイズ、太さ、行間、コントラストを調整できます。"
                    + "編集ボタンをタップすると、設定を変更できます。",
                imageName: "text setting"
            ),
            TutorialPage(
                title: "シミュレーション",
                description: "シミュレーションタブでは、様々な日常のシーンでの「見えにくさ」を伝えられます。"
                    + "ぼかし度を調整して、見え方を確認しましょう。",
                imageName: "simulations"
            ),
        ]
        
        // ユーザーが存在しない場合、プロフィール設定ページを挿入
        if users.isEmpty {
            basePages.insert(TutorialPage(
                title: "プロフィール設定",
                description: "まずはあなたの名前とアイコンを設定しましょう。",
                imageName: "profile_setup"
            ), at: 1)
        } else {
            basePages.insert(TutorialPage(
                title: "プロフィール",
                description: "プロフィールは既に設定されています。変更したい場合は、設定画面から編集できます。",
                imageName: "profile"
            ), at: 1)
        }
        
        basePages.append(TutorialPage(
            title: "さあ、新しい世界へ",
            description: "これでチュートリアルは終了です。早速、体験してみてください。",
            imageName: "finish"
        ))
        
        return basePages
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        if index == 1 && users.isEmpty {
                            ProfileSetupView(userName: $userName, userIcon: $userIcon, useDefaultIcon: $useDefaultIcon, isImagePickerPresented: $isImagePickerPresented)
                                .tag(index)
                        } else {
                            TutorialPageView(page: pages[index])
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())

                HStack {
                    // 前のページへ移動するボタン
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    } else {
                        Spacer()
                    }

                    Spacer()

                    // 最後のページの場合は完了ボタン、それ以外はページコントロール
                    if currentPage == pages.count - 1 {
                        Button(action: {
                            if users.isEmpty {
                                addUser()
                            }
                            showTutorial = false
                        }) {
                            Text("完了")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Color.blue)
                                .cornerRadius(30)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    } else {
                        PageControl(numberOfPages: pages.count, currentPage: $currentPage)
                            .frame(width: CGFloat(pages.count * 20))
                    }

                    Spacer()

                    // 次のページへ移動するボタン
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.8, green: 0.9, blue: 1.0), Color(red: 0.6, green: 0.8, blue: 1.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $userIcon, sourceType: .photoLibrary)
        }
    }
    
    /// ユーザーを追加する
    private func addUser() {
        let user = User(context: viewContext)
        user.id = UUID()
        user.name = userName
        user.isFromCountryside = true

        if !useDefaultIcon, let userIcon = userIcon {
            let userIconData = UserIcon(context: viewContext)
            userIconData.id = UUID()
            userIconData.imageData = userIcon.cropToCircle().pngData() ?? Data()
            user.icon = userIconData
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to save user: \(error)")
        }
    }
}

/// プロフィール設定画面を表すView
struct ProfileSetupView: View {
    @Binding var userName: String
    @Binding var userIcon: UIImage?
    @Binding var useDefaultIcon: Bool
    @Binding var isImagePickerPresented: Bool
    
    var body: some View {
        VStack {
            Text("プロフィール設定")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            TextField("名前を入力", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Toggle("デフォルトのアイコンを使用", isOn: $useDefaultIcon)
                .padding()
            
            if !useDefaultIcon {
                Button(action: { isImagePickerPresented = true }) {
                    Text("ユーザーアイコンをアップロード")
                }
                .padding()
            }
            
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
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 100)
                }
            }
            .padding()
        }
    }
}

/// ページコントロールを表すView
struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(index == currentPage ? .black : .gray)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.spring(), value: currentPage)
            }
        }
    }
}

/// チュートリアルページの構造体
struct TutorialPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

/// チュートリアルページを表すView
struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack {
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding()

            Image(page.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 300)
                .cornerRadius(20)
                .padding()
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

            Text(LocalizedStringKey(page.description))
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

/// UIImageの拡張
extension UIImage {
    /// 画像を円形に切り取る
    func cropToCircle() -> UIImage {
        let shortestSide = min(size.width, size.height)
        let squareSize = CGSize(width: shortestSide, height: shortestSide)
        let squareRect = CGRect(origin: .zero, size: squareSize)
        
        UIGraphicsBeginImageContextWithOptions(squareSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        context.addEllipse(in: squareRect)
        context.clip()
        
        draw(in: CGRect(origin: CGPoint(x: (squareSize.width - size.width) / 2,
                                        y: (squareSize.height - size.height) / 2),
                        size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

/// TutorialViewのプレビュー
struct TutorialView_Previews: PreviewProvider {
    @State static var showTutorial = true

    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        TutorialView(showTutorial: $showTutorial)
            .environment(\.managedObjectContext, context)
    }
}
