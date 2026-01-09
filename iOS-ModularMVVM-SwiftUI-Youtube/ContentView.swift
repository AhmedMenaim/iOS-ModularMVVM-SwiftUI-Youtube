//
//  ContentView.swift
//  iOS-ModularMVVM-SwiftUI-Youtube
//
//  Created by Menaim on 13/10/2025.
//

import SwiftUI
import Combine

struct ContentView: View {
  @State private var cancellables: Set<AnyCancellable> = []
  @StateObject private var network = MoviesNetworkManager()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
          network.getMovies(currentPage: 1)
            .sink { failure in
              print(failure)
            } receiveValue: { response in
              print(response.results ?? [])
            }
            .store(in: &cancellables)

        }
    }

}

#Preview {
    ContentView()
}
