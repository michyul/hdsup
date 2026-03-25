//
//  ImmersiveView.swift
//  hdsup
//
//  Created by Michel Mainville on 2026-03-25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var hudEntities: [UUID: Entity] = [:]
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
            
            // Add spatial HUD elements in the immersive space
            await setupSpatialHUD(content: content)
            
        } update: { content in
            // Update HUD elements when data changes
            updateSpatialHUD(content: content)
        }
        .task {
            // Update spatial HUD periodically
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                // Trigger updates as needed
            }
        }
    }
    
    private func setupSpatialHUD(content: RealityViewContent) async {
        // Create floating HUD panels in 3D space
        // These will appear as spatial elements around the user
        
        // Example: Create a floating data panel
        let panelEntity = Entity()
        panelEntity.position = [0, 1.5, -2] // 2 meters in front, at eye level
        
        // You can add ModelComponent, TextComponent, etc. here
        // For now, we'll keep it simple as a placeholder
        
        content.add(panelEntity)
    }
    
    private func updateSpatialHUD(content: RealityViewContent) {
        // Update the spatial HUD elements based on current data
        // This gets called when data updates
        
        for (sourceId, data) in appModel.hudDataService.currentData {
            // Update or create entities for each data source
            if let entity = hudEntities[sourceId] {
                // Update existing entity
                // entity.components[TextComponent.self]?.text = data.value
            } else {
                // Create new entity
                let newEntity = Entity()
                hudEntities[sourceId] = newEntity
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
