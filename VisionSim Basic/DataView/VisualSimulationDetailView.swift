import SwiftUI
import CoreData

struct VisualSimulationDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var visualSimulation: VisualSimulation

    var body: some View {
        Form {
            Section(header: Text("Visual Simulation")) {
                HStack {
                    Text("Blurriness:")
                    Slider(value: $visualSimulation.blurriness, in: 0...1, step: 0.1) {
                        Text("Blurriness")
                    }
                    Text("\(visualSimulation.blurriness, specifier: "%.1f")")
                        .frame(width: 50, alignment: .trailing)
                }

                if let imageData = visualSimulation.selectedImage?.imageData, let uiImage = UIImage(data: imageData) {
                    VStack {
                        Text("Selected Image:")
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                } else {
                    Text("No image selected")
                }
            }
        }
        .navigationBarTitle("Visual Simulation", displayMode: .inline)
        .onDisappear {
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

struct VisualSimulationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let visualSimulation = VisualSimulation(context: context)
        visualSimulation.blurriness = 0.5

        return VisualSimulationDetailView(visualSimulation: visualSimulation)
            .environment(\.managedObjectContext, context)
    }
}
