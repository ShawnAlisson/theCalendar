//
//  CalendarWidget.swift
//  CalendarWidget
//
//  Created by Shayan Alizadeh on 11/8/22.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
        
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    
}

struct CalendarWidgetEntryView : View {
    var entry: Provider.Entry
    var nowDate: Date = Date()

    var body: some View {
        VStack{
           
            Text(nowDate.asPersianDay()).font(Font.system(size: 14, weight: .light))
            HStack{
                
                Text(nowDate.asPersianMonth()).font(Font.system(size: 14))
                Text(nowDate.asPersianDate()).font(Font.system(size: 72, weight: .bold))
            }
            
            Text(nowDate.asEngMonth()).font(Font.system(size: 14, weight: .light))
              
        }.padding()
        
    }
}

@main
struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("theCalendar")
        .description("Simple Persian Calendar Widget")
        .supportedFamilies([.systemSmall])
    }
}

//struct CalendarWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        CalendarWidgetEntryView(entry: SimpleEntry(date: Date()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
