import SwiftUI
import PhotosUI

/// 画像選択のためのUIImagePickerControllerをラップするSwiftUI View
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    /// UIImagePickerControllerを作成し、初期設定を行う
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    /// UIImagePickerControllerの更新処理（必要に応じて実装）
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 必要に応じて更新処理をここに追加
    }

    /// コーディネーターを作成する
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// UIImagePickerControllerDelegateを実装するコーディネータークラス
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        /// 画像が選択されたときに呼ばれるデリゲートメソッド
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image  // 選択された画像をBindingで更新
            }
            picker.dismiss(animated: true)
        }

        /// 画像選択がキャンセルされたときに呼ばれるデリゲートメソッド
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
