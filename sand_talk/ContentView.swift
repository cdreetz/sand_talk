//
//  ContentView.swift
//  sand_talk
//
//  Created by Christian Reetz on 7/22/23.
//


import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var responseText: String = ""
    
    @State private var audioURL: URL?
    @State private var transcribedText: String = ""
    
    @State private var isTranscriptionPermissionGranted = false

    var body: some View {
        VStack {
            TextField("Enter text", text: $inputText)
                .padding()

            Button(action: {
                sendText(inputText) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let responseText):
                            self.responseText = responseText
                        case .failure(let error):
                            self.responseText = "Error: \(error.localizedDescription)"
                        }
                    }
                }
            }) {
                Text("Send to GPT")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!isTranscriptionPermissionGranted)

            Text(responseText)
                .padding()
        }
        .onAppear(perform: {
            self.requestTranscriptionPermission()
        })
    }
    func sendText(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Convert the endpoint URL string to a URL object
        guard let url = URL(string: "http://127.0.0.1:8000/get_gpt_response") else {
            print("Invalid URL")
            return
        }

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set the request body
        let jsonData = try? JSONSerialization.data(withJSONObject: ["input": text])
        request.httpBody = jsonData

        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                do {
                    // Parse the JSON data
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let responseText = json["output"] as? String {
                        completion(.success(responseText))
                    }
                } catch {
                    print("Failed to parse JSON: \(error)")
                    completion(.failure(error))
                }
            }
        }
        // Start the data task
        task.resume()
    }
    func requestTranscriptionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.isTranscriptionPermissionGranted = true
                default:
                    self.isTranscriptionPermissionGranted = false
                }
            }
        }
    }
    func startTranscription() {
        // Check that the audioURL exists before proceeding
        guard let validAudioURL = audioURL else {
            print("No audio URL available for transcription")
            return
        }
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: validAudioURL)
        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            } else if let error = error {
                print("There was an error: \(error)")
            }
        }
    }
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }

}





    func sendAudioData(_ audioData: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        // Convert the endpoint URL string to a URL object
        guard let url = URL(string: "http://127.0.0.1:8000") else {
            print("Invalid URL")
            return
        }
        
        // Create the URLRequest object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = audioData
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //Handle the result of the data task
            if let data = data {
                completion(.success(data))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    
        // Start the data task
        task.resume()

}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
