import Foundation
import CoreData
import UIKit

struct ExportedData: Codable {
    var users: [UserDataStruct]
    var presets: [PresetDataStruct]
    var images: [ImageDataStruct]
    var userIcons: [UserIconStruct]
    var colorEntities: [ColorEntityStruct]

    init(context: NSManagedObjectContext) {
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        let presetRequest: NSFetchRequest<Preset> = Preset.fetchRequest()
        let imageRequest: NSFetchRequest<ImageData> = ImageData.fetchRequest()
        let userIconRequest: NSFetchRequest<UserIcon> = UserIcon.fetchRequest()
        let colorEntityRequest: NSFetchRequest<ColorEntity> = ColorEntity.fetchRequest()

        self.users = (try? context.fetch(userRequest).compactMap(UserDataStruct.init)) ?? []
        self.presets = (try? context.fetch(presetRequest).compactMap(PresetDataStruct.init)) ?? []
        self.images = (try? context.fetch(imageRequest).compactMap(ImageDataStruct.init)) ?? []
        self.userIcons = (try? context.fetch(userIconRequest).compactMap(UserIconStruct.init)) ?? []
        self.colorEntities = (try? context.fetch(colorEntityRequest).compactMap(ColorEntityStruct.init)) ?? []
    }
}

struct UserDataStruct: Codable, Identifiable {
    let id: UUID
    let name: String
    let isFromCountryside: Bool
    let iconImageID: UUID?

    init?(user: User) {
        guard let id = user.id, let name = user.name else { return nil }
        self.id = id
        self.name = name
        self.isFromCountryside = user.isFromCountryside
        self.iconImageID = user.icon?.id
    }

    func toEntity(context: NSManagedObjectContext) -> User {
        let user = User(context: context)
        user.id = self.id
        user.name = self.name
        user.isFromCountryside = self.isFromCountryside
        return user
    }
}

struct PresetDataStruct: Codable, Identifiable {
    let id: UUID
    let name: String
    let textFieldData: String
    let textSize: Double
    let textWeight: Double
    let backgroundColorID: UUID?
    let textColorID: UUID?
    let blurriness: Double
    let selectedImageID: UUID?

    init?(preset: Preset) {
        guard let id = preset.id, let name = preset.name else { return nil }
        self.id = id
        self.name = name
        self.textFieldData = preset.textSetting?.textFieldData ?? ""
        self.textSize = preset.textSetting?.textSize ?? 14.0
        self.textWeight = preset.textSetting?.textWeight ?? 1.0
        self.backgroundColorID = preset.textSetting?.backgroundColor?.id
        self.textColorID = preset.textSetting?.textColor?.id
        self.blurriness = preset.visualSimulation?.blurriness ?? 0.0
        self.selectedImageID = preset.visualSimulation?.selectedImage?.id
    }

    func toEntity(context: NSManagedObjectContext) -> Preset {
        let preset = Preset(context: context)
        preset.id = self.id
        preset.name = self.name

        let textSetting = TextSetting(context: context)
        textSetting.textFieldData = self.textFieldData
        textSetting.textSize = self.textSize
        textSetting.textWeight = self.textWeight
        preset.textSetting = textSetting

        let visualSimulation = VisualSimulation(context: context)
        visualSimulation.blurriness = self.blurriness
        preset.visualSimulation = visualSimulation

        return preset
    }
}

struct ImageDataStruct: Codable, Identifiable {
    let id: UUID
    let imageData: Data

    init?(imageData: ImageData) {
        guard let id = imageData.id, let data = imageData.imageData else { return nil }
        self.id = id
        self.imageData = data
    }

    func toEntity(context: NSManagedObjectContext) -> ImageData {
        let imageData = ImageData(context: context)
        imageData.id = self.id
        imageData.imageData = self.imageData
        return imageData
    }
}

struct UserIconStruct: Codable, Identifiable {
    let id: UUID
    let imageData: Data

    init?(userIcon: UserIcon) {
        guard let id = userIcon.id, let data = userIcon.imageData else { return nil }
        self.id = id
        self.imageData = data
    }

    func toEntity(context: NSManagedObjectContext) -> UserIcon {
        let userIcon = UserIcon(context: context)
        userIcon.id = self.id
        userIcon.imageData = self.imageData
        return userIcon
    }
}

struct ColorEntityStruct: Codable, Identifiable {
    let id: UUID
    let colorCode: String
    let backgroundColorCode: String
    let textColorCode: String

    init?(colorEntity: ColorEntity) {
        guard let id = colorEntity.id,
              let colorCode = colorEntity.colorCode,
              let backgroundColorCode = colorEntity.backgroundColorCode,
              let textColorCode = colorEntity.textColorCode else { return nil }
        self.id = id
        self.colorCode = colorCode
        self.backgroundColorCode = backgroundColorCode
        self.textColorCode = textColorCode
    }

    func toEntity(context: NSManagedObjectContext) -> ColorEntity {
        let colorEntity = ColorEntity(context: context)
        colorEntity.id = self.id
        colorEntity.colorCode = self.colorCode
        colorEntity.backgroundColorCode = self.backgroundColorCode
        colorEntity.textColorCode = self.textColorCode
        return colorEntity
    }
}
