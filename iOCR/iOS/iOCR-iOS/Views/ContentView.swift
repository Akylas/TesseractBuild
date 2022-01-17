//
//  ContentView.swift
//  iOCR
//
//  Created by Zach Young on 9/17/20.
//

import SwiftUI

import libtesseract

/// Run this demo as **iPad Pro (12.9-inch)**
struct ContentView: View {

    let jpnCaption = "Japanese (horizontal)"
    let jpnRecognizer = Recognizer(imgName: "japanese", trainedDataName: "jpn", imgDPI: 144)

    let jpnVertCaption = "Japanese (vertical)"
    let jpnVertRecognizer = Recognizer(imgName: "japanese_vert", trainedDataName: "jpn_vert", imgDPI: 144)

    let chiTraVertCaption = "Traditional Chinese"
    let chiTraVertRecognizer = Recognizer(imgName: "chinese_traditional_vert", trainedDataName: "chi_tra_vert")

    let engCaption = "English (left-justified)"
    let engRecognizer = Recognizer(imgName: "english_left_just_square", trainedDataName: "eng", tessPSM: PSM_SINGLE_BLOCK, tessPIL: RIL_BLOCK)

    var body: some View {
        if (UIDevice.current.userInterfaceIdiom == .pad)
        {
            let columns = [
                GridItem(.flexible(), spacing: 0),
                GridItem(.flexible(), spacing: 0),
            ]
            
            LazyVGrid(columns: columns) {
                RecognizedView(jpnCaption, jpnRecognizer).frame(width: 500, height: 650)
                RecognizedView(jpnVertCaption, jpnVertRecognizer).frame(width: 500, height: 650)
                RecognizedView(chiTraVertCaption, chiTraVertRecognizer).frame(width: 500, height: 650)
                RecognizedView(engCaption, engRecognizer).frame(width: 500, height: 650)
            }
        }
        else
        {
            ScrollView {
                VStack {
                    RecognizedView(jpnCaption, jpnRecognizer).frame(width: 300, height: 390)
                    RecognizedView(jpnVertCaption, jpnVertRecognizer).frame(width: 300, height: 390)
                    RecognizedView(chiTraVertCaption, chiTraVertRecognizer).frame(width: 300, height: 390)
                    RecognizedView(engCaption, engRecognizer).frame(width: 300, height: 390)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
