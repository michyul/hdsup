//
//  HUDOrnamentView.swift
//  hdsup
//
//  Ornament component for floating HUD display
//

import SwiftUI

struct HUDOrnamentView: View {
    let data: HUDData
    let style: OrnamentStyle
    
    enum OrnamentStyle {
        case compact
        case detailed
        case minimal
    }
    
    var body: some View {
        switch style {
        case .compact:
            compactView
        case .detailed:
            detailedView
        case .minimal:
            minimalView
        }
    }
    
    private var compactView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(data.value)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                    
                    if let unit = data.unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var detailedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(data.value)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                
                if let unit = data.unit {
                    Text(unit)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let metadata = data.metadata {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(metadata[key] ?? "")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            Text(data.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(minWidth: 200)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var minimalView: some View {
        HStack(spacing: 6) {
            Text(data.value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
            
            if let unit = data.unit {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        HUDOrnamentView(
            data: HUDData(
                title: "Temperature",
                value: "72",
                unit: "°F",
                metadata: ["condition": "Sunny", "humidity": "45%"]
            ),
            style: .compact
        )
        
        HUDOrnamentView(
            data: HUDData(
                title: "System Load",
                value: "42",
                unit: "%",
                metadata: ["cores": "8", "threads": "16"]
            ),
            style: .detailed
        )
        
        HUDOrnamentView(
            data: HUDData(
                title: "Memory",
                value: "16.0",
                unit: "GB"
            ),
            style: .minimal
        )
    }
    .padding()
}
