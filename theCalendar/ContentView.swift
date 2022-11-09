//
//  ContentView.swift
//  theCalendar
//
//  Created by Shayan Alizadeh on 11/8/22.
//

import SwiftUI

struct ContentView: View {
    let currentDate = Date()
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.vertical)
                    .overlay(
        VStack{
           
            Text(currentDate.asPersianDay()).font(Font.system(size: 28, weight: .light))
            Circle().opacity(0.1).overlay(
                VStack{
                    Text(currentDate.asPersianDate()).font(Font.system(size: 142, weight: .bold))
                }
            )
            
            VStack{
                Text(currentDate.asShortDateString())
                Text(currentDate.asShortDateStringEng())
                Text(currentDate.asShortDateStringAr())
            }.padding().font(Font.system(size: 28))
            
                
              
        }
            .foregroundColor(Color.white)
            
        .padding()
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
