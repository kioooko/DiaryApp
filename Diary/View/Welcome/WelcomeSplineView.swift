//
//  WelcomeSplineView.swift
//  MOSS
//
//  Created by jackma on 2024/10/1.
//
import SplineRuntime
import SwiftUI
//import SnapKit

struct WelcomeSplineView: View {
    var body: some View {
        // fetching from local
        let url = Bundle.main.url(forResource: "meeet", withExtension: "splineswift")!
        if #available(iOS 16.0, *) {
            SplineView(sceneFileURL: url).ignoresSafeArea(.all)
        } 
        /*else {
            ZStack {
                Color.black.ignoresSafeArea(.all)
                Image("mosstr_0").resizable().scaledToFit()
            }
        }*/
    }
}

//#Preview {
//    WelcomeContentView()
//}
