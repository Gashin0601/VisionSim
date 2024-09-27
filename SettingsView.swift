import SwiftUI
import SafariServices

/// アプリの設定画面を表示するView
struct SettingsView: View {
    @State private var showTermsOfService = false
    @State private var showTutorial = false
    
    var body: some View {
        NavigationView {
            Form {
                // プロフィール設定セクション
                Section(header: Text("プロフィール")) {
                    NavigationLink(destination: ProfileEditView()) {
                        Text("プロフィールを編集")
                    }
                }
                
                // アプリ情報セクション
                Section(header: Text("アプリ情報")) {
                    // 利用規約ボタン
                    Button("利用規約") {
                        showTermsOfService = true
                    }
                    
                    // チュートリアル表示ボタン
                    Button("チュートリアルを表示") {
                        showTutorial = true
                    }
                }
            }
            .navigationBarTitle("設定", displayMode: .inline)
            // 利用規約をSafariViewで表示
            .sheet(isPresented: $showTermsOfService) {
                SafariView(url: URL(string: "https://visionsim.prot-news.com/terms-of-service.html")!)
            }
            // チュートリアルを表示
            .sheet(isPresented: $showTutorial) {
                TutorialView(showTutorial: $showTutorial)
            }
        }
    }
}

/// SafariViewControllerをSwiftUIで使用するためのラッパー
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
        // 更新処理が必要ない場合は空のままで問題ありません
    }
}

/// SettingsViewのプレビュー用struct
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
