import SwiftUI
import CoreData

struct InitialSetupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userName: String = ""
    @State private var userIcon: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var useDefaultIcon = false

    var body: some View {
        VStack {
            Text("ようこそ。VisionSimへ")
                .font(.largeTitle)
                .padding()

            Text("まずはあなたの名前を教えてください。")
                .padding()

            TextField("名前を入力", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Toggle("デフォルトのアイコンを使用", isOn: $useDefaultIcon)
                .padding()

            if !useDefaultIcon {
                Button(action: { isImagePickerPresented = true }) {
                    Text("ユーザーアイコンをアップロードしてください")
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

            Button("完了") {
                addUser()
            }
            .padding()
            .disabled(userName.isEmpty)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $userIcon)
        }
    }

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
            // Transition to the next view (e.g., HomeView)
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
        } catch {
            print("Failed to save user: \(error)")
        }
    }
}

extension UIImage {
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

struct InitialSetupView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        InitialSetupView()
            .environment(\.managedObjectContext, context)
    }
}
