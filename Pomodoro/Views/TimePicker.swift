//
//  TimePicker.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/17/22.
//

import Foundation
import SwiftUI

struct TimePicker: View {
    let data: [[String]] = [
        Array(0...24).map { "\($0) hr" },
        Array(0...59).map { "\($0) min" },
        Array(0...59).map { "\($0) s" }
    ]

    @Binding var selections: [Int]
    @State var showingPopover = false

    var body: some View {
        Button(action: {
            showingPopover = true
        }, label: {
            Text("\(self.data[0][self.selections[0]]) \(self.data[1][self.selections[1]]) \(self.data[2][self.selections[2]])")
                .monospacedDigit()
        })
        .foregroundColor(.primary)
        .buttonStyle(.bordered)
        .alwaysPopover(isPresented: $showingPopover) {
            TimePickerView(data: self.data, selections: self.$selections)
                .frame(width: 280, height: 200)
                .padding()
        }
    }
}

struct TimePicker_Previews: PreviewProvider {
    
    @State static var selections = [0, 12, 30]
    
    static var previews: some View {
        VStack {
            VStack {
                Text("Seconds: \(selections[2])")
            }
                .frame(maxWidth: 200, maxHeight: 200)
                .background(Color(hex: 0xCEE8C1))
                .cornerRadius(30)
                .padding(.bottom, 140)

            TimePicker(selections: $selections)
        }
    }
}


struct TimePickerView: UIViewRepresentable {
    var data: [[String]]
    @Binding var selections: [Int]

    func makeCoordinator() -> TimePickerView.Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: UIViewRepresentableContext<TimePickerView>) -> UIPickerView {
        let picker = UIPickerView(frame: .zero)

        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIView(_ view: UIPickerView, context: UIViewRepresentableContext<TimePickerView>) {
        for i in 0..<(self.selections.count) {
            view.selectRow(self.selections[i], inComponent: i, animated: false)
        }
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: TimePickerView

        init(_ pickerView: TimePickerView) {
            self.parent = pickerView
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return self.parent.data.count
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return self.parent.data[component].count
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return self.parent.data[component][row]
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            self.parent.selections[component] = row
        }
    }
}
