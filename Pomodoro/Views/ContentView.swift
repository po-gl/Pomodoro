//
//  ContentView.swift
//  Pomodoro
//
//  Created by Porter Glines on 6/12/22.
//

import SwiftUI

struct ContentView: View {
    // TODO move to constants file
    let backgroundActiveColors = [Color(hex: 0xE0EDA4), Color(hex: 0xEDD9A3)]
    let backgroundInactiveColor = Color(hex: 0xFFFFFF)
    let barActiveColors = [Color(hex: 0x44D37B), Color(hex: 0xF06136)]
    let barInactiveColors = [Color(hex: 0x75C493), Color(hex: 0xF08260)]
    
    @ObservedObject var sequenceTimer = SequenceTimer(sequenceOfIntervals: [6.0, 3.0], timerProvider: Timer.self)
    
    @State var backgroundActiveColor = Color(hex: 0xE0EDA4)
    @State var barColors = [Color(hex: 0x44D37B), Color(hex: 0xF08260)]
    @State var timerMessage = "Timer:"

    @State var timerSelections = [[0, 0, 6], [0, 0, 3]]
    
    @State var colorBarProportions = [0.666, 0.333]
    @State var colorBarIndicatorProgress = 0.0
    

    var body: some View {
        GeometryReader { metrics in
            
            VStack {
                HStack {
                    Spacer()
                    menuButton()
                        .padding(.horizontal)
                        .padding(.top)
                        .foregroundColor(.black)
                }
                Spacer()
                timerDisplay()
                Spacer()
                colorBar(metrics)
                    .frame(maxHeight: 130)

                HStack {
                    Spacer()
                    pickerCluster()
                        .padding(.trailing, 20)
                }
                Spacer()
                buttonCluster()
                Spacer()
            }
            .background(sequenceTimer.isPaused ? backgroundInactiveColor : backgroundActiveColor)
        }
    }
    
    
    func handleTimerEnd() {
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundActiveColor = backgroundActiveColors[sequenceTimer.currentIndex]
            updateBarColors()
        }
        
        // Asking permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        
        // Vibration?
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Notification
        let content = UNMutableNotificationContent()
        content.title = "Time is up."
        content.subtitle = "\(Date().formatted(date: .abbreviated, time: .shortened)) it happens to everyone"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
    

    func timerDisplay() -> some View {
        VStack(alignment: .leading) {
            Text("\(timerMessage) \(sequenceTimer.currentIndex+1)")
                .font(.system(size: 30))
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
                .onChange(of: sequenceTimer.currentIndex) { _ in
                    handleTimerEnd()
                }
            Text("\(sequenceTimer.timeRemaining.timerFormatted())")
                .font(.system(size: 70))
                .fontWeight(.light)
                .monospacedDigit()
                .onChange(of: sequenceTimer.timeRemaining) { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        colorBarIndicatorProgress = getTimerProgress()
                    }
                }
                .shadow(radius: 20)
        }
    }

    func colorBar(_ metrics: GeometryProxy) -> some View {
        VStack (alignment: .leading){
            downArrow()
                .offset(x: (metrics.size.width-20) * colorBarIndicatorProgress)
            HStack(spacing: 0) {
                ForEach(0..<timerSelections.count, id: \.self) { i in
                    ZStack {
                        Rectangle()
                            .foregroundColor(barColors[i])
                            .innerShadow(using: Rectangle())
                            .cornerRadius(10)
                            .padding(.horizontal, 2)
                        highlightRectangle()
                    }
                        .frame(maxWidth: metrics.size.width * colorBarProportions[i], maxHeight: 80)
                }
            }
            upArrow()
                .offset(x: (metrics.size.width-20) * colorBarIndicatorProgress)
        }
    }

    func buttonCluster() -> some View {
        return HStack {
            Spacer()
            Button(action: {
                sequenceTimer.reset()
            }, label: {
                Text("Reset")
                    .font(.system(size: 20).monospaced())
                    .foregroundColor(sequenceTimer.isPaused ? .orange : .gray)
            })
            .disabled(!sequenceTimer.isPaused)
            Spacer()

            Button(action: {
                withAnimation(.easeIn(duration: 0.2)){
                    sequenceTimer.toggle()
                    if sequenceTimer.isPaused {
                        resetBarColors()
                    } else {
                        updateBarColors()
                    }
                }
            }, label: {
                Text(sequenceTimer.isPaused ? "Start" : "Stop")
                    .font(.system(size: 30).monospaced())
            })
            Spacer()
        }
    }

    func pickerCluster() -> some View {
        return VStack {
            ForEach(0..<timerSelections.count, id: \.self) { i in
                 TimePicker(selections: $timerSelections[i])
                    .padding(.top, 10)
                    .disabled(!sequenceTimer.isPaused)
                    .onChange(of: timerSelections[i]) { _ in
                        sequenceTimer.reset(getTimerSelectionIntervals())
                        updateProportions()
                    }
            }
        }
    }
    

    func getTimerSelectionIntervals() -> [TimeInterval] {
        var intervals: [TimeInterval] = []
        for timerSelection in timerSelections {
            intervals.append(selectionsToSeconds(timerSelection))
        }
        return intervals
    }

    func selectionsToSeconds(_ selections: [Int]) -> TimeInterval {
        let hourSeconds = selections[0] * 60 * 60
        let minuteSeconds = selections[1] * 60
        let seconds = selections[2]
        return TimeInterval(hourSeconds + minuteSeconds + seconds)
    }
    
    func updateProportions() {
        let intervals = getTimerSelectionIntervals()
        let total = intervals.reduce(0, +)
        for i in 0..<intervals.count {
            colorBarProportions[i] = intervals[i] / total
        }
    }
    
    func getTimerProgress() -> TimeInterval {
        let intervals = getTimerSelectionIntervals()
        let total = intervals.reduce(0, +)
        var cumulative = 0.0
        for i in 0..<sequenceTimer.currentIndex {
           cumulative += intervals[i]
        }
        let currentTime = intervals[sequenceTimer.currentIndex] - sequenceTimer.timeRemaining
        return (cumulative + currentTime) / total
    }
    
    
    func menuButton() -> some View {
        return Menu {
            Button(action: {}) {
                Label("Manage Timers", systemImage: "clock.arrow.2.circlepath")
            }
            Button(action: {}) {
                Label("About", systemImage: "sparkles")
                    .symbolRenderingMode(.multicolor)
            }
        }
        label: {
            Button(action: {}) {
                ZStack {
                    Circle()
                        .frame(maxWidth: 40)
                        .foregroundColor(.white)
                        .opacity(0.0)
                    Image(systemName: "cloud.rain.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 20))
                        .shadow(radius: 20)
                }
            }
        }
    }
    
    
    func updateBarColors() {
        for i in 0..<timerSelections.count {
            barColors[i] = i == sequenceTimer.currentIndex ? barActiveColors[i] : barInactiveColors[i]
        }
    }
    
    func resetBarColors() {
        for i in 0..<timerSelections.count {
            barColors[i] = barActiveColors[i]
        }
    }
    

    func downArrow() -> some View {
        return Image(systemName: "arrowtriangle.down.fill")
            .imageScale(.large)
            .foregroundColor(Color(hex: 0x444444))
            .opacity(0.9)
    }
    
    func upArrow() -> some View {
        return Image(systemName: "arrowtriangle.up.fill")
            .imageScale(.large)
            .foregroundColor(Color(hex: 0xAAAAAA))
            .opacity(0.7)
    }
    
    func highlightRectangle() -> some View {
        VStack() {
            HStack() {
                Spacer()
                ZStack {
                    Rectangle()
                        .frame(maxWidth: 16, maxHeight: 2)
                        .foregroundColor(.white)
                        .blur(radius: 4)
                        .padding(12)
                    Rectangle()
                        .frame(maxWidth: 8, maxHeight: 2)
                        .foregroundColor(.white)
                        .blur(radius: 2)
                        .padding(12)
                }
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
