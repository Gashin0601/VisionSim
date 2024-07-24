import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "VisionSimBasic")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        initializeEffectValues()
        checkFirstLaunch()
        addDefaultColorEntities()
    }

    func initializeEffectValues() {
        let context = container.viewContext
        let request: NSFetchRequest<EffectValue> = EffectValue.fetchRequest()

        do {
            let count = try context.count(for: request)
            if count == 0 {
                let effect1 = EffectValue(context: context)
                effect1.id = UUID()
                effect1.effectName = "Blur"
                effect1.value = 0.0

                let effect2 = EffectValue(context: context)
                effect2.id = UUID()
                effect2.effectName = "Contrast"
                effect2.value = 0.0

                try context.save()
            }
        } catch {
            print("Failed to initialize effect values: \(error)")
        }
    }

    func checkFirstLaunch() {
        let isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
        if !isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
        }
    }

    func addDefaultColorEntities() {
        let context = container.viewContext
        let colorPairs = [
            ("白", "黒", "#FFFFFF", "#000000"),
            ("黒", "白", "#000000", "#FFFFFF"),
            ("黒", "黄色", "#000000", "#FFFF00"),
            ("黄色", "青", "#FFFF00", "#0000FF"),
            ("青", "黄色", "#0000FF", "#FFFF00")
        ]
        
        for (backgroundName, textName, backgroundCode, textCode) in colorPairs {
            let fetchRequest: NSFetchRequest<ColorEntity> = ColorEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "colorCode == %@", "\(backgroundName),\(textName)")
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.isEmpty {
                    let colorEntity = ColorEntity(context: context)
                    colorEntity.id = UUID()
                    colorEntity.colorCode = "\(backgroundName),\(textName)"
                    colorEntity.backgroundColorCode = backgroundCode
                    colorEntity.textColorCode = textCode
                }
            } catch {
                print("Failed to fetch ColorEntity: \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save default color entities: \(error)")
        }
    }
}
