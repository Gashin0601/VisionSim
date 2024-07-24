import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    func addUser(name: String, isFromCountryside: Bool, userIcon: UIImage?, presetName: String, textFieldData: String, textSize: Double, textWeight: Double, backgroundColor: ColorEntity?, textColor: ColorEntity?, blurriness: Double, selectedImage: UIImage?, effects: [EffectValue], context: NSManagedObjectContext) {
        let user = User(context: context)
        user.id = UUID()
        user.name = name
        user.isFromCountryside = isFromCountryside

        if let userIcon = userIcon {
            let userIconData = UserIcon(context: context)
            userIconData.id = UUID()
            userIconData.imageData = userIcon.pngData()
            user.icon = userIconData
        }

        let preset = Preset(context: context)
        preset.id = UUID()
        preset.name = presetName
        preset.user = user

        let textSetting = TextSetting(context: context)
        textSetting.id = UUID()
        textSetting.textFieldData = textFieldData
        textSetting.textSize = textSize
        textSetting.textWeight = textWeight
        textSetting.backgroundColor = backgroundColor
        textSetting.textColor = textColor
        preset.textSetting = textSetting

        let visualSimulation = VisualSimulation(context: context)
        visualSimulation.id = UUID()
        visualSimulation.blurriness = blurriness

        if let selectedImage = selectedImage {
            let imageData = ImageData(context: context)
            imageData.id = UUID()
            imageData.imageData = selectedImage.pngData()
            if let thumbnail = selectedImage.generateThumbnail() {
                imageData.thumbnailData = thumbnail.pngData()
            }
            visualSimulation.selectedImage = imageData
        }

        preset.visualSimulation = visualSimulation

        for effect in effects {
            let newEffect = EffectValue(context: context)
            newEffect.id = UUID()
            newEffect.effectName = effect.effectName
            newEffect.value = effect.value
            newEffect.preset = preset
        }

        user.addToPresets(preset)

        do {
            try context.save()
        } catch {
            print("Failed to save user: \(error)")
        }
    }

    func fetchUsers(context: NSManagedObjectContext) -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch users: \(error)")
            return []
        }
    }

    func deleteUser(_ user: User, context: NSManagedObjectContext) {
        context.delete(user)
        do {
            try context.save()
        } catch {
            print("Failed to delete user: \(error)")
        }
    }
}

extension UIImage {
    func generateThumbnail(of size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
