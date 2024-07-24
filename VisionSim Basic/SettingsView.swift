import SwiftUI
import SafariServices

struct SettingsView: View {
    @State private var showTermsOfService = false
    @State private var showTutorial = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("プロフィール")) {
                    NavigationLink(destination: ProfileEditView()) {
                        Text("プロフィールを編集")
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    Button("利用規約") {
                        showTermsOfService = true
                    }
                    
                    Button("チュートリアルを表示") {
                        showTutorial = true
                    }
                }
            }
            .navigationBarTitle("設定", displayMode: .inline)
            .sheet(isPresented: $showTermsOfService) {
                SafariView(url: URL(string: "https://gashincreations.com/82530dfbf62b4754b00e7a41e675f289")!)
            }
            .sheet(isPresented: $showTutorial) {
                TutorialView(showTutorial: $showTutorial)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
