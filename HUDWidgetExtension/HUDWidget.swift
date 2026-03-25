//
//  HUDWidget.swift
//  HUDWidgetExtension
//
//  Spatial widgets for visionOS
//

import WidgetKit
import SwiftUI

struct HUDWidget: Widget {
    let kind: String = "HUDWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HUDWidgetProvider()) { entry in
            HUDWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("HUD Monitor")
        .description("Display external data on spatial surfaces")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        // visionOS-specific configurations
        .supportedMountingStyles([.elevated, .recessed])
        .widgetTexture(.glass)
    }
}

struct HUDWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HUDWidgetEntry {
        HUDWidgetEntry(date: Date(), data: HUDData(
            title: "Sample",
            value: "42",
            unit: "%"
        ))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HUDWidgetEntry) -> Void) {
        let entry = HUDWidgetEntry(date: Date(), data: HUDData(
            title: "CPU",
            value: "67",
            unit: "%"
        ))
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HUDWidgetEntry>) -> Void) {
        Task {
            // Fetch real data from your API
            let data = await fetchWidgetData()
            let entry = HUDWidgetEntry(date: Date(), data: data)
            
            // Update every 5 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func fetchWidgetData() async -> HUDData {
        // Example: fetch from your API
        // Replace with actual network call
        do {
            let source = SystemMetricsDataSource()
            return try await source.fetchData()
        } catch {
            return HUDData(
                title: "Error",
                value: "N/A",
                unit: nil
            )
        }
    }
}

struct HUDWidgetEntry: TimelineEntry {
    let date: Date
    let data: HUDData
}

struct HUDWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.levelOfDetail) var levelOfDetail
    
    var entry: HUDWidgetProvider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            smallWidget
        }
    }
    
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.data.title)
                .font(levelOfDetail == .simplified ? .headline : .subheadline)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.data.value)
                    .font(levelOfDetail == .simplified ? .system(size: 48, weight: .bold, design: .rounded) : .system(size: 36, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                
                if let unit = entry.data.unit {
                    Text(unit)
                        .font(levelOfDetail == .simplified ? .title : .title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(entry.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .widgetAccentable()
    }
    
    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.data.title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(entry.data.value)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    
                    if let unit = entry.data.unit {
                        Text(unit)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let metadata = entry.data.metadata {
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(Array(metadata.keys.sorted().prefix(3)), id: \.self) { key in
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(metadata[key] ?? "")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(key.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.data.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(entry.data.value)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                
                if let unit = entry.data.unit {
                    Text(unit)
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            if let metadata = entry.data.metadata {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(metadata[key] ?? "")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Text("Updated")
                    .foregroundStyle(.tertiary)
                Text(entry.date, style: .relative)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding()
    }
}

#Preview(as: .systemSmall) {
    HUDWidget()
} timeline: {
    HUDWidgetEntry(date: .now, data: HUDData(
        title: "Temperature",
        value: "72",
        unit: "°F"
    ))
}

#Preview(as: .systemMedium) {
    HUDWidget()
} timeline: {
    HUDWidgetEntry(date: .now, data: HUDData(
        title: "Server Load",
        value: "42",
        unit: "%",
        metadata: ["CPU": "67%", "Memory": "8.2GB", "Uptime": "5d"]
    ))
}
